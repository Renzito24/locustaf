import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/services/logging_service.dart';
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
      // Marcar como leído al abrir, sin depender de que el PDF cargue bien
      // (si falla la lectura de bytes por CORS, igual queda registrada la lectura).
      _markAsRead(ref, com);
      // Comunicado con PDF → visor compartido
      showDialog(
        context: context,
        builder: (_) => PdfViewerDialog(
          storagePath: com.storagePath!,
          downloadFileName: com.fileName ?? '${com.title}.pdf',
          title: com.title,
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgDarkTop,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
                ),
                child: const Icon(LucideIcons.inbox, size: 40, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              const Text(
                'No hay comunicados registrados',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Los avisos y notificaciones de la empresa aparecerán aquí.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final currentUser = ref.watch(currentUserModelProvider);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comunicados.length,
      separatorBuilder: (_, i) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final com = comunicados[index];
        final readIdsAsync = ref.watch(comunicadosReadIdsProvider);
        final isRead = currentUser != null && (readIdsAsync.value?.contains(com.id) ?? false);
        final showReadState = !isAdmin;

        final isPdf = com.storagePath != null;

        return Material(
          color: AppColors.bgDarkTop,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: (showReadState && !isRead)
                  ? AppColors.gold.withValues(alpha: 0.5)
                  : AppColors.textSecondary.withValues(alpha: 0.2),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (showReadState && !isRead)
                    ? AppColors.gold.withValues(alpha: 0.15)
                    : isPdf
                        ? AppColors.info.withValues(alpha: 0.15)
                        : AppColors.cardDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (showReadState && !isRead)
                      ? AppColors.gold.withValues(alpha: 0.4)
                      : isPdf
                          ? AppColors.info.withValues(alpha: 0.3)
                          : AppColors.textSecondary.withValues(alpha: 0.2),
                ),
              ),
              child: Center(
                child: showReadState
                    ? Icon(
                        isRead ? LucideIcons.mailOpen : LucideIcons.mail,
                        size: 20,
                        color: isRead ? AppColors.textMuted : AppColors.gold,
                      )
                    : Icon(
                        isPdf ? LucideIcons.fileText : LucideIcons.megaphone,
                        size: 20,
                        color: isPdf ? AppColors.info : AppColors.gold,
                      ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    com.title,
                    style: TextStyle(
                      fontWeight: (showReadState && !isRead) ? FontWeight.bold : FontWeight.w600,
                      color: AppColors.textWhite,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (showReadState && !isRead) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                    ),
                    child: const Text(
                      'NUEVO',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  Icon(LucideIcons.calendar, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(com.createdAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAdmin)
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, color: AppColors.error, size: 18),
                    tooltip: 'Eliminar comunicado',
                    onPressed: () => _confirmDelete(context, ref, com),
                  ),
                const Icon(LucideIcons.chevronRight, color: AppColors.textSecondary, size: 20),
              ],
            ),
            onTap: () => _openComunicado(context, ref, com),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ComunicadoModel com) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar comunicado', style: TextStyle(color: AppColors.textWhite)),
        content: Text(
          '¿Estás seguro de que deseás eliminar "${com.title}"? Esta acción no se puede deshacer.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(comunicadoRepositoryProvider).deleteComunicado(com.id);
                // Borrar también el PDF de Storage para no dejar huérfanos.
                final pathToDelete = com.storagePath;
                if (pathToDelete != null && pathToDelete.isNotEmpty) {
                  try {
                    await ref.read(storageServiceProvider).deleteFile(pathToDelete);
                  } catch (e) {
                    LoggingService.instance.error(
                      'No se pudo borrar el PDF del comunicado',
                      error: e,
                    );
                  }
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Comunicado eliminado')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ErrorHandler.parse(e).message)),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
      backgroundColor: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.2)),
      ),
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(28),
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
                          color: AppColors.textWhite,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x, color: AppColors.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(LucideIcons.calendar, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(widget.comunicado.createdAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: AppColors.textSecondary.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  widget.comunicado.content ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: AppColors.textWhite,
                  ),
                ),
              ),
            ),
            if (widget.isAdmin) ...[
              const SizedBox(height: 20),
              Divider(color: AppColors.textSecondary.withValues(alpha: 0.2)),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(LucideIcons.eye, size: 16, color: AppColors.gold),
                          SizedBox(width: 8),
                          Text(
                            'Leído por:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textWhite,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _ReadByList(comunicadoId: widget.comunicado.id),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.bgDarkTop,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
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
          return const Text(
            'Nadie ha visto este comunicado aún.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          );
        }

        final usersAsync = ref.watch(usersStreamProvider);

        return usersAsync.when(
          data: (users) {
            final readUsers = users.where((u) => readByIds.contains(u.id)).toList();
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: readUsers.map((u) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.bgDarkTop,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.check, size: 12, color: AppColors.success),
                      const SizedBox(width: 6),
                      Text(
                        '${u.nombre} ${u.apellido}',
                        style: const TextStyle(color: AppColors.textWhite, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
          ),
          error: (e, st) => const Text('Error al cargar usuarios', style: TextStyle(color: AppColors.error)),
        );
      },
      loading: () => const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
      ),
      error: (e, st) => const Text('Error al cargar lecturas', style: TextStyle(color: AppColors.error)),
    );
  }
}
