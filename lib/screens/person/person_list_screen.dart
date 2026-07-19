import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/person_avatar.dart';
import 'person_detail_screen.dart';
import 'person_edit_screen.dart';

/// 相手一覧画面（要件 6.5.1）。
class PersonListScreen extends StatelessWidget {
  const PersonListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final people = appState.people;

    return Scaffold(
      appBar: AppBar(title: const Text('人')),
      body: people.isEmpty
          ? const EmptyState(
              icon: Icons.people_outline,
              title: '相手が登録されていません',
              message: '右下のボタンから相手を追加できます。',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: people.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final p = people[i];
                final balance = appState.balanceForPerson(p.id);
                final diff = balance.diff;
                final diffColor = diff > 0
                    ? AppColors.lend
                    : diff < 0
                    ? AppColors.borrow
                    : AppColors.unpaid;

                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PersonDetailScreen(personId: p.id),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          PersonAvatar(person: p, radius: 24),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  balance.unsettledCount == 0
                                      ? '未精算なし'
                                      : '未精算 ${balance.unsettledCount}件',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${Formatters.signed(diff)}円',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: diffColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                diff > 0
                                    ? '受け取る'
                                    : diff < 0
                                    ? '返す'
                                    : '精算済み',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: diffColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        // IndexedStack で全タブが同時に生存するため heroTag を一意にする。
        heroTag: 'person_fab',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PersonEditScreen()),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text('相手を追加'),
      ),
    );
  }
}
