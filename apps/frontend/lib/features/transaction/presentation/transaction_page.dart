import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/context_ai_insight.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../dashboard/models/transaction_model.dart';
import '../../finance/state/financial_transaction_store.dart';
import '../../forms/presentation/money_form_page.dart';

class TransactionPage extends ConsumerStatefulWidget {
  const TransactionPage({super.key});

  @override
  ConsumerState<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends ConsumerState<TransactionPage> {
  TransactionType? filter;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _transactionScrollController = ScrollController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _transactionScrollController.dispose();
    super.dispose();
  }

  void _setFilter(TransactionType? value) {
    setState(() => filter = value);
    if (_transactionScrollController.hasClients) {
      _transactionScrollController.animateTo(0, duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
    }
  }

  Future<void> _editTransaction(TransactionModel item) async {
    if (item.isTransfer) {
      _showMessage('Transfer belum bisa diedit. Hapus lalu buat transfer baru jika diperlukan.');
      return;
    }
    await Navigator.of(context).push<TransactionModel>(
      MaterialPageRoute(builder: (_) => MoneyFormPage(income: item.isIncome, transaction: item)),
    );
  }

  Future<void> _deleteTransaction(TransactionModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Hapus transaksi?'),
        content: Text('Transaksi "${item.title}" sebesar ${rupiah(item.amount)} akan dihapus. Saldo wallet dan ringkasan keuangan akan dihitung ulang.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    try {
      await ref.read(financialTransactionStoreProvider.notifier).delete(item.id);
      if (mounted) _showMessage('Transaksi berhasil dihapus.');
    } catch (error) {
      if (mounted) _showMessage('Gagal menghapus transaksi: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showTransactionDetail(TransactionModel item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (sheetContext) => _TransactionDetailSheet(
        item: item,
        onEdit: () {
          Navigator.pop(sheetContext);
          _editTransaction(item);
        },
        onDelete: () {
          Navigator.pop(sheetContext);
          _deleteTransaction(item);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(recentTransactionsProvider);

    return PremiumScaffold(
      child: Stack(
        children: [
          Padding(
            padding: AppSpacing.screen.copyWith(bottom: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TransactionHeader(onFilter: () => _showFilterSheet(context)),
                const SizedBox(height: 14),
                _SearchBar(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value.trim()),
                  onFilter: () => _showFilterSheet(context),
                ),
                const SizedBox(height: 10),
                _FilterTabs(selected: filter, onChanged: _setFilter),
                const SizedBox(height: 12),
                Expanded(
                  child: transactions.when(
                    loading: () => ListView.separated(
                      controller: _transactionScrollController,
                      padding: EdgeInsets.only(top: 8, bottom: AppSpacing.bottomNav(context) + 112),
                      itemCount: 6,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, _) => const ShimmerSkeleton(height: 70),
                    ),
                    error: (error, _) => Center(child: EmptyStateCard(icon: LucideIcons.triangleAlert, title: 'Transaksi belum tersedia', message: error.toString(), action: 'Coba Lagi')),
                    data: (items) {
                      final visible = items
                          .where((item) => filter == null || item.type == filter)
                          .where((item) {
                            final query = _query.toLowerCase();
                            return query.isEmpty ||
                                item.title.toLowerCase().contains(query) ||
                                _categoryLabel(item.category).toLowerCase().contains(query) ||
                                (item.isTransfer && 'transfer'.contains(query));
                          })
                          .toList()
                        ..sort(_compareTransactionsNewestFirst);

                      if (visible.isEmpty) return _NoResults(query: _query);

                      return ListView(
                        key: ValueKey(filter),
                        controller: _transactionScrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(top: 4, bottom: AppSpacing.bottomNav(context) + 112),
                        children: [
                          _SummaryCard(items: visible),
                          const SizedBox(height: 8),
                          ..._buildGroups(visible),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: AppSpacing.screen.left,
            right: AppSpacing.screen.right,
            bottom: AppSpacing.bottomNav(context) + 8,
            child: const ContextAIInsight(
              title: 'Nexora Insight',
              actionLabel: 'Lihat insight',
              message: 'Pantau pola pemasukan dan pengeluaranmu dari transaksi terbaru.',
            ),
          ),
        ],
      ),
    );
  }

  int _compareTransactionsNewestFirst(TransactionModel a, TransactionModel b) {
    final occurred = b.date.compareTo(a.date);
    if (occurred != 0) return occurred;
    final aCreated = a.createdAt;
    final bCreated = b.createdAt;
    if (aCreated != null && bCreated != null) return bCreated.compareTo(aCreated);
    if (aCreated != null) return -1;
    if (bCreated != null) return 1;
    return b.id.compareTo(a.id);
  }

  List<Widget> _buildGroups(List<TransactionModel> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final groups = <String, List<TransactionModel>>{};
    for (final item in items) {
      final date = DateTime(item.date.year, item.date.month, item.date.day);
      final label = date == today ? 'Hari ini' : date == yesterday ? 'Kemarin' : DateFormat('dd MMM yyyy', 'id_ID').format(date);
      groups.putIfAbsent(label, () => <TransactionModel>[]).add(item);
    }
    return groups.entries.map((entry) => _Group(title: entry.key, items: entry.value, onTap: _showTransactionDetail)).toList();
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter transaksi', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              _SheetOption(label: 'Semua transaksi', selected: filter == null, onTap: () { _setFilter(null); Navigator.pop(sheetContext); }),
              _SheetOption(label: 'Pemasukan', selected: filter == TransactionType.income, onTap: () { _setFilter(TransactionType.income); Navigator.pop(sheetContext); }),
              _SheetOption(label: 'Pengeluaran', selected: filter == TransactionType.expense, onTap: () { _setFilter(TransactionType.expense); Navigator.pop(sheetContext); }),
              _SheetOption(label: 'Transfer', selected: filter == TransactionType.transfer, onTap: () { _setFilter(TransactionType.transfer); Navigator.pop(sheetContext); }),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionHeader extends StatelessWidget {
  const _TransactionHeader({this.onFilter});
  final VoidCallback? onFilter;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Text('Transaksi', style: AppTypography.heading1), const SizedBox(width: 5), const Icon(LucideIcons.sparkles, size: 16, color: AppColors.primaryLight)]),
        const SizedBox(height: 1),
        Text('Pantau arus uangmu', style: AppTypography.bodySmall),
      ])),
      Material(
        color: AppColors.card.withValues(alpha: .72),
        shape: const CircleBorder(),
        child: InkWell(onTap: onFilter, customBorder: const CircleBorder(), child: const SizedBox(width: 44, height: 44, child: Icon(LucideIcons.slidersHorizontal, size: 20, color: AppColors.textSecondary))),
      ),
    ],
  );
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged, this.onFilter});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFilter;
  @override
  Widget build(BuildContext context) => Container(
    height: 50,
    padding: const EdgeInsets.symmetric(horizontal: 13),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: AppRadius.radiusXL, border: Border.all(color: AppColors.primaryLight.withValues(alpha: .10))),
    child: Row(children: [
      const Icon(LucideIcons.search, color: AppColors.textMuted, size: 20),
      const SizedBox(width: 9),
      Expanded(child: TextField(controller: controller, onChanged: onChanged, textInputAction: TextInputAction.search, style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary), decoration: InputDecoration(hintText: 'Cari transaksi', hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero))),
      if (controller.text.isNotEmpty) GestureDetector(onTap: () { controller.clear(); onChanged(''); }, child: const Icon(LucideIcons.x, size: 18, color: AppColors.textMuted)),
      const SizedBox(width: 6),
      GestureDetector(onTap: onFilter, child: const Icon(LucideIcons.listFilter, color: AppColors.primaryLight, size: 19)),
    ]),
  );
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.selected, required this.onChanged});
  final TransactionType? selected;
  final ValueChanged<TransactionType?> onChanged;
  int _index() => selected == TransactionType.income ? 1 : selected == TransactionType.expense ? 2 : selected == TransactionType.transfer ? 3 : 0;
  @override
  Widget build(BuildContext context) => Container(
    height: 50,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(color: AppColors.card.withValues(alpha: .68), borderRadius: AppRadius.radiusLG, border: Border.all(color: AppColors.border.withValues(alpha: .28))),
    child: LayoutBuilder(builder: (context, constraints) {
      final itemWidth = constraints.maxWidth / 4;
      return Stack(children: [
        AnimatedPositioned(left: itemWidth * _index(), top: 0, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic, child: Container(width: itemWidth, height: 44, decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: AppRadius.radiusMD, boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .20), blurRadius: 12, offset: const Offset(0, 4))]))),
        Row(children: [
          _Tab(label: 'Semua', selected: selected == null, onTap: () => onChanged(null)),
          _Tab(label: 'Masuk', selected: selected == TransactionType.income, onTap: () => onChanged(TransactionType.income)),
          _Tab(label: 'Keluar', selected: selected == TransactionType.expense, onTap: () => onChanged(TransactionType.expense)),
          _Tab(label: 'Transfer', selected: selected == TransactionType.transfer, onTap: () => onChanged(TransactionType.transfer)),
        ]),
      ]);
    }),
  );
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: Center(child: AnimatedDefaultTextStyle(duration: const Duration(milliseconds: 180), style: AppTypography.caption.copyWith(color: selected ? Colors.white : AppColors.textSecondary, fontWeight: selected ? FontWeight.w700 : FontWeight.w600), child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)))));
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.items});
  final List<TransactionModel> items;
  @override
  Widget build(BuildContext context) {
    final income = items.where((e) => e.isIncome).fold<double>(0, (sum, e) => sum + e.amount);
    final expense = items.where((e) => e.isExpense).fold<double>(0, (sum, e) => sum + e.amount);
    return PremiumCard(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      borderRadius: AppRadius.radiusXL,
      child: Row(children: [
        Expanded(child: _SummaryMetric(icon: LucideIcons.arrowDownLeft, label: 'Total masuk', value: income, color: AppColors.success)),
        Container(width: 1, height: 40, color: AppColors.border.withValues(alpha: .45)),
        const SizedBox(width: 12),
        Expanded(child: _SummaryMetric(icon: LucideIcons.arrowUpRight, label: 'Total keluar', value: expense, color: AppColors.danger)),
      ]),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final double value;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: AppRadius.radiusLG), child: Icon(icon, color: color, size: 17)),
    const SizedBox(width: 8),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: AppTypography.caption), const SizedBox(height: 1), Text(rupiah(value), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800))])),
  ]);
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.items, required this.onTap});
  final String title;
  final List<TransactionModel> items;
  final ValueChanged<TransactionModel> onTap;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.fromLTRB(0, 9, 0, 8), child: Row(children: [Text(title, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)), const SizedBox(width: 7), Expanded(child: Divider(color: AppColors.border.withValues(alpha: .35), height: 1))])),
    for (final item in items) _TransactionTile(item: item, onTap: onTap),
    const SizedBox(height: 4),
  ]);
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.item, required this.onTap});
  final TransactionModel item;
  final ValueChanged<TransactionModel> onTap;
  @override
  Widget build(BuildContext context) {
    final color = item.isIncome ? AppColors.success : item.isExpense ? AppColors.danger : AppColors.primaryLight;
    final prefix = item.isIncome ? '+' : item.isExpense ? '-' : '↔ ';
    final time = DateFormat('HH:mm').format(item.date);
    final date = DateFormat('dd MMM yyyy').format(item.date);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: InkWell(
        borderRadius: AppRadius.radiusXL,
        onTap: () => onTap(item),
        child: PremiumCard(
          borderRadius: AppRadius.radiusXL,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          child: Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: AppRadius.radiusLG), child: Icon(item.isTransfer ? LucideIcons.arrowLeftRight : _icon(item.category), color: color, size: 20)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Row(children: [Flexible(child: Text(item.isTransfer ? 'Transfer' : _categoryLabel(item.category), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption)), const SizedBox(width: 5), Container(width: 3, height: 3, decoration: const BoxDecoration(color: AppColors.textMuted, shape: BoxShape.circle)), const SizedBox(width: 5), Flexible(child: Text('$date • $time', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption))]),
            ])),
            const SizedBox(width: 8),
            Text('$prefix${rupiah(item.amount)}', maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end, style: AppTypography.labelMedium.copyWith(color: color, fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
    );
  }
}

class _TransactionDetailSheet extends StatelessWidget {
  const _TransactionDetailSheet({required this.item, required this.onEdit, required this.onDelete});
  final TransactionModel item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final color = item.isIncome ? AppColors.success : item.isExpense ? AppColors.danger : AppColors.primaryLight;
    final prefix = item.isIncome ? '+' : item.isExpense ? '-' : '↔ ';
    return SafeArea(child: Container(
      decoration: BoxDecoration(color: AppColors.background, borderRadius: const BorderRadius.vertical(top: Radius.circular(28)), border: Border.all(color: Colors.white.withValues(alpha: .07))),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: AppColors.textMuted.withValues(alpha: .45), borderRadius: AppRadius.radiusPill))),
        const SizedBox(height: 18),
        Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withValues(alpha: .13), borderRadius: AppRadius.radiusLG), child: Icon(item.isTransfer ? LucideIcons.arrowLeftRight : _icon(item.category), color: color, size: 23)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.title, style: AppTypography.heading3.copyWith(fontWeight: FontWeight.w800)), Text(item.isTransfer ? 'Transfer' : _categoryLabel(item.category), style: AppTypography.caption)]))]),
        const SizedBox(height: 16),
        Text('$prefix${rupiah(item.amount)}', style: AppTypography.heading1.copyWith(color: color, fontWeight: FontWeight.w900)),
        const SizedBox(height: 18),
        _DetailRow(icon: LucideIcons.calendarDays, label: 'Tanggal', value: DateFormat('dd MMMM yyyy', 'id_ID').format(item.date)),
        _DetailRow(icon: LucideIcons.clock3, label: 'Waktu', value: '${DateFormat('HH:mm').format(item.date)} WIB'),
        _DetailRow(icon: LucideIcons.tag, label: 'Kategori', value: item.isTransfer ? 'Transfer' : _categoryLabel(item.category)),
        if ((item.note ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Catatan', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.card.withValues(alpha: .75), borderRadius: AppRadius.radiusLG, border: Border.all(color: AppColors.border.withValues(alpha: .35))), child: Text(item.note!.trim(), style: AppTypography.bodySmall.copyWith(height: 1.35))),
        ],
        if ((item.sourceAccount ?? '').isNotEmpty || (item.destinationAccount ?? '').isNotEmpty) ...[
          const SizedBox(height: 10),
          if ((item.sourceAccount ?? '').isNotEmpty) _DetailRow(icon: LucideIcons.walletCards, label: 'Dari', value: item.sourceAccount!),
          if ((item.destinationAccount ?? '').isNotEmpty) _DetailRow(icon: LucideIcons.walletCards, label: 'Ke', value: item.destinationAccount!),
        ],
        const SizedBox(height: 16),
        Row(children: [Expanded(child: OutlinedButton.icon(onPressed: onEdit, icon: const Icon(LucideIcons.pencil, size: 17), label: const Text('Edit'))), const SizedBox(width: 10), Expanded(child: FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: AppColors.danger), onPressed: onDelete, icon: const Icon(LucideIcons.trash2, size: 17), label: const Text('Hapus')))]),
      ]),
    ));
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Icon(icon, size: 17, color: AppColors.primaryLight), const SizedBox(width: 10), SizedBox(width: 62, child: Text(label, style: AppTypography.caption)), const SizedBox(width: 8), Expanded(child: Text(value, textAlign: TextAlign.end, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700)))]));
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});
  final String query;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.only(top: 70), child: Column(children: [Container(width: 58, height: 58, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .12), shape: BoxShape.circle), child: const Icon(LucideIcons.searchX, color: AppColors.primaryLight, size: 25)), const SizedBox(height: 12), Text('Transaksi tidak ditemukan', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(query.isEmpty ? 'Belum ada transaksi pada filter ini.' : 'Coba gunakan kata kunci lain.', textAlign: TextAlign.center, style: AppTypography.caption)])));
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(dense: true, contentPadding: EdgeInsets.zero, onTap: onTap, title: Text(label, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)), trailing: Icon(selected ? LucideIcons.circleCheck : LucideIcons.circle, size: 20, color: selected ? AppColors.primaryLight : AppColors.textMuted));
}

IconData _icon(TransactionCategory c) => switch (c) {
  TransactionCategory.food => LucideIcons.utensils,
  TransactionCategory.transport => LucideIcons.car,
  TransactionCategory.shopping => LucideIcons.shoppingBag,
  TransactionCategory.salary => LucideIcons.wallet,
  TransactionCategory.investment => LucideIcons.chartColumn,
  TransactionCategory.bills => LucideIcons.receiptText,
  TransactionCategory.entertainment => LucideIcons.gamepad2,
  TransactionCategory.health => LucideIcons.heartPulse,
  TransactionCategory.education => LucideIcons.graduationCap,
  TransactionCategory.other => LucideIcons.circleDollarSign,
};

String _categoryLabel(TransactionCategory category) => <TransactionCategory, String>{
  TransactionCategory.food: 'Makan & Minum',
  TransactionCategory.transport: 'Transportasi',
  TransactionCategory.shopping: 'Belanja',
  TransactionCategory.salary: 'Gaji',
  TransactionCategory.investment: 'Investasi',
  TransactionCategory.bills: 'Tagihan',
  TransactionCategory.entertainment: 'Hiburan',
  TransactionCategory.health: 'Kesehatan',
  TransactionCategory.education: 'Pendidikan',
  TransactionCategory.other: 'Lainnya',
}[category] ?? 'Lainnya';