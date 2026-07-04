import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/workplace_model.dart';
import '../providers/workplace_notifier.dart';

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

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _nombreController = TextEditingController(text: data?.nombre ?? '');
    _descriptionController = TextEditingController(text: data?.description ?? '');
    _direccionController = TextEditingController(text: data?.direccion ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descriptionController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.isEditing) {
      final updated = widget.initialData!.copyWith(
        nombre: _nombreController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        direccion: _direccionController.text.trim().isEmpty
            ? null
            : _direccionController.text.trim(),
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
                          labelText: 'Descripción (opcional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _direccionController,
                        decoration: const InputDecoration(
                          labelText: 'Dirección (opcional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
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
