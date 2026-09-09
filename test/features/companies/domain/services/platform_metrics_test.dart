import 'package:flutter_test/flutter_test.dart';
import 'package:app_locustaf/core/models/company_model.dart';
import 'package:app_locustaf/features/companies/domain/services/platform_metrics.dart';

void main() {
  group('PlatformMetrics', () {
    test('empresa sin paidUntil y activa → enPrueba', () {
      final now = DateTime(2026, 9, 8, 12);
      final companies = [
        CompanyModel(
          id: '1',
          nombreComercial: 'A',
          razonSocial: '',
          cuit: '20-12345678-0',
          createdAt: now,
          estado: CompanyEstado.activa,
        ),
      ];
      final m = computePlatformMetrics(companies, now);
      expect(m.total, 1);
      expect(m.activas, 1);
      expect(m.suspendidas, 0);
      expect(m.enPrueba, 1);
      expect(m.porVencer, 0);
    });

    test('empresa con paidUntil futuro lejano → activa, no por vencer', () {
      final now = DateTime(2026, 9, 8, 12);
      final companies = [
        CompanyModel(
          id: '1',
          nombreComercial: 'A',
          razonSocial: '',
          cuit: '20-12345678-0',
          createdAt: now,
          estado: CompanyEstado.activa,
          paidUntil: now.add(const Duration(days: 30)),
        ),
      ];
      final m = computePlatformMetrics(companies, now);
      expect(m.activas, 1);
      expect(m.porVencer, 0);
      expect(m.enPrueba, 0);
    });

    test('empresa con paidUntil vence en 3 días → porVencer', () {
      final now = DateTime(2026, 9, 8, 12);
      final companies = [
        CompanyModel(
          id: '1',
          nombreComercial: 'A',
          razonSocial: '',
          cuit: '20-12345678-0',
          createdAt: now,
          estado: CompanyEstado.activa,
          paidUntil: now.add(const Duration(days: 3)),
        ),
      ];
      final m = computePlatformMetrics(companies, now);
      expect(m.porVencer, 1);
      expect(m.activas, 1);
    });

    test('empresa con paidUntil vencida (ayer) → suspendida', () {
      final now = DateTime(2026, 9, 8, 12);
      final companies = [
        CompanyModel(
          id: '1',
          nombreComercial: 'A',
          razonSocial: '',
          cuit: '20-12345678-0',
          createdAt: now,
          estado: CompanyEstado.activa,
          paidUntil: now.subtract(const Duration(days: 1)),
        ),
      ];
      final m = computePlatformMetrics(companies, now);
      expect(m.activas, 0);
      expect(m.suspendidas, 1);
    });

    test('empresa inactiva aunque paidUntil futuro → suspendida', () {
      final now = DateTime(2026, 9, 8, 12);
      final companies = [
        CompanyModel(
          id: '1',
          nombreComercial: 'A',
          razonSocial: '',
          cuit: '20-12345678-0',
          createdAt: now,
          estado: CompanyEstado.inactiva,
          paidUntil: now.add(const Duration(days: 30)),
        ),
      ];
      final m = computePlatformMetrics(companies, now);
      expect(m.suspendidas, 1);
      expect(m.activas, 0);
    });

    test('empresa con paidUntil exactamente hoy (no isAfter) → suspendida', () {
      final now = DateTime(2026, 9, 8, 12);
      final paidUntil = DateTime(2026, 9, 8, 12);
      final companies = [
        CompanyModel(
          id: '1',
          nombreComercial: 'A',
          razonSocial: '',
          cuit: '20-12345678-0',
          createdAt: now,
          estado: CompanyEstado.activa,
          paidUntil: paidUntil,
        ),
      ];
      final m = computePlatformMetrics(companies, now);
      expect(m.activas, 0);
      expect(m.suspendidas, 1);
    });

    test('empresa con paidUntil vence en 7 días exacto → porVencer', () {
      final now = DateTime(2026, 9, 8, 12);
      final companies = [
        CompanyModel(
          id: '1',
          nombreComercial: 'A',
          razonSocial: '',
          cuit: '20-12345678-0',
          createdAt: now,
          estado: CompanyEstado.activa,
          paidUntil: now.add(const Duration(days: 7)),
        ),
      ];
      final m = computePlatformMetrics(companies, now);
      expect(m.porVencer, 1);
      expect(m.activas, 1);
    });

    test('empresa con paidUntil vence en 8 días → NO por vencer', () {
      final now = DateTime(2026, 9, 8, 12);
      final companies = [
        CompanyModel(
          id: '1',
          nombreComercial: 'A',
          razonSocial: '',
          cuit: '20-12345678-0',
          createdAt: now,
          estado: CompanyEstado.activa,
          paidUntil: now.add(const Duration(days: 8)),
        ),
      ];
      final m = computePlatformMetrics(companies, now);
      expect(m.porVencer, 0);
      expect(m.activas, 1);
    });

    test('lista vacía → métricas en ceros', () {
      final m = computePlatformMetrics([], DateTime.now());
      expect(m.total, 0);
      expect(m.activas, 0);
      expect(m.suspendidas, 0);
      expect(m.porVencer, 0);
      expect(m.enPrueba, 0);
    });

    test('empresa paidUntil justo 1 día más que ahora → porVencer (y activa)', () {
      final now = DateTime(2026, 9, 8, 12);
      final companies = [
        CompanyModel(
          id: '1',
          nombreComercial: 'A',
          razonSocial: '',
          cuit: '20-12345678-0',
          createdAt: now,
          estado: CompanyEstado.activa,
          paidUntil: now.add(const Duration(days: 1)),
        ),
      ];
      final m = computePlatformMetrics(companies, now);
      expect(m.porVencer, 1);
      expect(m.activas, 1);
    });

    test('empresa con paidUntil en el límite exacto de 7 días y 1 segundo → no porVencer (7 días completos con hora de diferencia)', () {
      final now = DateTime(2026, 9, 8, 12);
      // 7 días y 1 hora → inDays = 7 → <= 7 → porVencer
      final companies = [
        CompanyModel(
          id: '1',
          nombreComercial: 'A',
          razonSocial: '',
          cuit: '20-12345678-0',
          createdAt: now,
          estado: CompanyEstado.activa,
          paidUntil: now.add(const Duration(days: 7, hours: 1)),
        ),
      ];
      final m = computePlatformMetrics(companies, now);
      expect(m.porVencer, 1);
    });

    test('empresa paidUntil 6 días 23 horas → inDays=6 ≤7 → porVencer', () {
      final now = DateTime(2026, 9, 8, 12);
      final companies = [
        CompanyModel(
          id: '1',
          nombreComercial: 'A',
          razonSocial: '',
          cuit: '20-12345678-0',
          createdAt: now,
          estado: CompanyEstado.activa,
          paidUntil: now.add(const Duration(days: 6, hours: 23)),
        ),
      ];
      final m = computePlatformMetrics(companies, now);
      expect(m.porVencer, 1);
    });

    test('empresa paidUntil justo ahora + 7 días exactos con horas iguales → inDays=7 → porVencer', () {
      final now = DateTime(2026, 9, 8, 12);
      final companies = [
        CompanyModel(
          id: '1',
          nombreComercial: 'A',
          razonSocial: '',
          cuit: '20-12345678-0',
          createdAt: now,
          estado: CompanyEstado.activa,
          paidUntil: now.add(const Duration(days: 7)),
        ),
      ];
      final m = computePlatformMetrics(companies, now);
      expect(m.porVencer, 1);
    });
  });
}