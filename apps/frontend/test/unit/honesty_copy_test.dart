import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feature UI does not ship fake financial copy', () {
    final root = Directory('lib');
    final files = root
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    final banned = [
      'Fajar',
      'Nexora Premium',
      'SPayLater',
      'Rp 15.000.000',
      'AI Intelligence Active',
    ];

    for (final file in files) {
      final source = file.readAsStringSync();
      for (final needle in banned) {
        expect(source.contains(needle), isFalse, reason: '${file.path} contains "$needle"');
      }
    }
  });

  test('financial providers isolate by currentUserProvider', () {
    expect(
      File('lib/features/finance/state/financial_transaction_store.dart').readAsStringSync().contains('currentUserProvider'),
      isTrue,
    );
    expect(
      File('lib/features/wallet/controllers/wallet_controller.dart').readAsStringSync().contains('currentUserProvider'),
      isTrue,
    );
    expect(
      File('lib/features/budget/controllers/budget_controller.dart').readAsStringSync().contains('currentUserProvider'),
      isTrue,
    );
  });
}
