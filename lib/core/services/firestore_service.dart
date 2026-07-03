import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService(this._firestore);

  Stream<List<T>> collectionStream<T>({
    required String path,
    required T Function(Map<String, dynamic> json) fromJson,
  }) {
    return _firestore.collection(path).snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => fromJson({...doc.data(), 'id': doc.id}))
          .toList(),
    );
  }
}
