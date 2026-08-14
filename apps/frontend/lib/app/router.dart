import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_client.dart';
import '../core/supabase/supabase_config.dart';
import '../features/ai/presentation/ai_page.dart';
import '../features/auth/presentation/auth_page.dart';
import '../features/budget/presentation/budget_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/dashboard/presentation/financial_overview_realtime_page.dart';
import '../features/forms/presentation/money_form_page.dart';
import '../features/goals/presentation/goal_detail_page.dart';
import '../features/goals/presentation/goals_page.dart';
import '../features/installment/presentation/installment_page.dart';
import '../features/notifications/presentation/notifications_page.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/onboarding/presentation/splash_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/report/presentation/report_page.dart';
import '../features/transaction/presentation/transaction_page.dart';
import '../features/transfer/presentation/transfer_page.dart';
import '../features/wallet/presentation/wallet_detail_page.dart';
import '../features/wallet/presentation/wallet_page.dart';
import 'app_shell.dart';
import 'auth_route_guard.dart';

final _authRouterRefresh = _AuthRouterRefresh();

final appRouter = GoRouter(
  initialLocation: '/splash',
  refreshListenable: _authRouterRefresh,
  redirect: (context, state) {
    final isAuthenticated = SupabaseConfig.isConfigured &&
        NexoraSupabase.client.auth.currentSession != null;
    return AuthRouteGuard.resolve(isAuthenticated: isAuthenticated, location: state.uri.toString());
  },
  routes: [
    GoRoute(path: '/splash', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: const SplashPage())),
    GoRoute(path: '/onboarding', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: const OnboardingPage())),
    GoRoute(path: '/auth', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: AuthPage(redirect: state.uri.queryParameters['redirect']))),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: const DashboardPage()))]),
        StatefulShellBranch(routes: [GoRoute(path: '/transactions', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: const TransactionPage()))]),
        StatefulShellBranch(routes: [GoRoute(path: '/wallet', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: const WalletPage()))]),
        StatefulShellBranch(routes: [GoRoute(path: '/goals', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: const GoalsPage()))]),
      ],
    ),
    GoRoute(path: '/goals/:goalId', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: GoalDetailPage(goalId: state.pathParameters['goalId']!))),
    GoRoute(path: '/wallet/:walletId', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: WalletDetailPage(walletId: state.pathParameters['walletId']!))),
    GoRoute(path: '/financial-overview', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: const FinancialOverviewRealtimePage())),
    GoRoute(path: '/profile', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: const ProfilePage())),
    GoRoute(path: '/ai', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: const AIPage())),
    GoRoute(path: '/add-income', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: const MoneyFormPage(income: true))),
    GoRoute(path: '/add-expense', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: const MoneyFormPage(income: false))),
    GoRoute(path: '/transfer', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: const TransferPage())),
    GoRoute(path: '/budget', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: const BudgetPage())),
    GoRoute(path: '/installments', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: const InstallmentPage())),
    GoRoute(path: '/reports', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: const ReportPage())),
    GoRoute(path: '/notifications', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: const NotificationsPage())),
  ],
  errorBuilder: (context, state) => Scaffold(body: Center(child: Text('404\n${state.uri}', textAlign: TextAlign.center))),
);

class _AuthRouterRefresh extends ChangeNotifier {
  StreamSubscription<AuthState>? _subscription;
  _AuthRouterRefresh() {
    if (!SupabaseConfig.isConfigured) return;
    _subscription = NexoraSupabase.client.auth.onAuthStateChange.listen((_) => notifyListeners(), onError: (Object error, StackTrace stack) => debugPrint('Supabase auth state error: $error'));
  }
  @override
  void dispose() { _subscription?.cancel(); super.dispose(); }
}

CustomTransitionPage<void> _buildTransitionPage({required GoRouterState state, required Widget child}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 360),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return FadeTransition(opacity: curved, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0.04, .03), end: Offset.zero).animate(curved), child: child));
    },
  );
}
