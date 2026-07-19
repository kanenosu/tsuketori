import 'package:flutter_test/flutter_test.dart';
import 'package:tsuketori/models/balance.dart';
import 'package:tsuketori/models/transaction.dart';
import 'package:tsuketori/models/transaction_status.dart';
import 'package:tsuketori/models/transaction_type.dart';

TransactionModel tx({
  String id = 't',
  String personId = 'p',
  TransactionType type = TransactionType.lend,
  int amount = 1000,
  int repaid = 0,
  TransactionStatus status = TransactionStatus.unpaid,
  DateTime? dueDate,
}) {
  final now = DateTime(2026, 1, 1);
  return TransactionModel(
    id: id,
    personId: personId,
    type: type,
    amount: amount,
    date: now,
    dueDate: dueDate,
    status: status,
    repaidAmount: repaid,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('TransactionModel', () {
    test('残額 = 金額 − 返済済み金額（要件10.1）', () {
      expect(tx(amount: 10000, repaid: 3000).remainingAmount, 7000);
    });

    test('全額返済で返済済み扱い', () {
      final t = tx(amount: 5000, repaid: 5000, status: TransactionStatus.settled);
      expect(t.effectiveStatus(), TransactionStatus.settled);
      expect(t.isOutstanding, isFalse);
    });

    test('一部返済のステータス', () {
      final t = tx(amount: 10000, repaid: 3000, status: TransactionStatus.partial);
      expect(t.effectiveStatus(), TransactionStatus.partial);
    });

    test('期限超過は期限翌日から', () {
      final due = DateTime(2026, 1, 10);
      final t = tx(amount: 5000, dueDate: due);
      // 当日は超過しない
      expect(t.isOverdue(asOf: DateTime(2026, 1, 10)), isFalse);
      // 翌日は超過
      expect(t.isOverdue(asOf: DateTime(2026, 1, 11)), isTrue);
      expect(
        t.effectiveStatus(asOf: DateTime(2026, 1, 11)),
        TransactionStatus.overdue,
      );
    });

    test('返済済みなら期限を過ぎても超過にならない', () {
      final t = tx(
        amount: 5000,
        repaid: 5000,
        status: TransactionStatus.settled,
        dueDate: DateTime(2026, 1, 1),
      );
      expect(t.isOverdue(asOf: DateTime(2027, 1, 1)), isFalse);
    });

    test('取り消しはステータス優先', () {
      final t = tx(status: TransactionStatus.cancelled);
      expect(t.effectiveStatus(), TransactionStatus.cancelled);
    });
  });

  group('BalanceCalculator.summarize（要件10.3）', () {
    test('全体残高 = 未返済貸付 − 未返済借入', () {
      final summary = BalanceCalculator.summarize([
        tx(id: '1', type: TransactionType.lend, amount: 5000),
        tx(id: '2', type: TransactionType.borrow, amount: 2000),
      ]);
      expect(summary.overallBalance, 3000);
      expect(summary.lentTotal, 5000);
      expect(summary.borrowedTotal, 2000);
      expect(summary.unpaidAmount, 7000);
      expect(summary.transactionCount, 2);
    });

    test('一部返済を残高へ反映', () {
      final summary = BalanceCalculator.summarize([
        tx(id: '1', type: TransactionType.lend, amount: 10000, repaid: 4000),
      ]);
      expect(summary.overallBalance, 6000);
      expect(summary.repaidAmount, 4000);
      expect(summary.unpaidAmount, 6000);
    });

    test('取り消しは集計対象外', () {
      final summary = BalanceCalculator.summarize([
        tx(id: '1', type: TransactionType.lend, amount: 5000),
        tx(
          id: '2',
          type: TransactionType.lend,
          amount: 3000,
          status: TransactionStatus.cancelled,
        ),
      ]);
      expect(summary.overallBalance, 5000);
      expect(summary.transactionCount, 1);
    });
  });

  group('BalanceCalculator.summarizeForPerson（要件10.2）', () {
    test('相手差額 = 未返済貸付 − 未返済借入', () {
      final balance = BalanceCalculator.summarizeForPerson([
        tx(id: '1', type: TransactionType.lend, amount: 5000),
        tx(id: '2', type: TransactionType.borrow, amount: 2000),
      ]);
      expect(balance.diff, 3000);
      expect(balance.lentOutstanding, 5000);
      expect(balance.borrowedOutstanding, 2000);
      expect(balance.unsettledCount, 2);
    });

    test('返済済み取引は未精算件数に含めない', () {
      final balance = BalanceCalculator.summarizeForPerson([
        tx(
          id: '1',
          type: TransactionType.lend,
          amount: 5000,
          repaid: 5000,
          status: TransactionStatus.settled,
        ),
      ]);
      expect(balance.unsettledCount, 0);
      expect(balance.diff, 0);
    });
  });
}
