import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/models/medical_document_model.dart';
import '../../domain/file_attachment_kind.dart';
import '../providers/medical_documents_provider.dart';

class MedicalDocumentDetailDialog extends ConsumerWidget {
  final MedicalDocumentModel document;
  final String employeeName;
  final String employeeEmail;

  const MedicalDocumentDetailDialog({
    super.key,
    required this.document,
    required this.employeeName,
    required this.employeeEmail,
  });

  static Future<void> show(
    BuildContext context, {
    required MedicalDocumentModel document,
    required String employeeName,
    required String employeeEmail,
  }) {
    return showDialog(
      context: context,
      builder: (_) => MedicalDocumentDetailDialog(
        document: document,
        employeeName: employeeName,
        employeeEmail: employeeEmail,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issue = _formatDate(document.fechaInicio);
    final expiry = _formatDate(document.fechaFin);
    final isAdmin = ref.watch(isAdminProvider);
    final isApproving = ref.watch(medicalDocumentApprovalProvider).isLoading;

    return Dialog(
      backgroundColor: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold.withValues(alpha: 0.15),
                      ),
                      child: const Icon(
                        Icons.description,
                        color: AppColors.gold,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Detalle del documento',
                        style: AppTheme.headingMd,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                Divider(
                  height: 24,
                  color: AppColors.gold.withValues(alpha: 0.15),
                ),
                _DetailRow(label: 'Empleado', value: employeeName),
                _DetailRow(label: 'Email', value: employeeEmail),
                _DetailRow(label: 'Tipo', value: document.tipo.label),
                _DetailRow(label: 'Emisión', value: issue),
                _DetailRow(label: 'Vencimiento', value: expiry),
                _DetailRow(
                  label: 'Vigencia',
                  value: document.vigencia.label,
                  valueColor: _vigenciaColor(document.vigencia),
                ),
                _DetailRow(
                  label: 'Estado',
                  value: document.estado.label,
                  valueColor: _estadoColor(document.estado),
                ),
                if (document.motivo.isNotEmpty)
                  _DetailRow(label: 'Observaciones', value: document.motivo),
                if (document.observacionRechazo != null &&
                    document.observacionRechazo!.isNotEmpty)
                  _DetailRow(
                    label: 'Motivo de rechazo',
                    value: document.observacionRechazo!,
                    valueColor: AppColors.error,
                  ),
                if (document.archivoUrl != null &&
                    document.archivoUrl!.isNotEmpty)
                  _ArchivoAdjunto(
                    fileName: document.archivoNombre ?? document.archivoUrl!,
                    url: document.archivoUrl!,
                    kind: fileAttachmentKind(
                      mimeType: document.mimeType,
                      fileName: document.archivoNombre,
                    ),
                  ),
                if (isAdmin &&
                    document.estado == MedicalDocumentEstado.pendiente) ...[
                  const SizedBox(height: 16),
                  Divider(
                    height: 24,
                    color: AppColors.gold.withValues(alpha: 0.15),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isApproving
                              ? null
                              : () => _confirmReject(context, ref),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Rechazar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: isApproving
                              ? null
                              : () {
                                  ref
                                      .read(
                                        medicalDocumentApprovalProvider
                                            .notifier,
                                      )
                                      .approve(document.id);
                                },
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Aprobar'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmReject(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        title: Text('Rechazar documento', style: AppTheme.headingMd),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: AppTheme.inputDecoration(
            label: 'Motivo del rechazo *',
            icon: Icons.comment_outlined,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          FilledButton(
            onPressed: () {
              final motivo = controller.text.trim();
              if (motivo.isEmpty) return;
              Navigator.of(ctx).pop();
              ref
                  .read(medicalDocumentApprovalProvider.notifier)
                  .reject(document.id, observacion: motivo);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Color _vigenciaColor(VigenciaEstado v) {
    switch (v) {
      case VigenciaEstado.vigente:
        return AppColors.success;
      case VigenciaEstado.proximoAVencer:
        return AppColors.warning;
      case VigenciaEstado.vencido:
        return AppColors.error;
    }
  }

  Color _estadoColor(MedicalDocumentEstado e) {
    switch (e) {
      case MedicalDocumentEstado.pendiente:
        return AppColors.warning;
      case MedicalDocumentEstado.aprobado:
        return AppColors.success;
      case MedicalDocumentEstado.rechazado:
        return AppColors.error;
    }
  }
}

/// Muestra el adjunto según su tipo: imágenes como vista previa real, PDFs con
/// un botón "Abrir PDF" y otros tipos como el enlace copiable original.
///
/// Fase B — Corrección: antes todos los adjuntos se mostraban como un enlace
/// (el URL de Storage en lugar de la imagen). Ahora la URL nunca se muestra
/// como sustituto de la previsualización.
class _ArchivoAdjunto extends StatelessWidget {
  final String fileName;
  final String url;
  final FileAttachmentKind kind;

  const _ArchivoAdjunto({
    required this.fileName,
    required this.url,
    required this.kind,
  });

  @override
  Widget build(BuildContext context) {
    if (kind == FileAttachmentKind.other) {
      return _FileRow(fileName: fileName, url: url);
    }

    final content = kind == FileAttachmentKind.image
        ? _ImageAdjunto(fileName: fileName, url: url)
        : _PdfAdjunto(fileName: fileName, url: url);

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
          Expanded(child: content),
        ],
      ),
    );
  }
}

/// Vista previa real de una imagen adjunta (JPG/JPEG/PNG/...).
class _ImageAdjunto extends StatelessWidget {
  final String fileName;
  final String url;

  const _ImageAdjunto({required this.fileName, required this.url});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Container(
            color: Colors.black.withValues(alpha: 0.25),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: Image.network(
                url,
                width: double.infinity,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
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
                },
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    height: 120,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.textMuted,
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No se pudo cargar la vista previa',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
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

/// Adjunto PDF: permite abrirlo/compartirlo sin mostrar el URL como sustituto.
class _PdfAdjunto extends StatefulWidget {
  final String fileName;
  final String url;

  const _PdfAdjunto({required this.fileName, required this.url});

  @override
  State<_PdfAdjunto> createState() => _PdfAdjuntoState();
}

class _PdfAdjuntoState extends State<_PdfAdjunto> {
  bool _busy = false;

  Future<void> _openPdf() async {
    setState(() => _busy = true);
    try {
      final response = await http.get(Uri.parse(widget.url));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      await Printing.sharePdf(
        bytes: response.bodyBytes,
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

class _FileRow extends StatelessWidget {
  final String fileName;
  final String url;

  const _FileRow({required this.fileName, required this.url});

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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.textWhite,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
