import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/data_providers.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/services/storage_service.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/models/medical_document_model.dart';
import '../../data/repositories/medical_document_repository_impl.dart';
import '../../domain/repositories/medical_document_repository.dart';

export 'medical_documents_filter_provider.dart';
export 'medical_documents_action_provider.dart';

final medicalDocumentRepositoryProvider = Provider<MedicalDocumentRepository>((ref) {
  final companyId = ref.watch(currentCompanyIdProvider) ?? '';
  final firestoreService = ref.read(firestoreServiceProvider);
  final role = ref.watch(userRoleProvider);
  final userId = ref.watch(currentUserIdProvider);
  return MedicalDocumentRepositoryImpl(
    firestoreService,
    companyId: companyId,
    userId: userId,
    role: role,
  );
});

final medicalDocumentsStreamProvider = StreamProvider<List<MedicalDocumentModel>>((ref) {
  final companyId = ref.watch(currentCompanyIdProvider);
  if (companyId == null) {
    return Stream.value(<MedicalDocumentModel>[]);
  }
  final repo = ref.watch(medicalDocumentRepositoryProvider);
  return repo.getDocuments();
});

/// Bytes de un adjunto de Storage, descargados con el SDK autenticado.
///
/// Evita `Image.network` / `http.get`: el bucket no envía cabeceras CORS, por
/// lo que la vista previa de imágenes y la apertura de PDF fallan en web.
/// Queda cacheado por URL mientras el provider esté vivo.
final medicalAttachmentBytesProvider = FutureProvider.family<Uint8List, String>((ref, url) {
  return ref.watch(storageServiceProvider).readFileBytes(url);
});
