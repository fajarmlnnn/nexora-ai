import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../dashboard/models/transaction_model.dart';
import '../../finance/state/financial_transaction_store.dart';
import '../../forms/presentation/money_form_page.dart';

class TransactionPageV2 extends ConsumerStatefulWidget {
  const TransactionPageV2({super.key});
  @override
  ConsumerState<TransactionPageV2> createState() => _TransactionPageV2State();
}

class _TransactionPageV2State extends ConsumerState<TransactionPageV2> {
  TransactionType? filter;
  String query = '';
  final search = TextEditingController();

  @override
  void dispose() { search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(recentTransactionsProvider);
    return PremiumScaffold(
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(padding: AppSpacing.screen.copyWith(bottom: 0), sliver: SliverToBoxAdapter(child: _Header(onAdd: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MoneyFormPage(income: false))))),
            SliverPadding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), sliver: SliverToBoxAdapter(child: _Search(controller: search, onChanged: (v) => setState(() => query = v.trim()), onClear: () { search.clear(); setState(() => query = ''); }))),
            SliverPadding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 0), sliver: SliverToBoxAdapter(child: _Filters(selected: filter, onChanged: (v) => setState(() => filter = v)))),
            SliverPadding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), sliver: SliverToBoxAdapter(child: async.when(loading: () => const ShimmerSkeleton(height: 104), error: (e, _) => _ErrorCard(message: '$e'), data: (items) => _Summary(items: _visible(items))))),
            async.when(
              loading: () => SliverPadding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 120), sliver: SliverList(delegate: SliverChildBuilderDelegate((_, i) => const Padding(padding: EdgeInsets.only(bottom: 10), child: ShimmerSkeleton(height: 78)), childCount: 6))),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              data: (items) {
                final visible = _visible(items);
                if (visible.isEmpty) return SliverPadding(padding: const EdgeInsets.fromLTRB(16, 18, 16, 120), sliver: SliverToBoxAdapter(child: _Empty(query: query)));
                return SliverPadding(padding: const EdgeInsets.fromLTRB(16, 18, 16, 120), sliver: SliverList(delegate: SliverChildBuilderDelegate((_, i) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _TransactionTile(item: visible[i], onTap: () => _detail(visible[i]))), childCount: visible.length)));
              },
            ),
          ],
        ),
      ),
    );
  }

  List<TransactionModel> _visible(List<TransactionModel> items) {
    final q = query.toLowerCase();
    final list = items.where((x) => filter == null || x.type == filter).where((x) => q.isEmpty || x.title.toLowerCase().contains(q) || _category(x.category).toLowerCase().contains(q) || (x.note ?? '').toLowerCase().contains(q)).toList();
    list.sort((a, b) => (b.createdAt ?? b.date).compareTo(a.createdAt ?? a.date));
    return list;
  }

  String _category(TransactionCategory c) => c.name[0].toUpperCase() + c.name.substring(1);

  Future<void> _detail(TransactionModel item) async {
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _Detail(item: item, category: _category(item.category), onEdit: () { Navigator.pop(context); if (!item.isTransfer) Navigator.push(context, MaterialPageRoute(builder: (_) => MoneyFormPage(income: item.isIncome, transaction: item))); }, onDelete: () async { Navigator.pop(context); final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(backgroundColor: AppColors.card, title: const Text('Hapus transaksi?'), content: Text('Hapus ${item.title} sebesar ${rupiah(item.amount)}?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus'))])); if (ok == true) { await ref.read(financialTransactionStoreProvider.notifier).delete(item.id); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaksi dihapus.'))); } }));
  }
}

class _Header extends StatelessWidget { const _Header({required this.onAdd}); final VoidCallback onAdd; @override Widget build(BuildContext context) => Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Transaksi', style: AppTypography.heading1.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text('Setiap rupiah, lebih mudah dipahami.', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary))])), IconButton(onPressed: onAdd, icon: const Icon(LucideIcons.plus), style: IconButton.styleFrom(backgroundColor: AppColors.primary.withValues(alpha: .16), foregroundColor: AppColors.primaryLight))]); }

class _Search extends StatelessWidget { const _Search({required this.controller, required this.onChanged, required this.onClear}); final TextEditingController controller; final ValueChanged<String> onChanged; final VoidCallback onClear; @override Widget build(BuildContext context) => Container(height: 52, padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: AppColors.card.withValues(alpha: .82), borderRadius: AppRadius.radiusXL, border: Border.all(color: AppColors.border.withValues(alpha: .35))), child: Row(children: [const Icon(LucideIcons.search, size: 20, color: AppColors.textMuted), const SizedBox(width: 10), Expanded(child: TextField(controller: controller, onChanged: onChanged, decoration: const InputDecoration(hintText: 'Cari transaksi, kategori, catatan...', border: InputBorder.none, isDense: true))), if (controller.text.isNotEmpty) IconButton(onPressed: onClear, icon: const Icon(LucideIcons.x, size: 18))])); }

class _Filters extends StatelessWidget { const _Filters({required this.selected, required this.onChanged}); final TransactionType? selected; final ValueChanged<TransactionType?> onChanged; @override Widget build(BuildContext context) { final data = <({String label, TransactionType? type})>[('Semua', null), ('Masuk', TransactionType.income), ('Keluar', TransactionType.expense), ('Transfer', TransactionType.transfer)]; return SizedBox(height: 42, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: data.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) { final x = data[i]; final active = selected == x.type; return ChoiceChip(label: Text(x.label), selected: active, onSelected: (_) => onChanged(x.type), selectedColor: AppColors.primary.withValues(alpha: .25), backgroundColor: AppColors.card.withValues(alpha: .7), side: BorderSide(color: active ? AppColors.primaryLight.withValues(alpha: .55) : AppColors.border.withValues(alpha: .25)), labelStyle: TextStyle(color: active ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w800)); })); } }

class _Summary extends StatelessWidget { const _Summary({required this.items}); final List<TransactionModel> items; @override Widget build(BuildContext context) { final income = items.where((x) => x.isIncome).fold<double>(0, (s, x) => s + x.amount); final expense = items.where((x) => x.isExpense).fold<double>(0, (s, x) => s + x.amount); return Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(gradient: AppGradients.heroCard, borderRadius: AppRadius.radiusXXL, border: Border.all(color: AppColors.primaryLight.withValues(alpha: .18)), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .12), blurRadius: 24, offset: const Offset(0, 10))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(LucideIcons.sparkles, size: 17, color: AppColors.primaryLight), const SizedBox(width: 7), Text('Snapshot', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w900)), const Spacer(), Text('${items.length} transaksi', style: AppTypography.caption.copyWith(color: AppColors.textMuted))]), const SizedBox(height: 14), Row(children: [Expanded(child: _Metric(label: 'Masuk', value: income, positive: true)), const SizedBox(width: 10), Expanded(child: _Metric(label: 'Keluar', value: expense, positive: false))]) ])); } }

class _Metric extends StatelessWidget { const _Metric({required this.label, required this.value, required this.positive}); final String label; final double value; final bool positive; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black.withValues(alpha: .12), borderRadius: AppRadius.radiusLG), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: AppTypography.caption.copyWith(color: AppColors.textMuted)), const SizedBox(height: 4), FittedBox(alignment: Alignment.centerLeft, child: Text('${positive ? '+' : '-'}${rupiah(value)}', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w900, color: positive ? AppColors.success : AppColors.danger)))])); }

class _TransactionTile extends StatelessWidget { const _TransactionTile({required this.item, required this.onTap}); final TransactionModel item; final VoidCallback onTap; @override Widget build(BuildContext context) { final positive = item.isIncome; final color = item.isTransfer ? AppColors.info : positive ? AppColors.success : AppColors.danger; final icon = item.isTransfer ? LucideIcons.arrowLeftRight : positive ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight; return Material(color: AppColors.card.withValues(alpha: .72), borderRadius: AppRadius.radiusXL, child: InkWell(onTap: onTap, borderRadius: AppRadius.radiusXL, child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [Container(width: 46, height: 46, decoration: BoxDecoration(color: color.withValues(alpha: .12), shape: BoxShape.circle), child: Icon(icon, color: color, size: 21)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text('${item.date.day.toString().padLeft(2, '0')} ${DateFormat('MMM', 'id_ID').format(item.date)} • ${item.note?.isNotEmpty == true ? item.note! : item.category.name}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(color: AppColors.textMuted))])), const SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${positive ? '+' : item.isTransfer ? '↔' : '-'}${rupiah(item.amount)}', style: AppTypography.labelLarge.copyWith(color: color, fontWeight: FontWeight.w900)), const SizedBox(height: 3), const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textMuted)])])))); } }

class _Detail extends StatelessWidget { const _Detail({required this.item, required this.category, required this.onEdit, required this.onDelete}); final TransactionModel item; final String category; final VoidCallback onEdit; final VoidCallback onDelete; @override Widget build(BuildContext context) => Container(padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + MediaQuery.paddingOf(context).bottom), decoration: BoxDecoration(color: AppColors.background, borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), border: Border.all(color: AppColors.primaryLight.withValues(alpha: .16))), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: AppColors.textMuted.withValues(alpha: .4), borderRadius: BorderRadius.circular(99)))), const SizedBox(height: 22), Text('Transaction detail', style: AppTypography.caption.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w900, letterSpacing: 1.1)), const SizedBox(height: 5), Text(item.title, style: AppTypography.heading2.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text('${item.isIncome ? '+' : item.isTransfer ? '↔' : '-'}${rupiah(item.amount)}', style: AppTypography.heading1.copyWith(color: item.isIncome ? AppColors.success : item.isTransfer ? AppColors.info : AppColors.danger, fontWeight: FontWeight.w900)), const SizedBox(height: 20), _Info(label: 'Tanggal', value: DateFormat('EEEE, dd MMMM yyyy • HH:mm', 'id_ID').format(item.date)), _Info(label: 'Kategori', value: category), if (item.walletId != null) _Info(label: 'Wallet', value: item.walletId!), if (item.note?.isNotEmpty == true) _Info(label: 'Catatan', value: item.note!), if (item.isTransfer) ...[_Info(label: 'Dari', value: item.sourceAccount ?? '-'), _Info(label: 'Ke', value: item.destinationAccount ?? '-')], const SizedBox(height: 14), Row(children: [if (!item.isTransfer) Expanded(child: OutlinedButton.icon(onPressed: onEdit, icon: const Icon(LucideIcons.pencil), label: const Text('Edit'))), if (!item.isTransfer) const SizedBox(width: 10), Expanded(child: FilledButton.icon(onPressed: onDelete, icon: const Icon(LucideIcons.trash2), label: const Text('Hapus'), style: FilledButton.styleFrom(backgroundColor: AppColors.danger)))]) ])); }

class _Info extends StatelessWidget { const _Info({required this.label, required this.value}); final String label; final String value; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 80, child: Text(label, style: AppTypography.caption.copyWith(color: AppColors.textMuted))), Expanded(child: Text(value, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700))) ])); }

class _Empty extends StatelessWidget { const _Empty({required this.query}); final String query; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(26), decoration: BoxDecoration(color: AppColors.card.withValues(alpha: .6), borderRadius: AppRadius.radiusXXL, border: Border.all(color: AppColors.border.withValues(alpha: .25))), child: Column(children: [const Icon(LucideIcons.searchX, size: 34, color: AppColors.primaryLight), const SizedBox(height: 10), Text(query.isEmpty ? 'Belum ada transaksi' : 'Transaksi tidak ditemukan', style: AppTypography.heading3), const SizedBox(height: 5), Text(query.isEmpty ? 'Mulai catat pemasukan dan pengeluaranmu.' : 'Coba kata kunci atau filter lain.', textAlign: TextAlign.center, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary))])); }

class _ErrorCard extends StatelessWidget { const _ErrorCard({required this.message}); final String message; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: .08), borderRadius: AppRadius.radiusXL, border: Border.all(color: AppColors.danger.withValues(alpha: .25))), child: Row(children: [const Icon(LucideIcons.triangleAlert, color: AppColors.danger), const SizedBox(width: 10), Expanded(child: Text(message, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppTypography.caption))])); }
