import 'dart:async';

/// Re-suscribe un stream de Firestore cuando falla, con backoff exponencial.
///
/// Por qué existe: un `StreamProvider` sin esto latchea el error. Si el
/// stream falla una sola vez (cache local de Firestore desactualizado tras
/// un update de la app, corte de red, `permission-denied` transitorio), el
/// provider queda en `AsyncError` para el resto de la sesion y nada vuelve a
/// pedir los datos. El usuario ve "Error al cargar las metricas" hasta que
/// borra el cache de la app a mano.
///
/// Con este wrapper el error se reintenta solo con esperas crecientes
/// (400ms, 800ms, 1600ms...) y recien despues de [maxAttempts] intentos
/// queda latcheado, para que la UI muestre el boton de reintentar manual.
///
/// Los valores emitidos antes de un error se conservan: el reintento no borra
/// lo ya recibido, solo agrega lo que venga despues.
Stream<T> retryOnError<T>(
  Stream<T> Function() subscribe, {
  int maxAttempts = 4,
  Duration initialDelay = const Duration(milliseconds: 400),
  double delayMultiplier = 2.0,
  Duration maxDelay = const Duration(seconds: 8),
}) {
  late final StreamController<T> controller;
  var attempt = 0;
  var cancelled = false;
  StreamSubscription<T>? subscription;

  void connect() {
    // `onCancel` no cierra el controller, asi que un retry ya agendado puede
    // ejecutarse igual. El flag es lo que frena de verdad la reconexion.
    if (cancelled || controller.isClosed) return;

    subscription = subscribe().listen(
      controller.add,
      onError: (Object error, StackTrace stackTrace) {
        if (cancelled || controller.isClosed) return;
        if (attempt >= maxAttempts) {
          controller.addError(error, stackTrace);
          return;
        }
        attempt += 1;
        final delayMs =
            (initialDelay.inMilliseconds * (delayMultiplier * (attempt - 1)))
                .round()
                .clamp(initialDelay.inMilliseconds, maxDelay.inMilliseconds);
        Future<void>.delayed(Duration(milliseconds: delayMs), () {
          connect();
        });
      },
      onDone: () {
        if (!cancelled && !controller.isClosed) controller.close();
      },
      cancelOnError: true,
    );
  }

  controller = StreamController<T>(
    onListen: connect,
    onCancel: () async {
      cancelled = true;
      await subscription?.cancel();
    },
  );

  return controller.stream;
}
