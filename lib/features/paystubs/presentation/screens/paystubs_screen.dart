import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';

import '../../../../core/models/user_model.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../employees/presentation/providers/users_provider.dart';
import '../../domain/models/paystub_model.dart';
import '../providers/paystubs_provider.dart';
import '../widgets/paystubs_components.dart';

class PaystubsScreen extends ConsumerWidget {
  const PaystubsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paystubsAsync = ref.watch(paystubsStreamProvider);
    final filteredPaystubsAsync = ref.watch(filteredPaystubsProvider);
    final usersAsync = ref.watch(usersStreamProvider);
    final filterState = ref.watch(paystubsFilterProvider);
    final isAdmin = ref.watch(isAdminProvider);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          sliver: SliverToBoxAdapter(
            child: PaystubsHeader(isAdmin: isAdmin),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          sliver: SliverToBoxAdapter(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: isAdmin
                  ? _buildAdminView(usersAsync, filteredPaystubsAsync, filterState)
                  : _buildEmployeeView(paystubsAsync),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminView(AsyncValue<List<UserModel>> usersAsync, AsyncValue<List<PaystubModel>> paystubsAsync, PaystubsFilterState filterState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminFilters(filterState: filterState),
        const SizedBox(height: 24),
        usersAsync.when(
          data: (users) {
            final activeEmployees = users.where((u) => u.isActive && (u.rol.name == 'employee' || u.rol.name == 'supervisor')).toList();
            
            return paystubsAsync.when(
              data: (paystubs) {
                // DEBUG TEMPORAL: Imprimir valores distintos de periodo
                final currentPeriodo = filterState.periodo ?? '';
                final currentPaystubs = paystubs.where((p) => getNormalizedPeriod(p) == currentPeriodo).toList();
                
                int sinRecibo = 0;
                int pendientes = 0;
                int aceptados = 0;
                int rechazados = 0;

                for (var emp in activeEmployees) {
                  final p = currentPaystubs.where((p) => p.userId == emp.id).firstOrNull;
                  if (p == null) {
                    sinRecibo++;
                  } else if (p.estado == PaystubEstado.pendiente) {
                    pendientes++;
                  } else if (p.estado == PaystubEstado.aceptado) {
                    aceptados++;
                  } else if (p.estado == PaystubEstado.rechazado) {
                    rechazados++;
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryRow(sinRecibo, pendientes, aceptados, rechazados),
                    const SizedBox(height: 16),
                    AdminPaystubsList(
                      users: activeEmployees,
                      paystubs: paystubs,
                      periodo: currentPeriodo,
                      searchQuery: filterState.searchQuery,
                      stateFilter: filterState.state,
                    ),
                  ],
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
              error: (error, stack) => _ErrorWidget(error: error.toString()),
            );
          },
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
          error: (error, stack) => _ErrorWidget(error: error.toString()),
        ),
      ],
    );
  }

  Widget _buildEmployeeView(AsyncValue<List<PaystubModel>> paystubsAsync) {
    return paystubsAsync.when(
      data: (paystubs) => EmployeePaystubsList(paystubs: paystubs),
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      error: (error, stack) => _ErrorWidget(error: error.toString()),
    );
  }

  Widget _buildSummaryRow(int sinRecibo, int pendientes, int aceptados, int rechazados) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _summaryCard('Sin recibo', sinRecibo, Colors.grey),
        _summaryCard('Pendientes', pendientes, AppColors.gold),
        _summaryCard('Aceptados', aceptados, AppColors.success),
        _summaryCard('Rechazados', rechazados, AppColors.error),
      ],
    );
  }

  Widget _summaryCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              count.toString(),
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _AdminFilters extends ConsumerWidget {
  final PaystubsFilterState filterState;

  const _AdminFilters({required this.filterState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextFormField(
            initialValue: filterState.searchQuery,
            decoration: const InputDecoration(
              hintText: 'Buscar empleado...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (val) => ref.read(paystubsFilterProvider.notifier).setSearchQuery(val),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: filterState.periodo,
            decoration: const InputDecoration(
              labelText: 'Mes / Año',
              border: OutlineInputBorder(),
            ),
            items: _generateMonths().map((p) {
              return DropdownMenuItem(
                value: p,
                child: Text(p), // YYYY-MM
              );
            }).toList(),
            onChanged: (val) => ref.read(paystubsFilterProvider.notifier).setPeriodo(val),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: filterState.state?.name,
            decoration: const InputDecoration(
              labelText: 'Estado',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todos')),
              DropdownMenuItem(value: 'sin_recibo', child: Text('Sin recibo')),
              DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
              DropdownMenuItem(value: 'aceptado', child: Text('Aceptado')),
              DropdownMenuItem(value: 'rechazado', child: Text('Rechazado')),
            ],
            onChanged: (val) {
              if (val == null || val == 'sin_recibo') {
                ref.read(paystubsFilterProvider.notifier).setState(null);
                // "Sin recibo" is handled logically in the list if we set an internal state, 
                // but for now we just clear it or handle it in the provider.
                // NOTE: To filter by "sin recibo", we would need to pass this string down to the list view.
                // I will update the state filter to handle it inside the list.
              } else {
                ref.read(paystubsFilterProvider.notifier).setState(
                  PaystubEstado.values.firstWhere((e) => e.name == val)
                );
              }
            },
          ),
        ),
      ],
    );
  }

  List<String> _generateMonths() {
    final List<String> months = [];
    final now = DateTime.now();
    for (int i = 0; i < 120; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      months.add('${date.year}-${date.month.toString().padLeft(2, '0')}');
    }
    return months;
  }
}

class _ErrorWidget extends ConsumerWidget {
  final String error;
  const _ErrorWidget({required this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text('Error al cargar datos', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(error, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(paystubsStreamProvider);
              ref.invalidate(filteredPaystubsProvider);
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
