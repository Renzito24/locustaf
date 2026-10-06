import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../employees/presentation/providers/users_provider.dart';
import '../../data/models/incidence_model.dart';
import 'incidence_form_components.dart';

class IncidenceFormData {
  final String userId;
  final IncidenceType type;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String observaciones;
  final String? documentoRelacionado;
  final PlatformFile? archivoFile;

  const IncidenceFormData({
    required this.userId,
    required this.type,
    required this.fechaInicio,
    required this.fechaFin,
    this.observaciones = '',
    this.documentoRelacionado,
    this.archivoFile,
  });
}

class IncidenceForm extends ConsumerStatefulWidget {
  final IncidenceModel? existingIncidence;
  final bool isLoading;
  final double uploadProgress;
  final String? errorMessage;
  final String? fixedUserId;
  final void Function(IncidenceFormData data) onSubmit;

  const IncidenceForm({
    super.key,
    this.existingIncidence,
    this.isLoading = false,
    this.uploadProgress = 0,
    this.errorMessage,
    this.fixedUserId,
    required this.onSubmit,
  });

  @override
  ConsumerState<IncidenceForm> createState() => _IncidenceFormState();
}

class _IncidenceFormState extends ConsumerState<IncidenceForm> {
  final _formKey = GlobalKey<FormState>();
  late String _userId;
  late IncidenceType _type;
  late DateTime _fechaInicio;
  late DateTime _fechaFin;
  late String _observaciones;
  final _observacionesController = TextEditingController();
  PlatformFile? _archivoFile;
  String? _archivoUrl;

  @override
  void initState() {
    super.initState();
    final inc = widget.existingIncidence;
    _userId = widget.fixedUserId ?? inc?.userId ?? '';
    _type = inc?.type ?? IncidenceType.vacaciones;
    _fechaInicio = inc?.fechaInicio ?? DateTime.now();
    _fechaFin = inc?.fechaFin ?? DateTime.now().add(const Duration(days: 1));
    _observaciones = inc?.observaciones ?? '';
    _observacionesController.text = _observaciones;
    _archivoUrl = inc?.documentoRelacionado;
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  bool get isEditing => widget.existingIncidence != null;
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
            IncidenceErrorMessage(errorMessage: widget.errorMessage!),
            
          if (widget.fixedUserId == null)
            IncidenceEmployeeDropdown(
              usersAsync: usersAsync,
              userId: _userId,
              isEditing: isEditing,
              onChanged: (v) => setState(() => _userId = v ?? ''),
            ),
            
          IncidenceTypeDropdown(
            type: _type,
            onChanged: (v) {
              if (v != null) setState(() => _type = v);
            },
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: IncidenceDatePicker(
                  label: 'Fecha inicio',
                  value: _fechaInicio,
                  onChanged: (d) => setState(() => _fechaInicio = d),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: IncidenceDatePicker(
                  label: 'Fecha fin',
                  value: _fechaFin,
                  onChanged: (d) => setState(() => _fechaFin = d),
                  validator: (_) {
                    if (_fechaFin.isBefore(_fechaInicio)) {
                      return 'La fecha fin no puede ser anterior a la fecha inicio';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          IncidenceTextField(
            controller: _observacionesController,
            label: 'Observaciones',
            icon: Icons.notes,
            maxLines: 3,
            onChanged: (v) => _observaciones = v,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese las observaciones' : null,
          ),
          const SizedBox(height: 16),
          
          IncidenceFilePicker(
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
                    : Text(isEditing ? 'Guardar cambios' : 'Crear incidencia'),
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
    widget.onSubmit(IncidenceFormData(
      userId: _userId,
      type: _type,
      fechaInicio: _fechaInicio,
      fechaFin: _fechaFin,
      observaciones: _observaciones.trim(),
      documentoRelacionado: _archivoUrl,
      archivoFile: _archivoFile,
    ));
  }
}
