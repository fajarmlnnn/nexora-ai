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
            if (child != null) child,
            const Positioned(
              right: 10,
              bottom: 88,
              child: NexoraMascotOverlay(),
            ),
          ],
        );
      },
    );
  }
}
