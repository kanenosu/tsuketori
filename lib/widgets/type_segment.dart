import 'package:flutter/material.dart';

import '../models/transaction_type.dart';
import '../theme/app_colors.dart';

/// 「貸した／借りた」のピル型セグメント（モックアップ②③準拠）。
/// 選択側が種別色（貸した=青／借りた=ピンク）で塗りつぶされる。
class TypeSegment extends StatelessWidget {
  const TypeSegment({super.key, required this.value, required this.onChanged});

  final TransactionType value;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final track =
        isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFEDF1F6);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _segment(context, TransactionType.lend, AppColors.lend),
          _segment(context, TransactionType.borrow, AppColors.borrow),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, TransactionType type, Color color) {
    final selected = value == type;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            type.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : Theme.of(context).hintColor,
            ),
          ),
        ),
      ),
    );
  }
}
