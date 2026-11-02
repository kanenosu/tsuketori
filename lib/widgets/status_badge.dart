import 'package:flutter/material.dart';

import '../models/transaction_status.dart';
import '../theme/status_style.dart';

/// 返済ステータスの Status Label（要件 6.1.2 / 12.5）。
/// 背景をステータス色で塗り、白文字 12 Bold・1行。
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.compact = false});

  final TransactionStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return StatusLabel(
      label: status.label,
      color: StatusStyle.statusColor(status),
      compact: compact,
    );
  }
}

class StatusLabel extends StatelessWidget {
  const StatusLabel({
    super.key,
    required this.label,
    required this.color,
    this.compact = false,
  });

  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      ),
    );
  }
}
