import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:file_saver/file_saver.dart';
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
    try {
      final String fileName = widget.paystub.fileName ?? 'recibo_${widget.paystub.periodo}.pdf';
      final path = widget.paystub.storagePath ?? widget.paystub.documentUrl;
      final storageService = ref.read(storageServiceProvider);
      final bytes = await storageService.readFileBytes(path);
      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al descargar el archivo: $e')),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detalle de Recibo de Sueldo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (widget.isAdmin) ...[
              _buildDetailRow('Empleado', '${widget.user?.nombre} ${widget.user?.apellido}'),
              const SizedBox(height: 16),
            ],
            _buildDetailRow('Periodo', widget.paystub.periodo),
            const SizedBox(height: 16),
            _buildDetailRow('Estado', widget.paystub.estado.displayName),
            const SizedBox(height: 16),
            _buildDetailRow('Fecha subida', DateFormat('dd/MM/yyyy HH:mm').format(widget.paystub.createdAt)),
            if (widget.paystub.respondedAt != null) ...[
              const SizedBox(height: 16),
              _buildDetailRow('Fecha respuesta', DateFormat('dd/MM/yyyy HH:mm').format(widget.paystub.respondedAt!)),
            ],
            
            if (widget.paystub.observacionRechazo != null && widget.paystub.observacionRechazo!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Motivo de rechazo:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
              const SizedBox(height: 4),
              Text(widget.paystub.observacionRechazo!),
            ],
            
            const SizedBox(height: 24),
            if (widget.paystub.documentUrl.isNotEmpty)
              Row(
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
                    icon: const Icon(LucideIcons.fileText),
                    label: const Text('Ver Documento'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold.withValues(alpha: 0.1),
                      foregroundColor: AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _downloadPdf,
                    icon: const Icon(LucideIcons.download),
                    label: const Text('Descargar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold.withValues(alpha: 0.1),
                      foregroundColor: AppColors.gold,
                    ),
                  ),
                ],
              )
            else
              const Text('No hay documento adjunto', style: TextStyle(color: AppColors.textSecondary)),
            
            if (!widget.isAdmin && widget.paystub.estado == PaystubEstado.pendiente) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              if (_isRejecting) ...[
                TextField(
                  controller: _observacionController,
                  decoration: InputDecoration(
                    labelText: 'Motivo del rechazo',
                    border: const OutlineInputBorder(),
                    counterText: '${_observacionController.text.length} / 500',
                  ),
                  maxLength: 500,
                  maxLines: 3,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isLoading ? null : () => setState(() => _isRejecting = false),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: (isLoading || _observacionController.text.trim().isEmpty) ? null : _handleReject,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                      child: isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Confirmar Rechazo'),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isLoading ? null : _handleReject,
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      child: const Text('Rechazar Recibo'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: isLoading ? null : _handleApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                      child: isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Aceptar Recibo'),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}


