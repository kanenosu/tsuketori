import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsuketori/models/transaction_status.dart';
import 'package:tsuketori/models/transaction_type.dart';
import 'package:tsuketori/repositories/app_repository.dart';
import 'package:tsuketori/state/app_state.dart';

void main() {
  late AppState state;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    state = AppState(repository: AppRepository());
    await state.load();
  });

  Future<void> seed() async {
    final person = await state.addPerson(name: '佐藤 花子');
    final transaction = await state.addTransaction(
      personId: person.id,
      type: TransactionType.lend,
      amount: 5000,
      date: DateTime(2026, 10, 4, 18, 30),
      memo: '夕食代',
    );
    await state.addRepayment(
      transactionId: transaction.id,
      amount: 2000,
      date: DateTime(2026, 10, 5),
    );
  }

  test('versioned backup round-trips all ledger data', () async {
    await seed();
    final source = state.createBackupJson(
      exportedAt: DateTime.utc(2026, 10, 6),
    );
    final preview = state.inspectBackup(source);

    expect(preview.data.people.single.name, '佐藤 花子');
    expect(preview.data.transactions.single.repaidAmount, 2000);
    expect(preview.data.repayments.single.amount, 2000);
    expect(preview.outstandingBalance, 3000);
  });

  test('restore replaces current data only after validation', () async {
    await seed();
    final preview = state.inspectBackup(state.createBackupJson());
    await state.addPerson(name: 'あとで追加');

    await state.restoreBackup(preview);

    expect(state.allPeople, hasLength(1));
    expect(state.transactions.single.remainingAmount, 3000);
  });

  test('rejects malformed JSON', () {
    expect(() => state.inspectBackup('{broken'), throwsFormatException);
  });

  test('rejects a non-Tsuketori document', () {
    expect(
      () => state.inspectBackup(jsonEncode({'version': 1, 'data': {}})),
      throwsFormatException,
    );
  });

  test('rejects unsupported versions', () async {
    await seed();
    final map = jsonDecode(state.createBackupJson()) as Map<String, dynamic>;
    map['version'] = 999;
    expect(() => state.inspectBackup(jsonEncode(map)), throwsFormatException);
  });

  test('rejects duplicate person IDs', () async {
    await seed();
    final map = jsonDecode(state.createBackupJson()) as Map<String, dynamic>;
    final data = map['data'] as Map<String, dynamic>;
    final people = data['people'] as List<dynamic>;
    people.add(Map<String, dynamic>.from(people.first as Map));
    expect(() => state.inspectBackup(jsonEncode(map)), throwsFormatException);
  });

  test('rejects transactions referencing a missing person', () async {
    await seed();
    final map = jsonDecode(state.createBackupJson()) as Map<String, dynamic>;
    final data = map['data'] as Map<String, dynamic>;
    final transaction =
        (data['transactions'] as List<dynamic>).first as Map<String, dynamic>;
    transaction['personId'] = 'missing';
    expect(() => state.inspectBackup(jsonEncode(map)), throwsFormatException);
  });

  test('rejects repayments referencing a missing transaction', () async {
    await seed();
    final map = jsonDecode(state.createBackupJson()) as Map<String, dynamic>;
    final data = map['data'] as Map<String, dynamic>;
    final repayment =
        (data['repayments'] as List<dynamic>).first as Map<String, dynamic>;
    repayment['transactionId'] = 'missing';
    expect(() => state.inspectBackup(jsonEncode(map)), throwsFormatException);
  });

  test('rejects repayment totals above the transaction amount', () async {
    await seed();
    final map = jsonDecode(state.createBackupJson()) as Map<String, dynamic>;
    final data = map['data'] as Map<String, dynamic>;
    final repayment =
        (data['repayments'] as List<dynamic>).first as Map<String, dynamic>;
    repayment['amount'] = 6000;
    expect(() => state.inspectBackup(jsonEncode(map)), throwsFormatException);
  });

  test('rejects status inconsistent with repayments', () async {
    await seed();
    final map = jsonDecode(state.createBackupJson()) as Map<String, dynamic>;
    final data = map['data'] as Map<String, dynamic>;
    final transaction =
        (data['transactions'] as List<dynamic>).first as Map<String, dynamic>;
    transaction['status'] = TransactionStatus.settled.storageValue;
    expect(() => state.inspectBackup(jsonEncode(map)), throwsFormatException);
  });

  test(
    'cancel keeps history but removes the transaction from balance',
    () async {
      await seed();
      final id = state.transactions.single.id;

      await state.cancelTransaction(id);
      expect(state.transactions.single.isCancelled, isTrue);
      expect(state.summary().overallBalance, 0);
      expect(state.repaymentsForTransaction(id), hasLength(1));

      await state.restoreCancelledTransaction(id);
      expect(state.transaction(id)!.status, TransactionStatus.partial);
      expect(state.summary().overallBalance, 3000);
    },
  );
}
