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
  TransactionType? _filter;
  String _query = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TransactionModel> _visible(List<TransactionModel> items) {
    final query = _query.toLowerCase();
    final result = items.where((item) {
      if (_filter != null && item.type != _filter) return false;
      if (query.isEmpty) return true;
      return item.title.toLowerCase().contains(query) ||
          _categoryLabel(item.category).toLowerCase().contains(query) ||
          (item.note ?? '').toLowerCase().contains(query);
    }).toList();

    result.sort((a, b) {
      final aDate = a.createdAt ?? a.date;
      final bDate = b.createdAt ?? b.date;
      return bDate.compareTo(aDate);
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final asyncTransactions = ref.watch(recentTransactionsProvider);
    final items = asyncTransactions.valueOrNull ?? const <TransactionModel>[];
    final visible = _visible(items);
    final income = visible.where((item) => item.isIncome).fold<double>(0, (sum, item) => sum + item.amount);
    final expense = visible.where((item) => item.isExpense).fold<double>(0, (sum, item) => sum + item.amount);

    return PremiumScaffold(
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator.adaptive(
          onRefresh: () async => ref.invalidate(recentTransactionsProvider),
          color: AppColors.primaryLight,
          backgroundColor: AppColors.card,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverPadding(
                padding: AppSpacing.screen.copyWith(bottom: 0),
                sliver: SliverToBoxAdapter(child: _Header(onAdd: _addTransaction)),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: _SearchField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value.trim()),
                    onClear: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: _Filters(
                    selected: _filter,
                    onChanged: (value) => setState(() => _filter = value),
                  ),
                ),
              ),
              if (asyncTransactions.hasError)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverToBoxAdapter(child: _ErrorCard(message: '${asyncTransactions.error}')),
                )
              else if (!asyncTransactions.isLoading)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverToBoxAdapter(child: _Snapshot(count: visible.length, income: income, expense: expense)),
                ),
              if (asyncTransactions.isLoading)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: ShimmerSkeleton(height: 82),
                      ),
                      childCount: 6,
                    ),
                  ),
                )
              else if (!asyncTransactions.hasError && visible.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 120),
                  sliver: SliverToBoxAdapter(child: _EmptyState(hasQuery: _query.isNotEmpty)),
                )
              else if (!asyncTransactions.hasError)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                  sliver: SliverList.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TransactionTile(
                        item: visible[index],
                        onTap: () => _showDetail(visible[index]),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _addTransaction() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const MoneyFormPage(income: false)),
    );
  }

  Future<void> _showDetail(TransactionModel item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _TransactionDetail(
        item: item,
        onEdit: item.isTransfer
            ? null
            : () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => MoneyFormPage(income: item.isIncome, transaction: item),
                  ),
                );
              },
        onDelete: () async {
          Navigator.pop(sheetContext);
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: AppColors.card,
              title: const Text('Hapus transaksi?'),
              content: Text('Hapus ${item.title} sebesar ${rupiah(item.amount)}?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
                FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Hapus')),
              ],
            ),
          );
          if (confirmed != true) return;
          await ref.read(financialTransactionStoreProvider.notifier).delete(item.id);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaksi dihapus.')));
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Transaksi', style: AppTypography.heading1.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('Setiap rupiah, lebih mudah dipahami.', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          IconButton(
            onPressed: onAdd,
            icon: const Icon(LucideIcons.plus),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: .16),
              foregroundColor: AppColors.primaryLight,
            ),
          ),
        ],
      );
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged, required this.onClear});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: .82),
          borderRadius: AppRadius.radiusXL,
          border: Border.all(color: AppColors.border.withValues(alpha: .35)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.search, size: 20, color: AppColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                decoration: const InputDecoration(
                  hintText: 'Cari transaksi, kategori, catatan...',
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) => value.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(onPressed: onClear, icon: const Icon(LucideIcons.x, size: 18)),
            ),
          ],
        ),
      );
}

class _Filters extends StatelessWidget {
  const _Filters({required this.selected, required this.onChanged});
  final TransactionType? selected;
  final ValueChanged<TransactionType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final filters = <(String, TransactionType?)>[
      ('Semua', null),
      ('Masuk', TransactionType.income),
      ('Keluar', TransactionType.expense),
      ('Transfer', TransactionType.transfer),
    ];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (label, type) = filters[index];
          final active = selected == type;
          return ChoiceChip(
            label: Text(label),
            selected: active,
            onSelected: (_) => onChanged(type),
            selectedColor: AppColors.primary.withValues(alpha: .25),
            backgroundColor: AppColors.card.withValues(alpha: .70),
            side: BorderSide(color: active ? AppColors.primaryLight.withValues(alpha: .55) : AppColors.border.withValues(alpha: .25)),
            labelStyle: TextStyle(color: active ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w800),
          );
        },
      ),
    );
  }
}

class _Snapshot extends StatelessWidget {
  const _Snapshot({required this.count, required this.income, required this.expense});
  final int count;
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    final net = income - expense;
    final netColor = net >= 0 ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.heroCard,
        borderRadius: AppRadius.radiusXXL,
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: .16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, size: 17, color: AppColors.primaryLight),
              const SizedBox(width: 7),
              Text('Financial snapshot', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w900)),
              const Spacer(),
              Text('$count transaksi', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _SnapshotMetric(label: 'Masuk', value: income, color: AppColors.success)),
              const SizedBox(width: 10),
              Expanded(child: _SnapshotMetric(label: 'Keluar', value: expense, color: AppColors.danger)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: netColor.withValues(alpha: .07),
              borderRadius: AppRadius.radiusLG,
              border: Border.all(color: netColor.withValues(alpha: .12)),
            ),
            child: Row(
              children: [
                Icon(net >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown, size: 16, color: netColor),
                const SizedBox(width: 8),
                Expanded(child: Text('Net cashflow', style: AppTypography.caption.copyWith(color: AppColors.textSecondary))),
                Text(rupiah(net), style: AppTypography.labelMedium.copyWith(color: netColor, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotMetric extends StatelessWidget {
  const _SnapshotMetric({required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: .12), borderRadius: AppRadius.radiusLG),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 4),
          FittedBox(
            alignment: Alignment.centerLeft,
            child: Text(rupiah(value), style: AppTypography.labelMedium.copyWith(color: color, fontWeight: FontWeight.w900)),
          ),
        ]),
      );
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.item, required this.onTap});
  final TransactionModel item;
  final VoidCallback onTap;

  Color get accent => item.isTransfer ? AppColors.info : item.isIncome ? AppColors.success : AppColors.danger;

  IconData get icon => item.isTransfer
      ? LucideIcons.arrowLeftRight
      : item.isIncome
          ? LucideIcons.arrowDownLeft
          : switch (item.category) {
              TransactionCategory.food => LucideIcons.utensils,
              TransactionCategory.transport => LucideIcons.car,
              TransactionCategory.shopping => LucideIcons.shoppingBag,
              TransactionCategory.salary => LucideIcons.badgeDollarSign,
              TransactionCategory.investment => LucideIcons.chartColumn,
              TransactionCategory.bills => LucideIcons.receipt,
              TransactionCategory.entertainment => LucideIcons.film,
              TransactionCategory.health => LucideIcons.heartPulse,
              TransactionCategory.education => LucideIcons.graduationCap,
              TransactionCategory.other => LucideIcons.circleDollarSign,
            };

  @override
  Widget build(BuildContext context) {
    final date = item.createdAt ?? item.date;
    return Material(
      color: AppColors.card.withValues(alpha: .72),
      borderRadius: AppRadius.radiusXL,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusXL,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: accent.withValues(alpha: .10), shape: BoxShape.circle),
                child: Icon(icon, color: accent, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    '${_categoryLabel(item.category)} • ${DateFormat('dd MMM, HH:mm', 'id_ID').format(date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                  ),
                ]),
              ),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('${item.isIncome ? '+' : '-'}${rupiah(item.amount)}', style: AppTypography.labelMedium.copyWith(color: accent, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 3),
                Text(item.isTransfer ? 'Transfer' : item.isIncome ? 'Masuk' : 'Keluar', style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 8)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionDetail extends StatelessWidget {
  const _TransactionDetail({required this.item, required this.onEdit, required this.onDelete});
  final TransactionModel item;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final date = item.createdAt ?? item.date;
    final accent = item.isTransfer ? AppColors.info : item.isIncome ? AppColors.success : AppColors.danger;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(99)))),
          const SizedBox(height: 18),
          Row(children: [
            Container(width: 46, height: 46, decoration: BoxDecoration(color: accent.withValues(alpha: .10), shape: BoxShape.circle), child: Icon(LucideIcons.receipt, color: accent)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.heading4.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(_categoryLabel(item.category), style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
            ])),
          ]),
          const SizedBox(height: 20),
          Text('${item.isIncome ? '+' : item.isTransfer ? '' : '-'}${rupiah(item.amount)}', style: AppTypography.displaySmall.copyWith(color: accent, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          _DetailRow(icon: LucideIcons.calendarDays, label: 'Tanggal', value: DateFormat('dd MMMM yyyy', 'id_ID').format(date)),
          const SizedBox(height: 10),
          _DetailRow(icon: LucideIcons.clock3, label: 'Waktu', value: DateFormat('HH:mm', 'id_ID').format(date)),
          const SizedBox(height: 10),
          _DetailRow(icon: LucideIcons.tag, label: 'Kategori', value: _categoryLabel(item.category)),
          if (item.note?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            _DetailRow(icon: LucideIcons.notebookPen, label: 'Catatan', value: item.note!),
          ],
          const SizedBox(height: 20),
          Row(children: [
            if (onEdit != null)
              Expanded(child: OutlinedButton.icon(onPressed: onEdit, icon: const Icon(LucideIcons.pencil, size: 17), label: const Text('Edit'))),
            if (onEdit != null) const SizedBox(width: 10),
            Expanded(child: FilledButton.icon(onPressed: onDelete, icon: const Icon(LucideIcons.trash2, size: 17), label: const Text('Hapus'))),
          ]),
        ]),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .025), borderRadius: AppRadius.radiusLG, border: Border.all(color: Colors.white.withValues(alpha: .045))),
        child: Row(children: [
          Icon(icon, size: 17, color: AppColors.primaryLight),
          const SizedBox(width: 10),
          Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          const Spacer(),
          Flexible(child: Text(value, textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700))),
        ]),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasQuery});
  final bool hasQuery;

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(width: 58, height: 58, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .10), shape: BoxShape.circle), child: const Icon(LucideIcons.searchX, color: AppColors.primaryLight, size: 24)),
        const SizedBox(height: 12),
        Text(hasQuery ? 'Transaksi tidak ditemukan' : 'Belum ada transaksi', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Text(hasQuery ? 'Coba kata kunci atau filter lain.' : 'Catat transaksi pertamamu untuk mulai melacak keuangan.', textAlign: TextAlign.center, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.35)),
      ]);
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: .07), borderRadius: AppRadius.radiusXL, border: Border.all(color: AppColors.danger.withValues(alpha: .16))),
        child: Row(children: [const Icon(LucideIcons.triangleAlert, color: AppColors.danger, size: 18), const SizedBox(width: 9), Expanded(child: Text(message, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)))]),
      );
}

String _categoryLabel(TransactionCategory category) => switch (category) {
      TransactionCategory.food => 'Makanan & Minuman',
      TransactionCategory.transport => 'Transportasi',
      TransactionCategory.shopping => 'Belanja',
      TransactionCategory.salary => 'Gaji',
      TransactionCategory.investment => 'Investasi',
      TransactionCategory.bills => 'Tagihan',
      TransactionCategory.entertainment => 'Hiburan',
      TransactionCategory.health => 'Kesehatan',
      TransactionCategory.education => 'Pendidikan',
      TransactionCategory.other => 'Lainnya',
    };
