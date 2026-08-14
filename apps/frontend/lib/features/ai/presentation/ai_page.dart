import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../finance/state/financial_analytics_provider.dart';
import '../data/ai_api_service.dart';

class AIPage extends ConsumerStatefulWidget {
  const AIPage({super.key});

  @override
  ConsumerState<AIPage> createState() => _AIPageState();
}

class _AIPageState extends ConsumerState<AIPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _ai = AiApiService();
  final List<_ChatMessage> _messages = const [
    _ChatMessage(
      text: 'Halo! Aku Nexora AI. Aku bisa membaca ringkasan keuanganmu dan membantu membuat keputusan yang lebih aman.',
      fromUser: false,
    ),
  ].toList();

  static const _prompts = [
    'Bagaimana kondisi cashflow saya?',
    'Di kategori mana saya paling boros?',
    'Apakah saya bisa hemat Rp 500.000?',
    'Kasih saya prioritas keuangan bulan ini',
  ];

  bool _isSending = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _ask(String question) async {
    final text = question.trim();
    if (text.isEmpty || _isSending) return;

    final analytics = ref.read(financialAnalyticsProvider);
    final history = [
      for (final message in _messages)
        AiChatMessage(
          role: message.fromUser ? 'user' : 'assistant',
          content: message.text,
        ),
      AiChatMessage(role: 'user', content: text),
    ];

    setState(() {
      _messages.add(_ChatMessage(text: text, fromUser: true));
      _isSending = true;
      _error = null;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final answer = await _ai.chat(
        messages: history.length > 20 ? history.sublist(history.length - 20) : history,
        analytics: analytics,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(text: answer, fromUser: false));
        _isSending = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _error = 'Terjadi kesalahan saat menghubungi Nexora AI.';
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
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
                        'Aku Nexora AI. Jawabanku sekarang diproses oleh Gemini melalui server Laravel, dengan financial analytics yang sama seperti Reports.',
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
                        onPressed: _isSending ? null : () => _ask(prompt),
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
                if (_isSending) const _TypingBubble(),
                if (_error != null) ...[
                  _ErrorBubble(message: _error!),
                  AppSpacing.gapSM,
                  TextButton.icon(
                    onPressed: () => _ask(_messages.isNotEmpty && _messages.last.fromUser ? _messages.last.text : ''),
                    icon: const Icon(LucideIcons.refreshCw, size: 16),
                    label: const Text('Coba lagi'),
                  ),
                ],
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
                        enabled: !_isSending,
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
                      onPressed: _isSending ? null : () => _ask(_controller.text),
                      icon: _isSending
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(LucideIcons.sendHorizontal, color: AppColors.primaryLight),
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
              Flexible(
                child: Text(
                  text,
                  style: AppTypography.bodySmall.copyWith(color: fromUser ? Colors.white : null),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: PremiumCard(
          borderRadius: AppRadius.radiusXL,
          padding: EdgeInsets.all(14),
          child: SizedBox(
            height: 22,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.bot, size: 18, color: AppColors.primaryLight),
                SizedBox(width: 8),
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBubble extends StatelessWidget {
  const _ErrorBubble({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      borderRadius: AppRadius.radiusXL,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(LucideIcons.circleAlert, size: 20, color: AppColors.danger),
          AppSpacing.hGapSM,
          Expanded(child: Text(message, style: AppTypography.bodySmall)),
        ],
      ),
    );
  }
}
