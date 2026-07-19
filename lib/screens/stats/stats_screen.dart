import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/transaction.dart';
import '../../models/transaction_type.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/person_avatar.dart';
import '../../widgets/pill_tabs.dart';
import '../person/person_detail_screen.dart';

/// 統計画面（要件 6.7・モックアップ⑧準拠）。
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  // 0=月別 / 1=年別。
  int _mode = 0;
  DateTime _anchor = DateTime.now();

  bool get _monthly => _mode == 0;

  void _shift(int delta) {
    setState(() {
      _anchor = _monthly
          ? DateTime(_anchor.year, _anchor.month + delta)
          : DateTime(_anchor.year + delta, _anchor.month);
    });
  }

  bool _inPeriod(TransactionModel tx) {
    if (_monthly) {
      return tx.date.year == _anchor.year && tx.date.month == _anchor.month;
    }
    return tx.date.year == _anchor.year;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final txs = appState.transactions.where(_inPeriod).toList();
    final summary = appState.summary(txs);
    final balance = summary.lentTotal - summary.borrowedTotal;

    final lendCount = txs
        .where((t) => !t.isCancelled && t.type == TransactionType.lend)
        .length;
    final borrowCount = txs
        .where((t) => !t.isCancelled && t.type == TransactionType.borrow)
        .length;

    final personBalances = appState.people
        .map((p) => (p, appState.balanceForPerson(p.id).diff))
        .where((e) => e.$2 != 0)
        .toList()
      ..sort((a, b) => b.$2.abs().compareTo(a.$2.abs()));

    return Scaffold(
      appBar: AppBar(title: const Text('統計'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          SizedBox(
            width: 220,
            child: PillTabs(
              labels: const ['月別', '年別'],
              selectedIndex: _mode,
              onChanged: (i) => setState(() => _mode = i),
            ),
          ),
          const SizedBox(height: 16),
          // 期間ナビゲーター。
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _shift(-1),
              ),
              Text(
                _monthly
                    ? Formatters.monthLabel(_anchor)
                    : '${_anchor.year}年',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _shift(1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 収支カード。
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '収支',
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${Formatters.signed(balance)}円',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: balance >= 0 ? AppColors.lend : AppColors.borrow,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _metric(
                        '貸した総額',
                        Formatters.yenSuffix(summary.lentTotal),
                        AppColors.lend,
                      ),
                      _metric(
                        '借りた総額',
                        Formatters.yenSuffix(summary.borrowedTotal),
                        AppColors.borrow,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 取引件数カード。
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '取引件数',
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _metric('貸した', '$lendCount件', AppColors.lend),
                      _metric('借りた', '$borrowCount件', AppColors.borrow),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '相手ごとの残高',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (personBalances.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '未精算の残高はありません',
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            )
          else
            ...personBalances.map((e) {
              final person = e.$1;
              final diff = e.$2;
              final color = diff > 0 ? AppColors.lend : AppColors.borrow;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: PersonAvatar(person: person, radius: 20),
                  title: Text(person.name),
                  trailing: Text(
                    '${Formatters.signed(diff)}円',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            PersonDetailScreen(personId: person.id),
                      ),
                    );
                  },
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
