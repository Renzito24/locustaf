import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/async_action_state.dart';
import '../../../employees/presentation/providers/users_provider.dart';
import '../providers/paystubs_provider.dart';

class CreatePaystubScreen extends ConsumerStatefulWidget {
  const CreatePaystubScreen({super.key});

  @override
  ConsumerState<CreatePaystubScreen> createState() => _CreatePaystubScreenState();
}

class _CreatePaystubScreenState extends ConsumerState<CreatePaystubScreen> {
  final _formKey = GlobalKey<FormState>();
  final _periodoController = TextEditingController();
  String? _selectedEmployeeId;
  PlatformFile? _selectedFile;

  @override
  void dispose() {
    _periodoController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      final file = result.files.first;
      if (file.size > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El archivo no debe pesar más de 10 MB')),
          );
        }
        return;
      }
      setState(() {
        _selectedFile = file;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe adjuntar el archivo del recibo')),
      );
      return;
    }

    if (_selectedEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar un empleado')),
      );
      return;
    }

    ref.read(paystubCreateProvider.notifier).createPaystub(
      userId: _selectedEmployeeId!,
      periodo: _periodoController.text.trim(),
      file: _selectedFile!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(paystubCreateProvider);
    final usersAsync = ref.watch(usersStreamProvider);
    final isLoading = actionState.status == AsyncActionStatus.loading;

    ref.listen<PaystubActionState>(paystubCreateProvider, (prev, next) {
      if (next.status == AsyncActionStatus.success) {
        ref.read(paystubCreateProvider.notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar('Recibo subido correctamente'),
        );
        context.pop();
      } else if (next.status == AsyncActionStatus.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar('Error al subir: ${next.error}'),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Subir Recibo de Sueldo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              usersAsync.when(
                data: (users) {
                  final employees = users.where((u) => u.isActive && !u.isDeleted).toList();
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedEmployeeId,
                    decoration: const InputDecoration(
                      labelText: 'Empleado',
                      border: OutlineInputBorder(),
                    ),
                    items: employees.map((user) {
                      return DropdownMenuItem(
                        value: user.id,
                        child: Text('${user.nombre} ${user.apellido}'),
                      );
                    }).toList(),
                    onChanged: isLoading ? null : (val) => setState(() => _selectedEmployeeId = val),
                    validator: (val) => val == null ? 'Seleccione un empleado' : null,
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _periodoController,
                decoration: const InputDecoration(
                  labelText: 'Periodo (ej. Octubre 2026)',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                enabled: !isLoading,
              ),
              const SizedBox(height: 24),
              const Text('Documento Adjunto', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_selectedFile != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.file, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_selectedFile!.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: AppColors.error),
                        onPressed: isLoading ? null : () => setState(() => _selectedFile = null),
                      ),
                    ],
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: isLoading ? null : _pickFile,
                  icon: const Icon(LucideIcons.paperclip),
                  label: const Text('Seleccionar Archivo (PDF)'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
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
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                            const SizedBox(width: 16),
                            Text('Subiendo... ${(actionState.uploadProgress * 100).toInt()}%'),
                          ],
                        )
                      : const Text('Guardar Recibo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
