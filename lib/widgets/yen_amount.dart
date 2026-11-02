import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// 価格表示（PayPay Typography の価格ルール）。
///
/// 「円」は数字より小さく：数字 24px 以上は 1/2、14〜22px は 12px、
/// それ未満は 11px。
class YenAmount extends StatelessWidget {
  const YenAmount({
    super.key,
    required this.amount,
    this.fontSize = 16,
    this.color,
    this.prefix = '',
    this.fontWeight = FontWeight.w700,
  });

  final int amount;
  final double fontSize;
  final Color? color;

  /// 「+」「-」など数字の前に付ける記号。
  final String prefix;
  final FontWeight fontWeight;

  static double unitSize(double numberSize) {
    if (numberSize >= 24) return numberSize / 2;
    if (numberSize >= 14) return 12;
    return 11;
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$prefix${Formatters.number(amount)}',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              letterSpacing: fontSize >= 24 ? -0.5 : 0,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          TextSpan(
            text: '円',
            style: TextStyle(
              fontSize: unitSize(fontSize),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      style: TextStyle(color: c, height: 1.2),
      maxLines: 1,
    );
  }
}

/// 金額入力欄の末尾に常時表示する「円」（数字 24px 以上 → 1/2 サイズ）。
class YenSuffix extends StatelessWidget {
  const YenSuffix({super.key, this.numberSize = 32});

  final double numberSize;

  static const constraints = BoxConstraints(minWidth: 0, minHeight: 0);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 6),
      child: Text(
        '円',
        style: TextStyle(
          fontSize: YenAmount.unitSize(numberSize),
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
