import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/data_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/workplace_model.dart';
import '../providers/workplace_notifier.dart';
import '../widgets/workplace_map_picker.dart';

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
    ref.listen<AsyncValue<void>>(
      widget.isEditing ? workplaceUpdateProvider : workplaceCreateProvider,
      (prev, next) {
        next.whenOrNull(
          data: (_) {
            if (widget.isEditing) {
              ref.read(workplaceUpdateProvider.notifier).reset();
            } else {
              ref.read(workplaceCreateProvider.notifier).reset();
            }
            ScaffoldMessenger.of(context).showSnackBar(
              AppTheme.successSnackBar(
                widget.isEditing
                    ? 'Lugar de trabajo actualizado'
                    : 'Lugar de trabajo creado',
              ),
            );
            context.pop();
          },
          error: (error, _) {
            ScaffoldMessenger.of(context).showSnackBar(
              AppTheme.errorSnackBar('Error: $error'),
            );
          },
        );
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
            child: Container(
              decoration: AppTheme.cardDecoration(),
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nombreController,
                      style: const TextStyle(color: AppColors.textWhite),
                      decoration: AppTheme.inputDecoration(
                        label: 'Nombre *',
                        icon: Icons.business_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es obligatorio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: AppColors.textWhite),
                      decoration: AppTheme.inputDecoration(
                        label: 'Descripción',
                        icon: Icons.description_outlined,
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La descripción es obligatoria';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    WorkplaceMapPicker(
                      initialLatitude: widget.initialData?.latitud,
                      initialLongitude: widget.initialData?.longitud,
                      initialAddress: widget.initialData?.direccion,
                      onLatitudeChanged: (lat) {
                        _latitudController.text = lat.toStringAsFixed(6);
                      },
                      onLongitudeChanged: (lng) {
                        _longitudController.text = lng.toStringAsFixed(6);
                      },
                      onAddressChanged: (address) {
                        if (address != null) {
                          _direccionController.text = address;
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latitudController,
                            style: const TextStyle(color: AppColors.textWhite),
                            decoration: AppTheme.inputDecoration(
                              label: 'Latitud *',
                              icon: Icons.map_outlined,
                              hint: '-34.6037',
                            ),
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true, signed: true),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Obligatorio';
                              }
                              if (double.tryParse(value.trim()) == null) {
                                return 'Número inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _longitudController,
                            style: const TextStyle(color: AppColors.textWhite),
                            decoration: AppTheme.inputDecoration(
                              label: 'Longitud *',
                              icon: Icons.map_outlined,
                              hint: '-58.3816',
                            ),
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true, signed: true),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Obligatorio';
                              }
                              if (double.tryParse(value.trim()) == null) {
                                return 'Número inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _radioController,
                            style: const TextStyle(color: AppColors.textWhite),
                            decoration: AppTheme.inputDecoration(
                              label: 'Radio (metros)',
                              icon: Icons.radar_outlined,
                              hint: '100',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                if (double.tryParse(value.trim()) == null) {
                                  return 'Número inválido';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _codigoController,
                            style: const TextStyle(color: AppColors.textWhite),
                            decoration: AppTheme.inputDecoration(
                              label: 'Código',
                              icon: Icons.qr_code_outlined,
                              hint: 'OF-A',
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.isEditing) ...[
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Activo', style: TextStyle(color: AppColors.textWhite)),
                        value: _isActive,
                        onChanged: (value) {
                          setState(() => _isActive = value);
                        },
                        activeThumbColor: AppColors.gold,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Configuración de jornada',
                      style: AppTheme.headingMd,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Opcional. Si se define, se detectan llegadas tarde y jornadas huérfanas.',
                      style: AppTheme.bodyMd,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _horaInicioController,
                            style: const TextStyle(color: AppColors.textWhite),
                            decoration: AppTheme.inputDecoration(
                              label: 'Hora de inicio',
                              icon: Icons.schedule_outlined,
                              hint: '08:00',
                            ),
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                if (!_isValidHhmm(value.trim())) {
                                  return 'Formato HH:mm';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _horaFinController,
                            style: const TextStyle(color: AppColors.textWhite),
                            decoration: AppTheme.inputDecoration(
                              label: 'Hora de fin',
                              icon: Icons.schedule_outlined,
                              hint: '16:00',
                            ),
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                if (!_isValidHhmm(value.trim())) {
                                  return 'Formato HH:mm';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _toleranciaController,
                      style: const TextStyle(color: AppColors.textWhite),
                      decoration: AppTheme.inputDecoration(
                        label: 'Tolerancia (minutos)',
                        icon: Icons.timer_outlined,
                        hint: '15',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final v = int.tryParse(value.trim());
                          if (v == null || v < 0) {
                            return 'Número válido';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: isSaving ? null : AppTheme.goldGradient,
                          color: isSaving ? AppColors.gold.withValues(alpha: 0.4) : null,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isSaving ? null : _submit,
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            child: Center(
                              child: isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF0B0B0F),
                                      ),
                                    )
                                  : Text(
                                      widget.isEditing
                                          ? 'Guardar cambios'
                                          : 'Crear lugar de trabajo',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0B0B0F),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
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
