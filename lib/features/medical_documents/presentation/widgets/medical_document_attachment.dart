import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/file_attachment_kind.dart';
import 'medical_document_attachment_components.dart';

/// Muestra el adjunto según su tipo: imágenes como vista previa real, PDFs con
/// un botón "Abrir PDF" y otros tipos como el enlace copiable original.
class MedicalDocumentAttachment extends StatelessWidget {
  final String fileName;
  final String url;
  final FileAttachmentKind kind;

  const MedicalDocumentAttachment({
    super.key,
    required this.fileName,
    required this.url,
    required this.kind,
  });

  @override
  Widget build(BuildContext context) {
    if (kind == FileAttachmentKind.other) {
      return OtherAttachmentPreview(fileName: fileName, url: url);
    }

    final content = kind == FileAttachmentKind.image
        ? ImageAttachmentPreview(fileName: fileName, url: url)
        : PdfAttachmentPreview(fileName: fileName, url: url);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 130,
            child: Text(
              'Archivo',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }
}
