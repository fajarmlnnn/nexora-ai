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

class _AIPageState extends ConsumerState<AIPage>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _ai = AiApiService();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          'Halo! Aku Nexora AI.\nAku bisa membantumu menganalisis cashflow kamu, memberi insight, dan membantumu mengambil keputusan finansial yang lebih baik.\n\nAda yang bisa aku bantu hari ini? 😊',
      fromUser: false,
    ),
  ];

  late final AnimationController _floatController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..repeat(reverse: true);

  static const _quickStartPrompts = [
    _Prompt(
      'Cashflow',
      'Lihat pemasukan\ndan pengeluaran',
      'Bagaimana kondisi cashflow saya?',
      LucideIcons.chartNoAxesCombined,
    ),
    _Prompt(
      'Pengeluaran',
      'Kategori & analisis\npengeluaranmu',
      'Di kategori mana saya paling boros?',
      LucideIcons.receiptText,
    ),
    _Prompt(
      'Goals',
      'Pantau progres\ntarget finansialmu',
      'Bagaimana progres target finansial saya?',
      LucideIcons.goal,
    ),
  ];

  static const _quickActions = [
    _Prompt('Berikan ringkasan keuanganku', '', 'Berikan ringkasan keuanganku', LucideIcons.chartNoAxesCombined),
    _Prompt('Analisis pengeluaranku', '', 'Analisis pengeluaranku', LucideIcons.chartPie),
    _Prompt('Apakah aku bisa menabung lebih banyak?', '', 'Apakah aku bisa menabung lebih banyak?', LucideIcons.piggyBank),
    _Prompt('Rekomendasi financial planning', '', 'Rekomendasi financial planning', LucideIcons.sparkles),
  ];

  static const _duplicateWindow = Duration(seconds: 3);

  bool _isSending = false;
  String? _error;
  String? _lastFailedQuestion;
  String? _lastSubmittedQuestion;
  DateTime? _lastSubmittedAt;
  int? _activePromptIndex;

  @override
  void dispose() {
    _floatController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _normalizeQuestion(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  bool _isDuplicateSubmission(String text) {
    final normalized = _normalizeQuestion(text);
    if (normalized.isEmpty) return true;
    if (_isSending && _lastSubmittedQuestion == normalized) return true;
    final submittedAt = _lastSubmittedAt;
    return _lastSubmittedQuestion == normalized &&
        submittedAt != null &&
        DateTime.now().difference(submittedAt) < _duplicateWindow;
  }

  Future<void> _ask(String question) async {
    final text = question.trim();
    if (text.isEmpty || _isSending || _isDuplicateSubmission(text)) return;

    final normalized = _normalizeQuestion(text);
    final analytics = ref.read(financialAnalyticsProvider);
    final history = [
      for (final message in _messages)
        AiChatMessage(
          role: message.fromUser ? 'user' : 'assistant',
          content: message.text,
        ),
      AiChatMessage(role: 'user', content: text),
    ];

    _lastSubmittedQuestion = normalized;
    _lastSubmittedAt = DateTime.now();

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
        messages: history.length > 20
            ? history.sublist(history.length - 20)
            : history,
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
                'Halo! Aku Nexora AI.\nPercakapan baru siap. Ada kondisi keuangan yang ingin kamu pahami hari ini? 😊',
            fromUser: false,
          ),
        );
      _error = null;
      _lastFailedQuestion = null;
      _lastSubmittedQuestion = null;
      _lastSubmittedAt = null;
      _activePromptIndex = null;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      bottomPadding: false,
      child: Container(
        color: const Color(0xFF07080D),
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
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _Bubble(
                          text: _messages[index].text,
                          fromUser: _messages[index].fromUser,
                          isInitial: index == 0 && !_messages[index].fromUser,
                        ),
                        childCount: _messages.length,
                      ),
                    ),
                  ),
                  if (_isSending)
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                      sliver: SliverToBoxAdapter(child: _TypingBubble()),
                    ),
                  if (_error != null)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      sliver: SliverToBoxAdapter(
                        child: _ErrorBubble(
                          message: _error!,
                          onRetry: _lastFailedQuestion == null
                              ? null
                              : () => _ask(_lastFailedQuestion!),
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(child: _buildQuickActions()),
                ],
              ),
            ),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 5),
      child: Row(
        children: [
          const _HeaderIconButton(
            tooltip: 'Kembali',
            icon: LucideIcons.arrowLeft,
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .34),
                  blurRadius: 16,
                ),
              ],
            ),
            child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Nexora AI',
                  style: AppTypography.heading2.copyWith(fontSize: 22, height: 1.05),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
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
                    const SizedBox(width: 5),
                    Text(
                      'Assistant aktif',
                      style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const _HeaderIconButton(
            tooltip: 'Riwayat percakapan',
            icon: LucideIcons.history,
          ),
          const SizedBox(width: 6),
          _HeaderIconButton(
            tooltip: 'Percakapan baru',
            icon: LucideIcons.squarePen,
            onPressed: _startNewChat,
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: LayoutBuilder(
        builder: (context, outer) {
          final compact = outer.maxWidth < 350;
          final heroHeight = compact ? 304.0 : 314.0;
          final mascotSize = compact ? 104.0 : 114.0;
          return Container(
            height: heroHeight,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              borderRadius: AppRadius.radiusXXL,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF321272), Color(0xFF100B27), Color(0xFF090B15)],
                stops: [0, .48, 1],
              ),
              border: Border.all(
                color: AppColors.primaryLight.withValues(alpha: .36),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .22),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  top: 0,
                  right: 0,
                  child: _PoweredBadge(compact: compact),
                ),
                Positioned(
                  right: 7,
                  bottom: 14,
                  width: mascotSize,
                  height: mascotSize,
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _floatController,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, -2 * _floatController.value),
                        child: child,
                      ),
                      child: Image.asset(
                        'assets/mascot/nexora-analytic.png',
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: compact ? 196 : 220),
                      child: Padding(
                        padding: EdgeInsets.only(top: compact ? 36 : 38),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Hai Fajar! 👋',
                              style: AppTypography.heading3.copyWith(
                                fontSize: compact ? 18 : 20,
                                fontWeight: FontWeight.w500,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 5),
                            RichText(
                              text: TextSpan(
                                style: AppTypography.heading1.copyWith(
                                  fontSize: compact ? 25 : 28,
                                  height: 1.05,
                                ),
                                children: const [
                                  TextSpan(text: 'Aku '),
                                  TextSpan(
                                    text: 'Nexora',
                                    style: TextStyle(color: AppColors.primaryLight),
                                  ),
                                  TextSpan(text: ' AI'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              'Asisten finansial cerdas yang siap\nmembantumu kapan saja.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: .86),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _PrivacyCard(compact: compact),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPromptSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 0, 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Text('Mulai dari sini', style: AppTypography.heading2),
                const Spacer(),
                Text(
                  'Geser →',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 154,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(right: 16, bottom: 2),
              itemCount: _quickStartPrompts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final prompt = _quickStartPrompts[index];
                return _PromptCard(
                  prompt: prompt,
                  highlighted: _activePromptIndex == index,
                  enabled: !_isSending,
                  onTap: () {
                    setState(() => _activePromptIndex = index);
                    _ask(prompt.question);
                  },
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Text('Percakapan', style: AppTypography.heading2),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryLight.withValues(alpha: .16),
              ),
            ),
            child: Text('${_messages.length}', style: AppTypography.labelMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 15),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _quickActions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 56,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          final prompt = _quickActions[index];
          return _QuickActionButton(
            prompt: prompt,
            enabled: !_isSending,
            onTap: () => _ask(prompt.question),
          );
        },
      ),
    );
  }

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(minHeight: 58, maxHeight: 76),
          padding: const EdgeInsets.fromLTRB(6, 5, 5, 5),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1020).withValues(alpha: .98),
            borderRadius: BorderRadius.circular(29),
            border: Border.all(color: AppColors.primary.withValues(alpha: .42)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: .16),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .035),
                  border: Border.all(color: Colors.white.withValues(alpha: .09)),
                ),
                child: const Icon(
                  LucideIcons.mic,
                  color: AppColors.primaryLight,
                  size: 18,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !_isSending,
                  minLines: 1,
                  maxLines: 2,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (value) {
                    if (!value.contains('\n')) _ask(value);
                  },
                  style: AppTypography.bodySmall.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: _isSending
                        ? 'Nexora sedang berpikir...'
                        : 'Tanya apa saja tentang keuanganmu...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 7),
                    hintStyle: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _isSending ? null : () => _ask(_controller.text),
                child: Ink(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _isSending ? null : AppGradients.primary,
                    color: _isSending ? AppColors.cardMuted : null,
                  ),
                  child: Center(
                    child: _isSending
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            LucideIcons.arrowUpRight,
                            size: 20,
                            color: Colors.white,
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

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: const Color(0xFF111426).withValues(alpha: .82),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _PoweredBadge extends StatelessWidget {
  const _PoweredBadge({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF201445).withValues(alpha: .82),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .16),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.zap, size: 14, color: AppColors.primaryLight),
          const SizedBox(width: 5),
          Text(
            'AI Powered',
            style: AppTypography.labelMedium.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 178 : 188),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF23124F).withValues(alpha: .58),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryLight.withValues(alpha: .30),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .22),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                LucideIcons.shieldCheck,
                color: AppColors.primaryLight,
                size: 18,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Privasi aman', style: AppTypography.labelLarge),
                  const SizedBox(height: 1),
                  Text(
                    'Data kamu dienkripsi\ndan 100% aman.',
                    style: AppTypography.caption.copyWith(color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              LucideIcons.chevronRight,
              color: Colors.white,
              size: 16,
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
  const _Prompt(this.title, this.description, this.question, this.icon);
  final String title;
  final String description;
  final String question;
  final IconData icon;
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.prompt,
    required this.highlighted,
    required this.enabled,
    required this.onTap,
  });

  final _Prompt prompt;
  final bool highlighted;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      height: 150,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(12, 11, 10, 9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: highlighted
                    ? const [Color(0xFF321178), Color(0xFF171026)]
                    : const [Color(0xFF12162A), Color(0xFF090B14)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: highlighted
                    ? AppColors.primaryLight.withValues(alpha: .70)
                    : Colors.white.withValues(alpha: .10),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(
                    alpha: highlighted ? .18 : .06,
                  ),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: AppGradients.primary,
                  ),
                  child: Icon(prompt.icon, color: Colors.white, size: 20),
                ),
                const SizedBox(height: 7),
                Text(
                  prompt.title,
                  style: AppTypography.heading3.copyWith(fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Text(
                    prompt.description,
                    style: AppTypography.caption.copyWith(color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: .18),
                    ),
                    child: const Icon(
                      LucideIcons.arrowRight,
                      color: AppColors.primaryLight,
                      size: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.fromUser,
    required this.isInitial,
  });

  final String text;
  final bool fromUser;
  final bool isInitial;

  @override
  Widget build(BuildContext context) {
    if (isInitial) return _InitialAssistantBubble(text: text);

    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!fromUser)
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(right: 6, bottom: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.sparkles,
                  size: 12,
                  color: AppColors.primaryLight,
                ),
              ),
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: fromUser ? 255 : 300,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: fromUser
                      ? const Color(0xFF17142A)
                      : AppColors.card,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(15),
                    topRight: const Radius.circular(15),
                    bottomLeft: Radius.circular(fromUser ? 15 : 5),
                    bottomRight: Radius.circular(fromUser ? 5 : 15),
                  ),
                  border: Border.all(
                    color: fromUser
                        ? AppColors.primary.withValues(alpha: .22)
                        : AppColors.border,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: .055),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  text,
                  style: AppTypography.bodySmall.copyWith(
                    color: fromUser ? Colors.white : AppColors.textPrimary,
                    height: 1.4,
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

class _InitialAssistantBubble extends StatelessWidget {
  const _InitialAssistantBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final parts = text.split('Ada yang bisa aku bantu hari ini? 😊');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(left: 32, right: 42),
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF17162B), Color(0xFF0D1020)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: .07)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .07),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: RichText(
              text: TextSpan(
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: .88),
                  height: 1.48,
                ),
                children: [
                  TextSpan(text: parts.first.trim()),
                  const TextSpan(text: '\n'),
                  TextSpan(
                    text: 'Ada yang bisa aku bantu hari ini? 😊',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w700,
                      height: 1.48,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 14,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .28),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.sparkles,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 2,
            child: Container(
              width: 54,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(21),
                gradient: AppGradients.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .22),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.ellipsis,
                  color: Colors.white70,
                  size: 21,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.prompt,
    required this.enabled,
    required this.onTap,
  });

  final _Prompt prompt;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(17),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: const Color(0xFF111426).withValues(alpha: .9),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: .16),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  gradient: AppGradients.primary,
                ),
                child: Icon(prompt.icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  prompt.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white,
                    fontSize: 11.5,
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

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomRight: Radius.circular(15),
            bottomLeft: Radius.circular(5),
          ),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.sparkles,
              size: 13,
              color: AppColors.primaryLight,
            ),
            SizedBox(width: 6),
            SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.circleAlert,
            size: 18,
            color: AppColors.danger,
          ),
          AppSpacing.hGapSM,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nexora belum bisa menjawab',
                  style: AppTypography.label,
                ),
                const SizedBox(height: 3),
                Text(message, style: AppTypography.caption),
                if (onRetry != null) ...[
                  const SizedBox(height: 7),
                  TextButton.icon(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 30),
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
