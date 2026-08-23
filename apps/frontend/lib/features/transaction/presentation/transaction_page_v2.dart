import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/nexora/nexora.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../dashboard/models/transaction_model.dart';
import '../../finance/state/financial_transaction_store.dart';
import '../../forms/presentation/money_form_page.dart';
import '../../wallet/controllers/wallet_controller.dart';

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
    final store = ref.watch(financialTransactionStoreProvider.notifier);
    final items = asyncTransactions.valueOrNull ?? const <TransactionModel>[];
    final visible = _visible(items);
    final grouped = _groupByDate(visible);

    return NexoraScaffold(
      body: RefreshIndicator.adaptive(
        color: AppColors.brandBright,
        backgroundColor: AppColors.surface,
        onRefresh: () => store.reload(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverPadding(
              padding: AppSpacing.screen.copyWith(bottom: 0),
              sliver: SliverToBoxAdapter(
                child: NexoraInlineHeader(
                  title: 'Transaksi',
                  subtitle: 'Pemasukan, pengeluaran, dan transfer',
                  actions: [
                    NexoraIconButton(
                      icon: LucideIcons.plus,
                      tooltip: 'Tambah transaksi',
                      onPressed: () => NexoraTransactionChooser.show(
                        context,
                        onIncome: () => context.push('/add-income'),
                        onExpense: () => context.push('/add-expense'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenGutter, AppSpacing.md, AppSpacing.screenGutter, 0),
              sliver: SliverToBoxAdapter(
                child: NexoraInput(
                  controller: _searchController,
                  hintText: 'Cari transaksi, kategori, catatan...',
                  prefix: const Icon(LucideIcons.search, size: 18, color: AppColors.textMuted),
                  onChanged: (value) => setState(() => _query = value.trim()),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenGutter, AppSpacing.sm, AppSpacing.screenGutter, 0),
              sliver: SliverToBoxAdapter(
                child: Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    NexoraChip(label: 'Semua', selected: _filter == null, onSelected: (_) => setState(() => _filter = null)),
                    NexoraChip(label: 'Masuk', selected: _filter == TransactionType.income, onSelected: (_) => setState(() => _filter = TransactionType.income)),
                    NexoraChip(label: 'Keluar', selected: _filter == TransactionType.expense, onSelected: (_) => setState(() => _filter = TransactionType.expense)),
                    NexoraChip(label: 'Transfer', selected: _filter == TransactionType.transfer, onSelected: (_) => setState(() => _filter = TransactionType.transfer)),
                  ],
                ),
              ),
            ),
            if (asyncTransactions.hasError)
              SliverPadding(
                padding: AppSpacing.screen,
                sliver: SliverToBoxAdapter(
                  child: NexoraEmpty(
                    error: true,
                    title: 'Transaksi belum dapat dimuat',
                    reason: 'Coba muat ulang daftar transaksi.',
                    onPressed: () => store.reload(),
                  ),
                ),
              )
            else if (asyncTransactions.isLoading)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screenGutter, AppSpacing.md, AppSpacing.screenGutter, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                      child: NexoraSkeleton(height: 64),
                    ),
                    childCount: 6,
                  ),
                ),
              )
            else if (visible.isEmpty)
              SliverPadding(
                padding: AppSpacing.screen.copyWith(bottom: 120),
                sliver: SliverToBoxAdapter(
                  child: NexoraEmpty(
                    icon: LucideIcons.receipt,
                    title: _query.isEmpty ? 'Belum ada transaksi' : 'Transaksi tidak ditemukan',
                    reason: _query.isEmpty ? 'Mulai catat pemasukan dan pengeluaranmu.' : 'Coba kata kunci atau filter lain.',
                    ctaLabel: _query.isEmpty ? 'Tambah transaksi' : null,
                    onPressed: _query.isEmpty
                        ? () => NexoraTransactionChooser.show(
                              context,
                              onIncome: () => context.push('/add-income'),
                              onExpense: () => context.push('/add-expense'),
                            )
                        : null,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screenGutter, AppSpacing.md, AppSpacing.screenGutter, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = grouped[index];
                      if (entry.header != null) {
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
                          child: Text(entry.header!, style: AppTypography.overline),
                        );
                      }
                      final item = entry.item!;
                      return NexoraTransactionTile(
                        title: item.title,
                        amount: item.amount,
                        type: item.isIncome
                            ? NexoraTransactionType.income
                            : item.isTransfer
                                ? NexoraTransactionType.transfer
                                : NexoraTransactionType.expense,
                        category: item.category.labelId,
                        date: DateFormat('HH.mm', 'id_ID').format(item.date),
                        onTap: () => _detail(item),
                      );
                    },
                    childCount: grouped.length,
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
          item.category.labelId.toLowerCase().contains(query) ||
          (item.note ?? '').toLowerCase().contains(query);
    }).toList();
    result.sort((a, b) {
      final aDate = a.createdAt ?? a.date;
      final bDate = b.createdAt ?? b.date;
      return bDate.compareTo(aDate);
    });
    return result;
  }

  List<_GroupEntry> _groupByDate(List<TransactionModel> items) {
    final entries = <_GroupEntry>[];
    String? lastHeader;
    for (final item in items) {
      final header = _dateHeader(item.date);
      if (header != lastHeader) {
        entries.add(_GroupEntry(header: header));
        lastHeader = header;
      }
      entries.add(_GroupEntry(item: item));
    }
    return entries;
  }

  String _dateHeader(DateTime date) {
    final now = DateTime.now();
    if (DateUtils.isSameDay(now, date)) return 'Hari ini';
    if (DateUtils.isSameDay(now.subtract(const Duration(days: 1)), date)) return 'Kemarin';
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
  }

  Future<void> _detail(TransactionModel item) async {
    await NexoraTransactionDetail.show(
      context,
      transaction: item,
      walletName: NexoraTransactionDetail.walletNameFor(item, ref.read(visibleWalletsProvider)),
      sourceWalletName: item.sourceAccount,
      destinationWalletName: item.destinationAccount,
      onEdit: item.isTransfer
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => MoneyFormPage(income: item.isIncome, transaction: item),
                ),
              );
            },
      onDelete: () async {
        final confirmed = await NexoraDialog.confirm(
          context,
          title: 'Hapus transaksi?',
          message: 'Hapus ${item.title} sebesar ${rupiah(item.amount)}?',
          confirmLabel: 'Hapus',
          danger: true,
        );
        if (!confirmed) return;
        await ref.read(financialTransactionStoreProvider.notifier).delete(item.id);
        if (!mounted) return;
        NexoraToast.show(context, 'Transaksi dihapus.');
      },
    );
  }
}

class _GroupEntry {
  const _GroupEntry({this.header, this.item});
  final String? header;
  final TransactionModel? item;
}
