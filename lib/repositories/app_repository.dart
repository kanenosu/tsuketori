import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/person.dart';
import '../models/repayment.dart';
import '../models/transaction.dart';

/// アプリのデータ一式。
class AppData {
  const AppData({
    required this.people,
    required this.transactions,
    required this.repayments,
  });

  const AppData.empty()
    : people = const [],
      transactions = const [],
      repayments = const [];

  final List<Person> people;
  final List<TransactionModel> transactions;
  final List<Repayment> repayments;
}

/// ローカル永続化（要件 12.3：初期リリースはローカル保存を基本とする）。
///
/// MVP では `shared_preferences` に JSON 文字列として保存する。
/// 将来的に SQLite / 暗号化 / クラウド同期へ差し替えられるよう、
/// 画面・状態層からはこのインターフェース経由でのみアクセスする。
class AppRepository {
  AppRepository({SharedPreferences? preferences}) : _prefs = preferences;

  static const _ledgerKey = 'tsuketori.ledger.v1';
  static const _peopleKey = 'tsuketori.people';
  static const _transactionsKey = 'tsuketori.transactions';
  static const _repaymentsKey = 'tsuketori.repayments';

  SharedPreferences? _prefs;
  bool _reloadRequired = false;

  Future<SharedPreferences> get _preferences async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    if (_reloadRequired) {
      await prefs.reload();
      _reloadRequired = false;
    }
    return prefs;
  }

  Future<AppData> load() async {
    final prefs = await _preferences;

    final ledger = prefs.getString(_ledgerKey);
    if (ledger != null) {
      final data = jsonDecode(ledger) as Map<String, dynamic>;
      if (data['version'] != 1) throw const FormatException('未対応の保存形式です');
      return AppData(
        people:
            (data['people'] as List)
                .map((p) => Person.fromJson(p as Map<String, dynamic>))
                .toList(),
        transactions:
            (data['transactions'] as List)
                .map(
                  (t) => TransactionModel.fromJson(t as Map<String, dynamic>),
                )
                .toList(),
        repayments:
            (data['repayments'] as List)
                .map((r) => Repayment.fromJson(r as Map<String, dynamic>))
                .toList(),
      );
    }
    // Read the original three keys until the first successful snapshot save.
    final people =
        _decodeList(prefs.getString(_peopleKey)).map(Person.fromJson).toList();
    final transactions =
        _decodeList(
          prefs.getString(_transactionsKey),
        ).map(TransactionModel.fromJson).toList();
    final repayments =
        _decodeList(
          prefs.getString(_repaymentsKey),
        ).map(Repayment.fromJson).toList();

    return AppData(
      people: people,
      transactions: transactions,
      repayments: repayments,
    );
  }

  Future<void> save(AppData data) async {
    final encoded = jsonEncode({
      'version': 1,
      'people': data.people.map((p) => p.toJson()).toList(),
      'transactions': data.transactions.map((t) => t.toJson()).toList(),
      'repayments': data.repayments.map((r) => r.toJson()).toList(),
    });
    final prefs = await _preferences;
    try {
      if (!await prefs.setString(_ledgerKey, encoded)) {
        throw StateError('データを保存できませんでした');
      }
    } catch (_) {
      // setString updates the plugin cache before the platform write completes.
      // Discard a rejected value so a later load cannot resurrect a failed import.
      _reloadRequired = true;
      try {
        await prefs.reload();
        _reloadRequired = false;
      } catch (_) {
        /* A later operation must reload before using this cache. */
      }
      rethrow;
    }
  }

  List<Map<String, dynamic>> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) throw const FormatException('保存データが不正です');
    return decoded.cast<Map<String, dynamic>>();
  }
}
