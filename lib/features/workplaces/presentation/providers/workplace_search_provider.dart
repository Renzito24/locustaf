import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/workplace_model.dart';
import 'workplace_notifier.dart';

enum WorkplaceStatusFilter { all, active, inactive }

class WorkplaceSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String value) {
    state = value;
  }

  void clear() {
    state = '';
  }
}

final workplaceSearchQueryProvider =
    NotifierProvider<WorkplaceSearchQuery, String>(WorkplaceSearchQuery.new);

class WorkplaceFilterNotifier extends Notifier<WorkplaceStatusFilter> {
  @override
  WorkplaceStatusFilter build() => WorkplaceStatusFilter.all;

  void setFilter(WorkplaceStatusFilter filter) {
    state = filter;
  }
}

final workplaceFilterProvider =
    NotifierProvider<WorkplaceFilterNotifier, WorkplaceStatusFilter>(
        WorkplaceFilterNotifier.new);

final filteredWorkplacesProvider =
    Provider<AsyncValue<List<WorkplaceModel>>>((ref) {
  final workplacesAsync = ref.watch(workplacesStreamProvider);
  final searchQuery = ref.watch(workplaceSearchQueryProvider).trim().toLowerCase();
  final statusFilter = ref.watch(workplaceFilterProvider);

  return workplacesAsync.whenData((workplaces) {
    var result = workplaces.toList();

    if (searchQuery.isNotEmpty) {
      result = result.where((w) {
        return w.nombre.toLowerCase().contains(searchQuery) ||
            (w.direccion?.toLowerCase().contains(searchQuery) ?? false) ||
            (w.description?.toLowerCase().contains(searchQuery) ?? false);
      }).toList();
    }

    switch (statusFilter) {
      case WorkplaceStatusFilter.active:
        result = result.where((w) => w.isActive).toList();
        break;
      case WorkplaceStatusFilter.inactive:
        result = result.where((w) => !w.isActive).toList();
        break;
      case WorkplaceStatusFilter.all:
        break;
    }

    result.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return result;
  });
});
