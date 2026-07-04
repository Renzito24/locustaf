import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/data/models/user_model.dart';
import '../providers/users_provider.dart';

class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersStreamProvider);

    return usersAsync.when(
        data: (List<UserModel> users) {
          if (users.isEmpty) {
            return const Center(
              child: Text('No hay empleados registrados'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final user = users[index];

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(user.nombre[0]),
                  ),
                  title: Text(user.nombreCompleto),
                  subtitle: Text(user.email),
                  trailing: Text(
                    user.rol.name,
                    style: TextStyle(
                      color: user.rol.name == 'admin'
                          ? Colors.red
                          : Colors.blue,
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
    );
  }
}