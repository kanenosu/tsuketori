import 'package:flutter/material.dart';

import '../models/transaction_status.dart';
import '../models/transaction_type.dart';
import 'app_colors.dart';

/// 取引種別・ステータスに対応する色（要件 11.2）。
/// 色だけで判別させないため、ラベルと併用する（要件 12.5）。
class StatusStyle {
  const StatusStyle._();

  static Color typeColor(TransactionType type) {
    return type == TransactionType.lend ? AppColors.lend : AppColors.borrow;
  }

  static Color statusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.settled:
        return AppColors.settled;
      case TransactionStatus.overdue:
        return AppColors.overdue;
      case TransactionStatus.partial:
        return AppColors.partial;
      case TransactionStatus.cancelled:
        return AppColors.unpaid;
      case TransactionStatus.unpaid:
        return AppColors.unpaid;
    }
  }
}
