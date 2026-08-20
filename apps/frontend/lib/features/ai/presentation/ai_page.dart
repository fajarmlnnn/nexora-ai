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
      Color(0xFF050715),
      Color(0xFF170D3D),
    ),
    _Prompt(
      'Pengeluaran',
      'Kategori & analisis\npengeluaranmu',
      'Di kategori mana saya paling boros?',
      LucideIcons.receiptText,
      Color(0xFF130B38),
      Color(0xFF351D83),
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

  static const _quickActions = [
    _Prompt(
      'Berikan ringkasan keuanganku',
      '',