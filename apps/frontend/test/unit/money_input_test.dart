import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/utils/money_input.dart';

void main() {
  group('parseRupiahInput', () {
    test('parses Indonesian thousand separators', () {
      expect(parseRupiahInput('500.000'), 500000);
      expect(parseRupiahInput('500,000'), 500000);
      expect(parseRupiahInput('Rp 1.250.000'), 1250000);
    });

    test('parses decimal comma amounts', () {
      expect(parseRupiahInput('500,50'), 500.50);
    });

    test('rejects empty and negative values', () {
      expect(parseRupiahInput(''), isNull);
      expect(parseRupiahInput('abc'), isNull);
    });

    test('allows zero only when requested', () {
      expect(parseRupiahInput('0'), isNull);
      expect(parseRupiahInput('0', allowZero: true), 0);
    });
  });

  test('spokenRupiah uses a talkback-friendly label', () {
    expect(spokenRupiah(0), 'nol rupiah');
    expect(spokenRupiah(15000), '15000 rupiah');
  });
}
