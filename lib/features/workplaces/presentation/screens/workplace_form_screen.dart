import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
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
        isActive: _isActive,
        createdAt: DateTime.now(),
      );
      await ref.read(workplaceCreateProvider.notifier).createWorkplace(workplace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = widget.isEditing
        ? ref.watch(workplaceUpdateProvider).isLoading
        : ref.watch(workplaceCreateProvider).isLoading;

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
              SnackBar(
                content: Text(widget.isEditing
                    ? 'Lugar de trabajo actualizado'
                    : 'Lugar de trabajo creado'),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop();
          },
          error: (error, _) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $error'),
                backgroundColor: AppColors.error,
              ),
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
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.isEditing
              ? 'Editando ${widget.initialData!.nombre}.'
              : 'Completa los campos para registrar un nuevo lugar de trabajo.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre *',
                          border: OutlineInputBorder(),
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
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          border: OutlineInputBorder(),
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
                              decoration: const InputDecoration(
                                labelText: 'Latitud *',
                                border: OutlineInputBorder(),
                                hintText: '-34.6037',
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
                              decoration: const InputDecoration(
                                labelText: 'Longitud *',
                                border: OutlineInputBorder(),
                                hintText: '-58.3816',
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
                              decoration: const InputDecoration(
                                labelText: 'Radio (metros)',
                                border: OutlineInputBorder(),
                                hintText: '100',
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
                              decoration: const InputDecoration(
                                labelText: 'Código',
                                border: OutlineInputBorder(),
                                hintText: 'OF-A',
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (widget.isEditing) ...[
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Activo'),
                          value: _isActive,
                          onChanged: (value) {
                            setState(() => _isActive = value);
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  widget.isEditing
                                      ? 'Guardar cambios'
                                      : 'Crear lugar de trabajo',
                                  style: const TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
