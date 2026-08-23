import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/nexora/nexora_nav.dart';

/// Product shell for the four locked financial branches.
/// Navigation architecture stays in router.dart; this widget only renders UI.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0);
        }
      },
      child: Scaffold(
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: NexoraNav(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) {
            navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
          },
          onAdd: () => _showCreateSheet(context),
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .55),
      isScrollControlled: true,
      builder: (_) => NexoraCreateSheet(parentContext: context),
    );
  }
}
