import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import 'yen_amount.dart';

/// 金額入力用のハーフシート（上左右角丸 20）。
///
/// 金額を中央に大きく表示し、専用テンキーで入力する。決定で金額を返す。
Future<int?> showAmountKeypad(
  BuildContext context, {
  int? initial,
  int? max,
  Color accent = AppColors.primary,
  String title = '金額を入力',
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder:
        (_) => _AmountKeypad(
          initial: initial ?? 0,
          max: max,
          accent: accent,
          title: title,
        ),
  );
}

class _AmountKeypad extends StatefulWidget {
  const _AmountKeypad({
    required this.initial,
    required this.max,
    required this.accent,
    required this.title,
  });

  final int initial;
  final int? max;
  final Color accent;
  final String title;

  @override
  State<_AmountKeypad> createState() => _AmountKeypadState();
}

class _AmountKeypadState extends State<_AmountKeypad> {
  // 上限は 9,999,999 円（8桁で表示が崩れないように）。
  static const _limit = 9999999;

  late int _value = widget.initial;
  String? _error;

  void _press(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      _error = null;
      if (key == 'del') {
        _value ~/= 10;
        return;
      }
      final next = int.parse('$_value$key');
      if (next > _limit) return;
      _value = next;
    });
  }

  void _submit() {
    if (_value <= 0) {
      setState(() => _error = '1円以上を入力してください');
      return;
    }
    if (widget.max != null && _value > widget.max!) {
      setState(() => _error = '残額（${widget.max}円）以下にしてください');
      return;
    }
    Navigator.of(context).pop(_value);
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.placeholder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 64,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: YenAmount(
                amount: _value,
                fontSize: 56,
                fontWeight: FontWeight.w800,
                color: _value == 0 ? AppColors.placeholder : widget.accent,
              ),
            ),
          ),
          SizedBox(
            height: 24,
            child:
                _error == null
                    ? null
                    : Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.overdue,
                      ),
                    ),
          ),
          const SizedBox(height: 8),
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
            ['00', '0', 'del'],
          ])
            Row(children: [for (final k in row) Expanded(child: _key(k))]),
          const SizedBox(height: 16),
          FilledButton(onPressed: _submit, child: const Text('決定する')),
        ],
      ),
    );
  }

  Widget _key(String k) {
    return SizedBox(
      height: 60,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _press(k == 'del' ? 'del' : k),
        child: Center(
          child:
              k == 'del'
                  ? Icon(
                    Icons.backspace_outlined,
                    size: 24,
                    color: Theme.of(context).colorScheme.onSurface,
                  )
                  : Text(
                    k,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
        ),
      ),
    );
  }
}
