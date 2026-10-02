import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/company_model.dart';
import '../providers/company_action_provider.dart';
import 'company_form_components.dart';

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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingCompany != null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CompanyFormBasicFields(
            nombreController: _nombreController,
            razonSocialController: _razonSocialController,
            cuitController: _cuitController,
            emailController: _emailController,
            telefonoController: _telefonoController,
            direccionController: _direccionController,
            isLoading: widget.isLoading,
          ),
          const SizedBox(height: 16),
          CompanyFormConfigFields(
            estado: _estado,
            onEstadoChanged: (v) => setState(() => _estado = v),
            toleranciaController: _toleranciaController,
            diasLaborables: _diasLaborables,
            onDiasChanged: (v) => setState(() => _diasLaborables = v),
            isLoading: widget.isLoading,
          ),
          if (widget.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.errorMessage!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ],
          const SizedBox(height: 24),
          CompanyFormSubmitButton(
            isEditing: isEditing,
            isLoading: widget.isLoading,
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }
}
