import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/utils/display_name.dart';

void main() {
  test('falls back to Pengguna Nexora without a hardcoded person', () {
    expect(displayNameFor(null), 'Pengguna Nexora');
    expect(displayNameFor(null), isNot(contains('Fajar')));
  });

  test('greeting is Indonesian and time-aware', () {
    expect(greetingForNow(DateTime(2026, 8, 24, 8)), 'Selamat pagi');
    expect(greetingForNow(DateTime(2026, 8, 24, 13)), 'Selamat siang');
    expect(greetingForNow(DateTime(2026, 8, 24, 16)), 'Selamat sore');
    expect(greetingForNow(DateTime(2026, 8, 24, 21)), 'Selamat malam');
  });
}
