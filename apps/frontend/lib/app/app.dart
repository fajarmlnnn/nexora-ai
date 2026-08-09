import 'package:flutter/material.dart';

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
    );
  }
}
