import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/nexora/nexora_nav.dart';
import '../features/goals/presentation/add_goal_sheet.dart';
import '../features/wallet/presentation/add_wallet_sheet.dart';

/// Product shell for the four locked financial branches.
/// Navigation architecture stays in router.dart; this widget only renders UI.
class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0);
        }
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: AppColors.canvas,
        body: navigationShell,
        bottomNavigationBar: NexoraNav(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) {
            navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
          },
          onAdd: () => _showCreateSheet(context, ref),
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.scrim,
      isScrollControlled: true,
      builder: (sheetContext) => NexoraCreateSheet(
        onAddIncome: () {
          Navigator.pop(sheetContext);
          context.push('/add-income');
        },
        onAddExpense: () {
          Navigator.pop(sheetContext);
          context.push('/add-expense');
        },
        onAddWallet: () {
          Navigator.pop(sheetContext);
          showAddWalletSheet(context, ref);
        },
        onAddGoal: () {
          Navigator.pop(sheetContext);
          showAddGoalSheet(context, ref);
        },
        onAskAi: () {
          Navigator.pop(sheetContext);
          context.push('/ai');
        },
      ),
    );
  }
}
