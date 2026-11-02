import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/person_avatar.dart';
import 'person_detail_screen.dart';
import 'person_edit_screen.dart';

/// 相手一覧画面（要件 6.5.1・モックアップ⑤準拠）。
class PersonListScreen extends StatefulWidget {
  const PersonListScreen({super.key});

  @override
  State<PersonListScreen> createState() => _PersonListScreenState();
}

class _PersonListScreenState extends State<PersonListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final query = _query.trim();
    final people =
        appState.people
            .where((p) => query.isEmpty || p.name.contains(query))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('人'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '相手を追加',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PersonEditScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: '名前で検索',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child:
                people.isEmpty
                    ? const EmptyState(
                      icon: Icons.people_outline,
                      title: '相手が登録されていません',
                      message: '右上の＋から相手を追加できます。',
                    )
                    : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Column(
                              children: [
                                for (var i = 0; i < people.length; i++) ...[
                                  if (i > 0) const Divider(height: 1),
                                  _PersonRow(personId: people[i].id),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'person_fab',
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const PersonEditScreen()));
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.personId});

  final String personId;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final person = appState.person(personId);
    if (person == null) return const SizedBox.shrink();
    final balance = appState.balanceForPerson(personId);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PersonDetailScreen(personId: personId),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            PersonAvatar(person: person, radius: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _amountLabel(
                        '貸した',
                        balance.lentOutstanding,
                        AppColors.lend,
                        positive: true,
                      ),
                      const SizedBox(width: 12),
                      _amountLabel(
                        '借りた',
                        balance.borrowedOutstanding,
                        AppColors.borrow,
                        positive: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _amountLabel(
    String label,
    int amount,
    Color color, {
    required bool positive,
  }) {
    final sign = amount == 0 ? '' : (positive ? '+' : '-');
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label：',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          TextSpan(
            text: '$sign${Formatters.yenSuffix(amount)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: amount == 0 ? Colors.grey : color,
            ),
          ),
        ],
      ),
    );
  }
}
