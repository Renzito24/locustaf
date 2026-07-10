import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../authentication/data/models/user_model.dart';
import '../../../employees/presentation/providers/users_provider.dart';
import '../../data/models/medical_document_model.dart';

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
  final void Function(MedicalDocumentFormData data) onSubmit;

  const MedicalDocumentForm({
    super.key,
    this.existingDocument,
    this.isLoading = false,
    this.uploadProgress = 0,
    this.errorMessage,
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
    _userId = doc?.userId ?? '';
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
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.errorMessage!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          usersAsync.when(
            data: (users) {
              final employees =
                  users.where((u) => u.rol == UserRole.employee && !u.isDeleted).toList();
              return DropdownButtonFormField<String>(
                initialValue: _userId.isEmpty ? null : _userId,
                decoration: const InputDecoration(
                  labelText: 'Empleado',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: employees
                    .map((e) => DropdownMenuItem<String>(
                          value: e.id,
                          child: Text(e.nombreCompleto),
                        ))
                    .toList(),
                onChanged: isEditing
                    ? null
                    : (value) {
                        setState(() => _userId = value ?? '');
                      },
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Seleccione un empleado';
                  return null;
                },
              );
            },
            loading: () => const TextField(
              decoration: InputDecoration(labelText: 'Empleado', border: OutlineInputBorder(), isDense: true),
              enabled: false,
            ),
            error: (_, _) => const TextField(
              decoration: InputDecoration(labelText: 'Empleado', border: OutlineInputBorder(), isDense: true),
              enabled: false,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<MedicalDocumentTipo>(
            initialValue: _tipo,
            decoration: const InputDecoration(
              labelText: 'Tipo de documento',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: MedicalDocumentTipo.values
                .map((t) => DropdownMenuItem<MedicalDocumentTipo>(
                      value: t,
                      child: Text(t.label),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _tipo = value);
            },
            validator: (value) {
              if (value == null) return 'Seleccione un tipo';
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  label: 'Fecha de emisión',
                  value: _fechaInicio,
                  onChanged: (d) => setState(() => _fechaInicio = d),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDatePicker(
                  label: 'Fecha de vencimiento',
                  value: _fechaFin,
                  onChanged: (d) => setState(() => _fechaFin = d),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _motivoController,
            decoration: const InputDecoration(
              labelText: 'Observaciones',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 3,
            onChanged: (value) => _motivo = value,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Ingrese las observaciones';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildFilePickerSection(),
          const SizedBox(height: 16),
          if (_isUploading)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: widget.uploadProgress,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  color: AppColors.primary,
                  minHeight: 6,
                ),
                const SizedBox(height: 4),
                Text(
                  'Subiendo archivo... ${(widget.uploadProgress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          SizedBox(height: widget.uploadProgress > 0 && widget.uploadProgress < 1 ? 16 : 0),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (widget.isLoading && !_isUploading) ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        ],
      ),
    );
  }

  Widget _buildFilePickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_archivoFile != null || _archivoUrl != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_file, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _archivoFile?.name ?? _archivoUrl!,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_archivoFile != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setState(() => _archivoFile = null),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
        OutlinedButton.icon(
          onPressed: widget.isLoading ? null : _pickFile,
          icon: const Icon(Icons.upload_file, size: 18),
          label: Text(_archivoFile != null ? 'Cambiar archivo' : 'Seleccionar archivo (opcional)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
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

  Widget _buildDatePicker({
    required String label,
    required DateTime value,
    required void Function(DateTime) onChanged,
  }) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        suffixIcon: IconButton(
          icon: const Icon(Icons.date_range, size: 18),
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (date != null) onChanged(date);
          },
        ),
      ),
      controller: TextEditingController(
        text:
            '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}',
      ),
      readOnly: true,
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un empleado')),
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
