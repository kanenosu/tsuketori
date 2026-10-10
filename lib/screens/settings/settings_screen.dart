import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../widgets/ledger_header.dart';
import 'package:provider/provider.dart';

import '../../state/settings_state.dart';
import '../../utils/persisted_action.dart';
import 'backup_screen.dart';

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
      appBar: LedgerHeader(title: '設定'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _heading(context, 'データ'),
          _group(context, [
            _Row(
              icon: CupertinoIcons.money_yen_circle,
              title: '通貨の設定',
              trailing: '円（¥）固定',
              onTap: null,
            ),
            _Row(
              icon: CupertinoIcons.square_arrow_up,
              title: 'データのバックアップ',

              onTap: () => _openBackup(context),
            ),
            _Row(
              icon: CupertinoIcons.arrow_counterclockwise,
              title: 'データの復元',

              onTap: () => _openBackup(context),
            ),
          ]),
          const SizedBox(height: 28),
          _heading(context, '表示'),
          _group(context, [
            _Row(
              icon: CupertinoIcons.circle_lefthalf_fill,
              title: 'テーマ設定',
              trailing: _themeLabel(settings.themeMode),
              onTap: () => _pickTheme(context, settings),
            ),
          ]),
          const SizedBox(height: 16),
          _group(context, [
            _Row(
              icon: CupertinoIcons.info,
              title: 'このアプリについて',
              onTap: () => _showAbout(context),
            ),
          ]),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'ツケトリ  1.0.0',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heading(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(left: 16, bottom: 8),
    child: Text(
      text,
      style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor),
    ),
  );

  void _openBackup(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BackupScreen()));
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
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final mode in ThemeMode.values)
                  ListTile(
                    trailing:
                        settings.themeMode == mode
                            ? const Icon(Icons.check)
                            : null,
                    onTap: () async {
                      if (await persistedAction(
                            context,
                            () => settings.setThemeMode(mode),
                          ) &&
                          ctx.mounted) {
                        Navigator.of(ctx).pop();
                      }
                    },
                    title: Text(_themeLabel(mode)),
                    leading: Icon(switch (mode) {
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

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: '貸し借り管理アプリ',
      applicationVersion: '1.0.0 (MVP)',
      children: const [Text('お金の貸し借りを、シンプルに、すぐに記録できるアプリです。')],
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
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w400)),
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
          if (onTap != null)
            const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }
}
