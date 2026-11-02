import 'dart:convert';

import '../models/transaction_status.dart';
import '../repositories/app_repository.dart';

class BackupPreview {
  const BackupPreview({required this.exportedAt, required this.data});

  final DateTime exportedAt;
  final AppData data;

  int get outstandingBalance {
    var result = 0;
    for (final transaction in data.transactions) {
      if (transaction.isCancelled) continue;
      final signed = transaction.type.name == 'lend' ? 1 : -1;
      result += transaction.remainingAmount * signed;
    }
    return result;
  }
}

/// Versioned and strictly validated import/export format.
class BackupCodec {
  static const format = 'tsuketori-backup';
  static const version = 1;

  static String encode(AppData data, {DateTime? exportedAt}) {
    return const JsonEncoder.withIndent('  ').convert({
      'format': format,
      'version': version,
      'exportedAt': (exportedAt ?? DateTime.now()).toUtc().toIso8601String(),
      'data': data.toJson(),
    });
  }

  static BackupPreview decode(String source) {
    Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const FormatException('JSONファイルとして読み取れません');
    }
    if (decoded is! Map) throw const FormatException('バックアップ形式が不正です');
    final root = Map<String, dynamic>.from(decoded);
    if (root['format'] != format) {
      throw const FormatException('ツケトリのバックアップではありません');
    }
    if (root['version'] != version) {
      throw const FormatException('このバックアップ形式には対応していません');
    }

    final exportedAtValue = root['exportedAt'];
    final dataValue = root['data'];
    if (exportedAtValue is! String || dataValue is! Map) {
      throw const FormatException('バックアップの必須項目が不足しています');
    }

    late final DateTime exportedAt;
    late final AppData data;
    try {
      exportedAt = DateTime.parse(exportedAtValue);
      data = AppData.fromJson(Map<String, dynamic>.from(dataValue));
    } catch (_) {
      throw const FormatException('バックアップ内の項目を読み取れません');
    }
    _validate(data);
    return BackupPreview(exportedAt: exportedAt, data: data);
  }

  static void _validate(AppData data) {
    final personIds = <String>{};
    for (final person in data.people) {
      if (person.id.isEmpty || person.name.trim().isEmpty) {
        throw const FormatException('相手データに空の必須項目があります');
      }
      if (!personIds.add(person.id)) {
        throw const FormatException('相手IDが重複しています');
      }
    }

    final transactionIds = <String>{};
    for (final transaction in data.transactions) {
      if (transaction.id.isEmpty || !personIds.contains(transaction.personId)) {
        throw const FormatException('取引が存在しない相手を参照しています');
      }
      if (!transactionIds.add(transaction.id)) {
        throw const FormatException('取引IDが重複しています');
      }
      if (transaction.amount <= 0 || transaction.repaidAmount < 0) {
        throw const FormatException('取引金額が不正です');
      }
    }

    final repaymentIds = <String>{};
    final totals = <String, int>{};
    for (final repayment in data.repayments) {
      if (repayment.id.isEmpty ||
          !transactionIds.contains(repayment.transactionId)) {
        throw const FormatException('返済が存在しない取引を参照しています');
      }
      if (!repaymentIds.add(repayment.id)) {
        throw const FormatException('返済IDが重複しています');
      }
      if (repayment.amount <= 0) {
        throw const FormatException('返済金額が不正です');
      }
      totals.update(
        repayment.transactionId,
        (value) => value + repayment.amount,
        ifAbsent: () => repayment.amount,
      );
    }

    for (final transaction in data.transactions) {
      final repaid = totals[transaction.id] ?? 0;
      if (repaid > transaction.amount || repaid != transaction.repaidAmount) {
        throw const FormatException('取引金額と返済合計が一致しません');
      }
      final expected =
          transaction.status == TransactionStatus.cancelled
              ? TransactionStatus.cancelled
              : repaid == transaction.amount
              ? TransactionStatus.settled
              : repaid > 0
              ? TransactionStatus.partial
              : TransactionStatus.unpaid;
      if (transaction.status != expected) {
        throw const FormatException('取引ステータスと返済履歴が一致しません');
      }
    }
  }
}
