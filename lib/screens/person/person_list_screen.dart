import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../widgets/ledger_header.dart';
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
  bool _showHidden = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final query = _query.trim();
    final people =
        (_showHidden
                ? appState.allPeople.where((p) => p.isHidden)
                : appState.people)
            .where((p) => query.isEmpty || p.name.contains(query))
            .toList();

    return Scaffold(
      appBar: LedgerHeader(
        title: _showHidden ? '非表示の相手' : '人',
        actions: [
          IconButton(
            tooltip: _showHidden ? '表示中の相手' : '非表示の相手',
            icon: Icon(
              _showHidden ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
            ),
            onPressed: () => setState(() => _showHidden = !_showHidden),
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.add),
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: '名前で検索',
                prefixIcon: Icon(CupertinoIcons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child:
                people.isEmpty
                    ? EmptyState(
                      icon: Icons.people_outline,
                      title:
                          query.isNotEmpty
                              ? '該当する相手がいません'
                              : (_showHidden ? '非表示の相手はいません' : '相手が登録されていません'),
                      message:
                          query.isNotEmpty
                              ? '名前を変えて検索してください。'
                              : (_showHidden
                                  ? '相手を非表示にするとここに表示されます。'
                                  : '右上の＋から相手を追加できます。'),
                    )
                    : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
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
      borderRadius: BorderRadius.circular(12),
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    children: [
                      _amountLabel(
                        '貸した',
                        balance.lentOutstanding,
                        AppColors.lend,
                        positive: true,
                      ),
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
              fontWeight: FontWeight.w500,
              color: amount == 0 ? Colors.grey : color,
            ),
          ),
        ],
      ),
    );
  }
}
