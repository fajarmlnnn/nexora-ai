import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../finance/state/financial_analytics_provider.dart';

class AIPage extends ConsumerStatefulWidget {
  const AIPage({super.key});

  @override
  ConsumerState<AIPage> createState() => _AIPageState();
}

class _AIPageState extends ConsumerState<AIPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text: 'Halo! Aku Nexora AI. Aku bisa membaca ringkasan keuanganmu dan membantu membuat keputusan yang lebih aman.',
      fromUser: false,
    ),
  ];

  static const _prompts = [
    'Bagaimana kondisi cashflow saya?',
    'Di kategori mana saya paling boros?',
    'Apakah saya bisa hemat Rp 500.000?',
    'Kasih saya prioritas keuangan bulan ini',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _ask(String question) {
    final text = question.trim();
    if (text.isEmpty) return;
    final analytics = ref.read(financialAnalyticsProvider);

    setState(() {
      _messages.add(_ChatMessage(text: text, fromUser: true));
      _messages.add(_ChatMessage(text: _answer(text, analytics), fromUser: false));
    });
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  String _answer(String question, FinancialAnalyticsSnapshot data) {
    final q = question.toLowerCase();
    final top = data.topExpenseCategory;
    final topName = top == null ? null : _categoryName(top.key.name);
    final topValue = top?.value ?? 0;

    if (q.contains('cashflow') || q.contains('arus')) {
      if (data.income <= 0 && data.expense <= 0) {
        return 'Belum ada pemasukan atau pengeluaran yang tercatat untuk periode ini. Tambahkan transaksi dulu supaya analisis cashflow punya data yang cukup.';
      }
      final direction = data.netCashflow >= 0 ? 'positif' : 'negatif';
      return 'Cashflow bulan ini $direction: pemasukan ${_rupiah(data.income)}, pengeluaran ${_rupiah(data.expense)}, sehingga net cashflow ${_signed(data.netCashflow)}. Saving rate sekitar ${(data.savingsRate * 100).clamp(0, 100).toStringAsFixed(0)}%.';
    }

    if (q.contains('boros') || q.contains('kategori') || q.contains('pengeluaran')) {
      if (topName == null) return 'Belum ada pengeluaran yang tercatat bulan ini, jadi belum ada kategori yang bisa dibandingkan.';
      return 'Kategori pengeluaran terbesar saat ini adalah $topName sebesar ${_rupiah(topValue)}. Mulai dari kategori ini kalau targetmu adalah memangkas pengeluaran tanpa mengganggu kebutuhan utama.';
    }

    if (q.contains('500') || q.contains('hemat') || q.contains('saving') || q.contains('tabung')) {
      if (data.netCashflow <= 0) {
        return 'Target hemat Rp 500.000 belum aman kalau cashflow masih negatif. Prioritas pertama: hentikan defisit, lalu tetapkan target tabungan dari surplus yang benar-benar tersisa.';
      }
      final target = 500000.0;
      final gap = target - data.netCashflow;
      if (gap <= 0) {
        return 'Secara arus kas, surplus bulan ini sudah mencapai ${_rupiah(data.netCashflow)}, jadi target hemat Rp 500.000 secara matematis sudah terlampaui. Tetap sisakan buffer untuk kewajiban dan pengeluaran tak terduga.';
      }
      return 'Surplus saat ini ${_rupiah(data.netCashflow)}. Untuk mencapai Rp 500.000, kamu masih perlu memperbesar surplus sekitar ${_rupiah(gap)}. Fokus dulu pada ${topName ?? 'pengeluaran terbesar'} karena itu memberi ruang penghematan paling jelas.';
    }

    if (q.contains('prioritas') || q.contains('bulan ini') || q.contains('rekomendasi')) {
      if (data.netCashflow < 0) {
        return 'Prioritas 1: hentikan defisit. Prioritas 2: pangkas kategori pengeluaran terbesar. Prioritas 3: jangan menaikkan target tabungan sebelum cashflow kembali positif.';
      }
      if (data.savingsRate < 0.10) {
        return 'Cashflow sudah positif, tetapi saving rate masih di bawah 10%. Prioritas bulan ini adalah membangun buffer dengan menyisihkan sebagian surplus sebelum uang habis untuk pengeluaran lain.';
      }
      return 'Kondisi bulan ini cukup sehat. Pertahankan cashflow positif, amankan dana untuk kebutuhan wajib, lalu arahkan sebagian surplus ke goal utama sebelum menambah pengeluaran baru.';
    }

    return 'Aku bisa bantu dari data finansial bulan ini. Coba tanyakan cashflow, kategori pengeluaran terbesar, target hemat Rp 500.000, atau prioritas keuangan bulan ini.';
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      bottomPadding: false,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: AppSpacing.screen.copyWith(bottom: 16),
              children: [
                Row(
                  children: [
                    BackButton(color: AppColors.textPrimary, onPressed: () => Navigator.maybePop(context)),
                    const Spacer(),
                    Text('AI Assistant', style: AppTypography.heading2),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
                AppSpacing.gapLG,
                PremiumCard(
                  gradient: AppGradients.primary,
                  child: Column(
                    children: [
                      const NexoraRobot(size: 142),
                      AppSpacing.gapSM,
                      Text('Hai! 👋', style: AppTypography.heading2),
                      Text(
                        'Aku Nexora AI. Tanya soal cashflow dan pola pengeluaranmu. Jawabanku memakai financial analytics yang sama dengan Reports.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapLG,
                const SectionHeader('Suggested prompts'),
                AppSpacing.gapMD,
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final prompt in _prompts)
                      ActionChip(
                        label: Text(prompt),
                        onPressed: () => _ask(prompt),
                        backgroundColor: AppColors.card,
                        labelStyle: AppTypography.caption.copyWith(color: AppColors.textPrimary),
                        side: const BorderSide(color: AppColors.border),
                      ),
                  ],
                ),
                AppSpacing.gapLG,
                const SectionHeader('Conversation'),
                AppSpacing.gapMD,
                for (final message in _messages)
                  _Bubble(text: message.text, fromUser: message.fromUser),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: PremiumCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                borderRadius: AppRadius.radiusXL,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _ask,
                        decoration: const InputDecoration(
                          hintText: 'Tanya soal keuanganmu...',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _ask(_controller.text),
                      icon: const Icon(LucideIcons.sendHorizontal, color: AppColors.primaryLight),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.fromUser});
  final String text;
  final bool fromUser;
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.fromUser});
  final String text;
  final bool fromUser;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 330),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: fromUser ? AppGradients.button : null,
            color: fromUser ? null : AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: fromUser ? null : Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!fromUser) ...[
                const Icon(LucideIcons.bot, size: 18, color: AppColors.primaryLight),
                AppSpacing.hGapSM,
              ],
              Flexible(child: Text(text, style: AppTypography.bodySmall.copyWith(color: fromUser ? Colors.white : null))),
            ],
          ),
        ),
      ),
    );
  }
}

String _rupiah(double value) => 'Rp ${value.round().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

String _signed(double value) => value >= 0 ? '+${_rupiah(value)}' : '-${_rupiah(value.abs())}';

String _categoryName(String value) {
  final normalized = value.replaceAll('_', ' ');
  return normalized.isEmpty ? 'lainnya' : '${normalized[0].toUpperCase()}${normalized.substring(1)}';
}
