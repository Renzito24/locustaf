import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/data_providers.dart';
import '../../../../core/providers/async_action_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/workplace_model.dart';
import '../providers/workplace_notifier.dart';
import '../widgets/workplace_form_sections.dart';

class WorkplaceFormScreen extends ConsumerWidget {
  const WorkplaceFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final existing = GoRouterState.of(context).extra as WorkplaceModel?;
    final isEditing = existing != null;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: _WorkplaceForm(
        key: ValueKey(existing?.id ?? '__create__'),
        isEditing: isEditing,
        initialData: existing,
      ),
    );
  }
}

class _WorkplaceForm extends ConsumerStatefulWidget {
  final bool isEditing;
  final WorkplaceModel? initialData;

  const _WorkplaceForm({
    super.key,
    required this.isEditing,
    this.initialData,
  });

  @override
  ConsumerState<_WorkplaceForm> createState() => _WorkplaceFormState();
}

class _WorkplaceFormState extends ConsumerState<_WorkplaceForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _direccionController;
  late final TextEditingController _latitudController;
  late final TextEditingController _longitudController;
  late final TextEditingController _codigoController;
  late final TextEditingController _radioController;
  late final TextEditingController _horaInicioController;
  late final TextEditingController _horaFinController;
  late final TextEditingController _toleranciaController;

  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _nombreController = TextEditingController(text: data?.nombre ?? '');
    _descriptionController = TextEditingController(text: data?.description ?? '');
    _direccionController = TextEditingController(text: data?.direccion ?? '');
    _latitudController = TextEditingController(
      text: data?.latitud?.toStringAsFixed(6) ?? '',
    );
    _longitudController = TextEditingController(
      text: data?.longitud?.toStringAsFixed(6) ?? '',
    );
    _codigoController = TextEditingController(text: data?.codigo ?? '');
    _radioController = TextEditingController(
      text: data?.radio?.toString() ?? '',
    );
    _horaInicioController = TextEditingController(text: data?.horaInicio ?? '');
    _horaFinController = TextEditingController(text: data?.horaFin ?? '');
    _toleranciaController = TextEditingController(
      text: data?.toleranciaMinutos.toString() ?? '15',
    );
    _isActive = data?.isActive ?? true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descriptionController.dispose();
    _direccionController.dispose();
    _latitudController.dispose();
    _longitudController.dispose();
    _codigoController.dispose();
    _radioController.dispose();
    _horaInicioController.dispose();
    _horaFinController.dispose();
    _toleranciaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final lat = double.tryParse(_latitudController.text.trim());
    final lng = double.tryParse(_longitudController.text.trim());
    final radio = double.tryParse(_radioController.text.trim());
    final codigo = _codigoController.text.trim().isEmpty
        ? null
        : _codigoController.text.trim();
    final horaInicio = _horaInicioController.text.trim().isEmpty
        ? null
        : _horaInicioController.text.trim();
    final horaFin = _horaFinController.text.trim().isEmpty
        ? null
        : _horaFinController.text.trim();
    final tolerancia = int.tryParse(_toleranciaController.text.trim()) ?? 15;

    if (widget.isEditing) {
      final updated = widget.initialData!.copyWith(
        nombre: _nombreController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        direccion: _direccionController.text.trim().isEmpty
            ? null
            : _direccionController.text.trim(),
        latitud: lat,
        longitud: lng,
        radio: radio,
        codigo: codigo,
        horaInicio: horaInicio,
        horaFin: horaFin,
        toleranciaMinutos: tolerancia,
        isActive: _isActive,
      );
      await ref.read(workplaceUpdateProvider.notifier).updateWorkplace(updated);
    } else {
      final workplace = WorkplaceModel(
        id: '',
        nombre: _nombreController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        direccion: _direccionController.text.trim().isEmpty
            ? null
            : _direccionController.text.trim(),
        latitud: lat,
        longitud: lng,
        radio: radio,
        codigo: codigo,
        horaInicio: horaInicio,
        horaFin: horaFin,
        toleranciaMinutos: tolerancia,
        companyId: ref.read(currentCompanyIdProvider),
        isActive: _isActive,
        createdAt: DateTime.now(),
      );
      await ref.read(workplaceCreateProvider.notifier).createWorkplace(workplace);
    }
  }

  bool _isValidHhmm(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return false;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return false;
    return h >= 0 && h <= 23 && m >= 0 && m <= 59;
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = widget.isEditing
        ? ref.watch(workplaceUpdateProvider).isLoading
        : ref.watch(workplaceCreateProvider).isLoading;
    final isMobile = AppTheme.isMobile(context);
    ref.listen<AsyncActionState>(
      widget.isEditing ? workplaceUpdateProvider : workplaceCreateProvider,
      (prev, next) {
        if (prev?.status != AsyncActionStatus.loading) return;
        switch (next.status) {
          case AsyncActionStatus.success:
            if (widget.isEditing) {
              ref.read(workplaceUpdateProvider.notifier).reset();
            } else {
              ref.read(workplaceCreateProvider.notifier).reset();
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                AppTheme.successSnackBar(
                  widget.isEditing
                      ? 'Lugar de trabajo actualizado'
                      : 'Lugar de trabajo creado',
                ),
              );
              context.pop();
            }
          case AsyncActionStatus.failure:
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                AppTheme.errorSnackBar('Error: ${next.error}'),
              );
            }
          case AsyncActionStatus.idle:
          case AsyncActionStatus.loading:
            break;
        }
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isEditing ? 'Editar lugar de trabajo' : 'Nuevo lugar de trabajo',
          style: AppTheme.headingLg,
        ),
        const SizedBox(height: 4),
        Text(
          widget.isEditing
              ? 'Editando ${widget.initialData!.nombre}.'
              : 'Completa los campos para registrar un nuevo lugar de trabajo.',
          style: AppTheme.bodyLg,
        ),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            child: AppCard(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WorkplaceBasicInfoSection(
                      nombreController: _nombreController,
                      descriptionController: _descriptionController,
                    ),
                    const SizedBox(height: 16),
                    WorkplaceLocationSection(
                      initialData: widget.initialData,
                      latitudController: _latitudController,
                      longitudController: _longitudController,
                      direccionController: _direccionController,
                      radioController: _radioController,
                      codigoController: _codigoController,
                    ),
                    if (widget.isEditing) ...[
                      const SizedBox(height: 16),
                      Material(
                        color: Colors.transparent,
                        child: SwitchListTile(
                          title: const Text('Activo', style: TextStyle(color: AppColors.textWhite)),
                          value: _isActive,
                          onChanged: (value) {
                            setState(() => _isActive = value);
                          },
                          activeThumbColor: AppColors.gold,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    WorkplaceScheduleSection(
                      horaInicioController: _horaInicioController,
                      horaFinController: _horaFinController,
                      toleranciaController: _toleranciaController,
                      isValidHhmm: _isValidHhmm,
                    ),
                    const SizedBox(height: 24),
                    WorkplaceSubmitButton(
                      isSaving: isSaving,
                      isEditing: widget.isEditing,
                      onSubmit: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
