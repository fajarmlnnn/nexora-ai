import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/card/n_card.dart';
import '../../budget/presentation/add_budget_sheet.dart';

class QuickActions extends ConsumerWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NCard(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionItem(
                  icon: LucideIcons.plus,
                  label: 'Tambah',
                  color: AppColors.primaryLight,
                  onTap: () => context.push('/add-expense'),
                ),
              ),
              Expanded(
                child: _ActionItem(
                  icon: LucideIcons.scanLine,
                  label: 'Scan',
                  color: AppColors.primaryLight,
                  isNew: true,
                  onTap: () {},
                ),
              ),
              Expanded(
                child: _ActionItem(
                  icon: LucideIcons.walletMinimal,
                  label: 'Budget',
                  color: AppColors.primaryLight,
                  onTap: () => showAddBudgetSheet(context, ref),
                ),
              ),
              Expanded(
                child: _ActionItem(
                  icon: LucideIcons.send,
                  label: 'Transfer',
                  color: AppColors.primaryLight,
                  onTap: () => context.push('/transfer'),
                ),
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
    required this.onTap,
    this.isNew = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isNew;

  @override
  State<_ActionItem> createState() => _ActionItemState();
}

class _ActionItemState extends State<_ActionItem> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        scale: _pressed ? .94 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: .075),
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.color.withValues(alpha: .13)),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.color.withValues(alpha: .82),
                    size: 20,
                  ),
                ),
                if (widget.isNew)
                  Positioned(
                    top: -5,
                    right: -7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.primary.withValues(alpha: .20)),
                      ),
                      child: Text(
                        'NEW',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primaryLight,
                          fontSize: 7,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
