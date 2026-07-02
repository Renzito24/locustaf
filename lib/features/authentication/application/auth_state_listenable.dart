import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthStateListenable extends ChangeNotifier {
  AuthStateListenable() {
    _subscription = FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription _subscription;

  User? get user => FirebaseAuth.instance.currentUser;

  bool get isLoggedIn => user != null;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}