import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../state/settings_state.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/surface_card.dart';

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
              subtitle: 'JSONファイルに書き出します',
              onTap: () => _exportBackup(context),
            ),
            _Row(
              icon: Icons.restore,
              title: 'データの復元',
              subtitle: '書き出したファイルから戻します',
              onTap: () => _importBackup(context),
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
    return SurfaceCard(
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 68),
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
                    leading: Icon(switch (mode) {
                      ThemeMode.light => Icons.light_mode,
                      ThemeMode.dark => Icons.dark_mode,
                      ThemeMode.system => Icons.brightness_auto,
                    }),
                    title: Text(_themeLabel(mode)),
                    trailing:
                        settings.themeMode == mode
                            ? const Icon(Icons.check, color: Colors.blue)
                            : null,
                    onTap: () {
                      settings.setThemeMode(mode);
                      Navigator.of(ctx).pop();
                    },
                  ),
              ],
            ),
          ),
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    final appState = context.read<AppState>();
    try {
      final json = appState.createBackupJson();
      final now = DateTime.now();
      final date =
          now.year.toString() +
          now.month.toString().padLeft(2, '0') +
          now.day.toString().padLeft(2, '0');
      final uri = await FilePicker.saveFile(
        dialogTitle: 'ツケトリのバックアップを保存',
        fileName: 'tsuketori-backup-$date.json',
        bytes: Uint8List.fromList(utf8.encode(json)),
        mimeType: 'application/json',
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (uri != null && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('バックアップを保存しました')));
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('バックアップを保存できませんでした')));
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    final appState = context.read<AppState>();
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'ツケトリのバックアップを選択',
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 20 * 1024 * 1024) {
        throw const FormatException('ファイルが大きすぎます');
      }
      final preview = appState.inspectBackup(utf8.decode(bytes));
      if (!context.mounted) return;
      final direction = preview.outstandingBalance < 0 ? '返す予定' : '受け取る予定';
      final message =
          '相手 ${preview.data.people.length}人、'
          '取引 ${preview.data.transactions.length}件、'
          '返済 ${preview.data.repayments.length}件\n'
          '差引残高 ${Formatters.yenSuffix(preview.outstandingBalance.abs())}'
          '（$direction）\n\n'
          '現在の台帳をこの内容で置き換えます。よろしいですか？';
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('バックアップを復元'),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('復元する'),
                ),
              ],
            ),
      );
      if (confirmed != true) return;
      await appState.restoreBackup(preview);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('バックアップを復元しました')));
      }
    } on FormatException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('バックアップを読み取れませんでした')));
    }
  }

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('「$label」は今後対応予定です')));
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
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      subtitle:
          subtitle == null
              ? null
              : Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.subtextGray,
                ),
              ),
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
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: AppColors.placeholder,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
