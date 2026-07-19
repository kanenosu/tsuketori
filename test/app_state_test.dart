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

  Future<String> seedPerson([String name = '田中太郎']) async {
    final p = await state.addPerson(name: name);
    return p.id;
  }

  test('取引を追加すると一覧と残高に反映される', () async {
    final personId = await seedPerson();
    await state.addTransaction(
      personId: personId,
      type: TransactionType.lend,
      amount: 5000,
      date: DateTime(2026, 1, 1),
    );

    expect(state.transactions, hasLength(1));
    expect(state.summary().overallBalance, 5000);
    expect(state.lastUsedType, TransactionType.lend);
  });

  test('一部返済でステータスが partial・残額が減る', () async {
    final personId = await seedPerson();
    final txm = await state.addTransaction(
      personId: personId,
      type: TransactionType.lend,
      amount: 10000,
      date: DateTime(2026, 1, 1),
    );

    await state.addRepayment(
      transactionId: txm.id,
      amount: 3000,
      date: DateTime(2026, 1, 5),
    );

    final updated = state.transaction(txm.id)!;
    expect(updated.repaidAmount, 3000);
    expect(updated.remainingAmount, 7000);
    expect(updated.status, TransactionStatus.partial);
  });

  test('全額返済でステータスが settled になる（要件6.4.3）', () async {
    final personId = await seedPerson();
    final txm = await state.addTransaction(
      personId: personId,
      type: TransactionType.lend,
      amount: 5000,
      date: DateTime(2026, 1, 1),
    );

    await state.addRepayment(
      transactionId: txm.id,
      amount: 5000,
      date: DateTime(2026, 1, 5),
    );

    final updated = state.transaction(txm.id)!;
    expect(updated.status, TransactionStatus.settled);
    expect(updated.remainingAmount, 0);
    expect(updated.isOutstanding, isFalse);
  });

  test('過剰返済は登録できない（要件6.4.4）', () async {
    final personId = await seedPerson();
    final txm = await state.addTransaction(
      personId: personId,
      type: TransactionType.lend,
      amount: 5000,
      date: DateTime(2026, 1, 1),
    );

    expect(
      () => state.addRepayment(
        transactionId: txm.id,
        amount: 6000,
        date: DateTime(2026, 1, 5),
      ),
      throwsArgumentError,
    );
  });

  test('返済記録を削除すると残額が戻る', () async {
    final personId = await seedPerson();
    final txm = await state.addTransaction(
      personId: personId,
      type: TransactionType.lend,
      amount: 10000,
      date: DateTime(2026, 1, 1),
    );
    final r = await state.addRepayment(
      transactionId: txm.id,
      amount: 4000,
      date: DateTime(2026, 1, 5),
    );

    await state.deleteRepayment(r.id);

    final updated = state.transaction(txm.id)!;
    expect(updated.repaidAmount, 0);
    expect(updated.status, TransactionStatus.unpaid);
  });

  test('相殺で差額分が精算される（要件6.5.4）', () async {
    final personId = await seedPerson();
    await state.addTransaction(
      personId: personId,
      type: TransactionType.lend,
      amount: 5000,
      date: DateTime(2026, 1, 1),
    );
    await state.addTransaction(
      personId: personId,
      type: TransactionType.borrow,
      amount: 2000,
      date: DateTime(2026, 1, 2),
    );

    expect(state.offsetableAmountForPerson(personId), 2000);

    final offset = await state.offsetPerson(personId);
    expect(offset, 2000);

    final balance = state.balanceForPerson(personId);
    // 5,000 貸し − 2,000 借り、2,000 相殺後の差額は 3,000（受け取る予定）。
    expect(balance.diff, 3000);
    expect(balance.borrowedOutstanding, 0);
    expect(balance.lentOutstanding, 3000);
  });

  test('相手を取引ごと削除すると取引と返済も消える（要件13.3）', () async {
    final personId = await seedPerson();
    final txm = await state.addTransaction(
      personId: personId,
      type: TransactionType.lend,
      amount: 5000,
      date: DateTime(2026, 1, 1),
    );
    await state.addRepayment(
      transactionId: txm.id,
      amount: 1000,
      date: DateTime(2026, 1, 5),
    );

    await state.deletePersonWithTransactions(personId);

    expect(state.person(personId), isNull);
    expect(state.transactions, isEmpty);
    expect(state.repaymentsForTransaction(txm.id), isEmpty);
  });

  test('保存したデータは再読み込みで復元される', () async {
    final personId = await seedPerson('佐藤花子');
    await state.addTransaction(
      personId: personId,
      type: TransactionType.borrow,
      amount: 3000,
      date: DateTime(2026, 1, 1),
    );

    // 同じ SharedPreferences から別インスタンスで読み直す。
    final reloaded = AppState(repository: AppRepository());
    await reloaded.load();

    expect(reloaded.people, hasLength(1));
    expect(reloaded.people.first.name, '佐藤花子');
    expect(reloaded.transactions, hasLength(1));
    expect(reloaded.summary().overallBalance, -3000);
  });
}
