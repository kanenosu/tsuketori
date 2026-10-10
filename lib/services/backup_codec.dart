import 'dart:convert';
import 'dart:typed_data';

import '../models/person.dart';
import '../models/repayment.dart';
import '../models/transaction.dart';
import '../repositories/app_repository.dart';

class BackupArchive {
  const BackupArchive._(this.data, this.exportedAt);
  final AppData data;
  final DateTime exportedAt;
}

/// Portable, versioned JPY ledger. Validate everything before changing state.
class BackupCodec {
  static const maxBytes = 10 * 1024 * 1024;
  static const maxRecords = 100000;
  static const maxAmount = 9999999999;

  static Uint8List encode(AppData data, {DateTime? now}) {
    final bytes = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'format': 'tsuketori.backup',
          'version': 1,
          'currency': 'JPY',
          'exportedAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
          'people': data.people.map((p) => p.toJson()).toList(),
          'transactions': data.transactions.map((t) => t.toJson()).toList(),
          'repayments': data.repayments.map((r) => r.toJson()).toList(),
        }),
      ),
    );
    decode(bytes); // Never offer an inconsistent ledger as a usable backup.
    return bytes;
  }

  static BackupArchive decode(Uint8List bytes) {
    if (bytes.isEmpty || bytes.length > maxBytes) {
      throw const FormatException('空のファイル、または10MBを超えるファイルは読み込めません');
    }
    try {
      final root = _map(jsonDecode(utf8.decode(bytes)));
      if (root['format'] != 'tsuketori.backup' ||
          root['version'] != 1 ||
          root['version'] is! int) {
        throw const FormatException('ツケトリの対応するバックアップ形式ではありません');
      }
      if (root['currency'] != 'JPY') {
        throw const FormatException('円以外のバックアップは読み込めません');
      }
      final exportedAt = _date(root, 'exportedAt');
      final people = _rows(root, 'people');
      final transactions = _rows(root, 'transactions');
      final repayments = _rows(root, 'repayments');
      final personIds = _ids(people);
      final transactionIds = _ids(transactions);
      _ids(repayments);
      for (final p in people) {
        _text(p, 'name', required: true);
        if (p['isHidden'] is! bool) _invalid();
        for (final key in ['phone', 'email', 'memo', 'iconPath']) {
          _text(p, key);
        }
        _date(p, 'createdAt');
        _date(p, 'updatedAt');
      }
      final sums = <String, int>{};
      for (final r in repayments) {
        final id = _text(r, 'transactionId', required: true)!;
        if (!transactionIds.contains(id)) _invalid();
        final amount = _amount(r, 'amount', minimum: 1);
        sums[id] = (sums[id] ?? 0) + amount;
        if (sums[id]! > maxAmount) _invalid();
        if (r['method'] != null &&
            !RepaymentMethod.values.any((m) => m.name == r['method'])) {
          _invalid();
        }
        _text(r, 'memo');
        _date(r, 'date');
        _date(r, 'createdAt');
      }
      for (final t in transactions) {
        if (!personIds.contains(_text(t, 'personId', required: true))) {
          _invalid();
        }
        if (!['lend', 'borrow'].contains(t['type'])) _invalid();
        if (![
          'unpaid',
          'partial',
          'settled',
          'cancelled',
        ].contains(t['status'])) {
          _invalid();
        }
        final amount = _amount(t, 'amount', minimum: 1);
        final repaid = _amount(t, 'repaidAmount');
        if (repaid > amount ||
            repaid != (sums[t['id']] ?? 0) ||
            _amount(t, 'remainingAmount') != amount - repaid) {
          _invalid();
        }
        final expected =
            repaid == amount ? 'settled' : (repaid > 0 ? 'partial' : 'unpaid');
        if (t['status'] != 'cancelled' && t['status'] != expected) _invalid();
        _text(t, 'memo');
        for (final key in ['date', 'createdAt', 'updatedAt']) {
          _date(t, key);
        }
        if (t['dueDate'] != null) _date(t, 'dueDate');
      }
      return BackupArchive._(
        AppData(
          people: List.unmodifiable(people.map(Person.fromJson)),
          transactions: List.unmodifiable(
            transactions.map(TransactionModel.fromJson),
          ),
          repayments: List.unmodifiable(repayments.map(Repayment.fromJson)),
        ),
        exportedAt,
      );
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('バックアップの内容が不正です');
    }
  }

  static Never _invalid() =>
      throw const FormatException('バックアップの項目・参照・金額に不整合があります');

  static Map<String, dynamic> _map(Object? value) {
    if (value is! Map<String, dynamic>) _invalid();
    return value;
  }

  static List<Map<String, dynamic>> _rows(
    Map<String, dynamic> root,
    String key,
  ) {
    final value = root[key];
    if (value is! List || value.length > maxRecords) _invalid();
    return value.map(_map).toList();
  }

  static Set<String> _ids(List<Map<String, dynamic>> rows) {
    final result = <String>{};
    for (final row in rows) {
      if (!result.add(_text(row, 'id', required: true)!)) _invalid();
    }
    return result;
  }

  static String? _text(
    Map<String, dynamic> row,
    String key, {
    bool required = false,
  }) {
    final value = row[key];
    if (value == null && !required) return null;
    if (value is! String ||
        value.length > 10000 ||
        (required && value.trim().isEmpty)) {
      _invalid();
    }
    return value;
  }

  static int _amount(Map<String, dynamic> row, String key, {int minimum = 0}) {
    final value = row[key];
    if (value is! int || value < minimum || value > maxAmount) _invalid();
    return value;
  }

  static DateTime _date(Map<String, dynamic> row, String key) {
    final raw = _text(row, key, required: true)!;
    final value = DateTime.tryParse(raw);
    // Reject normalized invalid dates (e.g. February 31), not just parse errors.
    if (value == null || value.toIso8601String() != raw) _invalid();
    return value;
  }
}
