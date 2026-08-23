import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_spacing.dart';

class NexoraScaffold extends StatelessWidget {
  const NexoraScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.extendBody = false,
    this.safeArea = true,
    this.padding,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool extendBody;
  final bool safeArea;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    Widget content = body;
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }
    if (safeArea) {
      content = SafeArea(bottom: bottomNavigationBar == null, child: content);
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      extendBody: extendBody,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.cosmicBackground)),
          content,
        ],
      ),
    );
  }
}

class NexoraPagePadding extends StatelessWidget {
  const NexoraPagePadding({super.key, required this.child, this.bottom});

  final Widget child;
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.screen.copyWith(
        bottom: bottom ?? AppSpacing.bottomNav(context),
      ),
      child: child,
    );
  }
}
