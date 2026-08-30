import 'package:cloud_firestore/cloud_firestore.dart';

/// Resultado de una consulta paginada.
class QueryPage<T> {
  final List<T> items;
  final bool hasMore;
  final Object? lastOrderValue;

  const QueryPage({
    required this.items,
    required this.hasMore,
    this.lastOrderValue,
  });
}

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService(this._firestore);

  /// Ejecuta una transacción atómica de Firestore.
  /// Útil para operaciones que requieren leer y escribir de forma atómica
  /// (ej: verificar que no exista una asistencia activa antes de crearla).
  Future<T> runTransaction<T>(Future<T> Function(Transaction transaction) callback) {
    return _firestore.runTransaction(callback);
  }

  /// Genera un ID único para un documento en la colección especificada,
  /// sin escribir el documento. Útil cuando se necesita el ID antes de
  /// realizar operaciones como upload a Storage.
  String generateId(String collection) {
    return _firestore.collection(collection).doc().id;
  }

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
    String? orderField,
    bool descending = true,
  }) {
    var query = _firestore.collection(path).where(field, isEqualTo: value);
    if (orderField != null) {
      query = query.orderBy(orderField, descending: descending);
    }
    return query.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) {
        return fromJson({
          ...doc.data(),
          'id': doc.id,
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
          'id': doc.id,
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

  /// Similar a [collectionStreamWhere] pero con soporte de ordenamiento.
  /// Requiere un índice compuesto que cubra todos los campos en [filters] más [orderField].
  Stream<List<T>> queryStreamWithFilters<T>({
    required String path,
    required Map<String, dynamic> filters,
    required T Function(Map<String, dynamic> json) fromJson,
    String? orderField,
    bool descending = false,
  }) {
    var query = _firestore.collection(path) as Query<Map<String, dynamic>>;
    filters.forEach((field, value) {
      query = query.where(field, isEqualTo: value);
    });
    if (orderField != null) {
      query = query.orderBy(orderField, descending: descending);
    }
    return query.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) {
        return fromJson({
          ...doc.data(),
          'id': doc.id,
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

  /// Consulta paginada con orden estable (usa [orderField] como cursor).
  /// Requiere un índice compuesto que cubra [filters] + [orderField].
  Future<QueryPage<T>> queryPage<T>({
    required String path,
    required Map<String, dynamic> filters,
    required T Function(Map<String, dynamic> json) fromJson,
    String? orderField,
    bool descending = false,
    required int limit,
    Object? startAfter,
  }) async {
    var query = _firestore.collection(path) as Query<Map<String, dynamic>>;
    filters.forEach((field, value) {
      query = query.where(field, isEqualTo: value);
    });
    if (orderField != null) {
      query = query.orderBy(orderField, descending: descending);
    }
    if (startAfter != null) {
      query = query.startAfter([startAfter]);
    }
    query = query.limit(limit);

    final snapshot = await query.get();
    final items = snapshot.docs.map((doc) {
      return fromJson({
        ...doc.data(),
        'id': doc.id,
      });
    }).toList();

    final lastValue = snapshot.docs.isEmpty || orderField == null
        ? null
        : snapshot.docs.last.get(orderField);
    return QueryPage<T>(
      items: items,
      hasMore: snapshot.docs.length == limit,
      lastOrderValue: lastValue,
    );
  }

  /// Cuenta documentos que cumplen los filtros usando la agregación COUNT
  /// nativa de Firestore (sin descargar los documentos).
  Future<int> countDocuments({
    required String path,
    required Map<String, dynamic> filters,
  }) async {
    var query = _firestore.collection(path) as Query<Map<String, dynamic>>;
    filters.forEach((field, value) {
      query = query.where(field, isEqualTo: value);
    });
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  /// IMPORTANTE: Se escribe tanto 'id' como 'uid' para mantener compatibilidad
  /// con documentos existentes en la colección 'attendances' que usaban 'uid'.
  ///
  /// [Migración futura]: Cuando todos los documentos de 'attendances' tengan el campo
  /// 'id', se debe eliminar la escritura de 'uid' en este método y actualizar
  /// AttendanceModel.fromJson para que solo lea 'id'. Para migrar los documentos
  /// existentes, ejecutar un script que copie 'uid' → 'id' en todos los documentos
  /// de la colección 'attendances'.
  Future<String> addDocument({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    final docRef = _firestore.collection(path).doc();
    await docRef.set({
      ...data,
      'id': docRef.id,
      'uid': docRef.id,
    });
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

  /// Expone el acceso a una colección para casos donde se necesita
  /// acceso directo (ej: transacciones con DocReference).
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }
}