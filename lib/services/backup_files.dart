import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'backup_codec.dart';

enum BackupSaveResult { saved, downloadStarted, cancelled }

/// Only user-selected local files; no network or automatic upload.
class BackupFiles {
  Future<BackupSaveResult> save(Uint8List bytes) async {
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(
      RegExp(r'[:.]'),
      '-',
    );
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'バックアップの保存先',
      fileName: 'tsuketori-$stamp.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
    );
    // Web returns null even on success: the browser owns download completion.
    if (kIsWeb) return BackupSaveResult.downloadStarted;
    return path == null ? BackupSaveResult.cancelled : BackupSaveResult.saved;
  }

  Future<Uint8List?> pick() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: '復元するバックアップを選択',
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
      withData: false,
      withReadStream: true,
    );
    if (result == null) return null;
    final file = result.files.single;
    if (file.size > BackupCodec.maxBytes) {
      throw const FormatException('10MBを超えるファイルは読み込めません');
    }
    final builder = BytesBuilder(copy: false);
    final stream = file.readStream ?? file.xFile.openRead();
    await for (final chunk in stream) {
      if (builder.length + chunk.length > BackupCodec.maxBytes) {
        throw const FormatException('10MBを超えるファイルは読み込めません');
      }
      builder.add(chunk);
    }
    return builder.takeBytes();
  }
}
