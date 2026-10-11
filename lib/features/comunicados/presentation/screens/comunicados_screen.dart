import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_routes.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../providers/comunicados_provider.dart';
import '../widgets/comunicados_components.dart';

class ComunicadosScreen extends ConsumerWidget {
  const ComunicadosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comunicadosAsync = ref.watch(comunicadosForUserProvider);
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDarkTop,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 600;

                      final headerInfo = Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(LucideIcons.megaphone, color: AppColors.gold, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Comunicados',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textWhite,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isAdmin
                                      ? 'Enviá notificaciones a tus empleados y lugares de trabajo'
                                      : 'Avisos y notificaciones de la empresa',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                  softWrap: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );

                      final actionButton = isAdmin
                          ? ElevatedButton.icon(
                              onPressed: () {
                                context.push(RoutePaths.createComunicado);
                              },
                              icon: const Icon(LucideIcons.plus, size: 18),
                              label: const Text('Nuevo Comunicado'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                backgroundColor: AppColors.gold,
                                foregroundColor: AppColors.bgDarkTop,
                                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            )
                          : null;

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            headerInfo,
                            if (actionButton != null) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: actionButton,
                              ),
                            ],
                          ],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: headerInfo),
                          if (actionButton != null) ...[
                            const SizedBox(width: 16),
                            actionButton,
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
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
                  padding: const EdgeInsets.all(20.0),
                  child: comunicadosAsync.when(
                    data: (comunicados) => ComunicadosList(
                      comunicados: comunicados,
                      isAdmin: isAdmin,
                    ),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(color: AppColors.gold),
                      ),
                    ),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              'Error al cargar comunicados',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.textWhite,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              e.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.error),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref.invalidate(comunicadosForUserProvider),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                foregroundColor: AppColors.bgDarkTop,
                              ),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
