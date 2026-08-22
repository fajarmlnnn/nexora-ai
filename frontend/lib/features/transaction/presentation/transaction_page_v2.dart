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

  @override
  Widget build(BuildContext context) {
    final asyncTransactions = ref.watch(recentTransactionsProvider);
    final items = asyncTransactions.valueOrNull ?? const <TransactionModel>[];
    final visible = _visible(items);

    return PremiumScaffold(
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: AppSpacing.screen.copyWith(bottom: 0),
              sliver: SliverToBoxAdapter(
                child: _Header(onAdd: _openAddTransaction),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _Search(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value.trim()),
                  onClear: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                  onFilter: _openFilter,
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
                sliver: SliverToBoxAdapter(
                  child: _ErrorCard(
                    message: 'Data transaksi gagal dimuat. Coba lagi.',
                    onRetry: () => ref.invalidate(recentTransactionsProvider),
                  ),
                ),
              )
            else if (!asyncTransactions.isLoading)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: _Summary(items: visible, filter: _filter),
                ),
              ),
            if (asyncTransactions.isLoading)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
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
            else if (asyncTransactions.hasError)
              const SliverToBoxAdapter(child: SizedBox(height: 120))
            else if (visible.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                sliver: SliverToBoxAdapter(child: _Empty(query: _query)),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = visible[index];
                      final previous = index == 0 ? null : visible[index - 1];
                      final showDate = previous == null || !_sameDay(previous.date, item.date);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDate) ...[
                            if (index != 0) const SizedBox(height: 10),
                            _DateDivider(date: item.date),
                            const SizedBox(height: 8),
                          ],
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _TransactionTile(
                              item: item,
                              onTap: () => _detail(item),
                            ),
                          ),
                        ],
                      );
                    },
                    childCount: visible.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<TransactionModel> _visible(List<TransactionModel> items) {
    final query = _query.toLowerCase();
    final result = items.where((item) {
      if (_filter != null && item.type != _filter) return false;
      if (query.isEmpty) return true;
      return item.title.toLowerCase().contains(query) ||
          _category(item.category).toLowerCase().contains(query) ||
          (item.note ?? '').toLowerCase().contains(query);
    }).toList();

    result.sort((a, b) {
      final aDate = a.createdAt ?? a.date;
      final bDate = b.createdAt ?? b.date;
      return bDate.compareTo(aDate);
    });
    return result;
  }

  String _category(TransactionCategory category) => switch (category) {
        TransactionCategory.food => 'Makanan',
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

  Future<void> _openAddTransaction() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const MoneyFormPage(income: false),
      ),
    );
    if (mounted) ref.invalidate(recentTransactionsProvider);
  }

  void _openFilter() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (sheetContext) => _FilterSheet(
        selected: _filter,
        onSelected: (value) {
          setState(() => _filter = value);
          Navigator.pop(sheetContext);
        },
      ),
    );
  }

  Future<void> _detail(TransactionModel item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (sheetContext) => _Detail(
        item: item,
        category: _category(item.category),
        onEdit: () {
          Navigator.pop(sheetContext);
          if (item.isTransfer) {
            _message('Transfer tidak bisa diedit.');
            return;
          }
          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (_) => MoneyFormPage(
                income: item.isIncome,
                transaction: item,
              ),
            ),
          ).then((_) {
            if (mounted) ref.invalidate(recentTransactionsProvider);
          });
        },
        onDelete: () async {
          Navigator.pop(sheetContext);
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: AppColors.card,
              title: const Text('Hapus transaksi?'),
              content: Text(
                'Hapus ${item.title} sebesar ${rupiah(item.amount)}? Saldo dan ringkasan akan dihitung ulang.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Hapus'),
                ),
              ],
            ),
          );
          if (confirmed != true) return;
          try {
            await ref.read(financialTransactionStoreProvider.notifier).delete(item.id);
            if (mounted) {
              ref.invalidate(recentTransactionsProvider);
              _message('Transaksi berhasil dihapus.');
            }
          } catch (_) {
            if (mounted) _message('Gagal menghapus transaksi.');
          }
        },
      ),
    );
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Transaksi',
                      style: AppTypography.heading1.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 7),
                    const Icon(LucideIcons.sparkles, size: 16, color: AppColors.primaryLight),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Setiap rupiah, lebih mudah dipahami.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.primary.withValues(alpha: .16),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onAdd,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 46,
                height: 46,
                child: Icon(LucideIcons.plus, color: AppColors.primaryLight, size: 22),
              ),
            ),
          ),
        ],
      );
}

class _Search extends StatelessWidget {
  const _Search({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onFilter,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) => Container(
        height: 52,
        padding: const EdgeInsets.only(left: 14, right: 5),
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: .82),
          borderRadius: AppRadius.radiusXL,
          border: Border.all(color: AppColors.border.withValues(alpha: .35)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.search, size: 19, color: AppColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Cari transaksi, kategori, catatan...',
                  hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) => value.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      onPressed: onClear,
                      icon: const Icon(LucideIcons.x, size: 17),
                      color: AppColors.textMuted,
                      visualDensity: VisualDensity.compact,
                    ),
            ),
            IconButton(
              onPressed: onFilter,
              icon: const Icon(LucideIcons.listFilter, size: 18),
              color: AppColors.primaryLight,
              visualDensity: VisualDensity.compact,
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
    const filters = <_FilterData>[
      _FilterData('Semua', null),
      _FilterData('Masuk', TransactionType.income),
      _FilterData('Keluar', TransactionType.expense),
      _FilterData('Transfer', TransactionType.transfer),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = filters[index];
          final active = selected == item.type;
          return GestureDetector(
            onTap: () => onChanged(item.type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: active ? AppGradients.primary : null,
                color: active ? null : AppColors.card.withValues(alpha: .70),
                borderRadius: AppRadius.radiusPill,
                border: Border.all(
                  color: active
                      ? AppColors.primaryLight.withValues(alpha: .22)
                      : AppColors.border.withValues(alpha: .25),
                ),
              ),
              child: Text(
                item.label,
                style: AppTypography.caption.copyWith(
                  color: active ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterData {
  const _FilterData(this.label, this.type);

  final String label;
  final TransactionType? type;
}

class _Summary extends StatelessWidget {
  const _Summary({required this.items, required this.filter});

  final List<TransactionModel> items;
  final TransactionType? filter;

  @override
  Widget build(BuildContext context) {
    final income = items.where((item) => item.isIncome).fold<double>(0, (sum, item) => sum + item.amount);
    final expense = items.where((item) => item.isExpense).fold<double>(0, (sum, item) => sum + item.amount);
    final transfer = items.where((item) => item.isTransfer).fold<double>(0, (sum, item) => sum + item.amount);
    final net = income - expense;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF17102D), Color(0xFF0E1020)],
        ),
        borderRadius: AppRadius.radiusXXL,
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: .15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.sparkles, size: 14, color: AppColors.primaryLight),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  filter == null ? 'Financial snapshot' : 'Filtered snapshot',
                  style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '${items.length} transaksi',
                style: AppTypography.caption.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(child: _Metric(label: 'Masuk', value: income, color: AppColors.success)),
              const SizedBox(width: 8),
              Expanded(child: _Metric(label: 'Keluar', value: expense, color: AppColors.danger)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .025),
              borderRadius: AppRadius.radiusLG,
            ),
            child: Row(
              children: [
                Icon(
                  net >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                  size: 15,
                  color: net >= 0 ? AppColors.success : AppColors.danger,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Net cashflow',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                Text(
                  rupiah(net),
                  style: AppTypography.labelMedium.copyWith(
                    color: net >= 0 ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (transfer > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '• ${rupiah(transfer)} transfer',
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 8.5),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .12),
          borderRadius: AppRadius.radiusLG,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 4),
            FittedBox(
              alignment: Alignment.centerLeft,
              child: Text(
                '${label == 'Masuk' ? '+' : '-'}${rupiah(value)}',
                style: AppTypography.labelMedium.copyWith(color: color, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      );
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    final day = DateUtils.dateOnly(date);
    final label = day == today
        ? 'Hari ini'
        : day == yesterday
            ? 'Kemarin'
            : DateFormat('dd MMMM yyyy', 'id_ID').format(date);

    return Row(
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 9),
        Expanded(child: Divider(color: Colors.white.withValues(alpha: .055))),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.item, required this.onTap});

  final TransactionModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = item.isTransfer
        ? AppColors.info
        : item.isIncome
            ? AppColors.success
            : AppColors.danger;
    final icon = item.isTransfer
        ? LucideIcons.arrowLeftRight
        : item.isIncome
            ? LucideIcons.arrowDownLeft
            : LucideIcons.arrowUpRight;

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.radiusXL,
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: .72),
          borderRadius: AppRadius.radiusXL,
          border: Border.all(color: Colors.white.withValues(alpha: .045)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.radiusXL,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .10),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: .12)),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.isTransfer ? 'Transfer' : item.category.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 9),
                            ),
                          ),
                          if (item.note?.isNotEmpty == true) ...[
                            const SizedBox(width: 5),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                color: AppColors.textMuted,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                item.note!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 9),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        item.isTransfer
                            ? rupiah(item.amount)
                            : '${item.isIncome ? '+' : '-'}${rupiah(item.amount)}',
                        style: AppTypography.labelMedium.copyWith(color: color, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.isTransfer
                          ? 'Transfer'
                          : item.isIncome
                              ? 'Masuk'
                              : 'Keluar',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 3),
                const Icon(LucideIcons.chevronRight, size: 15, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({required this.selected, required this.onSelected});

  final TransactionType? selected;
  final ValueChanged<TransactionType?> onSelected;

  @override
  Widget build(BuildContext context) {
    const options = <_FilterData>[
      _FilterData('Semua transaksi', null),
      _FilterData('Pemasukan', TransactionType.income),
      _FilterData('Pengeluaran', TransactionType.expense),
      _FilterData('Transfer', TransactionType.transfer),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 26),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: .45),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Filter transaksi', style: AppTypography.heading3.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text(
              'Pilih arus uang yang ingin kamu fokuskan.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            for (final option in options)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => onSelected(option.type),
                  borderRadius: AppRadius.radiusLG,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: selected == option.type
                          ? AppColors.primary.withValues(alpha: .11)
                          : AppColors.card.withValues(alpha: .65),
                      borderRadius: AppRadius.radiusLG,
                      border: Border.all(
                        color: selected == option.type
                            ? AppColors.primaryLight.withValues(alpha: .20)
                            : Colors.white.withValues(alpha: .045),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option.label,
                            style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (selected == option.type)
                          const Icon(LucideIcons.check, size: 18, color: AppColors.primaryLight),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.item,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final TransactionModel item;
  final String category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = item.isTransfer
        ? AppColors.info
        : item.isIncome
            ? AppColors.success
            : AppColors.danger;
    final title = item.isTransfer
        ? 'Transfer'
        : item.isIncome
            ? 'Pemasukan'
            : 'Pengeluaran';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: .45),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .10),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: .13)),
                  ),
                  child: Icon(
                    item.isTransfer
                        ? LucideIcons.arrowLeftRight
                        : item.isIncome
                            ? LucideIcons.arrowDownLeft
                            : LucideIcons.arrowUpRight,
                    color: color,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.heading3.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppGradients.heroCard,
                borderRadius: AppRadius.radiusXL,
                border: Border.all(color: color.withValues(alpha: .12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nominal', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: 3),
                  FittedBox(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item.isTransfer
                          ? rupiah(item.amount)
                          : '${item.isIncome ? '+' : '-'}${rupiah(item.amount)}',
                      style: AppTypography.heading2.copyWith(color: color, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _Info(label: 'Kategori', value: category)),
                      Expanded(
                        child: _Info(
                          label: 'Tanggal',
                          value: DateFormat('dd MMM yyyy', 'id_ID').format(item.date),
                        ),
                      ),
                    ],
                  ),
                  if (item.note?.isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    _Info(label: 'Catatan', value: item.note!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (!item.isTransfer)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(LucideIcons.pencil, size: 16),
                      label: const Text('Edit'),
                    ),
                  ),
                if (!item.isTransfer) const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onDelete,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                    icon: const Icon(LucideIcons.trash2, size: 16),
                    label: const Text('Hapus'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: .06),
          borderRadius: AppRadius.radiusXL,
          border: Border.all(color: AppColors.danger.withValues(alpha: .12)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.triangleAlert, color: AppColors.danger, size: 18),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                message,
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 38, 22, 42),
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: .62),
          borderRadius: AppRadius.radiusXXL,
          border: Border.all(color: Colors.white.withValues(alpha: .045)),
        ),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: .10),
              ),
              child: const Icon(LucideIcons.searchX, color: AppColors.primaryLight, size: 25),
            ),
            const SizedBox(height: 12),
            Text(
              query.isEmpty ? 'Belum ada transaksi' : 'Tidak ada hasil',
              style: AppTypography.heading4.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              query.isEmpty
                  ? 'Catat pemasukan atau pengeluaran pertamamu untuk mulai membaca pola keuangan.'
                  : 'Coba kata kunci lain atau ubah filter transaksi.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.45),
            ),
          ],
        ),
      );
}
