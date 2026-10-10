import 'package:flutter/material.dart';
import '../models/balance.dart';
import '../utils/formatters.dart';

/// Outstanding balances, presented as a compact ledger rather than a banner.
class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.summary});
  final BalanceSummary summary;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final receive = (summary.unpaidAmount + summary.overallBalance) ~/ 2;
    final repay = (summary.unpaidAmount - summary.overallBalance) ~/ 2;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '貸し借りの差額',
              style: TextStyle(fontSize: 13, color: theme.hintColor),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: Formatters.signed(summary.overallBalance),
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -1.4,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const TextSpan(
                      text: ' 円',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _amount(context, '受け取る予定', receive)),
                Expanded(child: _amount(context, '返す予定', repay)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _amount(BuildContext context, String label, int amount) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
      ),
      const SizedBox(height: 5),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          Formatters.yenSuffix(amount),
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w500,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    ],
  );
}
