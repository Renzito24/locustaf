/// Estado explícito de una acción asíncrona de UI (crear, actualizar, eliminar,
/// aprobar, registrar pago, etc.).
///
/// Reemplaza el patrón `AsyncNotifier<void>` cuyo valor inicial era
/// `AsyncData(null)` (éxito). Ese valor inicial hacía que `ref.listen` mostrara
/// mensajes de éxito fantasma al montar las pantallas (evento reutilizado:
/// estado idle == estado de éxito). Con este estado el inicio es
/// [AsyncActionStatus.idle] y el éxito solo existe después de que la operación
/// terminó realmente.
enum AsyncActionStatus { idle, loading, success, failure }

class AsyncActionState {
  final AsyncActionStatus status;
  final Object? error;

  const AsyncActionState._(this.status, {this.error});

  const AsyncActionState.idle() : this._(AsyncActionStatus.idle);

  const AsyncActionState.loading() : this._(AsyncActionStatus.loading);

  const AsyncActionState.success() : this._(AsyncActionStatus.success);

  const AsyncActionState.failure(Object error)
      : this._(AsyncActionStatus.failure, error: error);

  bool get isLoading => status == AsyncActionStatus.loading;
}