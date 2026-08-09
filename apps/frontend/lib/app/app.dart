import 'package:flutter/material.dart';

import '../core/widgets/nexora_mascot_overlay.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class NexoraApp extends StatelessWidget {
  const NexoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Nexora AI',
      theme: AppTheme.dark,
      routerConfig: appRouter,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            child ?? const SizedBox.shrink(),
            const Positioned(
              right: 12,
              bottom: 96,
              child: NexoraMascotOverlay(),
            ),
          ],
        );
      },
    );
  }
}
