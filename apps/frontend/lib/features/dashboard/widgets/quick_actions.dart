import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/card/n_card.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return NCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Actions",
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),

          AppSpacing.gapMD,

          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ActionItem(
                icon: LucideIcons.plus,
                label: "Tambah",
                color: AppColors.primary,
              ),
              _ActionItem(
                icon: LucideIcons.scanLine,
                label: "Scan",
                color: AppColors.info,
                isNew: true,
              ),
              _ActionItem(
                icon: LucideIcons.walletMinimal,
                label: "Budget",
                color: AppColors.warning,
              ),
              _ActionItem(
                icon: LucideIcons.send,
                label: "Transfer",
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatefulWidget {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    this.isNew = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isNew;

  @override
  State<_ActionItem> createState() => _ActionItemState();
}

class _ActionItemState extends State<_ActionItem> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => pressed = true);
      },
      onTapUp: (_) {
        setState(() => pressed = false);
      },
      onTapCancel: () {
        setState(() => pressed = false);
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: pressed ? .94 : 1,
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Hero(
                    tag: "quick_${widget.label}",
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppGradients.button,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: .22),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 22),
                    ),
                  ),

                  if (widget.isNew)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "NEW",
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              AppSpacing.gapSM,

              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
