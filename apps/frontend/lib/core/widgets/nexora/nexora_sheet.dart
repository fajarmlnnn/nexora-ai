import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class NexoraSheet extends StatelessWidget {
  const NexoraSheet({super.key, required this.title, required this.child, this.overline, this.actions, this.controller});

  final String title;
  final String? overline;
  final Widget child;
  final Widget? actions;
  final ScrollController? controller;

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? overline,
    required Widget child,
    Widget? actions,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .55),
      builder: (context) => NexoraSheet(title: title, overline: overline, child: child, actions: actions),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: title,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.canvasElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.borderGlass)),
          boxShadow: AppShadows.modal,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
            child: SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenGutter, 12, AppSpacing.screenGutter, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: Semantics(label: 'Geser untuk menutup', child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: AppRadius.radiusPill)))),
                  const SizedBox(height: 20),
                  if (overline != null) Text(overline!, style: AppTypography.overline),
                  if (overline != null) const SizedBox(height: 6),
                  Text(title, style: AppTypography.heading2),
                  const SizedBox(height: 20),
                  child,
                  if (actions != null) ...[const SizedBox(height: 16), actions!],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Duration get animationDuration => AppMotion.slow;
}
