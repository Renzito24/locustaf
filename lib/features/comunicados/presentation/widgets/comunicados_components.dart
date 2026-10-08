import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/pdf_viewer_dialog.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../employees/presentation/providers/users_provider.dart';
import '../../domain/models/comunicado_model.dart';
import '../providers/comunicados_provider.dart';

class ComunicadosList extends ConsumerWidget {
  final List<ComunicadoModel> comunicados;
  final bool isAdmin;

  const ComunicadosList({
    super.key,
    required this.comunicados,
    required this.isAdmin,
  });

  void _markAsRead(WidgetRef ref, ComunicadoModel com) {
    if (!isAdmin) {
      final readIds = ref.read(comunicadosReadIdsProvider).value ?? [];
      if (!readIds.contains(com.id)) {
        ref.read(comunicadoActionProvider.notifier).markAsRead(com.id);
      }
    }
  }

  void _openComunicado(BuildContext context, WidgetRef ref, ComunicadoModel com) {
    if (com.storagePath != null) {
      // Comunicado con PDF → visor compartido
      showDialog(
        context: context,
        builder: (_) => PdfViewerDialog(
          storagePath: com.storagePath!,
          downloadFileName: com.fileName ?? '${com.title}.pdf',
          title: com.title,
          onPdfLoaded: () => _markAsRead(ref, com),
        ),
      );
    } else {
      // Comunicado legacy de texto → diálogo existente
      showDialog(
        context: context,
        builder: (_) => ComunicadoDetailDialog(
          comunicado: com,
          isAdmin: isAdmin,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (comunicados.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No hay comunicados registrados',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final currentUser = ref.watch(currentUserModelProvider);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comunicados.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final com = comunicados[index];
        final readIdsAsync = ref.watch(comunicadosReadIdsProvider);
        final isRead = currentUser != null && (readIdsAsync.value?.contains(com.id) ?? false);
        final showReadState = !isAdmin;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          // ── ícono de sobre ───────────────────────────────────────
          leading: showReadState
              ? Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      isRead ? LucideIcons.mailOpen : LucideIcons.mail,
                      size: 28,
                      color: isRead ? AppColors.textMuted : AppColors.gold,
                    ),
                    if (isRead)
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.checkCircle2, size: 14, color: AppColors.success),
                        ),
                      ),
                  ],
                )
              : const Icon(LucideIcons.megaphone, size: 24, color: AppColors.textSecondary),
          // ── título y fecha ────────────────────────────────────
          tileColor: (showReadState && !isRead)
              ? AppColors.gold.withValues(alpha: 0.05)
              : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text(
            com.title,
            style: TextStyle(
              fontWeight: (showReadState && !isRead) ? FontWeight.w700 : FontWeight.normal,
              color: (showReadState && !isRead) ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          subtitle: Text(
            DateFormat('dd/MM/yyyy HH:mm').format(com.createdAt),
            style: const TextStyle(fontSize: 12),
          ),
          trailing: const Icon(LucideIcons.chevronRight, color: AppColors.textMuted),
          onTap: () => _openComunicado(context, ref, com),
        );
      },
    );
  }
}

class ComunicadoDetailDialog extends ConsumerStatefulWidget {
  final ComunicadoModel comunicado;
  final bool isAdmin;

  const ComunicadoDetailDialog({
    super.key,
    required this.comunicado,
    required this.isAdmin,
  });

  @override
  ConsumerState<ComunicadoDetailDialog> createState() => _ComunicadoDetailDialogState();
}

class _ComunicadoDetailDialogState extends ConsumerState<ComunicadoDetailDialog> {
  @override
  void initState() {
    super.initState();
    // Mark as read if not admin and not already read
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.isAdmin) {
        final readIds = ref.read(comunicadosReadIdsProvider).value ?? [];
        if (!readIds.contains(widget.comunicado.id)) {
          ref.read(comunicadoActionProvider.notifier).markAsRead(widget.comunicado.id);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.comunicado.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(widget.comunicado.createdAt),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  widget.comunicado.content ?? '',
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            ),
            if (widget.isAdmin) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Visto por:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _ReadByList(comunicadoId: widget.comunicado.id),
            ],
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadByList extends ConsumerWidget {
  final String comunicadoId;

  const _ReadByList({required this.comunicadoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readersAsync = ref.watch(comunicadoReadersProvider(comunicadoId));

    return readersAsync.when(
      data: (readByIds) {
        if (readByIds.isEmpty) {
          return const Text('Nadie ha visto este comunicado aún.', style: TextStyle(color: AppColors.textSecondary));
        }

        final usersAsync = ref.watch(usersStreamProvider);

        return usersAsync.when(
          data: (users) {
            final readUsers = users.where((u) => readByIds.contains(u.id)).toList();
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: readUsers.map((u) {
                return Chip(
                  label: Text('${u.nombre} ${u.apellido}'),
                  backgroundColor: AppColors.gold.withValues(alpha: 0.1),
                  labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                );
              }).toList(),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, st) => const Text('Error al cargar usuarios'),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, st) => const Text('Error al cargar lecturas'),
    );
  }
}
