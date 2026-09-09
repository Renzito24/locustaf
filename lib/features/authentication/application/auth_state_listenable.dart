import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/models/user_model.dart';
import '../../../core/models/company_model.dart';
import '../../../../core/services/firestore_service.dart';

/// Regla de bloqueo por empresa inactiva (TASK-016).
///
/// Un superadmin de plataforma NUNCA queda bloqueado por el estado de una
/// empresa, aunque su documento tenga un `companyId` heredado: no tiene empresa
/// propia y gestiona todas desde la pantalla Empresas. El bloqueo solo aplica a
/// usuarios con empresa (admin, supervisor y employee).
bool isCompanyInactiveFor(
  UserRole? role,
  String? companyId,
  CompanyEstado? companyEstado,
) {
  if (role == UserRole.superadmin) return false;
  return companyId != null && companyEstado == CompanyEstado.inactiva;
}

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
  StreamSubscription<Object?>? _companyDocSub;
  UserRole? _role;
  bool? _isActive;
  bool? _isDeleted;
  String? _companyId;
  CompanyEstado? _companyEstado;

  User? get user => FirebaseAuth.instance.currentUser;

  bool get isLoggedIn => user != null;

  UserRole? get role => _role;

  bool get isAdmin => _role == UserRole.admin;
  bool get isSupervisor => _role == UserRole.supervisor;
  bool get isEmployee => _role == UserRole.employee;
  bool get isSuperadmin => _role == UserRole.superadmin;

  bool get isUserActive => _isActive == true;
  bool get isUserDeleted => _isDeleted == true;
  bool get isUserBlocked => _isActive == false || _isDeleted == true;

  /// La empresa del usuario está inactiva (solo aplica a usuarios con empresa;
  /// el superadmin de plataforma nunca se bloquea, TASK-016).
  bool get isCompanyInactive =>
      isCompanyInactiveFor(_role, _companyId, _companyEstado);

  /// El usuario está autenticado pero aún no tiene empresa asignada
  /// (debe completar el onboarding). El superadmin queda excluido: no tiene
  /// empresa propia y gestiona todas las empresas desde la pantalla Empresas.
  bool get needsOnboarding => isLoggedIn && _companyId == null && !isSuperadmin;

  void _onAuthChanged(User? user) {
    _userDocSub?.cancel();
    _userDocSub = null;
    _companyDocSub?.cancel();
    _companyDocSub = null;
    _role = null;
    _isActive = null;
    _isDeleted = null;
    _companyId = null;
    _companyEstado = null;
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
      if (userModel == null) {
        // El usuario aún no tiene documento en 'users' (p. ej. recién se
        // registró con Google y debe completar el onboarding). Se deja sin
        // datos para que el router lo derive a /onboarding en lugar de
        // bloquearlo como cuenta eliminada.
        _role = null;
        _isActive = null;
        _isDeleted = null;
        _companyId = null;
        _startListeningCompanyDoc(svc, null);
        notifyListeners();
        return;
      }
      _role = userModel.rol;
      _isActive = userModel.isActive;
      _isDeleted = userModel.isDeleted;
      _companyId = userModel.companyId;
      _startListeningCompanyDoc(svc, userModel.companyId);
      notifyListeners();
    });
  }

  void _startListeningCompanyDoc(FirestoreService svc, String? companyId) {
    _companyDocSub?.cancel();
    _companyDocSub = null;
    _companyEstado = null;
    if (companyId == null) return;
    _companyDocSub = svc.documentStream<CompanyModel>(
      path: 'companies',
      documentId: companyId,
      fromJson: CompanyModel.fromJson,
    ).listen((company) {
      _companyEstado = company?.estado;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    _userDocSub?.cancel();
    _companyDocSub?.cancel();
    super.dispose();
  }
}