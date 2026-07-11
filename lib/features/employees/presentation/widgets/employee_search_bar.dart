import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/users_provider.dart';

class EmployeeSearchBar extends ConsumerStatefulWidget {
  const EmployeeSearchBar({super.key});

  @override
  ConsumerState<EmployeeSearchBar> createState() =>
      _EmployeeSearchBarState();
}

class _EmployeeSearchBarState extends ConsumerState<EmployeeSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(employeeSearchQueryProvider);
    _controller = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(employeeSearchQueryProvider, (previous, next) {
      if (next != _controller.text) {
        _controller.text = next;
      }
    });

    return TextField(
      controller: _controller,
      onChanged: (value) {
        ref
            .read(employeeSearchQueryProvider.notifier)
            .updateQuery(value);
      },
      style: const TextStyle(
        color: AppColors.textWhite,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: 'Buscar por nombre, apellido, DNI o email...',
        hintStyle: TextStyle(
          color: AppColors.textMuted.withValues(alpha: 0.6),
          fontSize: 14,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: AppColors.gold.withValues(alpha: 0.85),
          size: 20,
        ),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  Icons.clear,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onPressed: () {
                  _controller.clear();
                  ref
                      .read(employeeSearchQueryProvider.notifier)
                      .clear();
                },
              )
            : null,
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.25),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: const BorderSide(
            color: AppColors.gold,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}
