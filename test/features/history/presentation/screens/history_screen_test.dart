import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_locustaf/features/history/presentation/screens/history_screen.dart';
import 'package:app_locustaf/features/history/data/models/history_record_model.dart';
import 'package:app_locustaf/features/history/presentation/providers/history_provider.dart';
import 'package:app_locustaf/features/attendance/data/models/attendance_model.dart';

class MockHistoryPaginationNotifier extends HistoryPaginationNotifier {
  @override
  Future<HistoryPageState> build() async {
    return const HistoryPageState(hasMore: false);
  }
}

void main() {
  group('HistoryScreen Tests', () {
    testWidgets('renders properly with records', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      final records = [
        HistoryRecordModel(
          id: '1',
          employeeName: 'John Doe',
          employeeEmail: 'john@example.com',
          date: '2026-10-02',
          checkInTime: DateTime(2026, 10, 2, 8, 0),
          checkOutTime: DateTime(2026, 10, 2, 17, 0),
          durationMinutes: 540,
          status: AttendanceStatus.completed,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            filteredHistoryProvider.overrideWith((ref) => records),
            attendanceTotalCountProvider.overrideWith((ref) => Future.value(1)),
            activeRecordsProvider.overrideWith((ref) => 0),
            completedRecordsProvider.overrideWith((ref) => 1),
            historyPaginationProvider.overrideWith(MockHistoryPaginationNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: HistoryScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Historial de Asistencias'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Total registros'), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('renders properly with no records', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            filteredHistoryProvider.overrideWith((ref) => []),
            attendanceTotalCountProvider.overrideWith((ref) => Future.value(0)),
            activeRecordsProvider.overrideWith((ref) => 0),
            completedRecordsProvider.overrideWith((ref) => 0),
            historyPaginationProvider.overrideWith(MockHistoryPaginationNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: HistoryScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Historial de Asistencias'), findsOneWidget);
      expect(find.text('Sin registros de asistencia'), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });
  });
}
