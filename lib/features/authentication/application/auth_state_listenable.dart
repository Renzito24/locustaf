import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/models/user_model.dart';
import '../../../core/models/company_model.dart';
import '../../../core/services/firestore_service.dart';

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
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _profileLoading = true;
      _startListeningUserDoc(user.uid);
    }
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _onAuthChanged(user);
    });
  }

  late final StreamSubscription _authSub;
  StreamSubscription<Object?>? _userDocSub;
  StreamSubscription<Object?>? _companyDocSub;
  bool _profileLoading = true;
  UserModel? _userModel;
  UserRole? _role;
  bool? _isActive;
  bool? _isDeleted;
  String? _companyId;
  CompanyEstado? _companyEstado;

  User? get user => FirebaseAuth.instance.currentUser;

  bool get isLoggedIn => user != null;

  /// El documento del usuario en 'users' todavía no se ha leído: el estado de
  /// rol/empresa/bloqueo es desconocido. Mientras sea true el router debe
  /// permanecer en el splash y NO decidir (p. ej. mandar al onboarding a un
  /// usuario que ya tiene empresa). (Fase B — A3)
  bool get isProfileLoading => _profileLoading;

  UserModel? get userModel => _userModel;
  String? get companyId => _companyId;
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
  /// Solo aplica una vez que el perfil fue leído: durante la carga el router
  /// permanece en el splash vía [isProfileLoading]. (Fase B — A3)
  bool get needsOnboarding =>
      isLoggedIn && !_profileLoading && _companyId == null && !isSuperadmin;

  String? _profileError;
  String? get profileError => _profileError;
  bool get hasProfileError => _profileError != null;
  Timer? _profileTimeoutTimer;

  void _onAuthChanged(User? user) {
    _profileTimeoutTimer?.cancel();
    _profileTimeoutTimer = null;
    _profileError = null;
    _userDocSub?.cancel();
    _userDocSub = null;
    _companyDocSub?.cancel();
    _companyDocSub = null;
    _userModel = null;
    _role = null;
    _isActive = null;
    _isDeleted = null;
    _companyId = null;
    _companyEstado = null;
    _profileLoading = user != null;
    if (user != null) {
      _startListeningUserDoc(user.uid);
    }
    notifyListeners();
  }

  void _startListeningUserDoc(String uid) {
    _profileTimeoutTimer?.cancel();
    _profileError = null;
    _profileLoading = true;

    // Timeout de 10 segundos: si Firestore no responde (offline sin caché),
    // el splash muestra error con reintento en lugar de colgarse infinitamente.
    _profileTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (_profileLoading) {
        _profileLoading = false;
        _profileError = 'No se pudo conectar con el servidor. Verifique su conexión a internet.';
        notifyListeners();
      }
    });

    final svc = FirestoreService(FirebaseFirestore.instance);
    _userDocSub = svc.documentStream<UserModel>(
      path: 'users',
      documentId: uid,
      fromJson: UserModel.fromJson,
    ).listen(
      (userModel) {
        _profileTimeoutTimer?.cancel();
        _profileTimeoutTimer = null;
        _profileLoading = false;
        _userModel = userModel;
        if (userModel == null) {
          // El usuario aún no tiene documento en 'users' (p. ej. recién se
          // registró con Google y debe completar el onboarding). Se deja sin
          // datos para que el router lo derive a /onboarding en lugar de
          // bloquearlo con un error.
          _role = null;
          _isActive = null;
          _isDeleted = null;
          _companyId = null;
          _startListeningCompanyDoc(svc, null);
          notifyListeners();
          return;
        }
        _profileError = null;
        _role = userModel.rol;
        _isActive = userModel.isActive;
        _isDeleted = userModel.isDeleted;
        _companyId = userModel.companyId;
        _startListeningCompanyDoc(svc, userModel.companyId);
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        _profileTimeoutTimer?.cancel();
        _profileTimeoutTimer = null;
        _profileLoading = false;
        _profileError = 'Error al cargar el perfil de usuario. Verifique su conexión a internet.';
        _userModel = null;
        _role = null;
        _isActive = null;
        _isDeleted = null;
        _companyId = null;
        _companyEstado = null;
        _startListeningCompanyDoc(svc, null);
        notifyListeners();
      },
    );
  }

  /// Reintenta cargar el perfil del usuario actual desde Firestore.
  void retryProfileLoad() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _profileError = null;
      _profileLoading = true;
      notifyListeners();
      _startListeningUserDoc(user.uid);
    }
  }

  /// Cierra sesión en Auth y limpia cualquier temporizador o suscripción activa.
  Future<void> signOut() async {
    _profileTimeoutTimer?.cancel();
    _profileTimeoutTimer = null;
    _profileError = null;
    _profileLoading = false;
    await FirebaseAuth.instance.signOut();
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
    ).listen(
      (company) {
        _companyEstado = company?.estado;
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        _companyEstado = null;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _profileTimeoutTimer?.cancel();
    _authSub.cancel();
    _userDocSub?.cancel();
    _companyDocSub?.cancel();
    super.dispose();
  }
}