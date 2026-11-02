import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/person.dart';
import '../models/repayment.dart';
import '../models/transaction.dart';

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

  Map<String, dynamic> toJson() => {
    'people': people.map((item) => item.toJson()).toList(),
    'transactions': transactions.map((item) => item.toJson()).toList(),
    'repayments': repayments.map((item) => item.toJson()).toList(),
  };

  factory AppData.fromJson(Map<String, dynamic> json) => AppData(
    people: _maps(json['people']).map(Person.fromJson).toList(),
    transactions:
        _maps(json['transactions']).map(TransactionModel.fromJson).toList(),
    repayments: _maps(json['repayments']).map(Repayment.fromJson).toList(),
  );

  static List<Map<String, dynamic>> _maps(Object? value) {
    if (value is! List) throw const FormatException('一覧データが不正です');
    return value.map((item) {
      if (item is! Map) throw const FormatException('項目データが不正です');
      return Map<String, dynamic>.from(item);
    }).toList();
  }
}

/// Local persistence for the ledger.
///
/// Current releases store one complete JSON snapshot so related changes are
/// committed together. The three legacy keys are still read to avoid losing
/// data created by older builds.
class AppRepository {
  AppRepository({SharedPreferences? preferences}) : _prefs = preferences;

  static const _snapshotKey = 'tsuketori.snapshot.v2';
  static const _peopleKey = 'tsuketori.people';
  static const _transactionsKey = 'tsuketori.transactions';
  static const _repaymentsKey = 'tsuketori.repayments';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<AppData> load() async {
    final prefs = await _preferences;
    final snapshot = prefs.getString(_snapshotKey);
    if (snapshot != null && snapshot.isNotEmpty) {
      final decoded = jsonDecode(snapshot);
      if (decoded is! Map) throw const FormatException('保存データが不正です');
      return AppData.fromJson(Map<String, dynamic>.from(decoded));
    }

    return AppData(
      people:
          _decodeLegacy(
            prefs.getString(_peopleKey),
          ).map(Person.fromJson).toList(),
      transactions:
          _decodeLegacy(
            prefs.getString(_transactionsKey),
          ).map(TransactionModel.fromJson).toList(),
      repayments:
          _decodeLegacy(
            prefs.getString(_repaymentsKey),
          ).map(Repayment.fromJson).toList(),
    );
  }

  Future<void> saveAll(AppData data) async {
    final prefs = await _preferences;
    final saved = await prefs.setString(
      _snapshotKey,
      jsonEncode(data.toJson()),
    );
    if (!saved) throw StateError('台帳を保存できませんでした');
  }

  /// Legacy-compatible narrow saves. New code should prefer [saveAll].
  Future<void> savePeople(List<Person> people) async {
    final current = await load();
    await saveAll(
      AppData(
        people: people,
        transactions: current.transactions,
        repayments: current.repayments,
      ),
    );
  }

  Future<void> saveTransactions(List<TransactionModel> transactions) async {
    final current = await load();
    await saveAll(
      AppData(
        people: current.people,
        transactions: transactions,
        repayments: current.repayments,
      ),
    );
  }

  Future<void> saveRepayments(List<Repayment> repayments) async {
    final current = await load();
    await saveAll(
      AppData(
        people: current.people,
        transactions: current.transactions,
        repayments: repayments,
      ),
    );
  }

  List<Map<String, dynamic>> _decodeLegacy(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) throw const FormatException('保存データが不正です');
    return decoded.map((item) {
      if (item is! Map) throw const FormatException('保存データが不正です');
      return Map<String, dynamic>.from(item);
    }).toList();
  }
}
