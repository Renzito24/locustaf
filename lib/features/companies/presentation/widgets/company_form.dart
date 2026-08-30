import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/company_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../providers/company_action_provider.dart';

class CompanyForm extends ConsumerStatefulWidget {
  final CompanyModel? existingCompany;
  final bool isLoading;
  final String? errorMessage;
  final void Function(CompanyFormData data) onSubmit;

  const CompanyForm({
    super.key,
    this.existingCompany,
    this.isLoading = false,
    this.errorMessage,
    required this.onSubmit,
  });

  @override
  ConsumerState<CompanyForm> createState() => _CompanyFormState();
}

class _CompanyFormState extends ConsumerState<CompanyForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _razonSocialController = TextEditingController();
  final _cuitController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _toleranciaController = TextEditingController();
  CompanyEstado _estado = CompanyEstado.activa;
  Set<int> _diasLaborables = const {1, 2, 3, 4, 5};

  @override
  void initState() {
    super.initState();
    final company = widget.existingCompany;
    _nombreController.text = company?.nombreComercial ?? '';
    _razonSocialController.text = company?.razonSocial ?? '';
    _cuitController.text = company?.cuit ?? '';
    _direccionController.text = company?.direccion ?? '';
    _telefonoController.text = company?.telefono ?? '';
    _emailController.text = company?.email ?? '';
    _toleranciaController.text = (company?.toleranciaCheckIn ?? 15).toString();
    _estado = company?.estado ?? CompanyEstado.activa;
    _diasLaborables = Set.of(company?.diasLaborables ?? const [1, 2, 3, 4, 5]);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _razonSocialController.dispose();
    _cuitController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _toleranciaController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final dias = _diasLaborables.toList()..sort();
    widget.onSubmit(CompanyFormData(
      nombreComercial: _nombreController.text.trim(),
      razonSocial: _razonSocialController.text.trim(),
      cuit: _cuitController.text.trim(),
      direccion: _direccionController.text.trim().isEmpty
          ? null
          : _direccionController.text.trim(),
      telefono: _telefonoController.text.trim().isEmpty
          ? null
          : _telefonoController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      estado: _estado,
      toleranciaCheckIn: int.tryParse(_toleranciaController.text.trim()) ?? 15,
      diasLaborables: dias.isEmpty ? const [1, 2, 3, 4, 5] : dias,
    ));
  }

  String _dayLabel(int day) {
    switch (day) {
      case 1:
        return 'Lun';
      case 2:
        return 'Mar';
      case 3:
        return 'Mié';
      case 4:
        return 'Jue';
      case 5:
        return 'Vie';
      case 6:
        return 'Sáb';
      default:
        return 'Dom';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingCompany != null;
    final isMobile = AppTheme.isMobile(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nombreController,
            style: const TextStyle(color: AppColors.textWhite),
            decoration: AppTheme.inputDecoration(
              label: 'Nombre comercial *',
              icon: Icons.business_outlined,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _razonSocialController,
            style: const TextStyle(color: AppColors.textWhite),
            decoration: AppTheme.inputDecoration(
              label: 'Razón social *',
              icon: Icons.business_outlined,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cuitController,
            style: const TextStyle(color: AppColors.textWhite),
            decoration: AppTheme.inputDecoration(
              label: 'CUIT *',
              icon: Icons.numbers_outlined,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: Validators.cuit,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            style: const TextStyle(color: AppColors.textWhite),
            decoration: AppTheme.inputDecoration(
              label: 'Email',
              icon: Icons.email_outlined,
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              return Validators.email(v);
            },
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _telefonoController,
            style: const TextStyle(color: AppColors.textWhite),
            decoration: AppTheme.inputDecoration(
              label: 'Teléfono',
              icon: Icons.phone_outlined,
            ),
            keyboardType: TextInputType.phone,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _direccionController,
            style: const TextStyle(color: AppColors.textWhite),
            decoration: AppTheme.inputDecoration(
              label: 'Dirección',
              icon: Icons.home_outlined,
            ),
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<CompanyEstado>(
            initialValue: _estado,
            decoration: AppTheme.inputDecoration(
              label: 'Estado',
              icon: Icons.toggle_on_outlined,
            ),
            dropdownColor: AppColors.cardDark,
            style: const TextStyle(color: AppColors.textWhite),
            items: CompanyEstado.values
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.label),
                    ))
                .toList(),
            onChanged: widget.isLoading
                ? null
                : (v) => setState(() => _estado = v ?? CompanyEstado.activa),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _toleranciaController,
            style: const TextStyle(color: AppColors.textWhite),
            decoration: AppTheme.inputDecoration(
              label: 'Tolerancia de check-in (minutos)',
              hint: 'Minutos permitidos para marcar entrada (default 15)',
              icon: Icons.timer_outlined,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              final n = int.tryParse(v.trim());
              if (n == null || n < 0) {
                return 'Debe ser un número mayor o igual a 0';
              }
              return null;
            },
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),
          Text(
            'Días laborables',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (i) {
              final day = i + 1;
              final selected = _diasLaborables.contains(day);
              return FilterChip(
                label: Text(_dayLabel(day)),
                selected: selected,
                selectedColor: AppColors.gold,
                checkmarkColor: AppColors.textWhite,
                backgroundColor: AppColors.cardDark,
                labelStyle: TextStyle(
                  color: selected
                      ? AppColors.textWhite
                      : AppColors.textSecondary,
                ),
                side: selected
                    ? const BorderSide(color: AppColors.gold, width: 1)
                    : BorderSide.none,
                onSelected: widget.isLoading
                    ? null
                    : (v) => setState(() {
                          final updated = Set<int>.of(_diasLaborables);
                          if (v) {
                            updated.add(day);
                          } else {
                            updated.remove(day);
                          }
                          _diasLaborables = updated;
                        }),
              );
            }),
          ),
          const SizedBox(height: 4),
          Text(
            'Los reportes de "Ausentes" solo aplican en días laborables.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          if (widget.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.errorMessage!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: isMobile ? double.infinity : 300,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  onTap: widget.isLoading ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: widget.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isEditing ? 'Guardar cambios' : 'Crear empresa',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
