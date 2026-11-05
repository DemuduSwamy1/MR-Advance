import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../features/invoice/data/bill_record.dart';
import '../../features/invoice/domain/models/invoice.dart';
import '../../features/invoice/domain/services/invoice_calculator.dart';
import '../../firebase_options.dart';
import 'device_details.dart';

/// Saves bills and usage to Firebase in the background, with no action from
/// the user.
///
/// Each phone or browser signs in anonymously, so it gets its own user ID
/// without a login screen. Firestore collections:
///
/// * `users/{userId}`: device details, first and last seen, session, bill
///   and report counts.
/// * `users/{userId}/sessions/{id}`: one document per app session.
/// * `bills/{userId_billNo_date}`: every generated invoice.
///
/// Writes are queued on the device and sent when there is a connection. If
/// Firebase is not configured or cannot start, the app keeps working without
/// it.
class CloudSync {
  CloudSync._();

  static final instance = CloudSync._();

  /// Coming back after this long in the background starts a new session,
  /// matching how Firebase Analytics counts sessions.
  static const newSessionAfter = Duration(minutes: 30);

  Future<String?>? _ready;
  Map<String, Object?> _device = const {};
  DateTime? _hiddenAt;
  // Kept so the listener stays registered for the life of the app.
  // ignore: unused_field
  AppLifecycleListener? _lifecycle;

  /// Starts Firebase in the background; safe to call more than once.
  void start() => _ready ??= _initialize();

  Future<String?> _initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (error) {
      debugPrint('Cloud sync is off: $error');
      return null;
    }

    try {
      if (kIsWeb) {
        // Keep queued bills when the browser tab is closed while offline.
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
        );
      }

      final auth = FirebaseAuth.instance;
      // Wait for a saved sign-in to be restored before creating a new user.
      final user =
          await auth.authStateChanges().first ??
          (await auth.signInAnonymously()).user;
      if (user == null) {
        return null;
      }

      _device = await collectDeviceDetails();
      _startSession(user);
      _lifecycle = AppLifecycleListener(
        onHide: () => _hiddenAt = DateTime.now(),
        onShow: () {
          final hiddenAt = _hiddenAt;
          _hiddenAt = null;
          if (hiddenAt != null &&
              DateTime.now().difference(hiddenAt) >= newSessionAfter) {
            _startSession(user);
          }
        },
      );
      return user.uid;
    } catch (error) {
      debugPrint('Cloud sync could not sign in: $error');
      return null;
    }
  }

  void _startSession(User user) {
    final userDoc = _users.doc(user.uid);
    final created = user.metadata.creationTime;

    _write(
      userDoc.set({
        if (created != null) 'firstSeenAt': Timestamp.fromDate(created),
        'lastSeenAt': FieldValue.serverTimestamp(),
        'sessionCount': FieldValue.increment(1),
        'platform': _device['platform'],
        'appVersion': _device['appVersion'],
        'device': _device,
      }, SetOptions(merge: true)),
    );
    _write(
      userDoc.collection('sessions').add({
        'startedAt': FieldValue.serverTimestamp(),
        'platform': _device['platform'],
        'appVersion': _device['appVersion'],
        'device': _device,
      }),
    );
  }

  /// Saves a generated invoice. Generating the same bill again updates the
  /// saved copy. Returns false when cloud sync is off.
  Future<bool> saveBill(Invoice invoice, InvoiceTotals totals) async {
    final userId = await _userId();
    if (userId == null) {
      return false;
    }

    final id = billDocumentId(
      userId: userId,
      billNumber: invoice.billNumber,
      date: invoice.date,
    );
    _write(
      FirebaseFirestore.instance.collection('bills').doc(id).set({
        ...billRecord(invoice, totals),
        'billDateTime': Timestamp.fromDate(invoice.date),
        'userId': userId,
        'device': _device,
        'generatedAt': FieldValue.serverTimestamp(),
        'generateCount': FieldValue.increment(1),
      }, SetOptions(merge: true)),
    );
    _write(
      _users.doc(userId).set({
        'billsGenerated': FieldValue.increment(1),
        'lastBillAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );
    _logEvent('invoice_generated', {
      'items': totals.itemCount,
      'net_amount': totals.netPaise / 100,
    });
    return true;
  }

  /// Counts a converted report (the report itself is not uploaded).
  Future<void> recordReportConverted({required int pageCount}) async {
    final userId = await _userId();
    if (userId == null) {
      return;
    }

    _write(
      _users.doc(userId).set({
        'reportsConverted': FieldValue.increment(1),
        'lastReportAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );
    _logEvent('report_converted', {'pages': pageCount});
  }

  Future<String?> _userId() async {
    final ready = _ready;
    return ready == null ? null : await ready;
  }

  CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection('users');

  /// Firestore confirms a write only once it reaches the server, which never
  /// happens while offline, so writes are not awaited; failures are logged.
  void _write(Future<Object?> write) {
    unawaited(
      write.then<void>(
        (_) {},
        onError: (Object error) =>
            debugPrint('Cloud sync write failed: $error'),
      ),
    );
  }

  void _logEvent(String name, Map<String, Object> parameters) {
    unawaited(
      FirebaseAnalytics.instance
          .logEvent(name: name, parameters: parameters)
          .catchError((Object error) {
            debugPrint('Analytics event failed: $error');
          }),
    );
  }
}
