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
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          'Halo! Aku Nexora AI. Aku bisa membaca ringkasan keuanganmu dan membantu kamu mengambil keputusan yang lebih aman.',
      fromUser: false,
    ),
  ];

  static const _prompts = [
    _Prompt('Cashflow', 'Bagaimana kondisi cashflow saya?', LucideIcons.chartNoAxesCombined),
    _Prompt('Pengeluaran', 'Di kategori mana saya paling boros?', LucideIcons.walletCards),
    _Prompt('Hemat', 'Apakah saya bisa hemat Rp 500.000?', LucideIcons.target),
    _Prompt('Prioritas', 'Kasih saya prioritas keuangan bulan ini', LucideIcons.listChecks),
  ];

  bool _isSending = false;
  String? _error;
  String? _lastFailedQuestion;

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
      _lastFailedQuestion = null;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final answer = await _ai.chat(
        messages: history.length > 8 ? history.sublist(history.length - 8) : history,
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
        _lastFailedQuestion = text;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _error = 'Terjadi kesalahan saat menghubungi Nexora AI.';
        _lastFailedQuestion = text;
      });
    }
    _scrollToBottom();
  }

  void _startNewChat() {
    if (_isSending) return;
    setState(() {
      _messages
        ..clear()
        ..add(
          const _ChatMessage(
            text:
                'Percakapan baru siap. Ceritakan kondisi keuangan yang ingin kamu pahami.',
            fromUser: false,
          ),
        );
      _error = null;
      _lastFailedQuestion = null;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
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
            child: CustomScrollView(
              controller: _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildHero()),
                SliverToBoxAdapter(child: _buildPromptSection()),
                SliverToBoxAdapter(child: _buildConversationHeader()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _Bubble(
                        text: _messages[index].text,
                        fromUser: _messages[index].fromUser,
                      ),
                      childCount: _messages.length,
                    ),
                  ),
                ),
                if (_isSending)
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverToBoxAdapter(child: _TypingBubble()),
                  ),
                if (_error != null)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    sliver: SliverToBoxAdapter(
                      child: _ErrorBubble(
                        message: _error!,
                        onRetry: _lastFailedQuestion == null
                            ? null
                            : () => _ask(_lastFailedQuestion!),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Kembali',
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(LucideIcons.arrowLeft, size: 21),
          ),
          const SizedBox(width: 2),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(LucideIcons.sparkles, size: 19, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nexora AI', style: AppTypography.title),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('Assistant aktif', style: AppTypography.caption),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Percakapan baru',
            onPressed: _startNewChat,
            icon: const Icon(LucideIcons.squarePen, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: PremiumCard(
        gradient: AppGradients.primary,
        padding: const EdgeInsets.all(18),
        borderRadius: AppRadius.radiusXL,
        child: Row(
          children: [
            const NexoraRobot(size: 72),
            AppSpacing.hGapMD,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Teman finansialmu',
                    style: AppTypography.heading3.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Tanya cashflow, pengeluaran, target, atau keputusan finansialmu.',
                    style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _prompts.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final prompt = _prompts[index];
            return _PromptChip(
              prompt: prompt,
              onTap: () => _ask(prompt.question),
            );
          },
        ),
      ),
    );
  }

  Widget _buildConversationHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 10, 28, 14),
      child: Row(
        children: [
          Text('Percakapan', style: AppTypography.heading3),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${_messages.length}', style: AppTypography.caption),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                minLines: 1,
                maxLines: 4,
                onSubmitted: _ask,
                decoration: const InputDecoration(
                  hintText: 'Tanya soal keuanganmu...',
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: _isSending ? null : () => _ask(_controller.text),
              icon: const Icon(LucideIcons.arrowUp),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.fromUser});

  final String text;
  final bool fromUser;
}

class _Prompt {
  const _Prompt(this.label, this.question, this.icon);

  final String label;
  final String question;
  final IconData icon;
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({required this.prompt, required this.onTap});

  final _Prompt prompt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(prompt.icon, size: 16),
      label: Text(prompt.label),
      onPressed: onTap,
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.fromUser});

  final String text;
  final bool fromUser;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        constraints: const BoxConstraints(maxWidth: 560),
        decoration: BoxDecoration(
          color: fromUser ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(text, style: AppTypography.body),
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
        padding: EdgeInsets.only(bottom: 12),
        child: Text('Nexora sedang mikir...'),
      ),
    );
  }
}

class _ErrorBubble extends StatelessWidget {
  const _ErrorBubble({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.circleAlert, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}
