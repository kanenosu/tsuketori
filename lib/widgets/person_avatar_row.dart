import 'package:flutter/material.dart';

import '../models/person.dart';
import 'person_avatar.dart';

/// アイコン＋名前（＋補足）を横並びで表示する共通行。
class PersonAvatarRow extends StatelessWidget {
  const PersonAvatarRow({
    super.key,
    required this.person,
    this.subtitle,
    this.radius = 18,
  });

  final Person person;
  final String? subtitle;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PersonAvatar(person: person, radius: radius),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              person.name,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).hintColor,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
