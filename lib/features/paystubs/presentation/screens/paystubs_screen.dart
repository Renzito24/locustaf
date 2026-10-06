import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../employees/presentation/providers/users_provider.dart';
import '../providers/paystubs_provider.dart';
import '../widgets/paystubs_components.dart';

class PaystubsScreen extends ConsumerWidget {
  const PaystubsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paystubs = ref.watch(filteredPaystubsProvider);
    final usersAsync = ref.watch(usersStreamProvider);
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
              child: PaystubsList(
                paystubs: paystubs,
                usersAsync: usersAsync,
                isAdmin: isAdmin,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
