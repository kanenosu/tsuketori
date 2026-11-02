import 'transaction_status.dart';
import 'transaction_type.dart';

/// 取引データ（要件 9.3）。
///
/// 返済済み金額・未返済金額は返済履歴（[Repayment]）から導出するのが正だが、
/// 要件 9.3 に合わせて基底ステータスを保持する。返済履歴が変わるたびに
/// [AppState] が [status] と各金額を再計算して保存する。
class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.personId,
    required this.type,
    required this.amount,
    required this.date,
    this.dueDate,
    this.memo,
    required this.status,
    required this.repaidAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 取引ID（必須）
  final String id;

  /// 相手ID（必須）
  final String personId;

  /// 取引種別（貸した／借りた・必須）
  final TransactionType type;

  /// 金額（整数・必須。1円以上）
  final int amount;

  /// 取引日（必須）
  final DateTime date;

  /// 返済期限（任意）
  final DateTime? dueDate;

  /// メモ（任意）
  final String? memo;

  /// 基底ステータス（unpaid / partial / settled / cancelled）
  final TransactionStatus status;

  /// 返済済み金額（返済履歴の合計）
  final int repaidAmount;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// 取引残額 ＝ 取引金額 − 返済済み金額（要件 10.1）。
  int get remainingAmount => amount - repaidAmount;

  bool get isCancelled => status == TransactionStatus.cancelled;

  bool get isSettled => status == TransactionStatus.settled;

  /// まだ精算が残っている（残額がプラスで取り消しでない）か。
  bool get isOutstanding => !isCancelled && remainingAmount > 0;

  /// 返済期限を過ぎているか（[asOf] 基準。既定は現在時刻）。
  bool isOverdue({DateTime? asOf}) {
    final due = dueDate;
    if (due == null || !isOutstanding) return false;
    final now = asOf ?? DateTime.now();
    // 返済期限当日は超過扱いにしない（翌日以降を超過とする）。
    final dueDay = DateTime(due.year, due.month, due.day);
    final today = DateTime(now.year, now.month, now.day);
    return today.isAfter(dueDay);
  }

  /// 表示用の実効ステータス（期限超過を含む・要件 6.4.1）。
  TransactionStatus effectiveStatus({DateTime? asOf}) {
    if (isCancelled) return TransactionStatus.cancelled;
    if (remainingAmount <= 0) return TransactionStatus.settled;
    if (isOverdue(asOf: asOf)) return TransactionStatus.overdue;
    if (repaidAmount > 0) return TransactionStatus.partial;
    return TransactionStatus.unpaid;
  }

  /// 返済済み・取り消しなど、もう対応不要になった取引か。
  bool get isFinished {
    final s = effectiveStatus();
    return s == TransactionStatus.settled || s == TransactionStatus.cancelled;
  }

  TransactionModel copyWith({
    String? personId,
    TransactionType? type,
    int? amount,
    DateTime? date,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? memo,
    TransactionStatus? status,
    int? repaidAmount,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id,
      personId: personId ?? this.personId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      memo: memo ?? this.memo,
      status: status ?? this.status,
      repaidAmount: repaidAmount ?? this.repaidAmount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'personId': personId,
      'type': type.storageValue,
      'amount': amount,
      'date': date.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'memo': memo,
      'status': status.storageValue,
      'repaidAmount': repaidAmount,
      'remainingAmount': remainingAmount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      personId: json['personId'] as String,
      type: TransactionType.fromStorage(json['type'] as String),
      amount: json['amount'] as int,
      date: DateTime.parse(json['date'] as String),
      dueDate:
          json['dueDate'] == null
              ? null
              : DateTime.parse(json['dueDate'] as String),
      memo: json['memo'] as String?,
      status: TransactionStatus.fromStorage(json['status'] as String),
      repaidAmount: (json['repaidAmount'] as int?) ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
