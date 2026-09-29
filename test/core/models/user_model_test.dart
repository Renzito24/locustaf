import 'package:app_locustaf/core/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel (TASK-013) — acceptedPoliciesAt', () {
    final base = {
      'id': 'u1',
      'nombre': 'Ana',
      'apellido': 'Gomez',
      'email': 'ana@corp.com',
      'dni': '30111222',
      'rol': 'admin',
      'companyId': 'c1',
      'createdAt': '2026-09-09T12:00:00.000Z',
    };

    test('fromJson con acceptedPoliciesAt parsea la fecha y versiones', () {
      final json = {
        ...base,
        'acceptedPoliciesAt': '2026-09-09T12:05:00.000Z',
        'termsVersion': '1.0',
        'privacyVersion': '2.1',
      };
      final user = UserModel.fromJson(json);
      expect(user.acceptedPoliciesAt, isNotNull);
      expect(user.acceptedPoliciesAt!.toUtc().toIso8601String(),
          '2026-09-09T12:05:00.000Z');
      expect(user.termsVersion, '1.0');
      expect(user.privacyVersion, '2.1');
    });

    test('fromJson legacy sin acceptedPoliciesAt ni versiones no revienta (null)', () {
      final user = UserModel.fromJson(base);
      expect(user.acceptedPoliciesAt, isNull);
      expect(user.termsVersion, isNull);
      expect(user.privacyVersion, isNull);
    });

    test('toJson round-trip conserva acceptedPoliciesAt y versiones', () {
      final user = UserModel.fromJson({
        ...base,
        'acceptedPoliciesAt': '2026-09-09T12:05:00.000Z',
        'termsVersion': '1.0',
        'privacyVersion': '2.1',
      });
      final json = user.toJson();
      expect(json['acceptedPoliciesAt'], '2026-09-09T12:05:00.000Z');
      expect(json['termsVersion'], '1.0');
      expect(json['privacyVersion'], '2.1');
    });

    test('copyWith permite fijar acceptedPoliciesAt y versiones', () {
      final user = UserModel.fromJson(base);
      final updated = user.copyWith(
        acceptedPoliciesAt: DateTime.utc(2026, 9, 9, 12, 5),
        termsVersion: '1.0',
        privacyVersion: '2.1',
      );
      expect(updated.acceptedPoliciesAt, isNotNull);
      expect(updated.acceptedPoliciesAt!.toUtc().toIso8601String(),
          '2026-09-09T12:05:00.000Z');
      expect(updated.termsVersion, '1.0');
      expect(updated.privacyVersion, '2.1');
    });

    test('props incluye acceptedPoliciesAt y versiones (equatable)', () {
      final a = UserModel.fromJson(base);
      final b = UserModel.fromJson({
        ...base,
        'acceptedPoliciesAt': '2026-09-09T12:05:00.000Z',
        'termsVersion': '1.0',
        'privacyVersion': '2.1',
      });
      expect(a, isNot(equals(b)));
    });
  });
}