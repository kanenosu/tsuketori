import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/settings_state.dart';

/// 設定画面（要件 6.9）。
/// MVP ではテーマ設定を実装し、その他の項目は今後対応として一覧化する。
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _sectionHeader(context, '表示'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: settings.themeMode,
                  onChanged: (m) => settings.setThemeMode(m!),
                  title: const Text('端末設定に合わせる'),
                  secondary: const Icon(Icons.brightness_auto),
                ),
                const Divider(height: 1),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: settings.themeMode,
                  onChanged: (m) => settings.setThemeMode(m!),
                  title: const Text('ライト'),
                  secondary: const Icon(Icons.light_mode),
                ),
                const Divider(height: 1),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: settings.themeMode,
                  onChanged: (m) => settings.setThemeMode(m!),
                  title: const Text('ダーク'),
                  secondary: const Icon(Icons.dark_mode),
                ),
              ],
            ),
          ),
          _sectionHeader(context, '今後対応予定'),
          _comingSoonGroup(context, const [
            (Icons.notifications_outlined, '通知設定'),
            (Icons.attach_money, '通貨設定'),
            (Icons.lock_outline, 'パスコードロック'),
            (Icons.fingerprint, '生体認証'),
            (Icons.backup_outlined, 'データのバックアップ'),
            (Icons.restore, 'データの復元'),
          ]),
          _sectionHeader(context, 'アプリについて'),
          _comingSoonGroup(context, const [
            (Icons.description_outlined, '利用規約'),
            (Icons.privacy_tip_outlined, 'プライバシーポリシー'),
            (Icons.mail_outline, 'お問い合わせ'),
          ]),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'ツケトリ  version 1.0.0 (MVP)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).hintColor,
      ),
    ),
  );

  Widget _comingSoonGroup(
    BuildContext context,
    List<(IconData, String)> items,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            ListTile(
              leading: Icon(items[i].$1),
              title: Text(items[i].$2),
              trailing: const Text(
                '準備中',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('「${items[i].$2}」は今後対応予定です')),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
