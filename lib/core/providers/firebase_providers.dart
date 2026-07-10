import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/firestore_service.dart';
import '../services/storage_service.dart';

/// Provider centralizado de FirestoreService.
///
/// ÚNICA fuente de [FirestoreService] en toda la aplicación.
/// Todos los repositorios y providers deben importar desde aquí.
/// No crear instancias locales de [FirestoreService] en providers individuales.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(FirebaseFirestore.instance);
});

/// Provider centralizado de StorageService.
///
/// ÚNICA fuente de [StorageService] en toda la aplicación.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(FirebaseStorage.instance);
});
