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
      _transactionScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _editTransaction(TransactionModel item) async {
    if (item.isTransfer) {
      _showMessage('Transfer belum bisa diedit. Hapus lalu buat transfer baru jika diperlukan.');
      return;
    }

    await Navigator.of(context).push<TransactionModel>(
      MaterialPageRoute(
        builder: (_) => MoneyFormPage(
          income: item.isIncome,
          transaction: item,
        ),
      ),
    );
  }

  Future<void> _deleteTransaction(TransactionModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Hapus transaksi?'),
        content: Text(
          'Transaksi "${item.title}" sebesar ${rupiah(item.amount)} akan dihapus. Saldo wallet dan ringkasan keuangan akan dihitung ulang.',
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

    if (!mounted || confirmed != true) return;

    try {
      await ref.read(financialTransactionStoreProvider.notifier).delete(item.id);
      if (!mounted) return;
      _showMessage('Transaksi berhasil dihapus.');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Gagal menghapus transaksi: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(recentTransactionsProvider);

    return PremiumScaffold(
      child: Padding(
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
            const SizedBox(height: 10),
            Expanded(
              child: transactions.when(
                loading: () => ListView.separated(
                  controller: _transactionScrollController,
                  padding: EdgeInsets.only(
                    top: 8,
                    bottom: AppSpacing.bottomNav(context) + 28,
                  ),
                  itemCount: 6,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, _) => const ShimmerSkeleton(height: 68),
                ),
                error: (error, _) => Center(
                  child: EmptyStateCard(
                    icon: LucideIcons.triangleAlert,
                    title: 'Transaksi belum tersedia',
                    message: error.toString(),
                    action: 'Coba Lagi',
                  ),
                ),
                data: (items) {
                  final query = _query.toLowerCase();
                  final visible = items
                      .where((item) => filter == null || item.type == filter)
                      .where(
                        (item) =>
                            query.isEmpty ||
                            item.title.toLowerCase().contains(query) ||
                            _categoryLabel(item.category)
                                .toLowerCase()
                                .contains(query) ||
                            (item.isTransfer && 'transfer'.contains(query)),
                      )
                      .toList()
                    ..sort(_compareTransactionsNewestFirst);

                  if (visible.isEmpty) {
                    return _NoResults(query: _query);
                  }

                  return ListView(
                    key: ValueKey(filter),
                    controller: _transactionScrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      top: 8,
                      bottom: AppSpacing.bottomNav(context) + 28,
                    ),
                    children: _buildGroups(visible),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _compareTransactionsNewestFirst(TransactionModel a, TransactionModel b) {
    final occurred = b.date.compareTo(a.date);
    if (occurred != 0) return occurred;

    final aCreated = a.createdAt;
    final bCreated = b.createdAt;
    if (aCreated != null && bCreated != null) {
      final created = bCreated.compareTo(aCreated);
      if (created != 0) return created;
    } else if (aCreated != null) {
      return -1;
    } else if (bCreated != null) {
      return 1;
    }

    return b.id.compareTo(a.id);
  }

  List<Widget> _buildGroups(List<TransactionModel> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final groups = <String, List<TransactionModel>>{};

    for (final item in items) {
      final date = DateTime(item.date.year, item.date.month, item.date.day);
      final label = date == today
          ? 'Hari ini'
          : date == yesterday
              ? 'Kemarin'
              : DateFormat('dd MMM yyyy', 'id_ID').format(date);
      groups.putIfAbsent(label, () => <TransactionModel>[]).add(item);
    }

    return groups.entries
        .map(
          (entry) => _Group(
            title: entry.key,
            items: entry.value,
            onEdit: _editTransaction,
            onDelete: _deleteTransaction,
          ),
        )
        .toList();
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter transaksi',
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _SheetOption(
                label: 'Semua transaksi',
                selected: filter == null,
                onTap: () {
                  _setFilter(null);
                  Navigator.pop(sheetContext);
                },
              ),
              _SheetOption(
                label: 'Pemasukan',
                selected: filter == TransactionType.income,
                onTap: () {
                  _setFilter(TransactionType.income);
                  Navigator.pop(sheetContext);
                },
              ),
              _SheetOption(
                label: 'Pengeluaran',
                selected: filter == TransactionType.expense,
                onTap: () {
                  _setFilter(TransactionType.expense);
                  Navigator.pop(sheetContext);
                },
              ),
              _SheetOption(
                label: 'Transfer',
                selected: filter == TransactionType.transfer,
                onTap: () {
                  _setFilter(TransactionType.transfer);
                  Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _categoryLabel(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.food:
        return 'Makanan';
      case TransactionCategory.transport:
        return 'Transportasi';
      case TransactionCategory.shopping:
        return 'Belanja';
      case TransactionCategory.salary:
        return 'Gaji';
      case TransactionCategory.investment:
        return 'Investasi';
      case TransactionCategory.bills:
        return 'Tagihan';
      case TransactionCategory.entertainment:
        return 'Hiburan';
      case TransactionCategory.health:
        return 'Kesehatan';
      case TransactionCategory.education:
        return 'Pendidikan';
      case TransactionCategory.other:
        return 'Lainnya';
    }
  }
}

class _TransactionHeader extends StatelessWidget {
  const _TransactionHeader({required this.onFilter});

  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text('Transaksi', style: AppTypography.heading1),
        ),
        IconButton(
          onPressed: onFilter,
          icon: const Icon(LucideIcons.slidersHorizontal),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onFilter,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Cari transaksi...',
              prefixIcon: const Icon(LucideIcons.search),
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: AppRadius.radiusLG,
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: onFilter,
          icon: const Icon(LucideIcons.slidersHorizontal),
        ),
      ],
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.selected, required this.onChanged});

  final TransactionType? selected;
  final ValueChanged<TransactionType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = <(String, TransactionType?)>[
      ('Semua', null),
      ('Pemasukan', TransactionType.income),
      ('Pengeluaran', TransactionType.expense),
      ('Transfer', TransactionType.transfer),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in options) ...[
            ChoiceChip(
              label: Text(option.$1),
              selected: selected == option.$2,
              onSelected: (_) => onChanged(option.$2),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return EmptyStateCard(
      icon: LucideIcons.searchX,
      title: 'Tidak ada transaksi',
      message: query.isEmpty
          ? 'Belum ada transaksi sesuai filter.'
          : 'Tidak ada transaksi yang cocok dengan "$query".',
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        selected ? LucideIcons.circleCheck : LucideIcons.circle,
        color: selected ? AppColors.primaryLight : AppColors.textMuted,
      ),
      title: Text(label),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.title,
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final List<TransactionModel> items;
  final Future<void> Function(TransactionModel item) onEdit;
  final Future<void> Function(TransactionModel item) onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Text(
            title,
            style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        for (final item in items) ...[
          _TransactionTile(item: item, onEdit: onEdit, onDelete: onDelete),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final TransactionModel item;
  final Future<void> Function(TransactionModel item) onEdit;
  final Future<void> Function(TransactionModel item) onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = item.isIncome
        ? AppColors.success
        : item.isTransfer
            ? AppColors.primaryLight
            : AppColors.danger;
    final prefix = item.isIncome ? '+' : item.isTransfer ? '' : '-';

    return GestureDetector(
      onTap: () => onEdit(item),
      child: PremiumCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderRadius: AppRadius.radiusLG,
        child: Row(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor: accent.withValues(alpha: .12),
              child: Icon(
                item.isIncome
                    ? LucideIcons.arrowDownLeft
                    : item.isTransfer
                        ? LucideIcons.arrowLeftRight
                        : LucideIcons.arrowUpRight,
                color: accent,
                size: 19,
              ),
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
                  const SizedBox(height: 2),
                  Text(
                    '${_categoryLabel(item.category)} • ${DateFormat('dd MMM', 'id_ID').format(item.date)}',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$prefix${rupiah(item.amount)}',
                  style: AppTypography.labelMedium.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  onSelected: (value) {
                    if (value == 'edit') onEdit(item);
                    if (value == 'delete') onDelete(item);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Hapus')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.food:
        return 'Makanan';
      case TransactionCategory.transport:
        return 'Transportasi';
      case TransactionCategory.shopping:
        return 'Belanja';
      case TransactionCategory.salary:
        return 'Gaji';
      case TransactionCategory.investment:
        return 'Investasi';
      case TransactionCategory.bills:
        return 'Tagihan';
      case TransactionCategory.entertainment:
        return 'Hiburan';
      case TransactionCategory.health:
        return 'Kesehatan';
      case TransactionCategory.education:
        return 'Pendidikan';
      case TransactionCategory.other:
        return 'Lainnya';
    }
  }
}
