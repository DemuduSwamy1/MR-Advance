import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Describes the phone or browser the app runs on. Only general details are
/// collected (maker, model, OS, browser); no hardware IDs such as the IMEI.
Future<Map<String, Object?>> collectDeviceDetails() async {
  final details = <String, Object?>{};

  try {
    final package = await PackageInfo.fromPlatform();
    details['appVersion'] = '${package.version}+${package.buildNumber}';
  } catch (_) {
    // Not available on this platform.
  }

  try {
    final plugin = DeviceInfoPlugin();
    if (kIsWeb) {
      final web = await plugin.webBrowserInfo;
      details.addAll({
        'platform': 'web',
        'browser': web.browserName.name,
        'os': web.platform,
        'userAgent': web.userAgent,
        'language': web.language,
      });
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final android = await plugin.androidInfo;
          details.addAll({
            'platform': 'android',
            'manufacturer': android.manufacturer,
            'brand': android.brand,
            'model': android.model,
            'os': 'Android ${android.version.release}',
            'sdkInt': android.version.sdkInt,
            'isPhysicalDevice': android.isPhysicalDevice,
          });
        case TargetPlatform.macOS:
          final mac = await plugin.macOsInfo;
          details.addAll({
            'platform': 'macos',
            'model': mac.model,
            'os': 'macOS ${mac.osRelease}',
          });
        case TargetPlatform.windows:
          final windows = await plugin.windowsInfo;
          details.addAll({
            'platform': 'windows',
            'model': windows.productName,
            'os': 'Windows ${windows.displayVersion}',
          });
        default:
          details['platform'] = defaultTargetPlatform.name;
      }
    }
  } catch (_) {
    details['platform'] ??= kIsWeb ? 'web' : defaultTargetPlatform.name;
  }

  return details;
}
