import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_client.dart';
import '../core/supabase/supabase_config.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_gradients.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../features/ai/presentation/ai_page_v2.dart';
import '../features/auth/presentation/auth_page.dart';
import '../features/budget/presentation/budget_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/dashboard/presentation/financial_overview_realtime_page.dart';
import '../features/forms/presentation/money_form_page.dart';
import '../features/goals/presentation/goal_detail_page_v2.dart';
import '../features/goals/presentation/goals_page.dart';
import '../features/installment/presentation/installment_page.dart';
import '../features/notifications/presentation/notifications_page.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/onboarding/presentation/splash_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/report/presentation/report_page.dart';
import '../features/transaction/presentation/transaction_page_v2.dart';
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
    final isAuthenticated = SupabaseConfig.isConfigured && NexoraSupabase.client.auth.currentSession != null;
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
        StatefulShellBranch(routes: [GoRoute(path: '/transactions', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: const TransactionPageV2()))]),
        StatefulShellBranch(routes: [GoRoute(path: '/wallet', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: const WalletPage()))]),
        StatefulShellBranch(routes: [GoRoute(path: '/goals', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: const GoalsPage()))]),
      ],
    ),
    GoRoute(path: '/goals/:goalId', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: GoalDetailPageV2(goalId: state.pathParameters['goalId']!))),
    GoRoute(path: '/wallet/:walletId', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: WalletDetailPage(walletId: state.pathParameters['walletId']!))),
    GoRoute(path: '/financial-overview', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: const FinancialOverviewRealtimePage())),
    GoRoute(path: '/profile', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: const ProfilePage())),
    GoRoute(path: '/ai', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: const AIPageV2())),
    GoRoute(path: '/add-income', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: const MoneyFormPage(income: true))),
    GoRoute(path: '/add-expense', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: const MoneyFormPage(income: false))),
    GoRoute(path: '/transfer', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: const TransferPage())),
    GoRoute(path: '/budget', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: const BudgetPage())),
    GoRoute(path: '/installments', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: const InstallmentPage())),
    GoRoute(path: '/reports', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: const ReportPage())),
    GoRoute(path: '/notifications', pageBuilder: (context, state) => _buildTransitionPage(state: state, child: const NotificationsPage())),
  ],
  errorBuilder: (context, state) => _NexoraErrorPage(uri: state.uri.toString()),
);

class _AuthRouterRefresh extends ChangeNotifier {
  StreamSubscription<AuthState>? _subscription;
  _AuthRouterRefresh() {
    if (!SupabaseConfig.isConfigured) return;
    _subscription = NexoraSupabase.client.auth.onAuthStateChange.listen(
      (_) => notifyListeners(),
      onError: (Object error, StackTrace stack) => debugPrint('Supabase auth state error: $error'),
    );
  }
  @override
  void dispose() { _subscription?.cancel(); super.dispose(); }
}

class _NexoraErrorPage extends StatelessWidget {
  const _NexoraErrorPage({required this.uri});
  final String uri;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.screen,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 88, height: 88, decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppGradients.aiAurora, boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .28), blurRadius: 30)]), child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 38)),
                  const SizedBox(height: 24),
                  Text('Halaman tidak ditemukan', textAlign: TextAlign.center, style: AppTypography.heading1),
                  const SizedBox(height: 10),
                  Text('Nexora tidak menemukan halaman yang kamu cari. Kita bisa kembali ke pusat finansialmu.', textAlign: TextAlign.center, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.5)),
                  const SizedBox(height: 20),
                  Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.card.withValues(alpha: .72), borderRadius: AppRadius.radiusLG, border: Border.all(color: AppColors.border.withValues(alpha: .55)), boxShadow: AppShadows.card), child: Text(uri, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(color: AppColors.textMuted))),
                  const SizedBox(height: 24),
                  SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => context.go('/'), icon: const Icon(LucideIcons.house), label: const Text('Kembali ke Home'), style: FilledButton.styleFrom(padding: const EdgeInsets.all(17), shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXL)))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

CustomTransitionPage<void> _buildTransitionPage({required GoRouterState state, required Widget child}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return FadeTransition(opacity: curved, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0.025, .015), end: Offset.zero).animate(curved), child: child));
    },
  );
}
