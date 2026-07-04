import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/models/user_model.dart';
import '../../../../core/services/firestore_service.dart';

class AuthStateListenable extends ChangeNotifier {
  AuthStateListenable() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _onAuthChanged(user);
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _startListeningUserDoc(user.uid);
    }
  }

  late final StreamSubscription _authSub;
  StreamSubscription<Object?>? _userDocSub;
  UserRole? _role;

  User? get user => FirebaseAuth.instance.currentUser;

  bool get isLoggedIn => user != null;

  UserRole? get role => _role;

  bool get isAdmin => _role == UserRole.admin;
  bool get isSupervisor => _role == UserRole.supervisor;
  bool get isEmployee => _role == UserRole.employee;

  void _onAuthChanged(User? user) {
    _userDocSub?.cancel();
    _userDocSub = null;
    _role = null;
    if (user != null) {
      _startListeningUserDoc(user.uid);
    }
    notifyListeners();
  }

  void _startListeningUserDoc(String uid) {
    final svc = FirestoreService(FirebaseFirestore.instance);
    _userDocSub = svc.documentStream<UserModel>(
      path: 'users',
      documentId: uid,
      fromJson: UserModel.fromJson,
    ).listen((userModel) {
      _role = userModel?.rol;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    _userDocSub?.cancel();
    super.dispose();
  }
}