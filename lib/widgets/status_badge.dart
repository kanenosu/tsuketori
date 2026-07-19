import 'package:flutter/material.dart';

import '../models/transaction_status.dart';
import '../theme/status_style.dart';

/// 返済ステータスを色付きラベルで表示するバッジ（要件 6.1.2 / 12.5）。
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.compact = false});

  final TransactionStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = StatusStyle.statusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
