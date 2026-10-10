import 'dart:io';

import 'package:flutter/material.dart';

import '../models/person.dart';
import 'package:flutter/foundation.dart';

/// 相手のアイコン表示（要件 6.1.2）。
/// 画像が無い場合は名前の頭文字を色付きの丸で表示する。
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({super.key, required this.person, this.radius = 22});

  final Person? person;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final iconPath = person?.iconPath;
    if (!kIsWeb &&
        iconPath != null &&
        iconPath.isNotEmpty &&
        File(iconPath).existsSync()) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(iconPath)),
      );
    }

    final name = person?.name ?? '?';
    final initial = name.isNotEmpty ? name.characters.first : '?';
    final color = Theme.of(context).hintColor;
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Text(
        initial,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: radius * 0.72,
        ),
      ),
    );
  }
}
