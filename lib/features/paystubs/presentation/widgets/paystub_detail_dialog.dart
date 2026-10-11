import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/pdf_viewer_dialog.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../domain/models/paystub_model.dart';
import '../providers/paystubs_provider.dart';
import '../../../../core/providers/async_action_state.dart';

class PaystubDetailDialog extends ConsumerStatefulWidget {
  final PaystubModel paystub;
  final UserModel? user;
  final bool isAdmin;

  const PaystubDetailDialog({
    super.key,
    required this.paystub,
    this.user,
    required this.isAdmin,
  });

  @override
  ConsumerState<PaystubDetailDialog> createState() => _PaystubDetailDialogState();
}

class _PaystubDetailDialogState extends ConsumerState<PaystubDetailDialog> {
  final _observacionController = TextEditingController();
  bool _isRejecting = false;

  @override
  void dispose() {
    _observacionController.dispose();
    super.dispose();
  }

  void _handleApprove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar aceptación'),
        content: Text('¿Confirmás que estás de acuerdo con el recibo de ${widget.paystub.periodo}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, acepto'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && mounted) {
      ref.read(paystubApprovalProvider.notifier).approve(widget.paystub.id);
    }
  }

  void _handleReject() {
    if (!_isRejecting) {
      setState(() {
        _isRejecting = true;
      });
      return;
    }

    if (_observacionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe ingresar un motivo de rechazo')),
      );
      return;
    }
    
    if (_observacionController.text.trim().length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El motivo no puede superar los 500 caracteres')),
      );
      return;
    }

    ref.read(paystubApprovalProvider.notifier).reject(
      widget.paystub.id,
      observacion: _observacionController.text.trim(),
    );
  }

  Future<void> _downloadPdf() async {
    final String fileName =
        widget.paystub.fileName ?? 'recibo_${widget.paystub.periodo}.pdf';
    final path = widget.paystub.storagePath ?? widget.paystub.documentUrl;
    try {
      final storageService = ref.read(storageServiceProvider);
      final outcome = await storageService.downloadFile(
        pathOrUrl: path,
        fileName: fileName,
      );
      if (!mounted) return;
      if (outcome == DownloadOutcome.downloaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar('Recibo descargado'),
        );
      }
      // outcome == cancelled → el usuario canceló el diálogo: se ignora.
    } catch (e) {
      debugPrint('[PaystubDetailDialog] Error al descargar recibo ($path): $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb
                  ? 'No se pudo descargar el recibo. Usá "Ver Documento" para abrirlo en una pestaña nueva.'
                  : 'No se pudo descargar el recibo. Reintentá en unos instantes.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncActionState>(paystubApprovalProvider, (prev, next) {
      if (prev?.status != AsyncActionStatus.loading) return;
      if (next.status == AsyncActionStatus.success) {
        ref.read(paystubApprovalProvider.notifier).reset();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.successSnackBar('Estado del recibo actualizado'),
          );
          Navigator.of(context).pop();
        }
      } else if (next.status == AsyncActionStatus.failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.errorSnackBar('Error al actualizar el estado: ${next.error}'),
          );
        }
      }
    });

    final approvalState = ref.watch(paystubApprovalProvider);
    final isLoading = approvalState.status == AsyncActionStatus.loading;

    return Dialog(
      backgroundColor: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.2)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 500,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Detalle de Recibo',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textWhite,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x, color: AppColors.textMuted),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: AppColors.textSecondary.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              if (widget.isAdmin) ...[
                _buildDetailRow('Empleado', '${widget.user?.nombre} ${widget.user?.apellido}'),
                const SizedBox(height: 12),
              ],
              _buildDetailRow('Periodo', widget.paystub.periodo),
              const SizedBox(height: 12),
              _buildDetailRow('Estado', widget.paystub.estado.displayName),
              const SizedBox(height: 12),
              _buildDetailRow('Fecha subida', DateFormat('dd/MM/yyyy HH:mm').format(widget.paystub.createdAt)),
              if (widget.paystub.respondedAt != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow('Fecha respuesta', DateFormat('dd/MM/yyyy HH:mm').format(widget.paystub.respondedAt!)),
              ],
              
              if (widget.paystub.observacionRechazo != null && widget.paystub.observacionRechazo!.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('Motivo de rechazo:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error, fontSize: 13)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(widget.paystub.observacionRechazo!, style: const TextStyle(color: AppColors.textWhite, fontSize: 13)),
                ),
              ],
              
              const SizedBox(height: 20),
              if (widget.paystub.documentUrl.isNotEmpty)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        final path = widget.paystub.storagePath ?? widget.paystub.documentUrl;
                        final name = widget.paystub.fileName ?? 'recibo_${widget.paystub.periodo}.pdf';
                        showDialog(
                          context: context,
                          builder: (context) => PdfViewerDialog(
                            storagePath: path,
                            downloadFileName: name,
                            title: 'Recibo ${widget.paystub.periodo}',
                          ),
                        );
                      },
                      icon: const Icon(LucideIcons.fileText, size: 16),
                      label: const Text('Ver Documento'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                        foregroundColor: AppColors.gold,
                        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _downloadPdf,
                      icon: const Icon(LucideIcons.download, size: 16),
                      label: const Text('Descargar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                        foregroundColor: AppColors.gold,
                        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ],
                )
              else
                const Text('No hay documento adjunto', style: TextStyle(color: AppColors.textSecondary)),
              
              if (!widget.isAdmin && widget.paystub.estado == PaystubEstado.pendiente) ...[
                const SizedBox(height: 24),
                Divider(color: AppColors.textSecondary.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                if (_isRejecting) ...[
                  TextField(
                    controller: _observacionController,
                    style: const TextStyle(color: AppColors.textWhite),
                    decoration: InputDecoration(
                      labelText: 'Motivo del rechazo',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.bgDarkTop,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                      ),
                      counterText: '${_observacionController.text.length} / 500',
                      counterStyle: const TextStyle(color: AppColors.textMuted),
                    ),
                    maxLength: 500,
                    maxLines: 3,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isLoading ? null : () => setState(() => _isRejecting = false),
                        child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
                      ),
                      ElevatedButton(
                        onPressed: (isLoading || _observacionController.text.trim().isEmpty) ? null : _handleReject,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        child: isLoading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Confirmar Rechazo'),
                      ),
                    ],
                  ),
                ] else ...[
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isLoading ? null : _handleReject,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        child: const Text('Rechazar Recibo'),
                      ),
                      ElevatedButton(
                        onPressed: isLoading ? null : _handleApprove,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        child: isLoading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Aceptar Recibo'),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}


