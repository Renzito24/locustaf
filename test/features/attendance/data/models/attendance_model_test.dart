import 'package:app_locustaf/features/attendance/data/models/attendance_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> baseJson() => {
        'id': 'att-1',
        'userId': 'user-1',
        'checkInTime': Timestamp.fromDate(DateTime(2026, 8, 29, 9, 0)),
        'date': '2026-08-29',
        'status': 'active',
        'companyId': 'company-1',
      };

  group('AttendanceModel.fromJson con datos válidos', () {
    test('parsea un documento correcto', () {
      final model = AttendanceModel.fromJson(baseJson());

      expect(model.id, 'att-1');
      expect(model.userId, 'user-1');
      expect(model.checkInTime.year, 2026);
      expect(model.date, '2026-08-29');
      expect(model.status, AttendanceStatus.active);
      expect(model.companyId, 'company-1');
    });

    test('soporta uid legacy en id', () {
      final model = AttendanceModel.fromJson({
        ...baseJson(),
        'uid': 'att-uid',
      }..remove('id'));
      expect(model.id, 'att-uid');
    });

    test('soporta checkOutTime como Timestamp', () {
      final model = AttendanceModel.fromJson({
        ...baseJson(),
        'status': 'completed',
        'checkOutTime': Timestamp.fromDate(DateTime(2026, 8, 29, 18, 0)),
        'durationMinutes': 540,
      });
      expect(model.status, AttendanceStatus.completed);
      expect(model.checkOutTime, isNotNull);
      expect(model.durationMinutes, 540);
    });
  });

  group('AttendanceModel.fromJson con datos corruptos (BUG-1)', () {
    test('no revienta con checkInTime null', () {
      final model = AttendanceModel.fromJson({
        ...baseJson(),
        'checkInTime': null,
      });
      expect(model, isNotNull);
      expect(model.checkInTime, DateTime.fromMillisecondsSinceEpoch(0).toLocal());
    });

    test('no revienta con checkInTime ausente', () {
      final model = AttendanceModel.fromJson({
        ...baseJson(),
      }..remove('checkInTime'));
      expect(model, isNotNull);
    });

    test('no revienta con checkInTime en formato inválido', () {
      final model = AttendanceModel.fromJson({
        ...baseJson(),
        'checkInTime': 'esto-no-es-una-fecha',
      });
      expect(model, isNotNull);
    });

    test('no revienta con status null', () {
      final model = AttendanceModel.fromJson({
        ...baseJson(),
        'status': null,
      });
      expect(model, isNotNull);
      expect(model.status, AttendanceStatus.active);
    });

    test('no revienta con status ausente', () {
      final model = AttendanceModel.fromJson({
        ...baseJson(),
      }..remove('status'));
      expect(model, isNotNull);
      expect(model.status, AttendanceStatus.active);
    });

    test('no revienta con status inválido y degrada a active', () {
      final model = AttendanceModel.fromJson({
        ...baseJson(),
        'status': 'invalido',
      });
      expect(model, isNotNull);
      expect(model.status, AttendanceStatus.active);
    });

    test('no revienta con userId o date null', () {
      final model = AttendanceModel.fromJson({
        ...baseJson(),
        'userId': null,
        'date': null,
      });
      expect(model, isNotNull);
      expect(model.userId, '');
      expect(model.date, '');
    });

    test('checkOutTime null no revienta (jornada abierta)', () {
      final model = AttendanceModel.fromJson({
        ...baseJson(),
        'checkOutTime': null,
      });
      expect(model, isNotNull);
      expect(model.checkOutTime, isNull);
    });
  });
}