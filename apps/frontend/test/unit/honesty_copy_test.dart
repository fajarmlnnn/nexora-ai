import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('financial providers isolate by currentUserProvider', () {
    expect(
      File('lib/features/finance/state/financial_transaction_store.dart')
          .readAsStringSync()
          .contains('currentUserProvider'),
      isTrue,
    );
    expect(
      File('lib/features/wallet/controllers/wallet_controller.dart')
          .readAsStringSync()
          .contains('currentUserProvider'),
      isTrue,
    );
    expect(
      File('lib/features/budget/controllers/budget_controller.dart')
          .readAsStringSync()
          .contains('currentUserProvider'),
      isTrue,
    );
  });
}
