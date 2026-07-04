import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/data/models/user_model.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../../core/services/firestore_service.dart';
import '../../data/repositories/users_repository_impl.dart';
import '../../domain/repositories/users_repository.dart';

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  final firestore = ref.read(firebaseFirestoreProvider);
  return FirestoreService(firestore);
});

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  final firestoreService = ref.read(firestoreServiceProvider);
  final authService = ref.read(authServiceProvider);
  return UsersRepositoryImpl(firestoreService, authService);
});

final usersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final repo = ref.read(usersRepositoryProvider);
  return repo.getUsers();
});

enum EmployeeStatusFilter {
  all,
  active,
  inactive,
}

class EmployeeWorkplaceFilter extends Notifier<String?> {
  @override
  String? build() => null;

  void setFilter(String? workplaceId) {
    state = workplaceId;
  }

  void clear() {
    state = null;
  }
}

final employeeWorkplaceFilterProvider = NotifierProvider<EmployeeWorkplaceFilter, String?>(
  EmployeeWorkplaceFilter.new,
);

class EmployeeSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String value) {
    state = value;
  }

  void clear() {
    state = '';
  }
}

final employeeSearchQueryProvider = NotifierProvider<EmployeeSearchQuery, String>(EmployeeSearchQuery.new);

class EmployeeFilterNotifier extends Notifier<EmployeeStatusFilter> {
  @override
  EmployeeStatusFilter build() => EmployeeStatusFilter.all;

  void setFilter(EmployeeStatusFilter filter) {
    state = filter;
  }
}

final employeeFilterProvider = NotifierProvider<EmployeeFilterNotifier, EmployeeStatusFilter>(EmployeeFilterNotifier.new);

final filteredEmployeesProvider = Provider<AsyncValue<List<UserModel>>>((ref) {
  final usersAsync = ref.watch(usersStreamProvider);
  final searchQuery = ref.watch(employeeSearchQueryProvider).trim().toLowerCase();
  final statusFilter = ref.watch(employeeFilterProvider);

  return usersAsync.whenData((users) {
    // 1. Filter only employees
    var employees = users.where((u) => u.rol == UserRole.employee).toList();

    // 2. Exclude soft-deleted employees
    employees = employees.where((u) => !u.isDeleted).toList();

    // 3. Filter by search query (nombre, apellido, dni, email)
    if (searchQuery.isNotEmpty) {
      employees = employees.where((u) {
        return u.nombre.toLowerCase().contains(searchQuery) ||
            u.apellido.toLowerCase().contains(searchQuery) ||
            u.dni.toLowerCase().contains(searchQuery) ||
            u.email.toLowerCase().contains(searchQuery);
      }).toList();
    }

    // 4. Filter by active/inactive status
    switch (statusFilter) {
      case EmployeeStatusFilter.active:
        employees = employees.where((u) => u.isActive).toList();
        break;
      case EmployeeStatusFilter.inactive:
        employees = employees.where((u) => !u.isActive).toList();
        break;
      case EmployeeStatusFilter.all:
        break;
    }

    // 5. Filter by workplace
    final workplaceFilter = ref.watch(employeeWorkplaceFilterProvider);
    if (workplaceFilter != null) {
      employees = employees.where((u) => u.lugarDeTrabajoId == workplaceFilter).toList();
    }

    // 6. Sort alphabetically by last name (apellido), then name (nombre)
    employees.sort((a, b) {
      final comp = a.apellido.toLowerCase().compareTo(b.apellido.toLowerCase());
      if (comp != 0) return comp;
      return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
    });

    return employees;
  });
});

class EmployeeFormData {
  final String nombre;
  final String apellido;
  final String email;
  final String dni;
  final String? telefono;
  final String password;
  final String? lugarDeTrabajoId;

  const EmployeeFormData({
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.dni,
    this.telefono,
    required this.password,
    this.lugarDeTrabajoId,
  });
}

class CreateEmployeeNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() => Future.value();

  Future<void> createEmployee(EmployeeFormData data) async {
    state = const AsyncLoading();
    final repo = ref.read(usersRepositoryProvider);
    try {
      final user = UserModel(
        id: '',
        nombre: data.nombre,
        apellido: data.apellido,
        email: data.email,
        dni: data.dni,
        telefono: data.telefono,
        rol: UserRole.employee,
        lugarDeTrabajoId: data.lugarDeTrabajoId,
        createdAt: DateTime.now(),
      );
      await repo.createUser(user, data.password);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}

final createEmployeeProvider =
    AsyncNotifierProvider<CreateEmployeeNotifier, void>(
  CreateEmployeeNotifier.new,
);

