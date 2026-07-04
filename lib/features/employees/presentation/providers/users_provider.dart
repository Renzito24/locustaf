import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/data/models/user_model.dart';
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
  final service = ref.read(firestoreServiceProvider);
  return UsersRepositoryImpl(service);
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
    var employees = users.where((u) => u.rol == UserRole.empleado).toList();

    // 2. Filter by search query (nombre, apellido, dni, email)
    if (searchQuery.isNotEmpty) {
      employees = employees.where((u) {
        return u.nombre.toLowerCase().contains(searchQuery) ||
            u.apellido.toLowerCase().contains(searchQuery) ||
            u.dni.toLowerCase().contains(searchQuery) ||
            u.email.toLowerCase().contains(searchQuery);
      }).toList();
    }

    // 3. Filter by active/inactive status
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

    // 4. Sort alphabetically by last name (apellido), then name (nombre)
    employees.sort((a, b) {
      final comp = a.apellido.toLowerCase().compareTo(b.apellido.toLowerCase());
      if (comp != 0) return comp;
      return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
    });

    return employees;
  });
});

