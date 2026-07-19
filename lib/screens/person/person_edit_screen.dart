import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/person.dart';
import '../../state/app_state.dart';

/// 相手の追加・編集画面（要件 6.2.2 / 6.5.3）。
/// [person] を渡すと編集、null なら新規追加。
class PersonEditScreen extends StatefulWidget {
  const PersonEditScreen({super.key, this.person});

  final Person? person;

  bool get isEditing => person != null;

  @override
  State<PersonEditScreen> createState() => _PersonEditScreenState();
}

class _PersonEditScreenState extends State<PersonEditScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _memo;
  String? _nameError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.person;
    _name = TextEditingController(text: p?.name ?? '');
    _phone = TextEditingController(text: p?.phone ?? '');
    _email = TextEditingController(text: p?.email ?? '');
    _memo = TextEditingController(text: p?.memo ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = '名前を入力してください');
      return;
    }
    setState(() => _saving = true);
    final appState = context.read<AppState>();
    final phone = _phone.text.trim().isEmpty ? null : _phone.text.trim();
    final email = _email.text.trim().isEmpty ? null : _email.text.trim();
    final memo = _memo.text.trim().isEmpty ? null : _memo.text.trim();

    if (widget.isEditing) {
      await appState.updatePerson(
        widget.person!.id,
        name: name,
        phone: phone,
        email: email,
        memo: memo,
      );
      if (!mounted) return;
      Navigator.of(context).pop(appState.person(widget.person!.id));
    } else {
      final created = await appState.addPerson(
        name: name,
        phone: phone,
        email: email,
        memo: memo,
      );
      if (!mounted) return;
      Navigator.of(context).pop(created);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? '相手を編集' : '相手を追加')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: '名前（必須）',
              errorText: _nameError,
            ),
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: '電話番号（任意）'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'メールアドレス（任意）'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _memo,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'メモ（任意）'),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(widget.isEditing ? '保存する' : '追加する'),
          ),
        ],
      ),
    );
  }
}
