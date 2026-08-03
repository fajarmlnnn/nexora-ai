import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/transaction/presentation/transaction_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',

  routes: [
    GoRoute(path: '/', builder: (context, state) => const DashboardPage()),

    GoRoute(
      path: '/transactions',
      builder: (context, state) => const TransactionPage(),
    ),

    GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
  ],

  errorBuilder: (context, state) {
    return Scaffold(
      body: Center(
        child: Text('404\n${state.uri}', textAlign: TextAlign.center),
      ),
    );
  },
);
