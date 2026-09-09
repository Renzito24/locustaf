import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/company_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/company_action_provider.dart';

// ---------------------------------------------------------------------------
// Dialog to register a manual payment (TASK-011/017). Shared between the
// companies screen and the superadmin platform panel (TASK-017).
// ---------------------------------------------------------------------------
enum _PaymentType { mes, anio, custom }

class RegisterPaymentDialog extends ConsumerStatefulWidget {
  final CompanyModel company;
  const RegisterPaymentDialog({super.key, required this.company});

  @override
  ConsumerState<RegisterPaymentDialog> createState() => _RegisterPaymentDialogState();
}

class _RegisterPaymentDialogState extends ConsumerState<RegisterPaymentDialog> {
  late CompanyPlan _plan;
  _PaymentType _type = _PaymentType.mes;
  DateTime? _customDate;
  final _notaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _plan = widget.company.plan;
  }

  @override
  void dispose() {
    _notaController.dispose();
    super.dispose();
  }

  DateTime _baseDate() {
    final now = DateTime.now();
    final current = widget.company.paidUntil;
    return (current != null && current.isAfter(now)) ? current : now;
  }

  DateTime _computePaidUntil() {
    final base = _baseDate();
    switch (_type) {
      case _PaymentType.mes:
        return DateTime(base.year, base.month + 1, base.day);
      case _PaymentType.anio:
        return DateTime(base.year + 1, base.month, base.day);
      case _PaymentType.custom:
        return _customDate ?? base;
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _submit() {
    final paidUntil = _type == _PaymentType.custom ? _customDate : _computePaidUntil();
    if (paidUntil == null) return;
    final nota = _notaController.text.trim();
    ref.read(registerPaymentProvider.notifier).registerPayment(
          widget.company.id,
          paidUntil: paidUntil,
          plan: _plan,
          nota: nota.isEmpty ? null : nota,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _computePaidUntil();
    return AlertDialog(
      backgroundColor: AppColors.cardDark,
      title: const Text('Registrar pago',
          style: TextStyle(color: AppColors.textWhite)),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<CompanyPlan>(
              initialValue: _plan,
              decoration: AppTheme.inputDecoration(
                label: 'Plan',
                icon: Icons.credit_card_outlined,
              ),
              dropdownColor: AppColors.cardDark,
              style: const TextStyle(color: AppColors.textWhite),
              items: CompanyPlan.values
                  .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                  .toList(),
              onChanged: (v) => setState(() => _plan = v ?? CompanyPlan.mensual),
            ),
            const SizedBox(height: 16),
            const Text('Extender período',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            SegmentedButton<_PaymentType>(
              selected: {_type},
              onSelectionChanged: (v) => setState(() {
                _type = v.first;
                _customDate = null;
              }),
              segments: const [
                ButtonSegment(value: _PaymentType.mes, label: Text('+1 mes')),
                ButtonSegment(value: _PaymentType.anio, label: Text('+1 año')),
                ButtonSegment(value: _PaymentType.custom, label: Text('Fecha')),
              ],
            ),
            if (_type == _PaymentType.custom) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _customDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                      locale: const Locale('es'),
                    );
                    if (picked != null) setState(() => _customDate = picked);
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _customDate == null ? 'Elegir fecha' : _fmtDate(_customDate!),
                    style: const TextStyle(color: AppColors.textWhite),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.textSecondary),
                    foregroundColor: AppColors.textWhite,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _notaController,
              maxLines: 2,
              maxLength: 80,
              style: const TextStyle(color: AppColors.textWhite),
              decoration: AppTheme.inputDecoration(
                label: 'Nota (opcional)',
                icon: Icons.sticky_note_2_outlined,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgDarkTop,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text(
                'Nuevo paidUntil: ${_fmtDate(preview)}',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar',
              style: TextStyle(color: AppColors.textMuted)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.gold),
          onPressed: _submit,
          child: const Text('Registrar'),
        ),
      ],
    );
  }
}