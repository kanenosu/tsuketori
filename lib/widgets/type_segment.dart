import 'package:flutter/material.dart';

import '../models/transaction_type.dart';
import '../theme/app_colors.dart';

/// 「貸した／借りた」の2択（同等の選択肢を横並び2つ）。
/// 選択側が種別色で塗られ、アイコンでも区別する。角丸 8。
class TypeSegment extends StatelessWidget {
  const TypeSegment({super.key, required this.value, required this.onChanged});

  final TransactionType value;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _segment(
          context,
          TransactionType.lend,
          AppColors.lend,
          Icons.south_west_rounded,
        ),
        const SizedBox(width: 12),
        _segment(
          context,
          TransactionType.borrow,
          AppColors.borrow,
          Icons.north_east_rounded,
        ),
      ],
    );
  }

  Widget _segment(
    BuildContext context,
    TransactionType type,
    Color color,
    IconData icon,
  ) {
    final selected = value == type;
    final surface = Theme.of(context).colorScheme.surface;
    return Expanded(
      child: Material(
        color: selected ? color : surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side:
              selected
                  ? BorderSide.none
                  : const BorderSide(color: AppColors.placeholder),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onChanged(type),
          child: SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: selected ? Colors.white : color),
                const SizedBox(width: 4),
                Text(
                  type.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.subtextGray,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
