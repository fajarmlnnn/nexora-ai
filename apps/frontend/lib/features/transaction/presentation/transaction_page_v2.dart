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
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncItems = ref.watch(recentTransactionsProvider);
    final items = asyncItems.valueOrNull ?? const <TransactionModel>[];
    final visible = _filterItems(items);

    return PremiumScaffold(
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: AppSpacing.screen,
              sliver: SliverToBoxAdapter(child: _Header(onAdd: _add)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _SearchBar(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                  onClear: () {
                    _search.clear();
                    setState(() => _query = '');
                  },
                  onFilter: _filterSheet,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _FilterChips(
                  selected: _filter,
                  onChanged: (v) => setState(() => _filter = v),
                ),
              ),
            ),
            if (asyncItems.isLoading)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                sliver: SliverList.builder(
                  itemCount: 6,
                  itemBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.only(bottom: 9),
                    child: ShimmerSkeleton(height: 82),
                  ),
                ),
              )
            else if (asyncItems.hasError)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                sliver: SliverToBoxAdapter(
                  child: _ErrorCard(onRetry: () => ref.invalidate(recentTransactionsProvider)),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(child: _Snapshot(items: visible)),
              ),
              if (visible.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                  sliver: SliverToBoxAdapter(child: _Empty(query: _query)),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                  sliver: SliverList.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final item = visible[index];
                      final previous = index == 0 ? null : visible[index - 1];
                      final newDay = previous == null || !_sameDay(previous.date, item.date);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (newDay) ...[
                            if (index > 0) const SizedBox(height: 9),
                            _DateLabel(item.date),
                            const SizedBox(height: 7),
                          ],
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _TransactionTile(item: item, onTap: () => _detail(item)),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  List<TransactionModel> _filterItems(List<TransactionModel> source) {
    final result = source.where((item) {
      if (_filter != null && item.type != _filter) return false;
      if (_query.isEmpty) return true;
      return item.title.toLowerCase().contains(_query) ||
          item.category.name.toLowerCase().contains(_query) ||
          (item.note ?? '').toLowerCase().contains(_query);
    }).toList();
    result.sort((a, b) => (b.createdAt ?? b.date).compareTo(a.createdAt ?? a.date));
    return result;
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _add() async {
    await Navigator.push<void>(context, MaterialPageRoute(builder: (_) => const MoneyFormPage(income: false)));
    if (mounted) ref.invalidate(recentTransactionsProvider);
  }

  void _filterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheet) => _FilterSheet(
        selected: _filter,
        onSelected: (v) {
          setState(() => _filter = v);
          Navigator.pop(sheet);
        },
      ),
    );
  }

  Future<void> _detail(TransactionModel item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) => _DetailSheet(
        item: item,
        onEdit: item.isTransfer ? null : () {
          Navigator.pop(sheet);
          Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => MoneyFormPage(income: item.isIncome, transaction: item)),
          ).then((_) {
            if (mounted) ref.invalidate(recentTransactionsProvider);
          });
        },
        onDelete: () async {
          Navigator.pop(sheet);
          final ok = await showDialog<bool>(
            context: context,
            builder: (dialog) => AlertDialog(
              backgroundColor: AppColors.card,
              title: const Text('Hapus transaksi?'),
              content: Text('Hapus ${item.title} sebesar ${rupiah(item.amount)}?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Batal')),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                  onPressed: () => Navigator.pop(dialog, true),
                  child: const Text('Hapus'),
                ),
              ],
            ),
          );
          if (ok != true) return;
          try {
            await ref.read(financialTransactionStoreProvider.notifier).delete(item.id);
            if (mounted) {
              ref.invalidate(recentTransactionsProvider);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaksi dihapus.')));
            }
          } catch (_) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghapus transaksi.')));
          }
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
                Row(children: [
                  Text('Transaksi', style: AppTypography.heading1.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(width: 7),
                  const Icon(LucideIcons.sparkles, size: 16, color: AppColors.primaryLight),
                ]),
                const SizedBox(height: 4),
                Text('Setiap rupiah, lebih mudah dipahami.', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Material(
            color: AppColors.primary.withValues(alpha: .16),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onAdd,
              customBorder: const CircleBorder(),
              child: const SizedBox(width: 46, height: 46, child: Icon(LucideIcons.plus, color: AppColors.primaryLight)),
            ),
          ),
        ],
      );
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged, required this.onClear, required this.onFilter});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) => Container(
        height: 52,
        padding: const EdgeInsets.only(left: 14, right: 4),
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: .82),
          borderRadius: AppRadius.radiusXL,
          border: Border.all(color: AppColors.border.withValues(alpha: .35)),
        ),
        child: Row(children: [
          const Icon(LucideIcons.search, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Cari transaksi atau kategori...',
                hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(onPressed: onClear, icon: const Icon(LucideIcons.x, size: 17), visualDensity: VisualDensity.compact),
          IconButton(onPressed: onFilter, icon: const Icon(LucideIcons.listFilter, size: 18), color: AppColors.primaryLight, visualDensity: VisualDensity.compact),
        ]),
      );
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onChanged});
  final TransactionType? selected;
  final ValueChanged<TransactionType?> onChanged;

  @override
  Widget build(BuildContext context) {
    const data = [
      ('Semua', null),
      ('Masuk', TransactionType.income),
      ('Keluar', TransactionType.expense),
      ('Transfer', TransactionType.transfer),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: data.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final active = selected == data[i].$2;
          return GestureDetector(
            onTap: () => onChanged(data[i].$2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: active ? AppGradients.primary : null,
                color: active ? null : AppColors.card.withValues(alpha: .70),
                borderRadius: AppRadius.radiusPill,
                border: Border.all(color: active ? AppColors.primaryLight.withValues(alpha: .20) : AppColors.border.withValues(alpha: .25)),
              ),
              child: Text(data[i].$1, style: AppTypography.caption.copyWith(color: active ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w800)),
            ),
          );
        },
      ),
    );
  }
}

class _Snapshot extends StatelessWidget {
  const _Snapshot({required this.items});
  final List<TransactionModel> items;

  @override
  Widget build(BuildContext context) {
    final income = items.where((x) => x.isIncome).fold<double>(0, (s, x) => s + x.amount);
    final expense = items.where((x) => x.isExpense).fold<double>(0, (s, x) => s + x.amount);
    final net = income - expense;
    final netColor = net >= 0 ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF18102F), Color(0xFF0E1020)]),
        borderRadius: AppRadius.radiusXXL,
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: .14)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(LucideIcons.sparkles, size: 15, color: AppColors.primaryLight),
          const SizedBox(width: 7),
          Expanded(child: Text('Financial snapshot', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w900))),
          Text('${items.length} transaksi', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _Stat(label: 'Masuk', value: income, color: AppColors.success)),
          const SizedBox(width: 8),
          Expanded(child: _Stat(label: 'Keluar', value: expense, color: AppColors.danger)),
        ]),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .025), borderRadius: AppRadius.radiusLG),
          child: Row(children: [
            Icon(net >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown, size: 15, color: netColor),
            const SizedBox(width: 7),
            Expanded(child: Text('Net cashflow', style: AppTypography.caption.copyWith(color: AppColors.textSecondary))),
            Text(rupiah(net), style: AppTypography.labelMedium.copyWith(color: netColor, fontWeight: FontWeight.w900)),
          ]),
        ),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: .12), borderRadius: AppRadius.radiusLG),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 3),
          FittedBox(alignment: Alignment.centerLeft, child: Text('${label == 'Masuk' ? '+' : '-'}${rupiah(value)}', style: AppTypography.labelMedium.copyWith(color: color, fontWeight: FontWeight.w900))),
        ]),
      );
}

class _DateLabel extends StatelessWidget {
  const _DateLabel(this.date);
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(date);
    final label = day == today
        ? 'Hari ini'
        : day == today.subtract(const Duration(days: 1))
            ? 'Kemarin'
            : DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    return Row(children: [
      Text(label, style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w800)),
      const SizedBox(width: 8),
      Expanded(child: Divider(color: Colors.white.withValues(alpha: .055))),
    ]);
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.item, required this.onTap});
  final TransactionModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = item.isTransfer ? AppColors.info : item.isIncome ? AppColors.success : AppColors.danger;
    final icon = item.isTransfer ? LucideIcons.arrowLeftRight : item.isIncome ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight;
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.radiusXL,
      child: Ink(
        decoration: BoxDecoration(color: AppColors.card.withValues(alpha: .72), borderRadius: AppRadius.radiusXL, border: Border.all(color: Colors.white.withValues(alpha: .045))),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.radiusXL,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: color.withValues(alpha: .09), shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: .12))),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(item.isTransfer ? 'Transfer' : item.category.name, style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 9)),
              ])),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                FittedBox(fit: BoxFit.scaleDown, child: Text(item.isTransfer ? rupiah(item.amount) : '${item.isIncome ? '+' : '-'}${rupiah(item.amount)}', style: AppTypography.labelMedium.copyWith(color: color, fontWeight: FontWeight.w900))),
                const SizedBox(height: 4),
                Text(item.isTransfer ? 'Transfer' : item.isIncome ? 'Masuk' : 'Keluar', style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 8, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(width: 3),
              const Icon(LucideIcons.chevronRight, size: 15, color: AppColors.textMuted),
            ]),
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
    const options = [
      ('Semua transaksi', null),
      ('Pemasukan', TransactionType.income),
      ('Pengeluaran', TransactionType.expense),
      ('Transfer', TransactionType.transfer),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: AppColors.textMuted.withValues(alpha: .45), borderRadius: BorderRadius.circular(99)))),
        const SizedBox(height: 18),
        Text('Filter transaksi', style: AppTypography.heading3.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: ListTile(
              onTap: () => onSelected(option.$2),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
              tileColor: selected == option.$2 ? AppColors.primary.withValues(alpha: .10) : AppColors.card.withValues(alpha: .60),
              title: Text(option.$1, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800)),
              trailing: selected == option.$2 ? const Icon(LucideIcons.check, color: AppColors.primaryLight) : null,
            ),
          ),
      ])),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({required this.item, required this.onEdit, required this.onDelete});
  final TransactionModel item;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = item.isTransfer ? AppColors.info : item.isIncome ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
      decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: AppColors.textMuted.withValues(alpha: .45), borderRadius: BorderRadius.circular(99)))),
        const SizedBox(height: 18),
        Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withValues(alpha: .10), shape: BoxShape.circle), child: Icon(item.isTransfer ? LucideIcons.arrowLeftRight : item.isIncome ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight, color: color)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.isTransfer ? 'Transfer' : item.isIncome ? 'Pemasukan' : 'Pengeluaran', style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.heading3.copyWith(fontWeight: FontWeight.w900)),
          ])),
        ]),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(gradient: AppGradients.heroCard, borderRadius: AppRadius.radiusXL, border: Border.all(color: color.withValues(alpha: .12))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Nominal', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 3),
            FittedBox(child: Text(item.isTransfer ? rupiah(item.amount) : '${item.isIncome ? '+' : '-'}${rupiah(item.amount)}', style: AppTypography.heading2.copyWith(color: color, fontWeight: FontWeight.w900))),
            const SizedBox(height: 10),
            Text(DateFormat('dd MMMM yyyy', 'id_ID').format(item.date), style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
            if (item.note?.isNotEmpty == true) ...[
              const SizedBox(height: 5),
              Text(item.note!, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
            ],
          ]),
        ),
        const SizedBox(height: 13),
        Row(children: [
          if (onEdit != null) Expanded(child: OutlinedButton.icon(onPressed: onEdit, icon: const Icon(LucideIcons.pencil, size: 16), label: const Text('Edit'))),
          if (onEdit != null) const SizedBox(width: 9),
          Expanded(child: FilledButton.icon(onPressed: onDelete, style: FilledButton.styleFrom(backgroundColor: AppColors.danger), icon: const Icon(LucideIcons.trash2, size: 16), label: const Text('Hapus'))),
        ]),
      ])),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: .06), borderRadius: AppRadius.radiusXL),
        child: Row(children: [
          const Icon(LucideIcons.triangleAlert, color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text('Data transaksi gagal dimuat.', style: AppTypography.caption.copyWith(color: AppColors.textSecondary))),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: AppColors.card.withValues(alpha: .62), borderRadius: AppRadius.radiusXXL),
        child: Column(children: [
          const Icon(LucideIcons.receiptText, color: AppColors.primaryLight, size: 28),
          const SizedBox(height: 12),
          Text(query.isEmpty ? 'Belum ada transaksi' : 'Tidak ada hasil', style: AppTypography.heading4.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(query.isEmpty ? 'Catat transaksi pertama untuk mulai membaca pola keuanganmu.' : 'Coba kata kunci atau filter lain.', textAlign: TextAlign.center, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4)),
        ]),
      );
}
