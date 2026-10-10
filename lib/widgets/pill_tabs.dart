import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: CupertinoSlidingSegmentedControl<int>(
      groupValue: selectedIndex,
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2C2C2E)
              : const Color(0xFFE4E4E9),
      thumbColor:
          Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF636366)
              : Colors.white,
      onValueChanged: (value) {
        if (value != null) onChanged(value);
      },
      children: {
        for (var i = 0; i < labels.length; i++)
          i: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              labels[i],
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    i == selectedIndex ? FontWeight.w600 : FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
      },
    ),
  );
}
