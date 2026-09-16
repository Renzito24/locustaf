import '../../../../core/models/user_model.dart';

/// Busca dentro de la lista de usuarios de la empresa un DNI igual al dado.
///
/// Devuelve el DNI del usuario existente o `null` si no hay coincidencia.
/// Reglas:
/// - Ignora usuarios eliminados (soft-delete) para permitir re-utilizar el
///   DNI de una persona dada de baja.
/// - [excludeUserId] excluye al propio usuario al editar (el DNI propio no
///   puede considerarse duplicado).
/// - Comparación normalizada (trim) para tolerar espacios.
String? findDuplicateDni(
  List<UserModel> users, {
  required String dni,
  String? excludeUserId,
}) {
  final normalized = dni.trim();
  if (normalized.isEmpty) return null;
  for (final user in users) {
    if (user.isDeleted) continue;
    if (user.id == excludeUserId) continue;
    if (user.dni.trim() == normalized) {
      return user.dni;
    }
  }
  return null;
}