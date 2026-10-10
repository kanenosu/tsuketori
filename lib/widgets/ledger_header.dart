import 'package:flutter/material.dart';

/// Large, left-aligned title for the four main destinations.
class LedgerHeader extends StatelessWidget implements PreferredSizeWidget {
  const LedgerHeader({super.key, required this.title, this.actions = const []});
  final String title;
  final List<Widget> actions;
  @override
  Size get preferredSize => const Size.fromHeight(88);
  @override
  Widget build(BuildContext context) => AppBar(
    toolbarHeight: 88,
    titleSpacing: 20,
    centerTitle: false,
    title: Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
    actions: [...actions, const SizedBox(width: 8)],
  );
}
