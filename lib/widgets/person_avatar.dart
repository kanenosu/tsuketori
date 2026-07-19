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
    if (iconPath != null && iconPath.isNotEmpty && File(iconPath).existsSync()) {
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
    const palette = [
      Color(0xFF2563EB),
      Color(0xFF7C3AED),
      Color(0xFF0891B2),
      Color(0xFFDB2777),
      Color(0xFFEA580C),
      Color(0xFF16A34A),
      Color(0xFFCA8A04),
    ];
    return palette[name.hashCode.abs() % palette.length];
  }
}
