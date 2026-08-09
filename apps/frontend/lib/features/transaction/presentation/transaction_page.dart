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
                  final expanded = [...items, ..._extraTransactions()]
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
                      .toList();

                  if (expanded.isEmpty) {
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
                    children: [
                      _Group(
                        title: 'Hari ini',
                        items: expanded.take(4).toList(),
                      ),
                      _Group(
                        title: 'Kemarin',
                        items: expanded.skip(4).take(2).toList(),
                      ),
                      _Group(
                        title: 'Sebelumnya',
                        items: expanded.skip(6).toList(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
}

class _TransactionHeader extends StatelessWidget {
  const _TransactionHeader({this.onFilter});

  final VoidCallback? onFilter;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Transaksi', style: AppTypography.heading1),
              const SizedBox(height: 1),
              Text('Pantau arus uangmu', style: AppTypography.bodySmall),
            ],
          ),
        ),
        Material(
          color: AppColors.card.withValues(alpha: .72),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onFilter,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                LucideIcons.slidersHorizontal,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    this.onFilter,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.radiusXL,
        border: Border.all(color: AppColors.border.withValues(alpha: .4)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.search, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Cari transaksi',
                hintStyle: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: const Icon(
                LucideIcons.x,
                size: 18,
                color: AppColors.textMuted,
              ),
            ),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onFilter,
            child: const Icon(
              LucideIcons.listFilter,
              color: AppColors.primaryLight,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.selected, required this.onChanged});

  final TransactionType? selected;
  final ValueChanged<TransactionType?> onChanged;

  int _index() {
    if (selected == TransactionType.income) return 1;
    if (selected == TransactionType.expense) return 2;
    if (selected == TransactionType.transfer) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: .68),
        borderRadius: AppRadius.radiusLG,
        border: Border.all(color: AppColors.border.withValues(alpha: .28)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / 4;
          final index = _index();
          return Stack(
            children: [
              AnimatedPositioned(
                left: itemWidth * index,
                top: 0,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: Container(
                  width: itemWidth,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: AppRadius.radiusMD,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: .22),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  _Tab(
                    label: 'Semua',
                    selected: selected == null,
                    onTap: () => onChanged(null),
                  ),
                  _Tab(
                    label: 'Masuk',
                    selected: selected == TransactionType.income,
                    onTap: () => onChanged(TransactionType.income),
                  ),
                  _Tab(
                    label: 'Keluar',
                    selected: selected == TransactionType.expense,
                    onTap: () => onChanged(TransactionType.expense),
                  ),
                  _Tab(
                    label: 'Transfer',
                    selected: selected == TransactionType.transfer,
                    onTap: () => onChanged(TransactionType.transfer),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: AppTypography.caption.copyWith(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.items});

  final String title;
  final List<TransactionModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 9, 0, 8),
          child: Row(
            children: [
              Text(
                title,
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Divider(
                  color: AppColors.border.withValues(alpha: .35),
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        for (final item in items) _TransactionTile(item: item),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _TransactionTile extends StatefulWidget {
  const _TransactionTile({required this.item});

  final TransactionModel item;

  @override
  State<_TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<_TransactionTile> {
  static const double _actionWidth = 76;
  static const double _openThreshold = 34;
  static const Duration _settleDuration = Duration(milliseconds: 190);

  double _offset = 0;
  bool _open = false;

  void _dragUpdate(DragUpdateDetails details) {
    setState(() {
      _offset = (_offset + details.delta.dx).clamp(-_actionWidth, 0.0);
    });
  }

  void _dragEnd(DragEndDetails details) {
    final shouldOpen =
        _offset.abs() >= _openThreshold ||
        details.velocity.pixelsPerSecond.dx < -450;
    setState(() {
      _open = shouldOpen;
      _offset = shouldOpen ? -_actionWidth : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final color = item.isIncome
        ? AppColors.success
        : item.isExpense
            ? AppColors.danger
            : AppColors.primaryLight;
    final prefix = item.isIncome
        ? '+'
        : item.isExpense
            ? '-'
            : '↔';

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: ClipRRect(
        borderRadius: AppRadius.radiusXL,
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: .12),
                  borderRadius: AppRadius.radiusXL,
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 18),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 100),
                  opacity: _offset < -8 ? 1 : .35,
                  child: const Icon(
                    LucideIcons.trash2,
                    color: AppColors.danger,
                    size: 20,
                  ),
                ),
              ),
            ),
            AnimatedContainer(
              duration: _settleDuration,
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(_offset, 0, 0),
              transformAlignment: Alignment.center,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: _dragUpdate,
                onHorizontalDragEnd: _dragEnd,
                onTap: () {
                  if (_open) {
                    setState(() {
                      _open = false;
                      _offset = 0;
                    });
                  }
                },
                child: PremiumCard(
                  borderRadius: AppRadius.radiusXL,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .13),
                          borderRadius: AppRadius.radiusLG,
                        ),
                        child: Icon(
                          item.isTransfer
                              ? LucideIcons.arrowLeftRight
                              : _icon(item.category),
                          color: color,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    item.isTransfer
                                        ? 'Transfer'
                                        : _categoryLabel(item.category),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.caption,
                                  ),
                                ),
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
                                    DateFormat('dd MMM').format(item.date),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.caption,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$prefix${rupiah(item.amount)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: AppTypography.labelMedium.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 70),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.searchX,
                color: AppColors.primaryLight,
                size: 25,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Transaksi tidak ditemukan',
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              query.isEmpty
                  ? 'Belum ada transaksi pada filter ini.'
                  : 'Coba gunakan kata kunci lain.',
              textAlign: TextAlign.center,
              style: AppTypography.caption,
            ),
          ],
        ),
      ),
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
      dense: true,
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      title: Text(
        label,
        style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
      ),
      trailing: Icon(
        selected ? LucideIcons.circleCheck : LucideIcons.circle,
        size: 20,
        color: selected ? AppColors.primaryLight : AppColors.textMuted,
      ),
    );
  }
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

List<TransactionModel> _extraTransactions() => [
      TransactionModel(
        id: '4',
        title: 'Grab Bike',
        amount: 27000,
        type: TransactionType.expense,
        category: TransactionCategory.transport,
        date: DateTime.now(),
      ),
      TransactionModel(
        id: '5',
        title: 'Coffee',
        amount: 18000,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
      TransactionModel(
        id: '6',
        title: 'Freelance Project',
        amount: 3500000,
        type: TransactionType.income,
        category: TransactionCategory.investment,
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
      TransactionModel(
        id: '7',
        title: 'Monthly Groceries',
        amount: 650000,
        type: TransactionType.expense,
        category: TransactionCategory.shopping,
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
];

String _categoryLabel(TransactionCategory category) {
  final name = category.name;
  return '${name[0].toUpperCase()}${name.substring(1)}';
}
