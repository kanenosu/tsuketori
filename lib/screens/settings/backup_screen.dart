import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/balance.dart';
import '../../services/backup_codec.dart';
import '../../services/backup_files.dart';
import '../../state/app_state.dart';
import '../../utils/formatters.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key, this.files, this.closeOnRestore = false});
  final BackupFiles? files;
  final bool closeOnRestore;

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  late final BackupFiles _files = widget.files ?? BackupFiles();
  bool _busy = false;

  void _message(String text) {
    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _export() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await context.read<AppState>().exportBackup();
      final result = await _files.save(bytes);
      switch (result) {
        case BackupSaveResult.saved:
          _message('バックアップを保存しました');
        case BackupSaveResult.downloadStarted:
          _message('ダウンロードを開始しました。ブラウザーの保存先を確認してください');
        case BackupSaveResult.cancelled:
          break;
      }
    } catch (_) {
      _message('バックアップを書き出せませんでした。台帳は変更していません');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    if (_busy) return;
    setState(() => _busy = true);
    final state = context.read<AppState>();
    try {
      final bytes = await _files.pick();
      if (bytes == null || !mounted) return;
      final archive = BackupCodec.decode(bytes);
      final revision = state.revision;
      final incoming = archive.data;
      final summary = BalanceCalculator.summarize(incoming.transactions);
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('このバックアップから復元しますか？'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '作成日時: ${Formatters.dateTime(archive.exportedAt.toLocal())}',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '復元するデータ: 相手${incoming.people.length}人・取引${incoming.transactions.length}件・返済${incoming.repayments.length}件',
                    ),
                    Text('残高: ${Formatters.signed(summary.overallBalance)}円'),
                    const SizedBox(height: 12),
                    Text(
                      state.isLoaded
                          ? '現在のデータ: 相手${state.allPeople.length}人・取引${state.transactions.length}件'
                          : '現在の保存データは読み込めないため、件数を確認できません。',
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '現在の相手・取引・返済をすべて置き換えます。追加や結合ではありません。必要なデータは先にバックアップしてください。テーマ設定は変わりません。',
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('置き換えて復元'),
                ),
              ],
            ),
      );
      if (confirmed != true || !mounted) return;
      await state.restoreBackup(archive, expectedRevision: revision);
      if (widget.closeOnRestore && mounted) {
        Navigator.of(context).pop(true);
        return;
      }
      _message('バックアップから復元しました');
    } on FormatException {
      _message('バックアップが破損しているか、対応しない形式・不整合なデータです。台帳は変更していません');
    } on ArgumentError catch (error) {
      _message(error.message.toString());
    } catch (_) {
      _message('復元できませんでした。現在の台帳を保持しています。もう一度お試しください');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('バックアップと復元')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '相手・取引・返済の全件（非表示の相手を含む）をJSONファイルに保存します。自動アップロードやクラウド同期は行いません。',
          ),
          const SizedBox(height: 12),
          const Text('ファイルは暗号化されません。名前・連絡先・金額・メモが含まれるため、安全な保存先を選んでください。'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed:
                _busy || !context.watch<AppState>().isLoaded ? null : _export,
            icon: const Icon(Icons.download),
            label: const Text('ファイルに書き出す'),
          ),
          const SizedBox(height: 24),
          const Text(
            '復元前にファイルを検証し、内容を確認します。復元すると現在の台帳が置き換わります。取消や失敗の場合は変更しません。対応形式: ツケトリJSON v1、10MB以下。',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _import,
            icon: const Icon(Icons.upload_file),
            label: const Text('ファイルを選んで復元'),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    ),
  );
}
