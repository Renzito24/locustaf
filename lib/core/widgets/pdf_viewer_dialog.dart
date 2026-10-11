import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:file_saver/file_saver.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_colors.dart';
import '../providers/firebase_providers.dart';

/// Visor de PDF compartido entre Recibos y Comunicados.
///
/// Carga el archivo desde [storagePath] (ruta relativa o URL) usando el SDK
/// autenticado de Firebase Storage. Muestra el PDF en pantalla casi completa
/// con título, botón descargar (guarda con [downloadFileName]) y botón cerrar.
class PdfViewerDialog extends ConsumerStatefulWidget {
  final String storagePath;
  final String downloadFileName;
  final String title;
  final VoidCallback? onPdfLoaded;

  const PdfViewerDialog({
    super.key,
    required this.storagePath,
    required this.downloadFileName,
    required this.title,
    this.onPdfLoaded,
  });

  @override
  ConsumerState<PdfViewerDialog> createState() => _PdfViewerDialogState();
}

class _PdfViewerDialogState extends ConsumerState<PdfViewerDialog> {
  Uint8List? _pdfBytes;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final storageService = ref.read(storageServiceProvider);
      final bytes = await storageService.readFileBytes(widget.storagePath);
      if (mounted) {
        setState(() {
          _pdfBytes = bytes;
          _loading = false;
        });
        widget.onPdfLoaded?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _download() async {
    if (_pdfBytes == null) return;
    try {
      await FileSaver.instance.saveFile(
        name: widget.downloadFileName,
        bytes: _pdfBytes!,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al descargar: $e')),
        );
      }
    }
  }

  Future<void> _openInNewTab() async {
    try {
      final storageService = ref.read(storageServiceProvider);
      final url = await storageService.getDownloadUrl(widget.storagePath);
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el documento en una pestaña nueva')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir el documento: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.2)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: screenSize.width * 0.92,
        height: screenSize.height * 0.90,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textWhite,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_pdfBytes != null)
                  IconButton(
                    tooltip: 'Descargar ${widget.downloadFileName}',
                    icon: const Icon(LucideIcons.download, color: AppColors.gold),
                    onPressed: _download,
                  ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: AppColors.textSecondary.withValues(alpha: 0.2)),
            const SizedBox(height: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                    : _error != null
                        ? _buildError()
                        : _pdfBytes != null
                            ? PdfViewer.data(_pdfBytes!, sourceName: widget.downloadFileName)
                            : const Center(child: Text('No hay datos', style: TextStyle(color: AppColors.textSecondary))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              const Text('Error al cargar el PDF', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 16),
              if (kIsWeb) ...[
                ElevatedButton.icon(
                  onPressed: _openInNewTab,
                  icon: const Icon(LucideIcons.externalLink),
                  label: const Text('Abrir documento en pestaña nueva'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.white),
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton.icon(
                onPressed: () {
                  setState(() { _loading = true; _error = null; });
                  _loadPdf();
                },
                icon: const Icon(LucideIcons.refreshCw),
                label: const Text('Reintentar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.gold,
                  side: const BorderSide(color: AppColors.gold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
