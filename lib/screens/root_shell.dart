import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'home/home_screen.dart';
import 'history/history_screen.dart';
import 'person/person_list_screen.dart';
import 'settings/settings_screen.dart';

/// 下部タブナビゲーション（要件 8.1：ホーム／履歴／人／設定）。
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onOpenHistory: () => setState(() => _index = 1)),
      const HistoryScreen(),
      const PersonListScreen(),
      const SettingsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: _index,
        activeColor: Theme.of(context).colorScheme.primary,
        inactiveColor: Theme.of(context).hintColor,
        backgroundColor: Theme.of(context).cardColor.withValues(alpha: 0.96),
        height: 52,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.house),
            activeIcon: Icon(CupertinoIcons.house_fill),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.list_bullet),
            activeIcon: Icon(CupertinoIcons.list_bullet),
            label: '履歴',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_2),
            activeIcon: Icon(CupertinoIcons.person_2_fill),
            label: '人',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.gear),
            activeIcon: Icon(CupertinoIcons.gear_solid),
            label: '設定',
          ),
        ],
      ),
    );
  }
}
