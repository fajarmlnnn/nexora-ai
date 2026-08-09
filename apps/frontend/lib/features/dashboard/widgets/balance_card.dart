import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/card/n_card.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../models/dashboard_summary.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.summary, this.totalBalance, this.onTap});

  final DashboardSummary summary;
  final double? totalBalance;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final balance = totalBalance ?? summary.totalBalance;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusXXL,
        child: NCard(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF171525), Color(0xFF12121C), Color(0xFF0D0E15)]),
          showBorder: true,
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _BalanceHeader(),
            const SizedBox(height: 16),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Total Balance', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(rupiah(balance), style: AppTypography.heading2.copyWith(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: -.4))),
              ])),
              const SizedBox(width: 12),
              const _BalanceTrendPill(),
            ]),
            const SizedBox(height: 12),
            const _BalanceChart(),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _FinanceBubble(title: 'Income', value: rupiah(summary.monthlyIncome), percentage: '+12.4%', icon: Icons.arrow_downward_rounded, accent: AppColors.success)),
              const SizedBox(width: 10),
              Expanded(child: _FinanceBubble(title: 'Expense', value: rupiah(summary.monthlyExpense), percentage: '-8.2%', icon: Icons.arrow_upward_rounded, accent: AppColors.danger)),
            ]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [Text('Lihat detail', style: AppTypography.caption.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w700)), const SizedBox(width: 3), const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primaryLight)]),
          ]),
        ),
      ),
    );
  }
}

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader();
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .45), blurRadius: 10)])),
    const SizedBox(width: 8),
    Text('Financial Overview', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
  ]);
}

class _BalanceTrendPill extends StatelessWidget {
  const _BalanceTrendPill();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(color: AppColors.success.withValues(alpha: .08), borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.success.withValues(alpha: .16))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.trending_up_rounded, size: 14, color: AppColors.success), const SizedBox(width: 4), Text('+12.4%', style: AppTypography.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w700))]),
  );
}

class _BalanceChart extends StatelessWidget {
  const _BalanceChart();
  @override
  Widget build(BuildContext context) => SizedBox(height: 82, width: double.infinity, child: CustomPaint(painter: _BalanceChartPainter()));
}

class _BalanceChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[
      Offset(0, size.height * .72), Offset(size.width * .10, size.height * .58), Offset(size.width * .20, size.height * .66), Offset(size.width * .31, size.height * .42), Offset(size.width * .42, size.height * .52), Offset(size.width * .54, size.height * .28), Offset(size.width * .65, size.height * .40), Offset(size.width * .76, size.height * .22), Offset(size.width * .88, size.height * .32), Offset(size.width, size.height * .12),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i]; final next = points[i + 1];
      final c1 = Offset(current.dx + (next.dx - current.dx) * .45, current.dy);
      final c2 = Offset(next.dx - (next.dx - current.dx) * .45, next.dy);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, next.dx, next.dy);
    }
    final area = Path.from(path)..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(area, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.primary.withValues(alpha: .16), AppColors.primary.withValues(alpha: .025), Colors.transparent]).createShader(Offset.zero & size));
    canvas.drawPath(path, Paint()..color = AppColors.primary.withValues(alpha: .10)..style = PaintingStyle.stroke..strokeWidth = 7..strokeCap = StrokeCap.round..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawPath(path, Paint()..color = AppColors.primaryLight.withValues(alpha: .72)..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    canvas.drawCircle(points.last, 7, Paint()..color = AppColors.primaryLight.withValues(alpha: .14)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(points.last, 3, Paint()..color = AppColors.primaryLight);
  }
  @override
  bool shouldRepaint(covariant _BalanceChartPainter oldDelegate) => false;
}

class _FinanceBubble extends StatelessWidget {
  const _FinanceBubble({required this.title, required this.value, required this.percentage, required this.icon, required this.accent});
  final String title; final String value; final String percentage; final IconData icon; final Color accent;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .035), borderRadius: AppRadius.radiusLG, border: Border.all(color: Colors.white.withValues(alpha: .055))),
    child: Row(children: [
      Container(width: 30, height: 30, decoration: BoxDecoration(color: accent.withValues(alpha: .09), shape: BoxShape.circle), child: Icon(icon, size: 15, color: accent)),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: AppTypography.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700))),
        const SizedBox(height: 2),
        Text(percentage, style: AppTypography.caption.copyWith(color: accent.withValues(alpha: .78), fontWeight: FontWeight.w700)),
      ])),
    ]),
  );
}
