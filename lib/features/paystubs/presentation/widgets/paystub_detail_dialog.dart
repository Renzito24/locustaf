import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/user_model.dart';
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

  void _handleApprove() {
    ref.read(paystubApprovalProvider.notifier).approve(widget.paystub.id).then((_) {
      if (mounted) Navigator.of(context).pop();
    });
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

    ref.read(paystubApprovalProvider.notifier).reject(
      widget.paystub.id,
      observacion: _observacionController.text.trim(),
    ).then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
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
            
            if (widget.paystub.observacionRechazo != null && widget.paystub.observacionRechazo!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Motivo de rechazo:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
              const SizedBox(height: 4),
              Text(widget.paystub.observacionRechazo!),
            ],
            
            const SizedBox(height: 24),
            if (widget.paystub.documentUrl.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => _ImageViewerDialog(url: widget.paystub.documentUrl),
                  );
                },
                icon: const Icon(LucideIcons.image),
                label: const Text('Ver Documento'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold.withValues(alpha: 0.1),
                  foregroundColor: AppColors.gold,
                ),
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
                  decoration: const InputDecoration(
                    labelText: 'Motivo del rechazo',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
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
                      onPressed: isLoading ? null : _handleReject,
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

class _ImageViewerDialog extends StatelessWidget {
  final String url;

  const _ImageViewerDialog({required this.url});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4,
            child: Image.network(
              url,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.fileWarning, size: 48, color: AppColors.error),
                      SizedBox(height: 16),
                      Text('No se pudo cargar el documento', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(LucideIcons.x, color: Colors.white, size: 32),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
