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
    _Prompt(
      'Berikan ringkasan keuanganku',
      '',
      'Berikan ringkasan keuanganku',
      LucideIcons.chartNoAxesCombined,
    ),
    _Prompt(
      'Analisis pengeluaranku',
      '',
      'Analisis pengeluaranku',
      LucideIcons.chartPie,
    ),
    _Prompt(
      'Apakah aku bisa menabung lebih banyak?',
      '',
      'Apakah aku bisa menabung lebih banyak?',
      LucideIcons.piggyBank,
    ),
    _Prompt(
      'Rekomendasi financial planning',
      '',
      'Rekomendasi financial planning',
      LucideIcons.sparkles,
    ),
  ];

  static const _duplicateWindow = Duration(seconds: 3);

  bool _isSending = false;
  String? _error;
  String? _lastFailedQuestion;
  String? _lastSubmittedQuestion;
  DateTime? _lastSubmittedAt;

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
        messages:
            history.length > 20 ? history.sublist(history.length - 20) : history,
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverToBoxAdapter(child: _TypingBubble()),
                  ),
                if (_error != null)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          _HeaderIconButton(
            tooltip: 'Kembali',
            icon: LucideIcons.arrowLeft,
            onPressed: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 14),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .42),
                  blurRadius: 26,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 25),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Nexora AI', style: AppTypography.heading2),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Assistant aktif',
                      style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _HeaderIconButton(
            tooltip: 'Riwayat percakapan',
            icon: LucideIcons.history,
            onPressed: _scrollToBottom,
          ),
          const SizedBox(width: 10),
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
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Container(
        constraints: const BoxConstraints(minHeight: 250),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: AppRadius.radiusXXL,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF321272), Color(0xFF100B27), Color(0xFF090B15)],
            stops: [0, .48, 1],
          ),
          border: Border.all(color: AppColors.primaryLight.withValues(alpha: .36)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: .26),
              blurRadius: 34,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 350;
            return Stack(
              children: [
                Positioned(
                  top: 18,
                  right: 90,
                  child: Icon(
                    LucideIcons.sparkle,
                    color: AppColors.primaryLight.withValues(alpha: .8),
                    size: 18,
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 0,
                  child: _PoweredBadge(compact: compact),
                ),
                Positioned(
                  right: compact ? -12 : 0,
                  bottom: -2,
                  child: AnimatedBuilder(
                    animation: _floatController,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, -5 * _floatController.value),
                      child: child,
                    ),
                    child: Container(
                      width: compact ? 136 : 166,
                      height: compact ? 156 : 184,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: .24),
                            blurRadius: 46,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/mascot/nexora-analytic.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: compact ? 190 : 245),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: compact ? 42 : 58),
                      Text(
                        'Hai Fajar! 👋',
                        style: AppTypography.heading3.copyWith(
                          fontSize: compact ? 20 : 23,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: AppTypography.heading1.copyWith(
                            fontSize: compact ? 28 : 34,
                            height: 1.08,
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
                      const SizedBox(height: 16),
                      Text(
                        'Asisten finansial cerdas yang siap\nmembantumu kapan saja.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: .86),
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _PrivacyCard(compact: compact),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPromptSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 30, 0, 22),
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
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(right: 16),
              itemCount: _quickStartPrompts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final prompt = _quickStartPrompts[index];
                return _PromptCard(
                  prompt: prompt,
                  highlighted: index == 1,
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Text('Percakapan', style: AppTypography.heading2),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.primaryLight.withValues(alpha: .18)),
            ),
            child: Text('${_messages.length}', style: AppTypography.labelMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _quickActions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 64,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
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
        padding: EdgeInsets.fromLTRB(
          16,
          10,
          16,
          12 + MediaQuery.viewInsetsOf(context).bottom * 0,
        ),
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1020).withValues(alpha: .96),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: AppColors.primary.withValues(alpha: .45)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: .22),
                blurRadius: 26,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Semantics(
                button: true,
                label: 'Mikrofon',
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .04),
                    border: Border.all(color: Colors.white.withValues(alpha: .1)),
                  ),
                  child: const Icon(
                    LucideIcons.mic,
                    color: AppColors.primaryLight,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
                  style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: _isSending
                        ? 'Nexora sedang berpikir...'
                        : 'Tanya apa saja tentang keuanganmu...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTap: _isSending ? null : () => _ask(_controller.text),
                  child: Ink(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _isSending ? null : AppGradients.primary,
                      color: _isSending ? AppColors.cardMuted : null,
                      boxShadow: _isSending
                          ? null
                          : [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: .36),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                    ),
                    child: Center(
                      child: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              LucideIcons.arrowUpRight,
                              size: 25,
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

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
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
        horizontal: compact ? 9 : 12,
        vertical: compact ? 7 : 9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF201445).withValues(alpha: .82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: .22), blurRadius: 20),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.zap, size: 15, color: AppColors.primaryLight),
          const SizedBox(width: 7),
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
    return Container(
      width: compact ? 184 : 238,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF23124F).withValues(alpha: .58),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: .32)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              LucideIcons.shieldCheck,
              color: AppColors.primaryLight,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Privasi aman', style: AppTypography.labelLarge),
                const SizedBox(height: 3),
                Text(
                  'Data kamu dienkripsi\ndan 100% aman.',
                  style: AppTypography.caption.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, color: Colors.white, size: 18),
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
      width: 154,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: highlighted
                    ? const [Color(0xFF321178), Color(0xFF171026)]
                    : const [Color(0xFF12162A), Color(0xFF090B14)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: highlighted
                    ? AppColors.primaryLight.withValues(alpha: .72)
                    : Colors.white.withValues(alpha: .1),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: highlighted ? .2 : .08),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: AppGradients.primary,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: .28),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Icon(prompt.icon, color: Colors.white, size: 23),
                ),
                const Spacer(),
                Text(prompt.title, style: AppTypography.heading3.copyWith(fontSize: 16)),
                const SizedBox(height: 5),
                Text(
                  prompt.description,
                  style: AppTypography.caption.copyWith(color: Colors.white70),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: .2),
                    ),
                    child: const Icon(
                      LucideIcons.arrowRight,
                      color: AppColors.primaryLight,
                      size: 17,
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
                  color: AppColors.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.sparkles,
                  size: 14,
                  color: AppColors.primaryLight,
                ),
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

class _InitialAssistantBubble extends StatelessWidget {
  const _InitialAssistantBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final parts = text.split('Ada yang bisa aku bantu hari ini? 😊');
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(left: 38, right: 52),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF18162C), Color(0xFF0D1020)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withValues(alpha: .1), blurRadius: 22),
              ],
            ),
            child: RichText(
              text: TextSpan(
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: .88),
                  height: 1.55,
                ),
                children: [
                  TextSpan(text: parts.first.trim()),
                  const TextSpan(text: '\n'),
                  TextSpan(
                    text: 'Ada yang bisa aku bantu hari ini? 😊',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 20,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.primary,
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: .45), blurRadius: 24),
                ],
              ),
              child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 25),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 2,
            child: Container(
              width: 82,
              height: 62,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: AppGradients.primary,
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: .32), blurRadius: 24),
                ],
              ),
              child: const Center(
                child: Icon(LucideIcons.ellipsis, color: Colors.white70, size: 30),
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
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF111426).withValues(alpha: .9),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.primary.withValues(alpha: .18)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: AppGradients.primary,
                ),
                child: Icon(prompt.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
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
            SizedBox(
              width: 15,
              height: 15,
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
