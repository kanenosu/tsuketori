import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// すべて／貸した／借りた の切替（PayPay の Select Button）。
///
/// 高さ 30・角丸 15。選択は塗り＋白文字、非選択は白背景＋1px #BABABA。
class PillTabs extends StatelessWidget {
  const PillTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.selectedColor = AppColors.primary,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < labels.length; i++)
          _SelectButton(
            label: labels[i],
            selected: i == selectedIndex,
            selectedColor: selectedColor,
            surface: surface,
            onTap: () => onChanged(i),
          ),
      ],
    );
  }
}

class _SelectButton extends StatelessWidget {
  const _SelectButton({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.surface,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final Color surface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? selectedColor : surface,
      shape: StadiumBorder(
        side:
            selected
                ? BorderSide.none
                : const BorderSide(color: AppColors.placeholder),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.subtextGray,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
