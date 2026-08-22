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
                child: _Header(
                  onAdd: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const MoneyFormPage(income: false),
                      ),
                    );
                  },
                ),
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
                  child: _ErrorCard(message: '${asyncTransactions.error}'),
                ),
              )
            else if (!asyncTransactions.isLoading)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(child: _Summary(items: visible)),
              ),
            if (asyncTransactions.isLoading)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: ShimmerSkeleton(height: 78),
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
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _TransactionTile(
                          item: item,
                          onTap: () => _detail(item),
                        ),
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

  List<TransactionModel> _visible(List<TransactionModel> items) {
    final query = _query.toLowerCase();
    final result = items.where((item) {
      final matchesType = _filter == null || item.type == _filter;
      if (!matchesType) return false;
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

  String _category(TransactionCategory category) {
    final name = category.name;
    if (name.isEmpty) return '-';
    return name[0].toUpperCase() + name.substring(1);
  }

  Future<void> _detail(TransactionModel item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _Detail(
          item: item,
          category: _category(item.category),
          onEdit: () {
            Navigator.pop(sheetContext);
            if (item.isTransfer) return;
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => MoneyFormPage(
                  income: item.isIncome,
                  transaction: item,
                ),
              ),
            );
          },
          onDelete: () async {
            Navigator.pop(sheetContext);
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (dialogContext) {
                return AlertDialog(
                  backgroundColor: AppColors.card,
                  title: const Text('Hapus transaksi?'),
                  content: Text(
                    'Hapus ${item.title} sebesar ${rupiah(item.amount)}?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Hapus'),
                    ),
                  ],
                );
              },
            );

            if (confirmed != true) return;
            await ref.read(financialTransactionStoreProvider.notifier).delete(item.id);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Transaksi dihapus.')),
            );
          },
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Transaksi', style: AppTypography.heading1.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                'Setiap rupiah, lebih mudah dipahami.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
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
}

class _Search extends StatelessWidget {
  const _Search({required this.controller, required this.onChanged, required this.onClear});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            builder: (context, value, child) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                onPressed: onClear,
                icon: const Icon(LucideIcons.x, size: 18),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.selected, required this.onChanged});

  final TransactionType? selected;
  final ValueChanged<TransactionType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final filters = <_FilterData>[
      const _FilterData('Semua', null),
      _FilterData('Masuk', TransactionType.income),
      _FilterData('Keluar', TransactionType.expense),
      _FilterData('Transfer', TransactionType.transfer),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final active = selected == filter.type;
          return ChoiceChip(
            label: Text(filter.label),
            selected: active,
            onSelected: (_) => onChanged(filter.type),
            selectedColor: AppColors.primary.withValues(alpha: .25),
            backgroundColor: AppColors.card.withValues(alpha: .7),
            side: BorderSide(
              color: active
                  ? AppColors.primaryLight.withValues(alpha: .55)
                  : AppColors.border.withValues(alpha: .25),
            ),
            labelStyle: TextStyle(
              color: active ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w800,
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
  const _Summary({required this.items});

  final List<TransactionModel> items;

  @override
  Widget build(BuildContext context) {
    final income = items.where((item) => item.isIncome).fold<double>(0, (sum, item) => sum + item.amount);
    final expense = items.where((item) => item.isExpense).fold<double>(0, (sum, item) => sum + item.amount);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppGradients.heroCard,
        borderRadius: AppRadius.radiusXXL,
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: .18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, size: 17, color: AppColors.primaryLight),
              const SizedBox(width: 7),
              Text('Snapshot', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w900)),
              const Spacer(),
              Text('${items.length} transaksi', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _SummaryMetric(label: 'Masuk', value: income, positive: true)),
              const SizedBox(width: 10),
              Expanded(child: _SummaryMetric(label: 'Keluar', value: expense, positive: false)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value, required this.positive});

  final String label;
  final double value;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              '${positive ? '+' : '-'}${rupiah(value)}',
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w900,
                color: positive ? AppColors.success : AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.item, required this.onTap});

  final TransactionModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final positive = item.isIncome;
    final color = item.isTransfer
        ? AppColors.info
        : positive
            ? AppColors.success
            : AppColors.danger;
    final icon = item.isTransfer
        ? LucideIcons.arrowLeftRight
        : positive
            ? LucideIcons.arrowDownLeft
            : LucideIcons.arrowUpRight;

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
                decoration: BoxDecoration(color: color.withValues(alpha: .12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.date.day.toString().padLeft(2, '0')} ${DateFormat('MMM', 'id_ID').format(item.date)} • ${item.note?.isNotEmpty == true ? item.note! : item.category.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${positive ? '+' : item.isTransfer ? '↔' : '-'}${rupiah(item.amount)}',
                    style: AppTypography.labelLarge.copyWith(color: color, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.item, required this.category, required this.onEdit, required this.onDelete});

  final TransactionModel item;
  final String category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final amountColor = item.isIncome
        ? AppColors.success
        : item.isTransfer
            ? AppColors.info
            : AppColors.danger;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: .16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: .4),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Transaction detail',
            style: AppTypography.caption.copyWith(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 5),
          Text(item.title, style: AppTypography.heading2.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(
            '${item.isIncome ? '+' : item.isTransfer ? '↔' : '-'}${rupiah(item.amount)}',
            style: AppTypography.heading1.copyWith(color: amountColor, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 20),
          _Info(label: 'Tanggal', value: DateFormat('EEEE, dd MMMM yyyy • HH:mm', 'id_ID').format(item.date)),
          _Info(label: 'Kategori', value: category),
          if (item.walletId != null) _Info(label: 'Wallet', value: item.walletId!),
          if (item.note?.isNotEmpty == true) _Info(label: 'Catatan', value: item.note!),
          if (item.isTransfer) ...[
            _Info(label: 'Dari', value: item.sourceAccount ?? '-'),
            _Info(label: 'Ke', value: item.destinationAccount ?? '-'),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (!item.isTransfer) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(LucideIcons.pencil),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(LucideIcons.trash2),
                  label: const Text('Hapus'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: .6),
        borderRadius: AppRadius.radiusXXL,
        border: Border.all(color: AppColors.border.withValues(alpha: .25)),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.searchX, size: 34, color: AppColors.primaryLight),
          const SizedBox(height: 10),
          Text(
            query.isEmpty ? 'Belum ada transaksi' : 'Transaksi tidak ditemukan',
            style: AppTypography.heading3,
          ),
          const SizedBox(height: 5),
          Text(
            query.isEmpty
                ? 'Mulai catat pemasukan dan pengeluaranmu.'
                : 'Coba kata kunci atau filter lain.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: .08),
        borderRadius: AppRadius.radiusXL,
        border: Border.all(color: AppColors.danger.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.triangleAlert, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppTypography.caption),
          ),
        ],
      ),
    );
  }
}
