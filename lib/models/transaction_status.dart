/// 取引の返済ステータス（要件 6.4.1）。
///
/// [overdue]（期限超過）は返済期限と現在日から導出する表示上の状態のため、
/// 永続化する基底ステータスは [unpaid] / [partial] / [settled] / [cancelled] の4つ。
enum TransactionStatus {
  /// 未返済
  unpaid,

  /// 一部返済
  partial,

  /// 返済済み
  settled,

  /// 期限超過（導出値。永続化はしない）
  overdue,

  /// 取り消し
  cancelled;

  String get label {
    switch (this) {
      case TransactionStatus.unpaid:
        return '返済待ち';
      case TransactionStatus.partial:
        return '一部返済';
      case TransactionStatus.settled:
        return '返済済み';
      case TransactionStatus.overdue:
        return '期限超過';
      case TransactionStatus.cancelled:
        return '取り消し';
    }
  }

  /// 永続化用の文字列。
  String get storageValue => name;

  static TransactionStatus fromStorage(String value) {
    return TransactionStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => TransactionStatus.unpaid,
    );
  }
}
