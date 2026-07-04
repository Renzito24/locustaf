import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService(this._firestore);

  Stream<List<T>> collectionStream<T>({
    required String path,
    required T Function(Map<String, dynamic> json) fromJson,
  }) {
    return _firestore.collection(path).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) {
        return fromJson({
          ...doc.data(),
          'id': doc.id,
        });
      }).toList(),
    );
  }

  Stream<T?> documentStream<T>({
    required String path,
    required String documentId,
    required T Function(Map<String, dynamic> json) fromJson,
  }) {
    return _firestore.collection(path).doc(documentId).snapshots().map(
      (snapshot) {
        if (!snapshot.exists) return null;
        return fromJson({
          ...snapshot.data()!,
          'id': snapshot.id,
        });
      },
    );
  }

  Future<void> setDocument({
    required String path,
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    return _firestore.collection(path).doc(documentId).set(data);
  }

  Future<Map<String, dynamic>?> getDocument({
    required String path,
    required String documentId,
  }) async {
    final doc = await _firestore.collection(path).doc(documentId).get();
    if (!doc.exists) return null;
    return {...doc.data()!, 'id': doc.id};
  }

  Future<void> updateDocument({
    required String path,
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    return _firestore.collection(path).doc(documentId).update(data);
  }

  Future<void> deleteDocument({
    required String path,
    required String documentId,
  }) {
    return _firestore.collection(path).doc(documentId).delete();
  }
}