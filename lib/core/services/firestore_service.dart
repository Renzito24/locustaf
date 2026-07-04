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

  Stream<List<T>> queryStream<T>({
    required String path,
    required String field,
    required dynamic value,
    required T Function(Map<String, dynamic> json) fromJson,
  }) {
    return _firestore
        .collection(path)
        .where(field, isEqualTo: value)
        .orderBy('checkInTime', descending: true)
        .snapshots()
        .map(
      (snapshot) => snapshot.docs.map((doc) {
        return fromJson({
          ...doc.data(),
          'uid': doc.id,
        });
      }).toList(),
    );
  }

  Stream<List<T>> queryStreamWithoutOrder<T>({
    required String path,
    required String field,
    required dynamic value,
    required T Function(Map<String, dynamic> json) fromJson,
  }) {
    return _firestore
        .collection(path)
        .where(field, isEqualTo: value)
        .snapshots()
        .map(
      (snapshot) => snapshot.docs.map((doc) {
        return fromJson({
          ...doc.data(),
          'uid': doc.id,
        });
      }).toList(),
    );
  }

  Stream<List<T>> collectionStreamWhere<T>({
    required String path,
    required Map<String, dynamic> filters,
    required T Function(Map<String, dynamic> json) fromJson,
  }) {
    var query = _firestore.collection(path) as Query<Map<String, dynamic>>;
    filters.forEach((field, value) {
      query = query.where(field, isEqualTo: value);
    });
    return query.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        return fromJson({
          ...data,
          'id': doc.id,
          'uid': doc.id,
        });
      }).toList(),
    );
  }

  Future<void> setDocument({
    required String path,
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    return _firestore.collection(path).doc(documentId).set(data);
  }

  Future<String> addDocument({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    final docRef = _firestore.collection(path).doc();
    await docRef.set({...data, 'uid': docRef.id});
    return docRef.id;
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