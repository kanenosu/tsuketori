import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/person.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/person_avatar.dart';
import 'person_edit_screen.dart';

/// 相手選択画面（要件 6.2.2 / 7.1-5）。
/// 名前検索・最近使った相手・新しい相手の追加に対応する。
class PersonSelectScreen extends StatefulWidget {
  const PersonSelectScreen({super.key});

  @override
  State<PersonSelectScreen> createState() => _PersonSelectScreenState();
}

class _PersonSelectScreenState extends State<PersonSelectScreen> {
  String _query = '';

  Future<void> _addNew() async {
    final created = await Navigator.of(context).push<Person>(
      MaterialPageRoute(builder: (_) => const PersonEditScreen()),
    );
    if (created != null && mounted) {
      Navigator.of(context).pop(created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final query = _query.trim();
    final people = appState.people
        .where((p) => query.isEmpty || p.name.contains(query))
        .toList();
    final recent = query.isEmpty ? appState.recentPeople() : const <Person>[];

    return Scaffold(
      appBar: AppBar(title: const Text('相手を選択')),
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
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_add)),
            title: const Text(
              '新しい相手を追加',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            onTap: _addNew,
          ),
          const Divider(),
          Expanded(
            child: people.isEmpty && recent.isEmpty
                ? const EmptyState(
                    icon: Icons.people_outline,
                    title: '相手が登録されていません',
                    message: '「新しい相手を追加」から登録しましょう。',
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      if (recent.isNotEmpty) ...[
                        _sectionHeader(context, '最近使った相手'),
                        ...recent.map((p) => _personTile(context, p)),
                        _sectionHeader(context, 'すべての相手'),
                      ],
                      ...people.map((p) => _personTile(context, p)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).hintColor,
      ),
    ),
  );

  Widget _personTile(BuildContext context, Person p) => ListTile(
    leading: PersonAvatar(person: p),
    title: Text(p.name),
    onTap: () => Navigator.of(context).pop(p),
  );
}
