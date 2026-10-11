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
  static const _meses = [
    '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  final _formKey = GlobalKey<FormState>();
  String? _selectedEmployeeId;
  int? _selectedMonth;
  int? _selectedYear;
  PlatformFile? _selectedFile;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
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
            AppTheme.errorSnackBar('El archivo no debe pesar más de 10 MB'),
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
        AppTheme.errorSnackBar('Debe adjuntar el archivo del recibo'),
      );
      return;
    }

    if (_selectedEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar('Debe seleccionar un empleado'),
      );
      return;
    }

    final periodo = '${_selectedYear!.toString()}-${_selectedMonth!.toString().padLeft(2, '0')}';

    ref.read(paystubCreateProvider.notifier).createPaystub(
      userId: _selectedEmployeeId!,
      periodo: periodo,
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

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.gold),
    );
    final baseDecoration = InputDecoration(
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.bgDarkTop,
      enabledBorder: border,
      focusedBorder: focusedBorder,
      border: border,
    );

    return Scaffold(
      backgroundColor: AppColors.bgDarkTop,
      appBar: AppBar(
        title: const Text('Subir Recibo de Sueldo'),
        backgroundColor: AppColors.bgDarkTop,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              color: AppColors.cardDark,
              child: Padding(
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
                            decoration: baseDecoration.copyWith(labelText: 'Empleado'),
                            dropdownColor: AppColors.cardDark,
                            style: const TextStyle(color: AppColors.textWhite),
                            iconEnabledColor: AppColors.textMuted,
                            items: employees.map((user) {
                              return DropdownMenuItem(
                                value: user.id,
                                child: Text(
                                  '${user.nombre} ${user.apellido}',
                                  style: const TextStyle(color: AppColors.textWhite),
                                ),
                              );
                            }).toList(),
                            onChanged: isLoading ? null : (val) => setState(() => _selectedEmployeeId = val),
                            validator: (val) => val == null ? 'Seleccione un empleado' : null,
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                          ),
                        ),
                        error: (e, _) => Text('Error: $e', style: const TextStyle(color: AppColors.error)),
                      ),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final monthField = DropdownButtonFormField<int>(
                            initialValue: _selectedMonth,
                            decoration: baseDecoration.copyWith(labelText: 'Mes'),
                            dropdownColor: AppColors.cardDark,
                            style: const TextStyle(color: AppColors.textWhite),
                            iconEnabledColor: AppColors.textMuted,
                            items: [
                              for (int m = 1; m <= 12; m++)
                                DropdownMenuItem(
                                  value: m,
                                  child: Text(_meses[m], style: const TextStyle(color: AppColors.textWhite)),
                                ),
                            ],
                            onChanged: isLoading ? null : (val) => setState(() => _selectedMonth = val),
                          );

                          final yearField = DropdownButtonFormField<int>(
                            initialValue: _selectedYear,
                            decoration: baseDecoration.copyWith(labelText: 'Año'),
                            dropdownColor: AppColors.cardDark,
                            style: const TextStyle(color: AppColors.textWhite),
                            iconEnabledColor: AppColors.textMuted,
                            items: [
                              for (int y = DateTime.now().year; y >= DateTime.now().year - 10; y--)
                                DropdownMenuItem(
                                  value: y,
                                  child: Text(y.toString(), style: const TextStyle(color: AppColors.textWhite)),
                                ),
                            ],
                            onChanged: isLoading ? null : (val) => setState(() => _selectedYear = val),
                          );
                          if (constraints.maxWidth >= 480) {
                            return Row(
                              children: [
                                Expanded(child: monthField),
                                const SizedBox(width: 12),
                                Expanded(child: yearField),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              monthField,
                              const SizedBox(height: 12),
                              yearField,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Documento Adjunto',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textWhite),
                      ),
                      const SizedBox(height: 8),
                      if (_selectedFile != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.file, color: AppColors.gold, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedFile!.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppColors.textWhite),
                                ),
                              ),
                              if (!isLoading)
                                IconButton(
                                  icon: const Icon(LucideIcons.x, color: AppColors.error, size: 18),
                                  onPressed: () => setState(() => _selectedFile = null),
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
                            foregroundColor: AppColors.gold,
                            side: const BorderSide(color: AppColors.gold),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                            foregroundColor: AppColors.bgDarkTop,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          child: isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bgDarkTop),
                                    ),
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
            ),
          ),
        ),
      ),
    );
  }
}
