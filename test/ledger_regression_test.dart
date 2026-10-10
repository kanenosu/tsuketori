import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsuketori/models/transaction_type.dart';
import 'package:tsuketori/repositories/app_repository.dart';
import 'package:tsuketori/state/app_state.dart';

class FailingRepository extends AppRepository {
  bool fail = false;

  @override
  Future<void> save(AppData data) async {
    if (fail) throw StateError('disk unavailable');
    await super.save(data);
  }
}

void main() {
  late FailingRepository repository;
  late AppState state;
  late String personId;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = FailingRepository();
    state = AppState(repository: repository);
    await state.load();
    personId = (await state.addPerson(name: 'テスト相手')).id;
  });

  Future<String> lend([int amount = 5000]) async =>
      (await state.addTransaction(
        personId: personId,
        type: TransactionType.lend,
        amount: amount,
        date: DateTime(2026, 1, 31),
      )).id;

  test('invalid transactions never change the ledger', () async {
    for (final amount in [0, -1, 10000000000]) {
      await expectLater(lend(amount), throwsArgumentError);
    }
    await expectLater(
      state.addTransaction(
        personId: 'missing',
        type: TransactionType.borrow,
        amount: 100,
        date: DateTime(2026),
      ),
      throwsArgumentError,
    );
    expect(state.transactions, isEmpty);
    final id = await lend();
    await state.addRepayment(
      transactionId: id,
      amount: 2000,
      date: DateTime(2026),
    );
    await expectLater(
      state.updateTransaction(id, amount: 1999),
      throwsArgumentError,
    );
    expect(state.transaction(id)!.remainingAmount, 3000);
    await state.updateTransaction(id, amount: 2000);
    expect(state.transaction(id)!.isSettled, isTrue);
  });

  test(
    'failed creation rolls back and a retry creates exactly one record',
    () async {
      repository.fail = true;
      await expectLater(lend(), throwsStateError);
      expect(state.transactions, isEmpty);
      repository.fail = false;
      await lend();
      final restored = AppState();
      await restored.load();
      expect(restored.transactions, hasLength(1));
    },
  );

  test(
    'failed repayment, offset and deletion preserve the entire ledger',
    () async {
      final id = await lend();
      await state.addTransaction(
        personId: personId,
        type: TransactionType.borrow,
        amount: 2000,
        date: DateTime(2026),
      );
      repository.fail = true;
      await expectLater(
        state.addRepayment(
          transactionId: id,
          amount: 1000,
          date: DateTime(2026),
        ),
        throwsStateError,
      );
      await expectLater(state.offsetPerson(personId), throwsStateError);
      await expectLater(
        state.deletePersonWithTransactions(personId),
        throwsStateError,
      );
      expect(state.transaction(id)!.remainingAmount, 5000);
      expect(state.repaymentsForTransaction(id), isEmpty);
      expect(state.people, hasLength(1));
      expect(state.transactions, hasLength(2));
      final restored = AppState();
      await restored.load();
      expect(restored.summary().overallBalance, 3000);
      repository.fail = false;
      expect(await state.offsetPerson(personId), 2000);
      await restored.load();
      expect(restored.transaction(id)!.remainingAmount, 3000);
      expect(restored.repaymentsForTransaction(id), hasLength(1));
    },
  );

  test('concurrent repayments are serialized and cannot overpay', () async {
    final id = await lend();
    final first = state.addRepayment(
      transactionId: id,
      amount: 4000,
      date: DateTime(2026),
    );
    final second = state.addRepayment(
      transactionId: id,
      amount: 4000,
      date: DateTime(2026),
    );
    await expectLater(second, throwsArgumentError);
    await first;
    expect(state.transaction(id)!.remainingAmount, 1000);
    final restored = AppState();
    await restored.load();
    expect(restored.transaction(id)!.remainingAmount, 1000);
    expect(restored.repaymentsForTransaction(id), hasLength(1));
  });

  test(
    'legacy three-key data migrates without losing repayments or hidden people',
    () async {
      final id = await lend();
      await state.addRepayment(
        transactionId: id,
        amount: 1500,
        date: DateTime(2026),
      );
      await state.hidePerson(personId);
      SharedPreferences.setMockInitialValues({
        'tsuketori.people': jsonEncode(
          state.allPeople.map((p) => p.toJson()).toList(),
        ),
        'tsuketori.transactions': jsonEncode(
          state.transactions.map((t) => t.toJson()).toList(),
        ),
        'tsuketori.repayments': jsonEncode(
          state.repaymentsForTransaction(id).map((r) => r.toJson()).toList(),
        ),
      });
      final migrated = AppState();
      await migrated.load();
      expect(migrated.people, isEmpty);
      expect(migrated.transaction(id)!.remainingAmount, 3500);
      await migrated.unhidePerson(personId);
      final restored = AppState();
      await restored.load();
      expect(restored.people.single.id, personId);
      expect(restored.repaymentsForTransaction(id).single.amount, 1500);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('tsuketori.ledger.v1'), isNotNull);
    },
  );

  test(
    'corrupt legacy data fails visibly instead of loading an empty ledger',
    () async {
      SharedPreferences.setMockInitialValues({'tsuketori.people': '{}'});
      await expectLater(AppState().load(), throwsFormatException);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('tsuketori.people'), '{}');
      expect(prefs.getString('tsuketori.ledger.v1'), isNull);
    },
  );
}
