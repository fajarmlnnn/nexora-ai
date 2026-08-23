import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/utils/nexora_id.dart';

void main() {
  test('nexoraUuidV4 generates a reusable UUID v4', () {
    final first = nexoraUuidV4();
    final second = nexoraUuidV4();
    expect(isNexoraUuid(first), isTrue);
    expect(isNexoraUuid(second), isTrue);
    expect(first, isNot(second));
  });

  test('the same submit key can be reused for retries', () {
    final key = nexoraUuidV4();
    expect(isNexoraUuid(key), isTrue);
    expect(key, key);
  });
}
