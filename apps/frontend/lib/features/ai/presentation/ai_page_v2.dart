import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
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
  final List<_Message> _messages = [
    const _Message(false, 'Aku Nexora AI. Aku bisa membaca pola cashflow, pengeluaran, tabungan, dan goals kamu. Mari kita cari keputusan finansial terbaik.'),
  ];
  bool _sending = false;
  String? _error;

  static const _prompts = <({String title, String question, IconData icon})>[
    (title: 'Ringkas keuanganku', question: 'Berikan ringkasan kondisi keuangan saya bulan ini.', icon: LucideIcons.chartNoAxesCombined),
    (title: 'Cari kebocoran', question: 'Di kategori mana saya paling boros dan apa penyebabnya?', icon: LucideIcons.searchCheck),
    (title: 'Cek goals', question: 'Bagaimana cara saya mencapai goals lebih cepat?', icon: LucideIcons.target),
    (title: 'Buat strategi', question: 'Buatkan strategi finansial praktis untuk bulan ini.', icon: LucideIcons.sparkles),
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _ask(String value) async {
    final question = value.trim();
    if (question.isEmpty || _sending) return;
    final analytics = ref.read(financialAnalyticsProvider);
    final history = <AiChatMessage>[
      ..._messages.map((m) => AiChatMessage(role: m.user ? 'user' : 'assistant', content: m.text)),
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
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.message;
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

  void _newChat() {
    if (_sending) return;
    setState(() {
      _messages
        ..clear()
        ..add(const _Message(false, 'Percakapan baru siap. Ceritakan kondisi finansial yang ingin kamu pahami.'));
      _error = null;
    });
  }

  void _retry() {
    if (_sending) return;
    final previous = _messages.where((m) => m.user).toList();
    if (previous.isEmpty) return;
    _ask(previous.last.text);
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05050D),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                children: [
                  _hero(),
                  const SizedBox(height: 20),
                  if (_messages.length == 1) _starter(),
                  const SizedBox(height: 12),
                  ..._messages.map(_bubble),
                  if (_sending) const _Typing(),
                  if (_error != null) _errorCard(),
                  const SizedBox(height: 90),
                ],
              ),
            ),
            _composer(),
          ],
        ),
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: Row(
          children: [
            _circleButton(LucideIcons.arrowLeft, () => Navigator.maybePop(context)),
            const SizedBox(width: 10),
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF22D3EE)])),
              child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nexora AI', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Row(children: [Icon(Icons.circle, size: 7, color: Color(0xFF4ADE80)), SizedBox(width: 6), Text('Financial intelligence', style: TextStyle(color: Color(0xFF9C9CAF), fontSize: 12))]),
                ],
              ),
            ),
            _circleButton(LucideIcons.rotateCcw, _newChat),
          ],
        ),
      );

  Widget _circleButton(IconData icon, VoidCallback onTap) => Material(
        color: const Color(0xFF11111C),
        shape: const CircleBorder(),
        child: InkWell(onTap: onTap, customBorder: const CircleBorder(), child: SizedBox(width: 42, height: 42, child: Icon(icon, color: const Color(0xFFD8D8E5), size: 19))),
      );

  Widget _hero() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF211044), Color(0xFF0B142D)]),
          border: Border.all(color: Color(0x335F45B8)),
          boxShadow: const [BoxShadow(color: Color(0x291B1244), blurRadius: 30, offset: Offset(0, 12))],
        ),
        child: Row(
          children: [
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Your money, understood.', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.1)), SizedBox(height: 8), Text('Tanya apa pun. Nexora akan menggunakan konteks finansialmu untuk memberi jawaban yang relevan.', style: TextStyle(color: Color(0xFFC6C2D2), fontSize: 13, height: 1.4))])),
            const SizedBox(width: 10),
            Container(width: 62, height: 62, decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xFF8B5CF6).withValues(alpha: .16)), child: const Icon(LucideIcons.brainCircuit, color: Color(0xFFA78BFA), size: 30)),
          ],
        ),
      );

  Widget _starter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mulai dari sini', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: _prompts.map((p) => _prompt(p.title, p.question, p.icon)).toList()),
        ],
      );

  Widget _prompt(String title, String question, IconData icon) => InkWell(
        onTap: () => _ask(question),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 164,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF10101C), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withValues(alpha: .07))),
          child: Row(children: [Container(width: 34, height: 34, decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withValues(alpha: .12), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 17, color: const Color(0xFFA78BFA))), const SizedBox(width: 9), Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)))]),
        ),
      );

  Widget _bubble(_Message message) => Align(
        alignment: message.user ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            color: message.user ? const Color(0xFF6738C7) : const Color(0xFF11111C),
            borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: Radius.circular(message.user ? 18 : 5), bottomRight: Radius.circular(message.user ? 5 : 18)),
            border: Border.all(color: Colors.white.withValues(alpha: message.user ? .08 : .055)),
          ),
          child: Text(message.text, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.45)),
        ),
      );

  Widget _errorCard() => Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFF25131A), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x553F2028))),
        child: Row(children: [const Icon(LucideIcons.triangleAlert, color: Color(0xFFFCA5A5), size: 18), const SizedBox(width: 9), Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFFECACA), fontSize: 12, height: 1.35))), TextButton(onPressed: _sending ? null : _retry, child: const Text('Retry'))]),
      );

  Widget _composer() => Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: const BoxDecoration(color: Color(0xF20A0A13), border: Border(top: BorderSide(color: Color(0x18181829)))),
        child: Row(children: [
          Expanded(child: TextField(controller: _input, textInputAction: TextInputAction.send, onSubmitted: _ask, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: InputDecoration(hintText: 'Tanya Nexora tentang uangmu...', hintStyle: const TextStyle(color: Color(0xFF777789)), filled: true, fillColor: const Color(0xFF14141F), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none), focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(18)), borderSide: BorderSide(color: Color(0x665F45B8))))),
          const SizedBox(width: 9),
          Material(color: const Color(0xFF7C3AED), shape: const CircleBorder(), child: InkWell(onTap: _sending ? null : () => _ask(_input.text), customBorder: const CircleBorder(), child: SizedBox(width: 52, height: 52, child: Icon(_sending ? Icons.hourglass_top_rounded : LucideIcons.arrowUp, color: Colors.white, size: 21))),
        ]),
      );
}

class _Message {
  const _Message(this.user, this.text);
  final bool user;
  final String text;
}

class _Typing extends StatelessWidget {
  const _Typing();
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(color: const Color(0xFF11111C), borderRadius: BorderRadius.circular(18)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [SizedBox(width: 7, height: 7, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFA78BFA), shape: BoxShape.circle))), SizedBox(width: 5), SizedBox(width: 7, height: 7, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFF8B5CF6), shape: BoxShape.circle))), SizedBox(width: 5), SizedBox(width: 7, height: 7, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle))), SizedBox(width: 9), Text('Nexora sedang menganalisis...', style: TextStyle(color: Color(0xFFB9B6C4), fontSize: 12))]),
        ),
      );
}
