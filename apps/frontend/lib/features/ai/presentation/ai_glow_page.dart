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

class _AIGlowPageState extends ConsumerState<AIGlowPage> with SingleTickerProviderStateMixin {
  final c = TextEditingController();
  final scroll = ScrollController();
  final ai = AiApiService();
  final msgs = <M>[const M('Halo! Aku Nexora AI.\nAku bisa membantumu menganalisis cashflow kamu, memberi insight, dan membantumu mengambil keputusan finansial yang lebih baik.\n\nAda yang bisa aku bantu hari ini? 😊', false)];
  late final anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600))..repeat(reverse: true);

  static const prompts = [
    P('Cashflow', 'Lihat pemasukan\ndan pengeluaran', 'Bagaimana kondisi cashflow saya?', LucideIcons.chartNoAxesCombined),
    P('Pengeluaran', 'Kategori & analisis\npengeluaranmu', 'Di kategori mana saya paling boros?', LucideIcons.receiptText),
    P('Goals', 'Pantau progres\ntarget finansialmu', 'Bagaimana progres target finansial saya?', LucideIcons.goal),
  ];
  static const quickActions = [
    P('Berikan ringkasan keuanganku', '', 'Berikan ringkasan keuanganku', LucideIcons.chartNoAxesCombined),
    P('Analisis pengeluaranku', '', 'Analisis pengeluaranku', LucideIcons.chartPie),
    P('Apakah aku bisa menabung lebih banyak?', '', 'Apakah aku bisa menabung lebih banyak?', LucideIcons.piggyBank),
    P('Rekomendasi financial planning', '', 'Rekomendasi financial planning', LucideIcons.sparkles),
  ];

  bool sending = false;
  int? active;
  String? error, failed, last;
  DateTime? lastAt;

  @override
  void dispose() { anim.dispose(); c.dispose(); scroll.dispose(); super.dispose(); }

  String norm(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  Future<void> ask(String q) async {
    final t = q.trim();
    final n = norm(q);
    final duplicate = last == n && lastAt != null && DateTime.now().difference(lastAt!) < const Duration(seconds: 3);
    if (t.isEmpty || sending || duplicate) return;
    final analytics = ref.read(financialAnalyticsProvider);
    final history = <AiChatMessage>[
      for (final m in msgs) AiChatMessage(role: m.user ? 'user' : 'assistant', content: m.text),
      AiChatMessage(role: 'user', content: t),
    ];
    last = n;
    lastAt = DateTime.now();
    setState(() { msgs.add(M(t, true)); sending = true; error = null; failed = null; });
    c.clear();
    down();
    try {
      final ans = await ai.chat(messages: history.length > 20 ? history.sublist(history.length - 20) : history, analytics: analytics);
      if (!mounted) return;
      setState(() { msgs.add(M(ans, false)); sending = false; });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { sending = false; error = e.message; failed = t; });
    } catch (_) {
      if (!mounted) return;
      setState(() { sending = false; error = 'Terjadi kesalahan saat menghubungi Nexora AI.'; failed = t; });
    }
    down();
  }

  void down() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scroll.hasClients) return;
      scroll.animateTo(scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    });
  }

  void newChat() {
    if (sending) return;
    setState(() {
      msgs..clear()..add(const M('Halo! Aku Nexora AI.\nPercakapan baru siap. Ada kondisi keuangan yang ingin kamu pahami hari ini? 😊', false));
      error = null; failed = null; last = null; lastAt = null; active = null;
    });
    down();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.nexoraBackgroundEdge,
      resizeToAvoidBottomInset: true,
      body: Stack(fit: StackFit.expand, children: [const _Bg(), SafeArea(top: true, bottom: false, child: page())]),
    );
  }

  Widget page() {
    return Column(children: [
      Expanded(
        child: CustomScrollView(
          controller: scroll,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(child: header()),
            SliverToBoxAdapter(child: hero()),
            SliverToBoxAdapter(child: features()),
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('Percakapan', style: AppTypography.heading2.copyWith(fontSize: 25)))),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              sliver: SliverList(delegate: SliverChildBuilderDelegate((_, i) => Bubble(msgs[i]), childCount: msgs.length)),
            ),
            if (sending) const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(bottom: 12), child: Typing())),
            if (error != null) SliverToBoxAdapter(child: ErrorBox(error!, failed == null ? null : () => ask(failed!))),
            SliverToBoxAdapter(child: actionSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
          ],
        ),
      ),
      composer(),
    ]);
  }

  Widget header() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
    child: Row(children: [
      const H(icon: LucideIcons.arrowLeft, label: 'Kembali'), const SizedBox(width: 8), const IconBox(), const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Nexora AI', style: AppTypography.heading2.copyWith(fontSize: 21)),
        Row(children: [Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)), const SizedBox(width: 5), Text('Assistant aktif', style: AppTypography.bodySmall.copyWith(color: Colors.white70))]),
      ])),
      const H(icon: LucideIcons.history, label: 'Riwayat percakapan'), const SizedBox(width: 6), H(icon: LucideIcons.squarePen, label: 'Percakapan baru', onTap: newChat),
    ]),
  );

  Widget hero() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: LayoutBuilder(builder: (_, o) {
      final ms = (o.maxWidth * .31).clamp(92.0, 118.0);
      return Container(
        constraints: const BoxConstraints(minHeight: 276, maxHeight: 322),
        padding: const EdgeInsets.fromLTRB(16, 16, 14, 14),
        decoration: BoxDecoration(
          gradient: AppGradients.heroCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primaryLight.withValues(alpha: .34)),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .18), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Stack(clipBehavior: Clip.none, children: [
          const Positioned(top: 0, right: 0, child: Powered()),
          Positioned(right: 4, bottom: 3, width: ms, height: ms, child: AnimatedBuilder(animation: anim, builder: (_, child) => Transform.translate(offset: Offset(0, -2 * anim.value), child: child), child: Image.asset('assets/mascot/nexora-analytic.png', fit: BoxFit.contain, filterQuality: FilterQuality.high))),
          Align(alignment: Alignment.topLeft, child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 230),
            child: Padding(padding: const EdgeInsets.only(top: 38), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Hai Fajar! 👋', style: AppTypography.heading3.copyWith(fontSize: 20)),
              const SizedBox(height: 5),
              RichText(text: TextSpan(style: AppTypography.heading1.copyWith(fontSize: 28, height: 1.05), children: const [TextSpan(text: 'Aku '), TextSpan(text: 'Nexora', style: TextStyle(color: AppColors.primaryLight)), TextSpan(text: ' AI')])),
              const SizedBox(height: 10),
              Text('Asisten finansial cerdas yang siap membantumu kapan saja.', style: AppTypography.bodyMedium.copyWith(color: Colors.white70, height: 1.28)),
              const SizedBox(height: 12), const Privacy(),
            ])),
          )),
        ]),
      );
    }),
  );

  Widget features() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 0, 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(right: 16), child: Row(children: [Text('Mulai dari sini', style: AppTypography.heading2.copyWith(fontSize: 25)), const Spacer(), Text('Geser →', style: AppTypography.labelMedium.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w700))])),
      const SizedBox(height: 10),
      SizedBox(height: 170, child: ListView.separated(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.only(right: 16, bottom: 4), itemCount: prompts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) => Feature(prompts[i], i, active == i, !sending, () { setState(() => active = i); ask(prompts[i].question); }),
      )),
    ]),
  );

  Widget actionSection() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: quickActions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisExtent: 60, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemBuilder: (_, i) => Action(quickActions[i], i, !sending, () => ask(quickActions[i].question)),
    ),
  );

  Widget composer() => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 5, 16, 8),
      child: Container(
        constraints: const BoxConstraints(minHeight: 62, maxHeight: 72), padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(color: AppColors.inputBar, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.primary.withValues(alpha: .38)), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .12), blurRadius: 18, offset: const Offset(0, 5))]),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .025), border: Border.all(color: Colors.white.withValues(alpha: .08))), child: const Icon(LucideIcons.mic, color: AppColors.micCta, size: 20)),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: c, enabled: !sending, minLines: 1, maxLines: 2, textInputAction: TextInputAction.send, onSubmitted: (v) { if (!v.contains('\n')) ask(v); }, style: AppTypography.bodySmall.copyWith(color: Colors.white), decoration: InputDecoration(hintText: sending ? 'Nexora sedang berpikir...' : 'Tanya apa saja tentang keuanganmu...', border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 7), hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)))),
          const SizedBox(width: 8),
          InkWell(onTap: sending ? null : () => ask(c.text), borderRadius: BorderRadius.circular(18), child: Ink(width: 42, height: 42, decoration: BoxDecoration(shape: BoxShape.circle, color: sending ? AppColors.cardMuted : AppColors.sendButton), child: Center(child: sending ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(LucideIcons.arrowUpRight, color: Colors.white, size: 20)))),
        ]),
      ),
    ),
  );
}

class _Bg extends StatelessWidget {
  const _Bg();
  @override
  Widget build(BuildContext c) => const DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.nexoraBackground));
}

class IconBox extends StatelessWidget {
  const IconBox({super.key});
  @override
  Widget build(BuildContext c) => Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppGradients.primary, boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .28), blurRadius: 14)]), child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 20));
}

class H extends StatelessWidget {
  const H({super.key, required this.icon, required this.label, this.onTap});
  final IconData icon; final String label; final VoidCallback? onTap;
  @override
  Widget build(BuildContext c) => Material(color: AppColors.headerButton, shape: const CircleBorder(), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(24), child: Container(width: 42, height: 42, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: .08))), child: Icon(icon, color: Colors.white, size: 20))));
}

class Powered extends StatelessWidget {
  const Powered({super.key});
  @override
  Widget build(BuildContext c) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: AppColors.aiPowered, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primaryLight.withValues(alpha: .1)), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .10), blurRadius: 12)]), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(LucideIcons.zap, size: 14, color: AppColors.primaryLight), SizedBox(width: 5), Text('AI Powered', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600))]));
}

class Privacy extends StatelessWidget {
  const Privacy({super.key});
  @override
  Widget build(BuildContext c) => Container(constraints: const BoxConstraints(maxWidth: 190, minHeight: 72), padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8), decoration: BoxDecoration(color: AppColors.heroSubCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primaryLight.withValues(alpha: .25))), child: Row(children: [Container(width: 34, height: 34, decoration: BoxDecoration(color: AppColors.heroIconBox, borderRadius: BorderRadius.circular(10)), child: const Icon(LucideIcons.shieldCheck, color: AppColors.primaryLight, size: 18)), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text('Privasi aman', style: AppTypography.labelLarge), const SizedBox(height: 1), Text('Data kamu dienkripsi dan 100% aman.', style: AppTypography.caption.copyWith(color: Colors.white70), maxLines: 2, overflow: TextOverflow.ellipsis)])), const Icon(LucideIcons.chevronRight, color: Colors.white, size: 16)]));
}

class M { const M(this.text, this.user); final String text; final bool user; }
class P { const P(this.title, this.desc, this.question, this.icon); final String title, desc, question; final IconData icon; }

class Feature extends StatelessWidget {
  const Feature(this.p, this.i, this.active, this.enabled, this.tap, {super.key});
  final P p; final int i; final bool active, enabled; final VoidCallback tap;
  @override
  Widget build(BuildContext c) {
    final cards = [AppColors.featureTile1, AppColors.featureTile2, AppColors.featureTile3];
    final icons = [AppColors.featureIcon1, AppColors.featureIcon2, AppColors.featureIcon3];
    return SizedBox(width: 154, child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(17), child: InkWell(onTap: enabled ? tap : null, borderRadius: BorderRadius.circular(17), child: Ink(padding: const EdgeInsets.fromLTRB(12, 11, 10, 9), decoration: BoxDecoration(color: active ? AppColors.featureTile2 : cards[i], borderRadius: BorderRadius.circular(17), border: Border.all(color: active ? AppColors.primaryLight.withValues(alpha: .72) : Colors.white.withValues(alpha: .09)), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: active ? .16 : .045), blurRadius: 14, offset: const Offset(0, 5))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 38, height: 38, decoration: BoxDecoration(color: active ? AppColors.featureIcon2 : icons[i], borderRadius: BorderRadius.circular(11)), child: Icon(p.icon, color: Colors.white, size: 20)), const SizedBox(height: 7), Text(p.title, style: AppTypography.heading3.copyWith(fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 2), Expanded(child: Text(p.desc, style: AppTypography.caption.copyWith(color: Colors.white70), maxLines: 2, overflow: TextOverflow.ellipsis)), Align(alignment: Alignment.bottomRight, child: Container(width: 27, height: 27, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.arrowButton.withValues(alpha: .72)), child: const Icon(LucideIcons.arrowRight, color: AppColors.primaryLight, size: 15)))]))));
  }
}

class Bubble extends StatelessWidget {
  const Bubble(this.m, {super.key});
  final M m;
  @override
  Widget build(BuildContext c) {
    if (!m.user && m.text.startsWith('Halo! Aku Nexora AI.')) {
      return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.fromLTRB(18, 14, 18, 14), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.chatBubble, Color(0xFF090914)]), borderRadius: BorderRadius.circular(17), border: Border.all(color: AppColors.primary.withValues(alpha: .16)), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .05), blurRadius: 14)]), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 32, height: 32, margin: const EdgeInsets.only(right: 10, top: 2), decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.chatAvatar), child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 16)), Expanded(child: Text(m.text, style: AppTypography.bodySmall.copyWith(color: Colors.white.withValues(alpha: .9), height: 1.45)))]));
    }
    return Align(alignment: m.user ? Alignment.centerRight : Alignment.centerLeft, child: Container(constraints: BoxConstraints(maxWidth: m.user ? 235 : 285), margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9), decoration: BoxDecoration(color: m.user ? AppColors.userBubble : AppColors.chatBubble, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)), child: Text(m.text, style: AppTypography.bodySmall.copyWith(color: Colors.white.withValues(alpha: .92), height: 1.38))));
  }
}

class Action extends StatelessWidget {
  const Action(this.p, this.i, this.enabled, this.tap, {super.key});
  final P p; final int i; final bool enabled; final VoidCallback tap;
  @override
  Widget build(BuildContext c) {
    final cs = [AppColors.suggestion1, AppColors.suggestion2, AppColors.suggestion3, AppColors.suggestion4];
    return Material(color: Colors.transparent, borderRadius: BorderRadius.circular(15), child: InkWell(onTap: enabled ? tap : null, borderRadius: BorderRadius.circular(15), child: Ink(padding: const EdgeInsets.symmetric(horizontal: 9), decoration: BoxDecoration(color: AppColors.quickActionCard, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.primary.withValues(alpha: .13)), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .035), blurRadius: 10)]), child: Row(children: [Container(width: 34, height: 34, decoration: BoxDecoration(color: cs[i], borderRadius: BorderRadius.circular(11)), child: Icon(p.icon, color: Colors.white, size: 18)), const SizedBox(width: 8), Expanded(child: Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.labelMedium.copyWith(color: Colors.white, fontSize: 11.5)))]))));
  }
}

class Typing extends StatelessWidget {
  const Typing({super.key});
  @override
  Widget build(BuildContext c) => Align(alignment: Alignment.centerLeft, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.chatBubble, borderRadius: BorderRadius.circular(13)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(LucideIcons.sparkles, size: 13, color: AppColors.primaryLight), SizedBox(width: 6), SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2))])));
}

class ErrorBox extends StatelessWidget {
  const ErrorBox(this.message, this.retry, {super.key});
  final String message; final VoidCallback? retry;
  @override
  Widget build(BuildContext c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: .07), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.danger.withValues(alpha: .2))), child: Row(children: [const Icon(LucideIcons.circleAlert, size: 18, color: AppColors.danger), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Nexora belum bisa menjawab', style: AppTypography.label), Text(message, style: AppTypography.caption), if (retry != null) TextButton.icon(onPressed: retry, icon: const Icon(LucideIcons.refreshCw, size: 15), label: const Text('Coba lagi'))]))])));
}
