import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../finance/state/financial_analytics_provider.dart';
import '../data/ai_api_service.dart';

// Nexora AI layout is intentionally kept local to this screen so the visual
// proportions can be tuned without changing the application's business logic.
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
      const Color(0xFF050715),
      const Color(0xFF170D3D),
    ),
    _Prompt(
      'Pengeluaran',
      'Kategori & analisis\npengeluaranmu',
      'Di kategori mana saya paling boros?',
      LucideIcons.receiptText,
      const Color(0xFF130B38),
      const Color(0xFF351D83),
    ),
    _Prompt(
      'Goals',
      'Pantau progres\ntarget finansialmu',
      'Bagaimana progres target finansial saya?',
      LucideIcons.goal,
      const Color(0xFF040615),
      const Color(0xFF19142E),
    ),
  ];

  static const _quickActions = [
    _Prompt(
      'Berikan ringkasan keuanganku',
      '',
      'Berikan ringkasan keuanganku',
      LucideIcons.chartNoAxesCombined,
      Color(0xFF0D0B31),
      Color(0xFF734ECA),
    ),
    _Prompt(
      'Analisis pengeluaranku',
      '',
      'Analisis pengeluaranku',
      LucideIcons.chartPie,
      Color(0xFF110947),
      Color(0xFF734ECA),
    ),
    _Prompt(
      'Apakah aku bisa menabung lebih banyak?',
      '',
      'Apakah aku bisa menabung lebih banyak?',
      LucideIcons.piggyBank,
      Color(0xFF0D0B31),
      Color(0xFF734ECA),
    ),
    _Prompt(
      'Rekomendasi financial planning',
      '',
      'Rekomendasi financial planning',
      LucideIcons.sparkles,
      Color(0xFF0D0B31),
      Color(0xFF8E5FF6),
    ),
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF00010A), Color(0xFF0A0A1F)],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
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
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
    return SizedBox(
      height: 70,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF8E5FF6), Color(0xFF4D25B1)],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x446633D9),
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
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nexora AI',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF27D96F),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Assistant aktif',
                        style: TextStyle(
                          color: Color(0xFFBDB9C9),
                          fontSize: 13,
                          height: 1,
                        ),
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
            const SizedBox(width: 8),
            _HeaderIconButton(
              tooltip: 'Percakapan baru',
              icon: LucideIcons.squarePen,
              onPressed: _startNewChat,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final heroHeight = width < 344 ? 220.0 : 208.0;
          final mascotSize = width < 344 ? 78.0 : 86.0;

          return Container(
            constraints: const BoxConstraints(minHeight: 180),
            height: heroHeight,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF170F48),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x665F42C8)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3A6632D9),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  top: 0,
                  right: 0,
                  child: _PoweredBadge(),
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
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
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 34),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: FractionallySizedBox(
                        widthFactor: width < 344 ? .66 : .68,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Hai Fajar! 👋',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: 'Aku '),
                                  TextSpan(
                                    text: 'Nexora',
                                    style: TextStyle(color: Color(0xFF9A70FF)),
                                  ),
                                  TextSpan(text: ' AI'),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 27,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Asisten finansial cerdas yang siap\nmembantumu kapan saja.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFFD8D3E3),
                                fontSize: 14,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const _PrivacyCard(),
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
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Mulai dari sini',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Geser →',
                  style: TextStyle(
                    color: Color(0xFF9A70FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _quickStartPrompts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
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
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          const Text(
            'Percakapan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF110947),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x443F238D)),
            ),
            child: Text(
              '${_messages.length}',
              style: const TextStyle(
                color: Color(0xFFC8B9FF),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _quickActions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 52,
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
    final media = MediaQuery.of(context);
    final systemBottom = math.max(media.viewPadding.bottom, media.viewInsets.bottom);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 16 + systemBottom,
      ),
      child: SizedBox(
        height: 64,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A091D),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x664D25B1)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2E6632D9),
                blurRadius: 20,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              _ComposerCircleButton(
                icon: LucideIcons.mic,
                color: const Color(0xFFAD90F5),
                onTap: _isSending ? null : () {},
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !_isSending,
                  minLines: 1,
                  maxLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _ask,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: _isSending
                        ? 'Nexora sedang berpikir...'
                        : 'Tanya apa saja tentang keuanganmu...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF6F6B7C),
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _ComposerCircleButton(
                icon: LucideIcons.arrowUpRight,
                color: const Color(0xFF4D25B1),
                onTap: _isSending ? null : () => _ask(_controller.text),
              ),
              const SizedBox(width: 8),
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
        color: const Color(0xFF0B0D1A),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x332F3453)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _PoweredBadge extends StatelessWidget {
  const _PoweredBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF090630),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x443D2B80)),
      ),
      alignment: Alignment.center,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.zap, size: 14, color: Color(0xFFAD90F5)),
          SizedBox(width: 6),
          Text(
            'AI Powered',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      width: 188,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF211B3E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x443D2B80)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF200B58),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.shieldCheck,
                color: Color(0xFFAD90F5),
                size: 19,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privasi aman',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Data kamu dienkripsi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFFBDB9C9),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
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

class _Prompt {
  const _Prompt(
    this.title,
    this.description,
    this.question,
    this.icon,
    this.cardColor,
    this.iconColor,
  );

  final String title;
  final String description;
  final String question;
  final IconData icon;
  final Color cardColor;
  final Color iconColor;
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
      width: 101,
      height: 92,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: highlighted ? const Color(0xFF351D83) : prompt.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: highlighted
                    ? const Color(0xFF8E5FF6)
                    : const Color(0x223C3A55),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: highlighted ? const Color(0xFF8E5FF6) : prompt.iconColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(prompt.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    prompt.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * .75,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: fromUser ? const Color(0xFF17142A) : const Color(0xFF0D0C19),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(fromUser ? 20 : 4),
              topRight: const Radius.circular(20),
              bottomLeft: const Radius.circular(20),
              bottomRight: Radius.circular(fromUser ? 4 : 20),
            ),
            border: Border.all(
              color: fromUser
                  ? const Color(0x332F2070)
                  : const Color(0x222E2A45),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFE4E0EA),
              fontSize: 14,
              height: 1.45,
            ),
          ),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.only(right: 12),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF6632D9),
            ),
            child: const Icon(
              LucideIcons.sparkles,
              color: Colors.white,
              size: 22,
            ),
          ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * .75,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0C19),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border.all(color: const Color(0x332E2A45)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x226632D9),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: Color(0xFFE4E0EA),
                    fontSize: 14,
                    height: 1.45,
                  ),
                  children: [
                    TextSpan(text: parts.first.trim()),
                    const TextSpan(text: '\n'),
                    TextSpan(
                      text: 'Ada yang bisa aku bantu hari ini? 😊',
                      style: const TextStyle(
                        color: Color(0xFF9A70FF),
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
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.only(left: 12, right: 10),
          decoration: BoxDecoration(
            color: prompt.cardColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x222F2A4A)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: prompt.iconColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(prompt.icon, color: Colors.white, size: 17),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  prompt.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
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

class _ComposerCircleButton extends StatelessWidget {
  const _ComposerCircleButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: const [
              BoxShadow(
                color: Color(0x226632D9),
                blurRadius: 10,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0C19),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x222E2A45)),
        ),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF9A70FF),
          ),
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
        color: const Color(0x331F0B19),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x553F1728)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.circleAlert,
            size: 18,
            color: Color(0xFFFF6B81),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nexora belum bisa menjawab',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFFBDB9C9),
                    fontSize: 11,
                  ),
                ),
                if (onRetry != null)
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
