import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
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

  final List<_ChatMessage> _messages = <_ChatMessage>[
    const _ChatMessage(
      text:
          'Halo! Aku Nexora AI.\nAku bisa membantumu menganalisis cashflow kamu, memberi insight, dan membantumu mengambil keputusan finansial yang lebih baik.\n\nAda yang bisa aku bantu hari ini? 😊',
      fromUser: false,
    ),
  ];

  static const _quickStartPrompts = <_Prompt>[
    _Prompt(
      'Cashflow',
      'Lihat pemasukan\ndan pengeluaran',
      'Bagaimana kondisi cashflow saya?',
      LucideIcons.chartNoAxesCombined,
      Color(0xFF050715),
      Color(0xFF170D3D),
    ),
    _Prompt(
      'Pengeluaran',
      'Kategori & analisis\npengeluaranmu',
      'Di kategori mana saya paling boros?',
      LucideIcons.receiptText,
      Color(0xFF050715),
      Color(0xFF170D3D),
    ),
    _Prompt(
      'Goals',
      'Pantau progres\ntarget finansialmu',
      'Bagaimana progres target finansial saya?',
      LucideIcons.goal,
      Color(0xFF040615),
      Color(0xFF19142E),
    ),
  ];

  static const _quickActions = <_Prompt>[
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

  @override
  void dispose() {
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
    final history = <AiChatMessage>[
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
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF00010A),
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF00010A), Color(0xFF0A0A1F)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: CustomScrollView(
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
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
              Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
                child: _buildComposer(),
              ),
            ],
          ),
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
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF8E5FF6), Color(0xFF4D25B1)],
                ),
              ),
              child: const Icon(
                LucideIcons.sparkles,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nexora AI',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFF27D96F),
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox(width: 7, height: 7),
                      ),
                      SizedBox(width: 5),
                      Text(
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
      child: Container(
        constraints: const BoxConstraints(minHeight: 180),
        height: 208,
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
          clipBehavior: Clip.none,
          children: [
            const Positioned(
              top: 0,
              right: 0,
              child: _PoweredBadge(),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              width: 94,
              height: 94,
              child: Image.asset(
                'assets/mascot/nexora-analytic.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
            const Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(top: 36),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: FractionallySizedBox(
                    widthFactor: .70,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hai Fajar! 👋',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text.rich(
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
                        SizedBox(height: 12),
                        Text(
                          'Asisten finansial cerdas yang siap\nmembantumu kapan saja.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFFD8D3E3),
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: 14),
                        _PrivacyCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Mulai dari sini',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
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
            height: 104,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _quickStartPrompts.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final prompt = _quickStartPrompts[index];
                return _FeatureTile(
                  prompt: prompt,
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
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          Text(
            'Percakapan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _quickActions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 52,
        ),
        itemBuilder: (context, index) {
          final prompt = _quickActions[index];
          return _SuggestionPill(
            prompt: prompt,
            onTap: () => _ask(prompt.question),
          );
        },
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF0A091D),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF4D25B1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3A6632D9),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF17162A),
            ),
            child: IconButton(
              tooltip: 'Mikrofon',
              onPressed: _isSending ? null : () {},
              icon: const Icon(
                LucideIcons.mic,
                color: Color(0xFFAD90F5),
                size: 22,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_isSending,
              minLines: 1,
              maxLines: 2,
              textInputAction: TextInputAction.send,
              onSubmitted: _ask,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
              decoration: const InputDecoration(
                hintText: 'Tanya apa saja tentang\nkeuanganmu...',
                hintStyle: TextStyle(
                  color: Color(0xFF77748A),
                  fontSize: 15,
                  height: 1.3,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF4D25B1),
            ),
            child: IconButton(
              tooltip: 'Kirim',
              onPressed: _isSending ? null : () => _ask(_controller.text),
              icon: const Icon(
                LucideIcons.arrowUpRight,
                color: Colors.white,
                size: 23,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Prompt {
  const _Prompt(
    this.title,
    this.subtitle,
    this.question,
    this.icon,
    this.cardColor,
    this.iconColor,
  );

  final String title;
  final String subtitle;
  final String question;
  final IconData icon;
  final Color cardColor;
  final Color iconColor;
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.fromUser});

  final String text;
  final bool fromUser;
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
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF0C0D1C),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF27273B)),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed ?? () {},
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: Colors.white, size: 20),
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
        border: Border.all(color: const Color(0x443C2678)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.zap, color: Color(0xFFAD90F5), size: 14),
          SizedBox(width: 6),
          Text(
            'AI Powered',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
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
    return Container(
      height: 64,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF211B3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x554E347F)),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Data kamu dienkripsi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFBDB9C9),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            LucideIcons.chevronRight,
            color: Colors.white,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.prompt, required this.onTap});

  final _Prompt prompt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: prompt.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x332E2B5B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: prompt.iconColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(prompt.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  prompt.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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
    if (fromUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 260),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF241A45),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x553E2C7A)),
          ),
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.35),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF6632D9),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 19),
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0C19),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border.all(color: const Color(0x332D2A48)),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isInitial ? 15 : 14,
                  height: 1.5,
                  fontWeight: isInitial ? FontWeight.w400 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionPill extends StatelessWidget {
  const _SuggestionPill({required this.prompt, required this.onTap});

  final _Prompt prompt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: prompt.iconColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x332D2A5A)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: prompt.iconColor.computeLuminance() > .15
                      ? const Color(0xFF24105E)
                      : const Color(0xFF734ECA),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(prompt.icon, color: Colors.white, size: 17),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  prompt.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
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
    return Row(
      children: [
        const SizedBox(width: 50),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0C19),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'Nexora sedang berpikir…',
            style: TextStyle(color: Color(0xFFBDB9C9), fontSize: 12),
          ),
        ),
      ],
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
        color: const Color(0xFF1A0E20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x664D25B1)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.circleAlert, color: Color(0xFFAD90F5), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Coba lagi'),
            ),
        ],
      ),
    );
  }
}
