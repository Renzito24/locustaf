import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';

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

enum _ComunicadoMode { pdf, text }

class _CreateComunicadoScreenState extends ConsumerState<CreateComunicadoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  _ComunicadoMode _mode = _ComunicadoMode.pdf;
  PlatformFile? _selectedFile;
  TargetType _targetType = TargetType.all;
  final List<String> _selectedWorkplaces = [];
  final List<String> _selectedUsers = [];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.size > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El archivo supera el límite de 10 MB')),
          );
        }
        return;
      }
      setState(() => _selectedFile = file);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_mode == _ComunicadoMode.pdf && _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe adjuntar un archivo PDF')),
      );
      return;
    }

    if (_mode == _ComunicadoMode.text && _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe escribir el contenido del comunicado')),
      );
      return;
    }

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
      pdfFile: _mode == _ComunicadoMode.pdf ? _selectedFile : null,
      content: _mode == _ComunicadoMode.text ? _contentController.text.trim() : null,
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
              // ── Selector de modo: PDF o Texto ─────────────────────────
              const Text('Formato del comunicado:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<_ComunicadoMode>(
                segments: const [
                  ButtonSegment(value: _ComunicadoMode.pdf, label: Text('Archivo PDF'), icon: Icon(LucideIcons.fileText)),
                  ButtonSegment(value: _ComunicadoMode.text, label: Text('Escritura'), icon: Icon(LucideIcons.type)),
                ],
                selected: {_mode},
                onSelectionChanged: isLoading ? null : (Set<_ComunicadoMode> newSelection) {
                  setState(() => _mode = newSelection.first);
                },
              ),
              const SizedBox(height: 16),
              if (_mode == _ComunicadoMode.text) ...[
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Contenido del comunicado',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 8,
                  minLines: 5,
                  enabled: !isLoading,
                ),
              ] else
              if (_selectedFile == null)
                OutlinedButton.icon(
                  onPressed: isLoading ? null : _pickFile,
                  icon: const Icon(LucideIcons.paperclip),
                  label: const Text('Seleccionar PDF (máx. 10 MB)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    side: const BorderSide(color: AppColors.gold),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.fileText, color: AppColors.gold),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFile!.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${(_selectedFile!.size / 1024).toStringAsFixed(0)} KB',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (!isLoading)
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 18),
                          onPressed: () => setState(() => _selectedFile = null),
                          tooltip: 'Quitar archivo',
                        ),
                    ],
                  ),
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
              
              // ── Preview de destinatarios ──────────────────────────────
              const SizedBox(height: 16),
              _buildRecipientPreview(),
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipientPreview() {
    String label;
    if (_targetType == TargetType.all) {
      label = 'Se enviará a todo el personal';
    } else if (_targetType == TargetType.workplace) {
      final n = _selectedWorkplaces.length;
      label = n == 0 ? 'Seleccioná al menos un lugar de trabajo' : 'Se enviará a $n lugar${n == 1 ? '' : 'es'} de trabajo';
    } else {
      final n = _selectedUsers.length;
      label = n == 0 ? 'Seleccioná al menos un empleado' : 'Se enviará a $n persona${n == 1 ? '' : 's'}';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.info, size: 16, color: AppColors.gold),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.gold, fontSize: 13))),
        ],
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
