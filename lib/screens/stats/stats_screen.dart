import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/transaction.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/person_avatar.dart';
import '../person/person_detail_screen.dart';

/// 統計の集計期間（要件 6.7.2）。
enum StatsPeriod {
  thisMonth('今月'),
  lastMonth('先月'),
  months3('3か月'),
  months6('6か月'),
  year('1年'),
  all('全期間');

  const StatsPeriod(this.label);
  final String label;
}

/// 統計画面（要件 6.7）。MVP では数値カードで表示する。
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  StatsPeriod _period = StatsPeriod.all;

  bool _inPeriod(TransactionModel tx, DateTime now) {
    switch (_period) {
      case StatsPeriod.thisMonth:
        return tx.date.year == now.year && tx.date.month == now.month;
      case StatsPeriod.lastMonth:
        final lm = DateTime(now.year, now.month - 1);
        return tx.date.year == lm.year && tx.date.month == lm.month;
      case StatsPeriod.months3:
        return tx.date.isAfter(DateTime(now.year, now.month - 3, now.day));
      case StatsPeriod.months6:
        return tx.date.isAfter(DateTime(now.year, now.month - 6, now.day));
      case StatsPeriod.year:
        return tx.date.isAfter(DateTime(now.year - 1, now.month, now.day));
      case StatsPeriod.all:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final now = DateTime.now();
    final txs =
        appState.transactions.where((t) => _inPeriod(t, now)).toList();
    final summary = appState.summary(txs);

    // 相手ごとの残高（差額が0でない相手のみ、絶対額の大きい順）。
    final personBalances = appState.people
        .map((p) => (p, appState.balanceForPerson(p.id).diff))
        .where((e) => e.$2 != 0)
        .toList()
      ..sort((a, b) => b.$2.abs().compareTo(a.$2.abs()));

    return Scaffold(
      appBar: AppBar(title: const Text('統計')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: StatsPeriod.values
                  .map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(p.label),
                        selected: _period == p,
                        onSelected: (_) => setState(() => _period = p),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _StatCard(
                label: '現在残高',
                value: '${Formatters.signed(summary.overallBalance)}円',
                color: summary.overallBalance >= 0
                    ? AppColors.lend
                    : AppColors.borrow,
              ),
              _StatCard(
                label: '取引件数',
                value: '${summary.transactionCount}件',
                color: AppColors.primary,
              ),
              _StatCard(
                label: '貸した総額',
                value: Formatters.yenSuffix(summary.lentTotal),
                color: AppColors.lend,
              ),
              _StatCard(
                label: '借りた総額',
                value: Formatters.yenSuffix(summary.borrowedTotal),
                color: AppColors.borrow,
              ),
              _StatCard(
                label: '返済済み金額',
                value: Formatters.yenSuffix(summary.repaidAmount),
                color: AppColors.settled,
              ),
              _StatCard(
                label: '未返済金額',
                value: Formatters.yenSuffix(summary.unpaidAmount),
                color: AppColors.unpaid,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '相手ごとの残高',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
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
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).hintColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
