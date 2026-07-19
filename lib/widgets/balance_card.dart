import 'package:flutter/material.dart';

import '../models/balance.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

/// ホーム上部の残高サマリーカード（要件 6.1.1）。
class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.summary});

  final BalanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final balance = summary.overallBalance;
    // プラス残高は青、マイナス残高は赤（要件 6.1.1）。
    final isPositive = balance >= 0;
    final color = isPositive ? AppColors.lend : AppColors.borrow;
    final caption =
        balance > 0
            ? '受け取る予定'
            : balance < 0
            ? '返す予定'
            : '精算済み';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '現在残高',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${Formatters.signed(balance)}円',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    caption,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _Metric(
                  label: '貸した総額',
                  value: Formatters.yenSuffix(summary.lentTotal),
                  color: AppColors.lend,
                ),
                _divider(),
                _Metric(
                  label: '借りた総額',
                  value: Formatters.yenSuffix(summary.borrowedTotal),
                  color: AppColors.borrow,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _Metric(
                  label: '未返済金額',
                  value: Formatters.yenSuffix(summary.unpaidAmount),
                  color: AppColors.unpaid,
                ),
                _divider(),
                _Metric(
                  label: '返済済み金額',
                  value: Formatters.yenSuffix(summary.repaidAmount),
                  color: AppColors.settled,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 34,
    color: Colors.grey.withValues(alpha: 0.2),
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).hintColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
