import 'dart:io';

import 'package:flutter/material.dart';

import '../models/person.dart';
import '../theme/app_colors.dart';

/// 相手のアイコン表示（要件 6.1.2）。
/// 画像が無い場合は名前の頭文字を色付きの丸で表示する。
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({super.key, required this.person, this.radius = 22});

  final Person? person;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final iconPath = person?.iconPath;
    if (iconPath != null &&
        iconPath.isNotEmpty &&
        File(iconPath).existsSync()) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(iconPath)),
      );
    }

    final name = person?.name ?? '?';
    final initial = name.isNotEmpty ? name.characters.first : '?';
    final color = _colorFor(name);
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Text(
        initial,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }

  Color _colorFor(String name) {
    if (name.isEmpty) return AppColors.primary;
    // PayPay Extended color の 01 行（背景は同色 15%）。
    const palette = [
      Color(0xFF3895FF),
      Color(0xFF7921A3),
      Color(0xFF00C2C2),
      Color(0xFFF23099),
      Color(0xFFFC6600),
      Color(0xFF26BF7D),
      Color(0xFF00B9F5),
    ];
    return palette[name.hashCode.abs() % palette.length];
  }
}
