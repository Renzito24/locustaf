import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
              color: AppColors.cardDark,
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
                      sinRecibo: filterState.sinRecibo,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _summaryCard('Sin recibo', sinRecibo, Colors.grey.shade400, LucideIcons.fileX),
          _summaryCard('Pendientes', pendientes, AppColors.warning, LucideIcons.clock),
          _summaryCard('Aceptados', aceptados, AppColors.success, LucideIcons.circleCheck),
          _summaryCard('Rechazados', rechazados, AppColors.error, LucideIcons.circleX),
        ];
        if (constraints.maxWidth >= 460) {
          return Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 10),
              Expanded(child: cards[1]),
              const SizedBox(width: 10),
              Expanded(child: cards[2]),
              const SizedBox(width: 10),
              Expanded(child: cards[3]),
            ],
          );
        }
        return Column(
          children: [
            Row(children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 10),
              Expanded(child: cards[1]),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 10),
              Expanded(child: cards[3]),
            ]),
          ],
        );
      },
    );
  }

  Widget _summaryCard(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgDarkTop,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
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
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.gold),
    );
    final baseDecoration = InputDecoration(
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.bgDarkTop,
      enabledBorder: border,
      focusedBorder: focusedBorder,
      border: border,
    );

    final searchField = TextFormField(
      initialValue: filterState.searchQuery,
      decoration: baseDecoration.copyWith(
        hintText: 'Buscar empleado...',
        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
      ),
      style: const TextStyle(color: AppColors.textWhite),
      onChanged: (val) => ref.read(paystubsFilterProvider.notifier).setSearchQuery(val),
    );

    final monthField = DropdownButtonFormField<String>(
      initialValue: filterState.periodo,
      isExpanded: true,
      decoration: baseDecoration.copyWith(labelText: 'Mes / Año'),
      dropdownColor: AppColors.cardDark,
      style: const TextStyle(color: AppColors.textWhite),
      iconEnabledColor: AppColors.textMuted,
      items: _generateMonths().map((p) => DropdownMenuItem(
        value: p,
        child: Text(p, style: const TextStyle(color: AppColors.textWhite)),
      )).toList(),
      onChanged: (val) => ref.read(paystubsFilterProvider.notifier).setPeriodo(val),
    );

    final stateField = DropdownButtonFormField<String>(
      initialValue: filterState.sinRecibo ? 'sin_recibo' : filterState.state?.name,
      isExpanded: true,
      decoration: baseDecoration.copyWith(labelText: 'Estado'),
      dropdownColor: AppColors.cardDark,
      style: const TextStyle(color: AppColors.textWhite),
      iconEnabledColor: AppColors.textMuted,
      items: const [
        DropdownMenuItem(value: null, child: Text('Todos', style: TextStyle(color: AppColors.textWhite))),
        DropdownMenuItem(value: 'sin_recibo', child: Text('Sin recibo', style: TextStyle(color: AppColors.textWhite))),
        DropdownMenuItem(value: 'pendiente', child: Text('Pendiente', style: TextStyle(color: AppColors.textWhite))),
        DropdownMenuItem(value: 'aceptado', child: Text('Aceptado', style: TextStyle(color: AppColors.textWhite))),
        DropdownMenuItem(value: 'rechazado', child: Text('Rechazado', style: TextStyle(color: AppColors.textWhite))),
      ],
      onChanged: (val) {
        final notifier = ref.read(paystubsFilterProvider.notifier);
        if (val == 'sin_recibo') {
          notifier.setSinRecibo(true);
        } else if (val == null) {
          notifier.setState(null);
        } else {
          notifier.setState(PaystubEstado.values.firstWhere((e) => e.name == val));
        }
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 560) {
          return Row(
            children: [
              Expanded(flex: 2, child: searchField),
              const SizedBox(width: 12),
              Expanded(child: monthField),
              const SizedBox(width: 12),
              Expanded(child: stateField),
            ],
          );
        }
        return Column(
          children: [
            searchField,
            const SizedBox(height: 12),
            monthField,
            const SizedBox(height: 12),
            stateField,
          ],
        );
      },
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
