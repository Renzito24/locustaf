import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/history_provider.dart';
import '../../data/models/history_record_model.dart';
import '../widgets/history_filter_bar.dart';
import 'history_components.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(filteredHistoryProvider);
    final total = ref.watch(attendanceTotalCountProvider).value ?? 0;
    final active = ref.watch(activeRecordsProvider);
    final completed = ref.watch(completedRecordsProvider);
    final pageState = ref.watch(historyPaginationProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Historial de Asistencias', style: AppTheme.headingLg),
          const SizedBox(height: 4),
          Text(
            'Consulta todas las jornadas registradas en el sistema.',
            style: AppTheme.bodyLg,
          ),
          const SizedBox(height: 24),
          _buildIndicatorCards(total, active, completed),
          const SizedBox(height: 24),
          const HistoryFilterBar(),
          const SizedBox(height: 20),
          _buildContent(context, records, pageState),
        ],
      ),
    );
  }

  Widget _buildIndicatorCards(int total, int active, int completed) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 700 ? 3 : 1;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.2,
          children: [
            IndicatorCard(
              icon: Icons.list_alt,
              label: 'Total registros',
              value: total.toString(),
              color: AppColors.gold,
            ),
            IndicatorCard(
              icon: Icons.play_circle,
              label: 'Jornadas activas',
              value: active.toString(),
              color: AppColors.success,
            ),
            IndicatorCard(
              icon: Icons.check_circle,
              label: 'Jornadas finalizadas',
              value: completed.toString(),
              color: AppColors.textMuted,
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<HistoryRecordModel> records,
    AsyncValue<HistoryPageState> pageState,
  ) {
    final isLoading = pageState.isLoading;
    final hasMore = pageState.value?.hasMore ?? false;
    final isLoadingMore = pageState.isLoading && records.isNotEmpty;

    if (isLoading && records.isEmpty) {
      return AppTheme.loadingState(message: 'Cargando historial...');
    }

    if (pageState.hasError && records.isEmpty) {
      return AppTheme.errorState('Error al cargar el historial: ${pageState.error}');
    }

    return _buildPageContent(
      context,
      records,
      hasMore: hasMore,
      isLoadingMore: isLoadingMore,
    );
  }

  Widget _buildPageContent(
    BuildContext context,
    List<HistoryRecordModel> records, {
    required bool hasMore,
    required bool isLoadingMore,
  }) {
    if (records.isEmpty) {
      final loadMoreButton = LoadMoreButton(
        hasMore: hasMore,
        isLoadingMore: isLoadingMore,
      );
      if (!hasMore) {
        return AppTheme.emptyState(
          icon: Icons.history,
          title: 'Sin registros de asistencia',
          subtitle: 'No hay asistencias para los filtros seleccionados.',
        );
      }
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Sin coincidencias en las páginas cargadas.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            loadMoreButton,
          ],
        ),
      );
    }

    final loadMoreButton = LoadMoreButton(
      hasMore: hasMore,
      isLoadingMore: isLoadingMore,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return HistoryListMobile(
            records: records,
            hasMore: hasMore,
            loadMoreButton: loadMoreButton,
          );
        }

        return HistoryDataTable(
          records: records,
          hasMore: hasMore,
          loadMoreButton: loadMoreButton,
        );
      },
    );
  }
}
