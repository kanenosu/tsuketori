import 'transaction.dart';
import 'transaction_type.dart';

/// 全体の集計結果（ホーム・統計画面用）。
class BalanceSummary {
  const BalanceSummary({
    required this.overallBalance,
    required this.lentTotal,
    required this.borrowedTotal,
    required this.unpaidAmount,
    required this.repaidAmount,
    required this.transactionCount,
  });

  /// 全体残高 ＝ 全相手への未返済貸付額 − 全相手からの未返済借入額（要件 10.3）。
  /// プラスは「受け取る予定」、マイナスは「返す予定」。
  final int overallBalance;

  /// 貸した総額（取り消しを除く貸付取引の金額合計）。
  final int lentTotal;

  /// 借りた総額（取り消しを除く借入取引の金額合計）。
  final int borrowedTotal;

  /// 未返済金額（未精算取引の残額合計）。
  final int unpaidAmount;

  /// 返済済み金額（全取引の返済済み金額合計）。
  final int repaidAmount;

  /// 取引件数（取り消しを除く）。
  final int transactionCount;
}

/// 相手ごとの集計結果（相手一覧・相手詳細画面用）。
class PersonBalance {
  const PersonBalance({
    required this.lentOutstanding,
    required this.borrowedOutstanding,
    required this.lentTotal,
    required this.borrowedTotal,
    required this.unsettledCount,
  });

  /// 相手への未返済貸付額。
  final int lentOutstanding;

  /// 相手からの未返済借入額。
  final int borrowedOutstanding;

  /// 貸した合計（金額ベース）。
  final int lentTotal;

  /// 借りた合計（金額ベース）。
  final int borrowedTotal;

  /// 未精算件数。
  final int unsettledCount;

  /// 相手差額 ＝ 相手への未返済貸付額 − 相手からの未返済借入額（要件 10.2）。
  int get diff => lentOutstanding - borrowedOutstanding;
}

/// 取引リストから残高・差額を算出する純粋関数群（要件 10章）。
class BalanceCalculator {
  const BalanceCalculator._();

  /// 相手を問わない全体集計。
  static BalanceSummary summarize(Iterable<TransactionModel> transactions) {
    var lentTotal = 0;
    var borrowedTotal = 0;
    var unpaid = 0;
    var repaid = 0;
    var count = 0;
    var lentOutstanding = 0;
    var borrowedOutstanding = 0;

    for (final tx in transactions) {
      if (tx.isCancelled) continue;
      count++;
      repaid += tx.repaidAmount;
      if (tx.type == TransactionType.lend) {
        lentTotal += tx.amount;
        lentOutstanding += tx.remainingAmount;
      } else {
        borrowedTotal += tx.amount;
        borrowedOutstanding += tx.remainingAmount;
      }
      unpaid += tx.remainingAmount;
    }

    return BalanceSummary(
      overallBalance: lentOutstanding - borrowedOutstanding,
      lentTotal: lentTotal,
      borrowedTotal: borrowedTotal,
      unpaidAmount: unpaid,
      repaidAmount: repaid,
      transactionCount: count,
    );
  }

  /// 特定の相手に対する集計。[transactions] は当該相手の取引のみを渡す想定。
  static PersonBalance summarizeForPerson(
    Iterable<TransactionModel> transactions,
  ) {
    var lentOutstanding = 0;
    var borrowedOutstanding = 0;
    var lentTotal = 0;
    var borrowedTotal = 0;
    var unsettled = 0;

    for (final tx in transactions) {
      if (tx.isCancelled) continue;
      if (tx.type == TransactionType.lend) {
        lentTotal += tx.amount;
        lentOutstanding += tx.remainingAmount;
      } else {
        borrowedTotal += tx.amount;
        borrowedOutstanding += tx.remainingAmount;
      }
      if (tx.isOutstanding) unsettled++;
    }

    return PersonBalance(
      lentOutstanding: lentOutstanding,
      borrowedOutstanding: borrowedOutstanding,
      lentTotal: lentTotal,
      borrowedTotal: borrowedTotal,
      unsettledCount: unsettled,
    );
  }
}
