import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_typography.dart';
import '../../finance/state/financial_analytics_provider.dart';
import '../data/ai_api_service.dart';

class AIGlowPage extends ConsumerStatefulWidget {
  const AIGlowPage({super.key});

  @override
  ConsumerState<AIGlowPage> createState() => _AIGlowPageState();
}

class _AIGlowPageState extends ConsumerState<AIGlowPage>
    with SingleTickerProviderStateMixin {
  final c = TextEditingController();
  final scroll = ScrollController();
  final ai = AiApiService();

  final msgs = <M>[
    const M(
      'Halo! Aku Nexora AI.\n'
      'Aku bisa membantumu menganalisis cashflow kamu, memberi insight, '
      'dan membantumu mengambil keputusan finansial yang lebih baik.\n\n'
      'Ada yang bisa aku bantu hari ini? 😊',
      false,
    ),
  ];

  late final AnimationController anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..repeat(reverse: true);

  static const prompts = [
    P(
      'Cashflow',
      'Lihat pemasukan\ndan pengeluaran',
      'Bagaimana kondisi cashflow saya?',
      LucideIcons.chartNoAxesCombined,
    ),
    P(
      'Pengeluaran',
      'Kategori & analisis\npengeluaranmu',
      'Di kategori mana saya paling boros?',
      LucideIcons.receiptText,
    ),
    P(
      'Goals',
      'Pantau progres\ntarget finansialmu',
      'Bagaimana progres target finansial saya?',
      LucideIcons.goal,
    ),
  ];

  static const quickActions = [
    P(
      'Berikan ringkasan keuanganku',
      '',
      'Berikan ringkasan keuanganku',
      LucideIcons.chartNoAxesCombined,
    ),
    P(
      'Analisis pengeluaranku',
      '',
      'Analisis pengeluaranku',
      LucideIcons.chartPie,
    ),
    P(
      'Apakah aku bisa menabung lebih banyak?',
      '',
      'Apakah aku bisa menabung lebih banyak?',
      LucideIcons.piggyBank,
    ),
    P(
      'Rekomendasi financial planning',
      '',
      'Rekomendasi financial planning',
      LucideIcons.sparkles,
    ),
  ];

  bool sending = false;
  int? active;
  String? error;
  String? failed;
  String? last;
  DateTime? lastAt;

  @override
  void dispose() {
    anim.dispose();
    c.dispose();
    scroll.dispose();
    super.dispose();
  }

  String norm(String s) =>
      s.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  Future<void> ask(String q) async {
    final t = q.trim();
    final n = norm(q);
    final duplicate = last == n &&
        lastAt != null &&
        DateTime.now().difference(lastAt!) < const Duration(seconds: 3);

    if (t.isEmpty || sending || duplicate) return;

    final analytics = ref.read(financialAnalyticsProvider);
    final history = <AiChatMessage>[
      for (final m in msgs)
        AiChatMessage(
          role: m.user ? 'user' : 'assistant',
          content: m.text,
        ),
      AiChatMessage(role: 'user', content: t),
    ];

    last = n;
    lastAt = DateTime.now();

    setState(() {
      msgs.add(M(t, true));
      sending = true;
      error = null;
      failed = null;
    });
    c.clear();
    down();

    try {
      final ans = await ai.chat(
        messages: history.length > 20
            ? history.sublist(history.length - 20)
            : history,
        analytics: analytics,
      );
      if (!mounted) return;
      setState(() {
        msgs.add(M(ans, false));
        sending = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        sending = false;
        error = e.message;
        failed = t;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        sending = false;
        error = 'Terjadi kesalahan saat menghubungi Nexora AI.';
        failed = t;
      });
    }

    down();
  }

  void down() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scroll.hasClients) return;
      scroll.animateTo(
        scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void newChat() {
    if (sending) return;
    setState(() {
      msgs
        ..clear()
        ..add(
          const M(
            'Halo! Aku Nexora AI.\n'
            'Percakapan baru siap. Ada kondisi keuangan yang ingin kamu pahami '
            'hari ini? 😊',
            false,
          ),
        );
      error = null;
      failed = null;
      last = null;
      lastAt = null;
      active = null;
    });
    down();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.nexoraBackgroundEdge,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _Bg(),
          SafeArea(
            top: true,
            bottom: false,
            child: page(),
          ),
        ],
      ),
    );
  }

  Widget page() {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            controller: scroll,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(child: header()),
              SliverToBoxAdapter(child: hero()),
              SliverToBoxAdapter(child: features()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Percakapan',
                    style: AppTypography.heading2.copyWith(fontSize: 25),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Bubble(msgs[i]),
                    childCount: msgs.length,
                  ),
                ),
              ),
              if (sending)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Typing(),
                  ),
                ),
              if (error != null)
                SliverToBoxAdapter(
                  child: ErrorBox(
                    error!,
                    failed == null ? null : () => ask(failed!),
                  ),
                ),
              SliverToBoxAdapter(child: actionSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
            ],
          ),
        ),
        composer(),
      ],
    );
  }

  Widget header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          const H(icon: LucideIcons.arrowLeft, label: 'Kembali'),
          const SizedBox(width: 8),
          const IconBox(),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nexora AI',
                  style: AppTypography.heading2.copyWith(fontSize: 21),
                ),
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
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const H(
            icon: LucideIcons.history,
            label: 'Riwayat percakapan',
          ),
          const SizedBox(width: 6),
          H(
            icon: LucideIcons.squarePen,
            label: 'Percakapan baru',
            onTap: newChat,
          ),
        ],
      ),
    );
  }

  Widget hero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final ms = (constraints.maxWidth * .31)
              .clamp(92.0, 118.0)
              .toDouble();

          return Container(
            constraints: const BoxConstraints(
              minHeight: 276,
              maxHeight: 322,
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 14, 14),
            decoration: BoxDecoration(
              gradient: AppGradients.heroCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primaryLight.withValues(alpha: .34),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned(
                  top: 0,
                  right: 0,
                  child: Powered(),
                ),
                Positioned(
                  right: 4,
                  bottom: 3,
                  width: ms,
                  height: ms,
                  child: AnimatedBuilder(
                    animation: anim,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, -2 * anim.value),
                      child: child,
                    ),
                    child: Image.asset(
                      'assets/mascot/nexora-analytic.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 230),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 38),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hai Fajar! 👋',
                            style: AppTypography.heading3.copyWith(fontSize: 20),
                          ),
                          const SizedBox(height: 5),
                          RichText(
                            text: TextSpan(
                              style: AppTypography.heading1.copyWith(
                                fontSize: 28,
                                height: 1.05,
                              ),
                              children: const [
                                TextSpan(text: 'Aku '),
                                TextSpan(
                                  text: 'Nexora',
                                  style: TextStyle(
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                                TextSpan(text: ' AI'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Asisten finansial cerdas yang siap membantumu kapan saja.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white70,
                              height: 1.28,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Privacy(),
                        ],
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

  Widget features() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 0, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Text(
                  'Mulai dari sini',
                  style: AppTypography.heading2.copyWith(fontSize: 25),
                ),
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
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16, bottom: 4),
              itemCount: prompts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => Feature(
                prompts[i],
                i,
                active == i,
                !sending,
                () {
                  setState(() => active = i);
                  ask(prompts[i].question);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget actionSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: quickActions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 60,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (_, i) => Action(
          quickActions[i],
          i,
          !sending,
          () => ask(quickActions[i].question),
        ),
      ),
    );
  }

  Widget composer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 5, 16, 8),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 62,
            maxHeight: 72,
          ),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppColors.inputBar,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: .38),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: .12),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .025),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .08),
                  ),
                ),
                child: const Icon(
                  LucideIcons.mic,
                  color: AppColors.micCta,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: c,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  onSubmitted: ask,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Tanya apa saja tentang keuanganmu...',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Material(
                color: Colors.transparent,
                child: Ink(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: sending
                        ? AppColors.cardMuted
                        : AppColors.sendButton,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: sending ? null : () => ask(c.text),
                    child: Icon(
                      sending ? LucideIcons.loaderCircle : LucideIcons.arrowUp,
                      color: Colors.white,
                      size: 20,
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

class _Bg extends StatelessWidget {
  const _Bg();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppGradients.aiBackground),
    );
  }
}

class H extends StatelessWidget {
  const H({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext c) {
    return Material(
      color: AppColors.headerButton,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: .08),
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class IconBox extends StatelessWidget {
  const IconBox();

  @override
  Widget build(BuildContext c) {
    return Container(
      width: 40,
      height: 40,
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
        size: 19,
      ),
    );
  }
}

class Powered extends StatelessWidget {
  const Powered();

  @override
  Widget build(BuildContext c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.aiBadge,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: .22),
        ),
      ),
      child: const Text(
        'AI Powered',
        style: TextStyle(
          color: AppColors.primaryLight,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class Privacy extends StatelessWidget {
  const Privacy();

  @override
  Widget build(BuildContext c) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.subCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.iconContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.shieldCheck,
              color: AppColors.primaryLight,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Data finansialmu tetap aman dan privat.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Feature extends StatelessWidget {
  const Feature(this.p, this.index, this.selected, this.enabled, this.onTap);

  final P p;
  final int index;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgrounds = [
      AppColors.featureTile1,
      AppColors.featureTile2,
      AppColors.featureTile3,
    ];
    final icons = [
      AppColors.featureIcon1,
      AppColors.featureIcon2,
      AppColors.featureIcon3,
    ];

    return Opacity(
      opacity: enabled ? 1 : .55,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          width: 142,
          decoration: BoxDecoration(
            color: backgrounds[index % backgrounds.length],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.primaryLight.withValues(alpha: .55)
                  : Colors.white.withValues(alpha: .055),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: .22),
                      blurRadius: 18,
                    ),
                  ]
                : null,
          ),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: icons[index % icons.length],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(p.icon, color: Colors.white, size: 21),
                  ),
                  const Spacer(),
                  Text(
                    p.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    p.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white54,
                      fontSize: 10,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Action extends StatelessWidget {
  const Action(this.p, this.index, this.enabled, this.onTap);

  final P p;
  final int index;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.suggestion1,
      AppColors.suggestion2,
      AppColors.suggestion3,
      AppColors.suggestion4,
    ];

    return Opacity(
      opacity: enabled ? 1 : .55,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: colors[index % colors.length],
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: .055)),
          ),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(999),
            child: Row(
              children: [
                const SizedBox(width: 10),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .09),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(p.icon, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Bubble extends StatelessWidget {
  const Bubble(this.m);

  final M m;

  @override
  Widget build(BuildContext context) {
    if (m.user) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            m.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(right: 10, top: 2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.chatAvatar,
          ),
          child: const Icon(
            LucideIcons.sparkles,
            color: Colors.white,
            size: 16,
          ),
        ),
        Flexible(
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.chatBubble,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: .05)),
            ),
            child: Text(
              m.text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class Typing extends StatelessWidget {
  const Typing();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.chatAvatar,
              ),
              child: Icon(
                LucideIcons.sparkles,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Nexora AI sedang berpikir...',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class ErrorBox extends StatelessWidget {
  const ErrorBox(this.message, this.onRetry);

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.withValues(alpha: .18)),
        ),
        child: Row(
          children: [
            const Icon(
              LucideIcons.circleAlert,
              color: Colors.redAccent,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: const Text('Coba lagi'),
              ),
          ],
        ),
      ),
    );
  }
}

class M {
  const M(this.text, this.user);

  final String text;
  final bool user;
}

class P {
  const P(this.title, this.subtitle, this.question, this.icon);

  final String title;
  final String subtitle;
  final String question;
  final IconData icon;
}
