import 'package:flutter/material.dart';

import '../models/balance.dart';
import '../theme/app_colors.dart';
import 'yen_amount.dart';

/// 残高サマリー（PayPay の Half color background レイアウト）。
///
/// 上部にサービス色（ブルー）を敷き、最重要情報＝差引残高を大きく白で表示。
/// 受け取る予定／返す予定は白カード（Low-Shadow）で下に重ねる。
class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.summary, this.topInset = 0});

  final BalanceSummary summary;

  /// ステータスバー分などの上余白（背景色はその外側まで敷く）。
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final balance = summary.overallBalance;
    final lentOutstanding = (summary.unpaidAmount + balance) ~/ 2;
    final borrowedOutstanding = (summary.unpaidAmount - balance) ~/ 2;

    return Stack(
      children: [
        // 背景色は画面上端まで。下 40px はカードと重なる。
        Container(
          height: topInset + 188,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, topInset + 20, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                balance == 0
                    ? '差引残高なし'
                    : balance > 0
                    ? '差引で受け取る予定'
                    : '差引で返す予定',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: YenAmount(
                  amount: balance.abs(),
                  prefix: balance > 0 ? '+' : (balance < 0 ? '-' : ''),
                  fontSize: 44,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: AppColors.lowShadow,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _sub(
                          context,
                          Icons.south_west_rounded,
                          '受け取る予定',
                          lentOutstanding,
                          AppColors.lend,
                        ),
                      ),
                      VerticalDivider(
                        width: 1,
                        color: Theme.of(context).dividerColor,
                      ),
                      Expanded(
                        child: _sub(
                          context,
                          Icons.north_east_rounded,
                          '返す予定',
                          borrowedOutstanding,
                          AppColors.borrow,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sub(
    BuildContext context,
    IconData icon,
    String label,
    int value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppColors.textGray),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: YenAmount(amount: value, fontSize: 20, color: color),
          ),
        ],
      ),
    );
  }
}
