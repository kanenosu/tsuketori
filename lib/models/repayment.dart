/// 返済方法（要件 6.3.4）。
enum RepaymentMethod {
  cash,
  bankTransfer,
  payPay,
  linePay,
  other;

  String get label {
    switch (this) {
      case RepaymentMethod.cash:
        return '現金';
      case RepaymentMethod.bankTransfer:
        return '銀行振込';
      case RepaymentMethod.payPay:
        return 'PayPay';
      case RepaymentMethod.linePay:
        return 'LINE Pay';
      case RepaymentMethod.other:
        return 'その他';
    }
  }

  String get storageValue => name;

  static RepaymentMethod? fromStorage(String? value) {
    if (value == null) return null;
    for (final m in RepaymentMethod.values) {
      if (m.name == value) return m;
    }
    return null;
  }
}

/// 返済データ（要件 9.4）。
class Repayment {
  const Repayment({
    required this.id,
    required this.transactionId,
    required this.amount,
    required this.date,
    this.method,
    this.memo,
    required this.createdAt,
  });

  /// 返済ID（必須）
  final String id;

  /// 取引ID（必須）
  final String transactionId;

  /// 返済金額（整数・必須）
  final int amount;

  /// 返済日（必須）
  final DateTime date;

  /// 返済方法（任意）
  final RepaymentMethod? method;

  /// メモ（任意）
  final String? memo;

  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionId': transactionId,
      'amount': amount,
      'date': date.toIso8601String(),
      'method': method?.storageValue,
      'memo': memo,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Repayment.fromJson(Map<String, dynamic> json) {
    return Repayment(
      id: json['id'] as String,
      transactionId: json['transactionId'] as String,
      amount: json['amount'] as int,
      date: DateTime.parse(json['date'] as String),
      method: RepaymentMethod.fromStorage(json['method'] as String?),
      memo: json['memo'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
