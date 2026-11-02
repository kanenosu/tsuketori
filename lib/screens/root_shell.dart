import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'home/home_screen.dart';
import 'history/history_screen.dart';
import 'person/person_list_screen.dart';
import 'settings/settings_screen.dart';
import 'transaction/new_transaction_screen.dart';

/// 下部タブナビゲーション（要件 8.1：ホーム／履歴／人／設定）。
///
/// 中央に主アクション「記録」の丸ボタンを置く（PayPay の中央ボタンと同じ構成）。
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  void _openNew() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const NewTransactionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onOpenHistory: () => setState(() => _index = 1),
        onOpenPeople: () => setState(() => _index = 2),
      ),
      const HistoryScreen(),
      const PersonListScreen(),
      const SettingsScreen(),
    ];
    final surface = Theme.of(context).colorScheme.surface;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        padding: EdgeInsets.only(bottom: bottom),
        height: 64 + bottom,
        child: Row(
          children: [
            _tab(0, Icons.home_outlined, Icons.home_rounded, 'ホーム'),
            _tab(
              1,
              Icons.receipt_long_outlined,
              Icons.receipt_long_rounded,
              '履歴',
            ),
            Expanded(child: _centerButton()),
            _tab(2, Icons.people_outline_rounded, Icons.people_rounded, '人'),
            _tab(3, Icons.settings_outlined, Icons.settings_rounded, '設定'),
          ],
        ),
      ),
    );
  }

  Widget _tab(int index, IconData icon, IconData selectedIcon, String label) {
    final selected = _index == index;
    final color = selected ? AppColors.primary : AppColors.subtextGray;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _index = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? selectedIcon : icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _centerButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openNew,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
              ),
              boxShadow: AppColors.middleShadow,
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 2),
          const Text(
            '記録',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
