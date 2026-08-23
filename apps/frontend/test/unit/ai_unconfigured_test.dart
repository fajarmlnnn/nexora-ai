import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/ai/data/ai_api_service.dart';

void main() {
  test('unconfigured AI gateway reports an honest status', () async {
    final service = AiApiService(baseUrl: '');
    expect(service.isConfigured, isFalse);
    final health = await service.health();
    expect(health.configured, isFalse);
    expect(health.reachable, isFalse);
    expect(health.message, 'Server AI belum dikonfigurasi');
  });
}
