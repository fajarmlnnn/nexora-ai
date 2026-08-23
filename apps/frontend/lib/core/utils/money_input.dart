/// Indonesian rupiah input helpers.
///
/// `500.000` and `500,000` are thousand separators and must parse as 500000.
/// Decimal commas such as `500,50` are treated as 500.50.
double? parseRupiahInput(String raw, {bool allowZero = false}) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return allowZero ? 0 : null;

  final normalized = trimmed.replaceAll(RegExp(r'[^0-9.,]'), '');
  if (normalized.isEmpty) return allowZero ? 0 : null;

  String digits;
  if (normalized.contains(',') && normalized.contains('.')) {
    final lastComma = normalized.lastIndexOf(',');
    final lastDot = normalized.lastIndexOf('.');
    if (lastComma > lastDot) {
      digits = normalized.replaceAll('.', '').replaceAll(',', '.');
    } else {
      digits = normalized.replaceAll(',', '');
    }
  } else if (normalized.contains(',')) {
    final parts = normalized.split(',');
    if (parts.length == 2 && parts[1].length <= 2) {
      digits = '${parts[0]}.${parts[1]}';
    } else {
      digits = normalized.replaceAll(',', '');
    }
  } else if (normalized.contains('.')) {
    final parts = normalized.split('.');
    final last = parts.last;
    if (parts.length == 2 && last.length <= 2 && parts.first.length <= 3) {
      digits = normalized;
    } else {
      digits = normalized.replaceAll('.', '');
    }
  } else {
    digits = normalized;
  }

  final value = double.tryParse(digits);
  if (value == null || !value.isFinite || value < 0) return null;
  if (value == 0 && !allowZero) return null;
  return value;
}

/// Spoken representation for TalkBack / VoiceOver.
String spokenRupiah(num value) {
  final rounded = value.round();
  if (rounded == 0) return 'nol rupiah';
  return '$rounded rupiah';
}
