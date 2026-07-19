import 'package:flutter/material.dart';

import '../models/transaction_type.dart';
import '../theme/app_colors.dart';

/// 「貸した／借りた」を色と文言で明確に区別する選択UI（要件 4 / 6.2.1）。
class TypeSelector extends StatelessWidget {
  const TypeSelector({super.key, required this.value, required this.onChanged});

  final TransactionType value;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TypeButton(
            label: '貸した',
            sub: '受け取る予定',
            color: AppColors.lend,
            icon: Icons.arrow_upward,
            selected: value == TransactionType.lend,
            onTap: () => onChanged(TransactionType.lend),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TypeButton(
            label: '借りた',
            sub: '返す予定',
            color: AppColors.borrow,
            icon: Icons.arrow_downward,
            selected: value == TransactionType.borrow,
            onTap: () => onChanged(TransactionType.borrow),
          ),
        ),
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.sub,
    required this.color,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String sub;
  final Color color;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.12) : null,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color : Colors.grey.withValues(alpha: 0.3),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : Colors.grey, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: selected ? color : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? color : Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
