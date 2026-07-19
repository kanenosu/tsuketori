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

  static const _peopleKey = 'tsuketori.people';
  static const _transactionsKey = 'tsuketori.transactions';
  static const _repaymentsKey = 'tsuketori.repayments';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<AppData> load() async {
    final prefs = await _preferences;

    final people =
        _decodeList(prefs.getString(_peopleKey))
            .map(Person.fromJson)
            .toList();
    final transactions =
        _decodeList(prefs.getString(_transactionsKey))
            .map(TransactionModel.fromJson)
            .toList();
    final repayments =
        _decodeList(prefs.getString(_repaymentsKey))
            .map(Repayment.fromJson)
            .toList();

    return AppData(
      people: people,
      transactions: transactions,
      repayments: repayments,
    );
  }

  Future<void> savePeople(List<Person> people) async {
    final prefs = await _preferences;
    await prefs.setString(
      _peopleKey,
      jsonEncode(people.map((p) => p.toJson()).toList()),
    );
  }

  Future<void> saveTransactions(List<TransactionModel> transactions) async {
    final prefs = await _preferences;
    await prefs.setString(
      _transactionsKey,
      jsonEncode(transactions.map((t) => t.toJson()).toList()),
    );
  }

  Future<void> saveRepayments(List<Repayment> repayments) async {
    final prefs = await _preferences;
    await prefs.setString(
      _repaymentsKey,
      jsonEncode(repayments.map((r) => r.toJson()).toList()),
    );
  }

  List<Map<String, dynamic>> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded.cast<Map<String, dynamic>>();
  }
}
