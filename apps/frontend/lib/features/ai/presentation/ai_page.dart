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
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Gemini • Secure gateway',
                      style: AppTypography.caption.copyWith(color: Colors.white),
                    ),
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
      padding: const EdgeInsets.fromLTRB(16, 22, 0, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Text('Mulai dari sini', style: AppTypography.heading3),
                const Spacer(),
                Text('Geser →', style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              itemCount: _prompts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final prompt = _prompts[index];
                return _PromptCard(
                  prompt: prompt,
                  enabled: !_isSending,
                  onTap: () => _ask(prompt.question),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Text('Percakapan', style: AppTypography.heading3),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
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
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.7))),
        ),
        child: PremiumCard(
          padding: const EdgeInsets.fromLTRB(14, 8, 7, 8),
          borderRadius: AppRadius.radiusXL,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !_isSending,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (value) {
                    if (!value.contains('\n')) _ask(value);
                  },
                  decoration: InputDecoration(
                    hintText: _isSending ? 'Nexora sedang berpikir...' : 'Tanya soal keuanganmu...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 7),
                    hintStyle: AppTypography.bodySmall,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Material(
                color: _isSending ? AppColors.cardMuted : AppColors.primary,
                borderRadius: BorderRadius.circular(15),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: _isSending ? null : () => _ask(_controller.text),
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Center(
                      child: _isSending
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              LucideIcons.arrowUp,
                              size: 20,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
  const _Prompt(this.title, this.question, this.icon);

  final String title;
  final String question;
  final IconData icon;
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.prompt, required this.enabled, required this.onTap});

  final _Prompt prompt;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 172,
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(prompt.icon, size: 16, color: AppColors.primaryLight),
                ),
                const Spacer(),
                Text(prompt.title, style: AppTypography.label),
              ],
            ),
          ),
        ),
      ),
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
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!fromUser) ...[
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 8, bottom: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.sparkles, size: 14, color: AppColors.primaryLight),
              ),
            ],
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 330),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: fromUser ? AppGradients.button : null,
                  color: fromUser ? null : AppColors.card,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(fromUser ? 18 : 5),
                    bottomRight: Radius.circular(fromUser ? 5 : 18),
                  ),
                  border: fromUser ? null : Border.all(color: AppColors.border),
                ),
                child: Text(
                  text,
                  style: AppTypography.bodySmall.copyWith(
                    color: fromUser ? Colors.white : AppColors.textPrimary,
                    height: 1.45,
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

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(5),
          ),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.sparkles, size: 15, color: AppColors.primaryLight),
            SizedBox(width: 8),
            SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
      ),
    );
  }
}

class _ErrorBubble extends StatelessWidget {
  const _ErrorBubble({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.circleAlert, size: 19, color: AppColors.danger),
          AppSpacing.hGapSM,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nexora belum bisa menjawab', style: AppTypography.label),
                const SizedBox(height: 3),
                Text(message, style: AppTypography.caption),
                if (onRetry != null) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(LucideIcons.refreshCw, size: 15),
                    label: const Text('Coba lagi'),
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
