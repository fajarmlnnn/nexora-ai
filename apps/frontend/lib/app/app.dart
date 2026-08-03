import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/dashboard/presentation/dashboard_page.dart';

class NexoraApp extends StatelessWidget {
  const NexoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nexora AI',
      theme: AppTheme.dark,
      home: const DashboardPage(),
    );
  }
}
