import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:app_locustaf/core/services/stream_retry.dart';

void main() {
  group('retryOnError', () {
    test('deja pasar los valores si el stream nunca falla', () async {
      var subscribes = 0;
      final values = await retryOnError(() {
        subscribes += 1;
        return Stream<int>.fromIterable([1, 2, 3]);
      }).toList();

      expect(values, [1, 2, 3]);
      expect(subscribes, 1);
    });

    test('re-suscribe y recupera cuando el primer intento falla', () async {
      var subscribes = 0;
      final values = await retryOnError(
        () {
          subscribes += 1;
          if (subscribes == 1) {
            return Stream<int>.error(StateError('cache local corrupto'));
          }
          return Stream<int>.fromIterable([7, 8]);
        },
        initialDelay: const Duration(milliseconds: 1),
      ).toList();

      expect(values, [7, 8]);
      expect(subscribes, 2, reason: 'debe re-suscribir tras el error');
    });

    test('reintenta hasta maxAttempts y recien ahi propaga el error', () async {
      var subscribes = 0;
      Object? caught;

      await retryOnError(
        () {
          subscribes += 1;
          return Stream<int>.error(StateError('siempre falla'));
        },
        maxAttempts: 3,
        initialDelay: const Duration(milliseconds: 1),
      ).drain<void>().catchError((Object e) {
        caught = e;
      });

      expect(caught, isA<StateError>());
      // 1 intento inicial + 3 reintentos
      expect(subscribes, 4);
    });

    test('conserva los valores emitidos antes del error', () async {
      var subscribes = 0;
      final values = <int>[];
      Object? caught;

      Stream<int> emiteYFalla() async* {
        yield 1;
        yield 2;
        throw StateError('se rompio al final');
      }

      await retryOnError(
        () {
          subscribes += 1;
          if (subscribes == 1) return emiteYFalla();
          return Stream<int>.fromIterable([9]);
        },
        initialDelay: const Duration(milliseconds: 1),
      ).listen(values.add).asFuture<void>().then<void>((_) {}, onError: (Object e) {
        caught = e;
      });

      // Los datos previos no se pierden y el reintento agrega los nuevos.
      expect(values, [1, 2, 9]);
      expect(caught, isNull);
      expect(subscribes, 2);
    });

    test('respeta el atraso creciente entre reintentos', () async {
      final stopwatch = Stopwatch()..start();
      var subscribes = 0;

      await retryOnError(
        () {
          subscribes += 1;
          return Stream<int>.error(StateError('falla'));
        },
        maxAttempts: 2,
        initialDelay: const Duration(milliseconds: 30),
      ).drain<void>().catchError((Object e) => null);

      stopwatch.stop();
      expect(subscribes, 3);
      // 30ms (tras el 1er fallo) + 60ms (tras el 2do) = 90ms minimo.
      expect(
        stopwatch.elapsedMilliseconds,
        greaterThanOrEqualTo(85),
        reason: 'debe esperar entre reintentos, no fallar en boucle',
      );
    });

    test('corta el reintento si el listener cancela la suscripcion', () async {
      var subscribes = 0;

      final sub = retryOnError(
        () {
          subscribes += 1;
          return Stream<int>.error(StateError('falla'));
        },
        initialDelay: const Duration(milliseconds: 200),
      ).listen(null);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      await sub.cancel();
      final subscribesAtCancel = subscribes;
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(subscribes, subscribesAtCancel, reason: 'no debe reintentar tras cancelar');
    });
  });
}
