import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/medical_documents_provider.dart';

/// Vista previa real de una imagen adjunta (JPG/JPEG/PNG/...).
class ImageAttachmentPreview extends ConsumerWidget {
  final String fileName;
  final String url;

  const ImageAttachmentPreview({super.key, required this.fileName, required this.url});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytesAsync = ref.watch(medicalAttachmentBytesProvider(url));

    final preview = bytesAsync.when(
      data: (bytes) => Image.memory(
        bytes,
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const _PreviewError(),
      ),
      error: (error, stackTrace) => const _PreviewError(),
      loading: () => const _PreviewLoading(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Container(
            color: Colors.black.withValues(alpha: 0.25),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: preview,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.attach_file, size: 16, color: AppColors.gold),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                fileName,
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () => Clipboard.setData(ClipboardData(text: url)),
              child: const Icon(
                Icons.copy,
                size: 14,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PreviewLoading extends StatelessWidget {
  const _PreviewLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.gold,
          ),
        ),
      ),
    );
  }
}

class _PreviewError extends StatelessWidget {
  const _PreviewError();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 32),
            SizedBox(height: 8),
            Text(
              'No se pudo cargar la vista previa',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// Adjunto PDF: permite abrirlo/compartirlo sin mostrar el URL como sustituto.
class PdfAttachmentPreview extends ConsumerStatefulWidget {
  final String fileName;
  final String url;

  const PdfAttachmentPreview({super.key, required this.fileName, required this.url});

  @override
  ConsumerState<PdfAttachmentPreview> createState() => _PdfAttachmentPreviewState();
}

class _PdfAttachmentPreviewState extends ConsumerState<PdfAttachmentPreview> {
  bool _busy = false;

  Future<void> _openPdf() async {
    setState(() => _busy = true);
    try {
      final bytes = await ref.read(storageServiceProvider).readFileBytes(widget.url);
      await Printing.sharePdf(
        bytes: bytes,
        filename: widget.fileName.endsWith('.pdf')
            ? widget.fileName
            : '${widget.fileName}.pdf',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(AppTheme.errorSnackBar('No se pudo abrir el PDF'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.picture_as_pdf, size: 16, color: AppColors.gold),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                widget.fileName,
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () => Clipboard.setData(ClipboardData(text: widget.url)),
              child: const Icon(
                Icons.copy,
                size: 14,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _openPdf,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('Abrir PDF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.gold,
              side: const BorderSide(color: AppColors.gold),
            ),
          ),
        ),
      ],
    );
  }
}

/// Otro adjunto: muestra el enlace copiable.
class OtherAttachmentPreview extends StatelessWidget {
  final String fileName;
  final String url;

  const OtherAttachmentPreview({super.key, required this.fileName, required this.url});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 130,
            child: Text(
              'Archivo',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => Clipboard.setData(ClipboardData(text: url)),
              child: Row(
                children: [
                  const Icon(
                    Icons.attach_file,
                    size: 16,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      fileName,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.copy, size: 14, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
