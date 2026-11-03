import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/exceptions/conversion_exception.dart';
import '../data/file_picker_service.dart';
import '../data/file_save_service.dart';
import '../domain/models/conversion_result.dart';
import '../domain/services/conversion_service.dart';
import '../domain/services/report_decoder.dart';
import 'pdf_preview_screen.dart';
import 'widgets/conversion_summary_card.dart';
import 'widgets/file_selection_card.dart';
import 'widgets/primary_action_button.dart';
import 'widgets/warning_card.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final _filePickerService = FilePickerService();
  final _fileSaveService = FileSaveService();
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Legacy Report to PDF Converter')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const _Header(),
                const SizedBox(height: 20),
                FileSelectionCard(
                  selectedFile: _selectedFile,
                  detectedEncoding: _detectedEncoding,
                  isLoading: _isPicking,
                  onSelect: _isBusy ? null : () => _pickFile(),
                  onBrowseAll: _isBusy
                      ? null
                      : () => _pickFile(allowAnyFile: true),
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
                if (_result != null) ...[
                  const SizedBox(height: 20),
                  ConversionSummaryCard(result: _result!),
                  if (_result!.validation.warnings.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    WarningCard(warnings: _result!.validation.warnings),
                  ],
                  const SizedBox(height: 16),
                  _ResultActions(
                    isSaving: _isSaving,
                    isSharing: _isSharing,
                    onPreview: _isBusy ? null : _previewPdf,
                    onSave: _hasResult && !_isBusy ? _savePdf : null,
                    onShare: _hasResult && !_isBusy ? _sharePdf : null,
                    onReset: _isBusy ? null : _reset,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickFile({bool allowAnyFile = false}) async {
    setState(() {
      _isPicking = true;
      _result = null;
      _detectedEncoding = null;
      _selectionWarnings = const [];
    });

    try {
      final file = await _filePickerService.pickReportFile(
        allowAnyFile: allowAnyFile,
      );

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
      MaterialPageRoute<void>(builder: (_) => PdfPreviewScreen(result: result)),
    );
  }

  Future<void> _savePdf() async {
    final result = _result;
    if (result == null) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final uri = await _fileSaveService.savePdf(
        fileName: result.outputFileName,
        bytes: result.pdfBytes,
      );

      if (!mounted) {
        return;
      }

      if (uri == null) {
        _showMessage('Save canceled.');
      } else {
        _showMessage('Saved ${result.outputFileName}.');
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
      final file = await _fileSaveService.writeTemporaryPdf(
        fileName: result.outputFileName,
        bytes: result.pdfBytes,
      );
      await SharePlus.instance.share(
        ShareParams(
          title: 'Share converted report',
          subject: result.outputFileName,
          files: [
            XFile(
              file.path,
              name: result.outputFileName,
              mimeType: 'application/pdf',
            ),
          ],
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
          'Select a legacy report file from disk. Conversion happens locally and preserves rows, spacing, totals, page breaks, and column alignment.',
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
