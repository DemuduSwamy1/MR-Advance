import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/cloud/cloud_sync.dart';
import '../../../core/exceptions/conversion_exception.dart';
import '../../../core/widgets/page_heading.dart';
import '../../../core/widgets/pdf_preview_screen.dart';
import '../../../core/widgets/primary_action_button.dart';
import '../data/file_picker_service.dart';
import '../data/file_save_service.dart';
import '../data/incoming_file_service.dart';
import '../domain/models/conversion_result.dart';
import '../domain/services/conversion_service.dart';
import '../domain/services/report_decoder.dart';
import 'widgets/file_selection_card.dart';
import 'widgets/warning_card.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key, this.onIncomingFile});

  /// Called when another app opens or shares a file with this app, so the
  /// home shell can switch to this tab.
  final VoidCallback? onIncomingFile;

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final _filePickerService = FilePickerService();
  final _fileSaveService = FileSaveService();
  final _incomingFileService = IncomingFileService();
  final _conversionService = const ConversionService();
  final _decoder = const ReportDecoder();

  SelectedReportFile? _selectedFile;
  ConversionResult? _result;
  String? _detectedEncoding;
  List<String> _selectionWarnings = const [];
  bool _isPicking = false;
  bool _isConverting = false;
  bool _isSaving = false;
  bool _isSharing = false;

  bool get _hasSelectedFile => _selectedFile != null;
  bool get _hasResult => _result != null;
  bool get _isBusy => _isPicking || _isConverting || _isSaving || _isSharing;

  @override
  void initState() {
    super.initState();
    _incomingFileService.listen(_openIncomingFile);
  }

  @override
  void dispose() {
    _incomingFileService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) =>
              constraints.maxWidth >= wideLayoutBreakpoint
              ? _buildWide()
              : _buildNarrow(),
        ),
      ),
    );
  }

  /// Phones: one column.
  Widget _buildNarrow() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const _Header(),
            const SizedBox(height: 20),
            ..._workflow(),
            if (_result != null) ...[
              const SizedBox(height: 16),
              _resultActions(),
            ],
          ],
        ),
      ),
    );
  }

  /// Wide screens: the steps on the left and a guide on the right.
  Widget _buildWide() {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
          children: [
            PageHeading(
              title: 'Convert report to PDF',
              description: _Header.description,
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ..._workflow(),
                      if (_result != null) ...[
                        const SizedBox(height: 16),
                        _ResultCard(
                          fileName: _result!.outputFileName,
                          pageCount: _result!.pages.length,
                          actions: _resultActions(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                const SizedBox(width: 340, child: _GuideCard()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Pick, check and convert: the same on every screen size.
  List<Widget> _workflow() {
    return [
      FileSelectionCard(
        selectedFile: _selectedFile,
        detectedEncoding: _detectedEncoding,
        isLoading: _isPicking,
        onSelect: _isBusy ? null : _pickFile,
      ),
      if (_selectionWarnings.isNotEmpty) ...[
        const SizedBox(height: 12),
        WarningCard(warnings: _selectionWarnings),
      ],
      const SizedBox(height: 16),
      PrimaryActionButton(
        icon: Icons.picture_as_pdf_outlined,
        label: _isConverting ? 'Converting...' : 'Convert to PDF',
        onPressed: _hasSelectedFile && !_isBusy ? _convert : null,
        isLoading: _isConverting,
      ),
      if (_result != null && _result!.validation.warnings.isNotEmpty) ...[
        const SizedBox(height: 16),
        WarningCard(warnings: _result!.validation.warnings),
      ],
    ];
  }

  Widget _resultActions() {
    return _ResultActions(
      isSaving: _isSaving,
      isSharing: _isSharing,
      onPreview: _isBusy ? null : _previewPdf,
      onSave: _hasResult && !_isBusy ? _savePdf : null,
      onShare: _hasResult && !_isBusy ? _sharePdf : null,
      onReset: _isBusy ? null : _reset,
    );
  }

  Future<void> _pickFile() => _loadFile(_filePickerService.pickReportFile);

  Future<void> _openIncomingFile(Uri uri) {
    widget.onIncomingFile?.call();
    return _loadFile(() => _incomingFileService.readFile(uri));
  }

  Future<void> _loadFile(Future<SelectedReportFile?> Function() load) async {
    setState(() => _isPicking = true);

    try {
      final file = await load();

      if (!mounted) {
        return;
      }

      if (file == null) {
        setState(() => _isPicking = false);
        return;
      }

      final decoded = _decoder.decode(file.bytes);
      setState(() {
        _selectedFile = file;
        _result = null;
        _detectedEncoding = decoded.encodingName;
        _selectionWarnings = [...file.warnings, ...decoded.warnings];
      });
    } catch (error) {
      if (mounted) {
        _showError(error);
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _convert() async {
    final selectedFile = _selectedFile;
    if (selectedFile == null) {
      return;
    }

    setState(() {
      _isConverting = true;
      _result = null;
    });

    try {
      final result = await _conversionService.convert(
        sourceBytes: selectedFile.bytes,
        sourceFileName: selectedFile.name,
        fileWarnings: selectedFile.warnings,
      );

      unawaited(
        CloudSync.instance.recordReportConverted(
          pageCount: result.pages.length,
        ),
      );
      if (mounted) {
        setState(() {
          _result = result;
          _detectedEncoding = result.validation.encodingName;
        });
      }
    } catch (error) {
      if (mounted) {
        _showError(error);
      }
    } finally {
      if (mounted) {
        setState(() => _isConverting = false);
      }
    }
  }

  Future<void> _previewPdf() async {
    final result = _result;
    if (result == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfPreviewScreen(
          pdfBytes: result.pdfBytes,
          fileName: result.outputFileName,
        ),
      ),
    );
  }

  Future<void> _savePdf() async {
    final result = _result;
    if (result == null) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final saved = await _fileSaveService.savePdf(
        fileName: result.outputFileName,
        bytes: result.pdfBytes,
      );

      if (!mounted) {
        return;
      }

      if (!saved) {
        _showMessage('Save canceled.');
      } else {
        _showMessage(
          kIsWeb
              ? 'Downloaded ${result.outputFileName}.'
              : 'Saved ${result.outputFileName}.',
        );
      }
    } catch (error) {
      if (mounted) {
        _showError(error);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _sharePdf() async {
    final result = _result;
    if (result == null) {
      return;
    }

    setState(() => _isSharing = true);
    try {
      final file = await _fileSaveService.shareablePdf(
        fileName: result.outputFileName,
        bytes: result.pdfBytes,
      );
      await SharePlus.instance.share(
        ShareParams(
          title: 'Share converted report',
          subject: result.outputFileName,
          files: [file],
        ),
      );
    } catch (error) {
      if (mounted) {
        _showError(error);
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  void _reset() {
    setState(() {
      _selectedFile = null;
      _result = null;
      _detectedEncoding = null;
      _selectionWarnings = const [];
    });
  }

  void _showError(Object error) {
    final message = error is ConversionException
        ? error.message
        : error.toString();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Header extends StatelessWidget {
  const _Header();

  static String get description => IncomingFileService.isSupported
      ? 'Pick a report file, or open one from WhatsApp, Files, or email with this app. Conversion happens locally and preserves rows, spacing, totals, page breaks, and column alignment.'
      : 'Pick a report file from this device. Conversion happens locally and preserves rows, spacing, totals, page breaks, and column alignment.';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Convert fixed-width printer reports into clean PDFs',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ResultActions extends StatelessWidget {
  const _ResultActions({
    required this.isSaving,
    required this.isSharing,
    required this.onPreview,
    required this.onSave,
    required this.onShare,
    required this.onReset,
  });

  final bool isSaving;
  final bool isSharing;
  final VoidCallback? onPreview;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton.icon(
          onPressed: onPreview,
          icon: const Icon(Icons.preview_outlined),
          label: const Text('Preview PDF'),
        ),
        OutlinedButton.icon(
          onPressed: onSave,
          icon: isSaving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_alt_outlined),
          label: Text(isSaving ? 'Saving...' : 'Save PDF'),
        ),
        OutlinedButton.icon(
          onPressed: onShare,
          icon: isSharing
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.ios_share_outlined),
          label: Text(isSharing ? 'Sharing...' : 'Share PDF'),
        ),
        TextButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.refresh_outlined),
          label: const Text('Reset'),
        ),
      ],
    );
  }
}

/// Shown on wide screens once the PDF is ready.
class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.fileName,
    required this.pageCount,
    required this.actions,
  });

  final String fileName;
  final int pageCount;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.check_rounded,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PDF ready', style: textTheme.titleMedium),
                      Text(
                        '$fileName  ·  $pageCount '
                        '${pageCount == 1 ? 'page' : 'pages'}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            actions,
          ],
        ),
      ),
    );
  }
}

/// How the converter works, beside the steps on wide screens.
class _GuideCard extends StatelessWidget {
  const _GuideCard();

  static const _steps = [
    (
      Icons.upload_file_outlined,
      'Select the report',
      'Plain-text printer reports: .txt, .prn, .dat, .lis, .out or no '
          'extension.',
    ),
    (
      Icons.picture_as_pdf_outlined,
      'Convert to PDF',
      'Columns, totals and page breaks are kept exactly as printed.',
    ),
    (
      Icons.ios_share_outlined,
      'Preview, save or share',
      'Print it, download it, or send it on.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How it works', style: textTheme.titleMedium),
            const SizedBox(height: 16),
            for (var i = 0; i < _steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        '${i + 1}',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _steps[i].$1,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _steps[i].$2,
                                  style: textTheme.titleSmall,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _steps[i].$3,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 8),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The report is converted on this device and never '
                    'uploaded.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
