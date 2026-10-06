import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/async_action_state.dart';
import '../../../employees/presentation/providers/users_provider.dart';
import '../../../workplaces/presentation/providers/workplace_notifier.dart';
import '../../domain/models/comunicado_model.dart';
import '../providers/comunicados_provider.dart';

class CreateComunicadoScreen extends ConsumerStatefulWidget {
  const CreateComunicadoScreen({super.key});

  @override
  ConsumerState<CreateComunicadoScreen> createState() => _CreateComunicadoScreenState();
}

class _CreateComunicadoScreenState extends ConsumerState<CreateComunicadoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  TargetType _targetType = TargetType.all;
  final List<String> _selectedWorkplaces = [];
  final List<String> _selectedUsers = [];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_targetType == TargetType.workplace && _selectedWorkplaces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar al menos un lugar de trabajo')),
      );
      return;
    }

    if (_targetType == TargetType.users && _selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar al menos un empleado')),
      );
      return;
    }

    ref.read(comunicadoActionProvider.notifier).createComunicado(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      targetType: _targetType,
      targetWorkplaceIds: _selectedWorkplaces,
      targetUserIds: _selectedUsers,
    );
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(comunicadoActionProvider);
    final isLoading = actionState.status == AsyncActionStatus.loading;

    ref.listen<AsyncActionState>(comunicadoActionProvider, (prev, next) {
      if (next.status == AsyncActionStatus.success) {
        ref.read(comunicadoActionProvider.notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar('Comunicado enviado correctamente'),
        );
        context.pop();
      } else if (next.status == AsyncActionStatus.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar('Error al enviar: ${next.error}'),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Nuevo Comunicado'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título del comunicado',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Contenido / Mensaje',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                enabled: !isLoading,
              ),
              const SizedBox(height: 24),
              const Text('Enviar a:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<TargetType>(
                segments: const [
                  ButtonSegment(value: TargetType.all, label: Text('Todos'), icon: Icon(LucideIcons.users)),
                  ButtonSegment(value: TargetType.workplace, label: Text('Lugar de trabajo'), icon: Icon(LucideIcons.building)),
                  ButtonSegment(value: TargetType.users, label: Text('Empleados específicos'), icon: Icon(LucideIcons.user)),
                ],
                selected: {_targetType},
                onSelectionChanged: isLoading ? null : (Set<TargetType> newSelection) {
                  setState(() {
                    _targetType = newSelection.first;
                    _selectedWorkplaces.clear();
                    _selectedUsers.clear();
                  });
                },
              ),
              const SizedBox(height: 24),
              
              if (_targetType == TargetType.workplace) _buildWorkplacesSelector(isLoading),
              if (_targetType == TargetType.users) _buildUsersSelector(isLoading),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Enviar Comunicado'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkplacesSelector(bool isLoading) {
    final workplacesAsync = ref.watch(workplacesStreamProvider);
    return workplacesAsync.when(
      data: (workplaces) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: workplaces.map((w) {
            return CheckboxListTile(
              title: Text(w.nombre),
              value: _selectedWorkplaces.contains(w.id),
              onChanged: isLoading ? null : (checked) {
                setState(() {
                  if (checked == true) {
                    _selectedWorkplaces.add(w.id);
                  } else {
                    _selectedWorkplaces.remove(w.id);
                  }
                });
              },
            );
          }).toList(),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }

  Widget _buildUsersSelector(bool isLoading) {
    final usersAsync = ref.watch(usersStreamProvider);
    return usersAsync.when(
      data: (users) {
        final employees = users.where((u) => u.isActive && !u.isDeleted).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: employees.map((u) {
            return CheckboxListTile(
              title: Text('${u.nombre} ${u.apellido}'),
              subtitle: Text(u.email),
              value: _selectedUsers.contains(u.id),
              onChanged: isLoading ? null : (checked) {
                setState(() {
                  if (checked == true) {
                    _selectedUsers.add(u.id);
                  } else {
                    _selectedUsers.remove(u.id);
                  }
                });
              },
            );
          }).toList(),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
