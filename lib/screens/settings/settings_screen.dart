import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/settings_state.dart';

/// 設定画面（要件 6.9・モックアップ⑨準拠）。
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'ライトモード';
      case ThemeMode.dark:
        return 'ダークモード';
      case ThemeMode.system:
        return '端末に合わせる';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();

    return Scaffold(
      appBar: AppBar(title: const Text('設定'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _group(context, [
            _Row(
              icon: Icons.attach_money,
              title: '通貨の設定',
              trailing: '円（¥）',
              onTap: () => _comingSoon(context, '通貨の設定'),
            ),
            _Row(
              icon: Icons.backup_outlined,
              title: 'データのバックアップ',
              onTap: () => _comingSoon(context, 'データのバックアップ'),
            ),
            _Row(
              icon: Icons.restore,
              title: 'データの復元',
              onTap: () => _comingSoon(context, 'データの復元'),
            ),
          ]),
          const SizedBox(height: 16),
          _group(context, [
            _Row(
              icon: Icons.palette_outlined,
              title: 'テーマ設定',
              trailing: _themeLabel(settings.themeMode),
              onTap: () => _pickTheme(context, settings),
            ),
            _Row(
              icon: Icons.lock_outline,
              title: 'パスコードロック',
              trailing: 'オフ',
              onTap: () => _comingSoon(context, 'パスコードロック'),
            ),
          ]),
          const SizedBox(height: 16),
          _group(context, [
            _Row(
              icon: Icons.mail_outline,
              title: 'サポート・お問い合わせ',
              onTap: () => _comingSoon(context, 'サポート・お問い合わせ'),
            ),
            _Row(
              icon: Icons.info_outline,
              title: 'このアプリについて',
              onTap: () => _showAbout(context),
            ),
          ]),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                '貸し借り管理アプリ  version 1.0.0',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _group(BuildContext context, List<_Row> rows) {
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 56),
            rows[i],
          ],
        ],
      ),
    );
  }

  Future<void> _pickTheme(BuildContext context, SettingsState settings) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final mode in ThemeMode.values)
              RadioListTile<ThemeMode>(
                value: mode,
                groupValue: settings.themeMode,
                onChanged: (m) {
                  settings.setThemeMode(m!);
                  Navigator.of(ctx).pop();
                },
                title: Text(_themeLabel(mode)),
                secondary: Icon(switch (mode) {
                  ThemeMode.light => Icons.light_mode,
                  ThemeMode.dark => Icons.dark_mode,
                  ThemeMode.system => Icons.brightness_auto,
                }),
              ),
          ],
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('「$label」は今後対応予定です')),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: '貸し借り管理アプリ',
      applicationVersion: '1.0.0 (MVP)',
      children: const [
        Text('お金の貸し借りを、シンプルに、すぐに記録できるアプリです。'),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(
              trailing!,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).hintColor,
              ),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }
}
