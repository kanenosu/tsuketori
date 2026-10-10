import 'package:flutter/material.dart';

/// Keep the current screen and explain a failed write instead of losing input.
Future<bool> persistedAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
    return true;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ArgumentError
                ? error.message.toString()
                : '保存できませんでした。もう一度お試しください',
          ),
        ),
      );
    }
    return false;
  }
}
