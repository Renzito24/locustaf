import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_model.dart';
import '../../../employees/presentation/providers/users_provider.dart';
import '../../data/models/medical_document_model.dart';
import 'medical_document_form_components.dart';

class MedicalDocumentFormData {
  final String userId;
  final MedicalDocumentTipo tipo;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String motivo;
  final String? archivoUrl;
  final PlatformFile? archivoFile;

  const MedicalDocumentFormData({
    required this.userId,
    required this.tipo,
    required this.fechaInicio,
    required this.fechaFin,
    required this.motivo,
    this.archivoUrl,
    this.archivoFile,
  });
}

class MedicalDocumentForm extends ConsumerStatefulWidget {
  final MedicalDocumentModel? existingDocument;
  final bool isLoading;
  final double uploadProgress;
  final String? errorMessage;
  final String? fixedUserId;
  final void Function(MedicalDocumentFormData data) onSubmit;

  const MedicalDocumentForm({
    super.key,
    this.existingDocument,
    this.isLoading = false,
    this.uploadProgress = 0,
    this.errorMessage,
    this.fixedUserId,
    required this.onSubmit,
  });

  @override
  ConsumerState<MedicalDocumentForm> createState() => _MedicalDocumentFormState();
}

class _MedicalDocumentFormState extends ConsumerState<MedicalDocumentForm> {
  final _formKey = GlobalKey<FormState>();
  late String _userId;
  late MedicalDocumentTipo _tipo;
  late DateTime _fechaInicio;
  late DateTime _fechaFin;
  late String _motivo;
  final _motivoController = TextEditingController();
  PlatformFile? _archivoFile;
  String? _archivoUrl;

  @override
  void initState() {
    super.initState();
    final doc = widget.existingDocument;
    _userId = widget.fixedUserId ?? doc?.userId ?? '';
    _tipo = doc?.tipo ?? MedicalDocumentTipo.enfermedad;
    _fechaInicio = doc?.fechaInicio ?? DateTime.now();
    _fechaFin = doc?.fechaFin ?? DateTime.now().add(const Duration(days: 30));
    _motivo = doc?.motivo ?? '';
    _motivoController.text = _motivo;
    _archivoUrl = doc?.archivoUrl;
  }

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  bool get isEditing => widget.existingDocument != null;

  bool get _isUploading => widget.isLoading && widget.uploadProgress > 0 && widget.uploadProgress < 1;

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersStreamProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Text(
                widget.errorMessage!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          if (widget.fixedUserId == null) ...[
            usersAsync.when(
              data: (users) {
                final employees =
                    users.where((u) => u.rol == UserRole.employee && !u.isDeleted).toList();
                return MedicalDocumentEmployeeDropdown(
                  fixedUserId: widget.fixedUserId,
                  userId: _userId,
                  employees: employees,
                  isEditing: isEditing,
                  onChanged: (value) {
                    setState(() => _userId = value ?? '');
                  },
                );
              },
              loading: () => TextField(
                decoration: AppTheme.inputDecoration(label: 'Empleado', icon: Icons.person),
                enabled: false,
              ),
              error: (_, _) => TextField(
                decoration: AppTheme.inputDecoration(label: 'Empleado', icon: Icons.person),
                enabled: false,
              ),
            ),
          ],
          MedicalDocumentTypeDropdown(
            tipo: _tipo,
            onChanged: (value) {
              if (value != null) setState(() => _tipo = value);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MedicalDocumentDatePicker(
                  label: 'Fecha de emisión',
                  value: _fechaInicio,
                  onChanged: (d) => setState(() => _fechaInicio = d),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MedicalDocumentDatePicker(
                  label: 'Fecha de vencimiento',
                  value: _fechaFin,
                  onChanged: (d) => setState(() => _fechaFin = d),
                  validator: (_) {
                    if (_fechaFin.isBefore(_fechaInicio)) {
                      return 'La fecha de vencimiento no puede ser anterior a la de emisión';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _motivoController,
            decoration: AppTheme.inputDecoration(label: 'Observaciones', icon: Icons.notes),
            style: const TextStyle(color: AppColors.textWhite),
            maxLines: 3,
            onChanged: (value) => _motivo = value,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Ingrese las observaciones';
              return null;
            },
          ),
          const SizedBox(height: 16),
          MedicalDocumentFilePicker(
            isLoading: widget.isLoading,
            archivoFile: _archivoFile,
            archivoUrl: _archivoUrl,
            onPickFile: _pickFile,
            onClearFile: () => setState(() => _archivoFile = null),
          ),
          const SizedBox(height: 16),
          if (_isUploading)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: widget.uploadProgress,
                  backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                  color: AppColors.gold,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 4),
                Text(
                  'Subiendo archivo... ${(widget.uploadProgress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          SizedBox(height: widget.uploadProgress > 0 && widget.uploadProgress < 1 ? 16 : 0),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: ElevatedButton(
                onPressed: (widget.isLoading && !_isUploading) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                ),
                child: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isEditing ? 'Guardar cambios' : 'Crear documento'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _archivoFile = result.files.first;
        _archivoUrl = null;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar('Seleccione un empleado'),
      );
      return;
    }
    widget.onSubmit(MedicalDocumentFormData(
      userId: _userId,
      tipo: _tipo,
      fechaInicio: _fechaInicio,
      fechaFin: _fechaFin,
      motivo: _motivo.trim(),
      archivoUrl: _archivoUrl,
      archivoFile: _archivoFile,
    ));
  }
}
