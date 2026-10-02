import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/company_model.dart';
import '../../../../core/models/payment_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/company_providers.dart';

class SuperadminMetricChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const SuperadminMetricChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
            alignment: Alignment.center,
            child: Text(
              '$value',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class SuperadminPaymentTile extends StatelessWidget {
  final PaymentModel payment;

  const SuperadminPaymentTile({super.key, required this.payment});

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.payment, color: AppColors.gold, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.companyName,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${payment.plan.label} · Vence ${_fmtDate(payment.paidUntil)} · '
                    '${_fmtDate(payment.createdAt)}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  if (payment.nota != null && payment.nota!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      payment.nota!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AppTheme.badge(
              label: payment.plan.label,
              bgColor: AppColors.gold.withValues(alpha: 0.12),
              textColor: AppColors.gold,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sección de historial de pagos filtrada por empresa seleccionada.
// Usa companyPaymentsProvider (family) que hace la query con el índice
// compuesto (companyId ASC, createdAt DESC) declarado en firestore.indexes.json.
// ---------------------------------------------------------------------------
class SuperadminCompanyPaymentsSection extends ConsumerWidget {
  final String companyId;
  const SuperadminCompanyPaymentsSection({super.key, required this.companyId});

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(companyPaymentsProvider(companyId));
    return paymentsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Column(
        children: [
          const Text(
            'No se pudo cargar el historial',
            style: TextStyle(color: AppColors.error),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => ref.invalidate(companyPaymentsProvider(companyId)),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reintentar'),
            style: TextButton.styleFrom(foregroundColor: AppColors.gold),
          ),
        ],
      ),
      data: (payments) {
        if (payments.isEmpty) {
          return AppTheme.emptyState(
            icon: Icons.history,
            title: 'Sin pagos registrados para esta empresa',
            subtitle: 'Registrá el primer pago usando el botón "Pagar".',
          );
        }
        return AppCard(
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              // Cabecera de la tabla
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.bgDarkTop,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusMd),
                  ),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Fecha de pago',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Plan',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Vencimiento',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 40), // espacio badge
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0x1AFFFFFF)),
              // Filas
              ...payments.asMap().entries.map((entry) {
                final i = entry.key;
                final p = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              _fmtDate(p.createdAt),
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              p.plan.label,
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              _fmtDate(p.paidUntil),
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            child: p.nota != null && p.nota!.isNotEmpty
                                ? Tooltip(
                                    message: p.nota!,
                                    child: const Icon(
                                      Icons.sticky_note_2_outlined,
                                      size: 16,
                                      color: AppColors.textMuted,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    if (i < payments.length - 1)
                      const Divider(height: 1, color: Color(0x1AFFFFFF)),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
