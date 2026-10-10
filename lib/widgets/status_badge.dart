import 'package:flutter/material.dart';
import '../models/transaction_status.dart';
import '../theme/status_style.dart';

/// Status uses a small dot and text; color is never the only indication.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.compact = false});
  final TransactionStatus status;
  final bool compact;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(
          color: StatusStyle.statusColor(status),
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 5),
      Text(
        status.label,
        style: TextStyle(
          fontSize: compact ? 11 : 13,
          color: Theme.of(context).hintColor,
          fontWeight: FontWeight.w400,
        ),
      ),
    ],
  );
}
