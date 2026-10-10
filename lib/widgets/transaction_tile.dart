import 'package:flutter/material.dart';
import '../models/person.dart';
import '../models/transaction.dart';
import '../models/transaction_type.dart';
import '../utils/formatters.dart';
import 'person_avatar.dart';
import 'status_badge.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.person,
    this.onTap,
  });
  final TransactionModel transaction;
  final Person? person;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 4),
        child: Row(
          children: [
            PersonAvatar(person: person, radius: 19),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person?.name ?? '(不明な相手)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tx.type.label} · ${Formatters.relative(tx.date)}',
                    style: TextStyle(fontSize: 12, color: theme.hintColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              fit: FlexFit.tight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${tx.type == TransactionType.lend ? '+' : '−'}${Formatters.yenSuffix(tx.amount)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  StatusBadge(status: tx.effectiveStatus(), compact: true),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.chevron_right, size: 17, color: theme.disabledColor),
          ],
        ),
      ),
    );
  }
}
