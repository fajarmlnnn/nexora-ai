import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/nexora/nexora.dart';
import '../../../core/widgets/nexora_mascot.dart';
import '../../finance/state/financial_analytics_provider.dart';
import '../data/ai_api_service.dart';

class AIPageV2 extends ConsumerStatefulWidget {
  const AIPageV2({super.key});

  @override
  ConsumerState<AIPageV2> createState() => _AIPageV2State();
}

class _AIPageV2State extends ConsumerState<AIPageV2> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _service = AiApiService();
  final List<_Message> _messages = [];
  bool _sending = false;
  bool _checkingHealth = true;
  String? _error;
  AiGatewayHealth _health = const AiGatewayHealth(
    configured: false,
    reachable: false,
    message: 'Server AI belum dikonfigurasi',
  );

  static const _prompts = <_PromptData>[
    _PromptData('Ringkas keuanganku', 'Berikan ringkasan kondisi keuangan saya bulan ini berdasarkan income, expense, dan net cashflow yang dikirim.', LucideIcons.chartNoAxesCombined),
    _PromptData('Cari kebocoran', 'Dari kategori pengeluaran teratas yang dikirim, di mana saya paling boros?', LucideIcons.searchCheck),
    _PromptData('Cek tabungan', 'Bagaimana rasio tabungan saya bulan ini berdasarkan data yang dikirim?', LucideIcons.target),
  ];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final health = await _service.health();
    if (!mounted) return;
    setState(() {
      _health = health;
      _checkingHealth = false;
      _messages.add(_Message(false, _openingMessage(health)));
    });
  }

  String _openingMessage(AiGatewayHealth health) {
    if (!health.configured) {
      return 'Server AI belum dikonfigurasi. Nexora hanya mengirim ringkasan cashflow (pemasukan, pengeluaran, rasio tabungan, dan kategori teratas) jika gateway aktif.';
    }
    if (!health.reachable) {
      return '${health.message}. Kamu tetap bisa menulis pertanyaan, lalu coba kirim ulang setelah gateway siap.';
    }
    return 'Aku Nexora AI. Aku hanya membaca ringkasan cashflow yang dikirim aplikasi: pemasukan, pengeluaran, rasio tabungan, dan kategori pengeluaran teratas periode ini. Aku tidak membaca seluruh riwayat transaksi.';
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _ask(String value) async {
    final question = value.trim();
    if (question.isEmpty || _sending) return;
    if (!_health.configured) {
      setState(() => _error = 'Server AI belum dikonfigurasi');
      return;
    }

    final analytics = ref.read(financialAnalyticsProvider);
    final history = <AiChatMessage>[
      ..._messages.map((message) => AiChatMessage(role: message.user ? 'user' : 'assistant', content: message.text)),
      AiChatMessage(role: 'user', content: question),
    ];

    setState(() {
      _messages.add(_Message(true, question));
      _sending = true;
      _error = null;
    });
    _input.clear();
    _scrollDown();

    try {
      final trimmedHistory = history.length > 20 ? history.sublist(history.length - 20) : history;
      final answer = await _service.chat(messages: trimmedHistory, analytics: analytics);
      if (!mounted) return;
      setState(() {
        _messages.add(_Message(false, answer));
        _sending = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = 'Nexora AI belum dapat terhubung. Coba lagi.';
      });
    }
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(_scroll.position.maxScrollExtent, duration: AppMotion.normal, curve: AppMotion.standard);
    });
  }

  @override
  Widget build(BuildContext context) {
    return NexoraScaffold(
      appBar: NexoraAppBar(
        title: 'Nexora AI',
        subtitle: _health.message,
        actions: [
          NexoraIconButton(
            icon: LucideIcons.refreshCw,
            tooltip: 'Periksa status',
            onPressed: _checkingHealth
                ? null
                : () async {
                    setState(() => _checkingHealth = true);
                    final health = await _service.health();
                    if (!mounted) return;
                    setState(() {
                      _health = health;
                      _checkingHealth = false;
                    });
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: AppSpacing.screen,
              children: [
                const Center(child: NexoraMascot(size: 120, state: NexoraMascotState.analyzing)),
                const SizedBox(height: AppSpacing.md),
                NexoraBanner(
                  title: _health.ready ? 'Gateway AI siap' : 'Status gateway',
                  message: _health.message,
                  tone: _health.ready ? NexoraBannerTone.success : NexoraBannerTone.warning,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_messages.length <= 1)
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final prompt in _prompts)
                        NexoraChip(
                          label: prompt.title,
                          onSelected: _health.configured ? (_) => _ask(prompt.prompt) : null,
                        ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.md),
                if (_checkingHealth) const NexoraSkeleton(height: 72),
                for (final message in _messages) _Bubble(message: message),
                if (_sending) const Padding(padding: EdgeInsets.only(top: AppSpacing.sm), child: Text('Nexora sedang menulis jawaban...', style: AppTypography.caption)),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  NexoraEmpty(
                    error: true,
                    icon: LucideIcons.triangleAlert,
                    title: 'Pesan belum terkirim',
                    reason: _error!,
                    onPressed: () {
                      final previous = _messages.where((message) => message.user).toList();
                      if (previous.isEmpty) return;
                      _ask(previous.last.text);
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.huge),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: NexoraInput(
                      controller: _input,
                      hintText: _health.configured ? 'Tulis pertanyaan...' : 'Server AI belum dikonfigurasi',
                      enabled: _health.configured && !_sending,
                      onSubmitted: _ask,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  NexoraIconButton(
                    icon: LucideIcons.send,
                    tooltip: 'Kirim',
                    variant: NexoraIconButtonVariant.add,
                    onPressed: _health.configured && !_sending ? () => _ask(_input.text) : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final _Message message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: message.user ? AppColors.brandDeep : AppColors.surface,
          borderRadius: AppRadius.radiusLG,
          border: Border.all(color: AppColors.border),
        ),
        child: Text(message.text, style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary)),
      ),
    );
  }
}

class _Message {
  const _Message(this.user, this.text);
  final bool user;
  final String text;
}

class _PromptData {
  const _PromptData(this.title, this.prompt, this.icon);
  final String title;
  final String prompt;
  final IconData icon;
}
