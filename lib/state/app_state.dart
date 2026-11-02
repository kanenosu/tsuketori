import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/balance.dart';
import '../models/person.dart';
import '../models/repayment.dart';
import '../models/transaction.dart';
import '../models/transaction_status.dart';
import '../models/transaction_type.dart';
import '../repositories/app_repository.dart';
import '../services/backup_codec.dart';

/// アプリ全体の状態を保持し、取引・相手・返済の CRUD と集計を提供する。
class AppState extends ChangeNotifier {
  AppState({AppRepository? repository})
    : _repository = repository ?? AppRepository();

  final AppRepository _repository;
  final Uuid _uuid = const Uuid();

  final Map<String, Person> _people = {};
  final Map<String, TransactionModel> _transactions = {};
  final List<Repayment> _repayments = [];

  bool _loaded = false;
  bool get isLoaded => _loaded;

  /// 直前に選んだ取引種別（要件 6.2.1：初期状態で保持してよい）。
  TransactionType lastUsedType = TransactionType.lend;

  // ---------------------------------------------------------------------------
  // 読み込み
  // ---------------------------------------------------------------------------

  Future<void> load() async {
    final data = await _repository.load();
    _replaceWith(data);
    _loaded = true;
    notifyListeners();
  }

  void _replaceWith(AppData data) {
    _people
      ..clear()
      ..addEntries(data.people.map((p) => MapEntry(p.id, p)));
    _transactions
      ..clear()
      ..addEntries(data.transactions.map((t) => MapEntry(t.id, t)));
    _repayments
      ..clear()
      ..addAll(data.repayments);
  }

  AppData get snapshot => AppData(
    people: List.unmodifiable(_people.values),
    transactions: List.unmodifiable(_transactions.values),
    repayments: List.unmodifiable(_repayments),
  );

  Future<void> _saveAll() => _repository.saveAll(snapshot);

  Future<T> _mutateAndSave<T>(T Function() mutation) async {
    final before = snapshot;
    final previousLastUsedType = lastUsedType;
    try {
      final result = mutation();
      await _saveAll();
      notifyListeners();
      return result;
    } catch (_) {
      _replaceWith(before);
      lastUsedType = previousLastUsedType;
      rethrow;
    }
  }

  String createBackupJson({DateTime? exportedAt}) =>
      BackupCodec.encode(snapshot, exportedAt: exportedAt);

  BackupPreview inspectBackup(String source) => BackupCodec.decode(source);

  Future<void> restoreBackup(BackupPreview preview) async {
    // Persist first. If this fails, the in-memory ledger remains untouched.
    await _repository.saveAll(preview.data);
    _replaceWith(preview.data);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // 参照
  // ---------------------------------------------------------------------------

  /// 表示対象の相手（非表示を除く）。名前順。
  List<Person> get people {
    final list = _people.values.where((p) => !p.isHidden).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  /// 非表示を含む全相手。
  List<Person> get allPeople => _people.values.toList();

  Person? person(String id) => _people[id];

  /// 全取引（新しい順）。
  List<TransactionModel> get transactions {
    final list = _transactions.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  TransactionModel? transaction(String id) => _transactions[id];

  /// 指定した相手の取引（新しい順）。
  List<TransactionModel> transactionsForPerson(String personId) {
    final list =
        _transactions.values.where((t) => t.personId == personId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// 指定した取引の返済履歴（新しい順）。
  List<Repayment> repaymentsForTransaction(String transactionId) {
    final list =
        _repayments.where((r) => r.transactionId == transactionId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// 最近取引した相手（新しい順・重複なし）。要件 6.2.2。
  List<Person> recentPeople({int limit = 5}) {
    final ordered = transactions;
    final seen = <String>{};
    final result = <Person>[];
    for (final tx in ordered) {
      if (seen.add(tx.personId)) {
        final p = _people[tx.personId];
        if (p != null && !p.isHidden) result.add(p);
      }
      if (result.length >= limit) break;
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // 集計
  // ---------------------------------------------------------------------------

  /// 全体集計（ホーム・統計）。[transactions] を指定すると期間絞り込み等に使える。
  BalanceSummary summary([Iterable<TransactionModel>? txs]) =>
      BalanceCalculator.summarize(txs ?? _transactions.values);

  PersonBalance balanceForPerson(String personId) =>
      BalanceCalculator.summarizeForPerson(transactionsForPerson(personId));

  // ---------------------------------------------------------------------------
  // 相手 CRUD
  // ---------------------------------------------------------------------------

  Future<Person> addPerson({
    required String name,
    String? phone,
    String? email,
    String? memo,
    String? iconPath,
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError('名前を入力してください');
    }
    final now = DateTime.now();
    final person = Person(
      id: _uuid.v4(),
      name: normalizedName,
      phone: phone,
      email: email,
      memo: memo,
      iconPath: iconPath,
      createdAt: now,
      updatedAt: now,
    );
    return _mutateAndSave(() {
      _people[person.id] = person;
      return person;
    });
  }

  Future<void> updatePerson(
    String id, {
    String? name,
    String? phone,
    String? email,
    String? memo,
    String? iconPath,
    bool? isHidden,
  }) async {
    final existing = _people[id];
    if (existing == null) return;
    if (name != null && name.trim().isEmpty) {
      throw ArgumentError('名前を入力してください');
    }
    await _mutateAndSave<void>(() {
      _people[id] = existing.copyWith(
        name: name?.trim(),
        phone: phone,
        email: email,
        memo: memo,
        iconPath: iconPath,
        isHidden: isHidden,
        updatedAt: DateTime.now(),
      );
    });
  }

  bool personHasTransactions(String id) =>
      _transactions.values.any((t) => t.personId == id);

  /// 相手を非表示にする（要件 13.3）。
  Future<void> hidePerson(String id) => updatePerson(id, isHidden: true);

  Future<void> unhidePerson(String id) => updatePerson(id, isHidden: false);

  /// 相手を取引ごと削除する（要件 13.3）。
  Future<void> deletePersonWithTransactions(String id) async {
    await _mutateAndSave<void>(() {
      final txIds =
          _transactions.values
              .where((t) => t.personId == id)
              .map((t) => t.id)
              .toSet();
      _transactions.removeWhere((_, t) => t.personId == id);
      _repayments.removeWhere((r) => txIds.contains(r.transactionId));
      _people.remove(id);
    });
  }

  // ---------------------------------------------------------------------------
  // 取引 CRUD
  // ---------------------------------------------------------------------------

  Future<TransactionModel> addTransaction({
    required String personId,
    required TransactionType type,
    required int amount,
    required DateTime date,
    DateTime? dueDate,
    String? memo,
  }) async {
    if (!_people.containsKey(personId)) {
      throw ArgumentError('相手が見つかりません');
    }
    if (amount <= 0) throw ArgumentError('1円以上の金額を入力してください');
    final now = DateTime.now();
    final tx = TransactionModel(
      id: _uuid.v4(),
      personId: personId,
      type: type,
      amount: amount,
      date: date,
      dueDate: dueDate,
      memo: memo,
      status: TransactionStatus.unpaid,
      repaidAmount: 0,
      createdAt: now,
      updatedAt: now,
    );
    return _mutateAndSave(() {
      _transactions[tx.id] = tx;
      lastUsedType = type;
      return tx;
    });
  }

  Future<void> updateTransaction(
    String id, {
    String? personId,
    TransactionType? type,
    int? amount,
    DateTime? date,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? memo,
  }) async {
    final existing = _transactions[id];
    if (existing == null) return;
    if (personId != null && !_people.containsKey(personId)) {
      throw ArgumentError('相手が見つかりません');
    }
    if (amount != null && (amount <= 0 || amount < existing.repaidAmount)) {
      throw ArgumentError('返済済み金額を下回る金額には変更できません');
    }
    await _mutateAndSave<void>(() {
      _transactions[id] = existing.copyWith(
        personId: personId,
        type: type,
        amount: amount,
        date: date,
        dueDate: dueDate,
        clearDueDate: clearDueDate,
        memo: memo,
        updatedAt: DateTime.now(),
      );
      _recomputeTransaction(id);
    });
  }

  Future<void> deleteTransaction(String id) async {
    await _mutateAndSave<void>(() {
      _transactions.remove(id);
      _repayments.removeWhere((r) => r.transactionId == id);
    });
  }

  /// Keeps the record in history but removes it from balances.
  Future<void> cancelTransaction(String id) async {
    final existing = _transactions[id];
    if (existing == null || existing.isCancelled) return;
    await _mutateAndSave<void>(() {
      _transactions[id] = existing.copyWith(
        status: TransactionStatus.cancelled,
        updatedAt: DateTime.now(),
      );
    });
  }

  Future<void> restoreCancelledTransaction(String id) async {
    final existing = _transactions[id];
    if (existing == null || !existing.isCancelled) return;
    await _mutateAndSave<void>(() {
      _transactions[id] = existing.copyWith(
        status: TransactionStatus.unpaid,
        updatedAt: DateTime.now(),
      );
      _recomputeTransaction(id);
    });
  }

  // ---------------------------------------------------------------------------
  // 返済
  // ---------------------------------------------------------------------------

  /// 返済登録の可否・エラー内容。
  int remainingForTransaction(String transactionId) =>
      _transactions[transactionId]?.remainingAmount ?? 0;

  /// 返済を記録する。過剰返済（残額超過）は登録不可（要件 6.4.4 / 13.1）。
  ///
  /// 登録できない場合は [ArgumentError] を投げる。
  Future<Repayment> addRepayment({
    required String transactionId,
    required int amount,
    required DateTime date,
    RepaymentMethod? method,
    String? memo,
  }) async {
    final tx = _transactions[transactionId];
    if (tx == null) {
      throw ArgumentError('取引が見つかりません');
    }
    if (tx.isCancelled) {
      throw ArgumentError('取り消した取引には返済を記録できません');
    }
    if (amount <= 0) {
      throw ArgumentError('1円以上の金額を入力してください');
    }
    if (amount > tx.remainingAmount) {
      throw ArgumentError('返済額が残りの金額を超えています');
    }
    final repayment = Repayment(
      id: _uuid.v4(),
      transactionId: transactionId,
      amount: amount,
      date: date,
      method: method,
      memo: memo,
      createdAt: DateTime.now(),
    );
    return _mutateAndSave(() {
      _repayments.add(repayment);
      _recomputeTransaction(transactionId);
      return repayment;
    });
  }

  Future<void> deleteRepayment(String repaymentId) async {
    final index = _repayments.indexWhere((r) => r.id == repaymentId);
    if (index < 0) return;
    await _mutateAndSave<void>(() {
      final txId = _repayments[index].transactionId;
      _repayments.removeAt(index);
      _recomputeTransaction(txId);
    });
  }

  // ---------------------------------------------------------------------------
  // 相殺（要件 6.5.4）
  // ---------------------------------------------------------------------------

  /// 相手に対して相殺できる金額（貸し・借りの未返済残高の小さい方）。
  int offsetableAmountForPerson(String personId) {
    final balance = balanceForPerson(personId);
    final lent = balance.lentOutstanding;
    final borrowed = balance.borrowedOutstanding;
    return lent < borrowed ? lent : borrowed;
  }

  /// 相手の貸し借りを差額で相殺する。相殺額分を貸付・借入それぞれの
  /// 未精算取引（古い順）へ返済として記録する。返した値は相殺した金額。
  Future<int> offsetPerson(String personId) async {
    final offset = offsetableAmountForPerson(personId);
    if (offset <= 0) return 0;

    return _mutateAndSave(() {
      final now = DateTime.now();
      _applyOffset(personId, TransactionType.lend, offset, now);
      _applyOffset(personId, TransactionType.borrow, offset, now);
      return offset;
    });
  }

  void _applyOffset(
    String personId,
    TransactionType type,
    int amount,
    DateTime now,
  ) {
    var remaining = amount;
    final targets =
        _transactions.values
            .where(
              (t) =>
                  t.personId == personId && t.type == type && t.isOutstanding,
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    for (final tx in targets) {
      if (remaining <= 0) break;
      final applied =
          remaining < tx.remainingAmount ? remaining : tx.remainingAmount;
      _repayments.add(
        Repayment(
          id: _uuid.v4(),
          transactionId: tx.id,
          amount: applied,
          date: now,
          method: RepaymentMethod.other,
          memo: '相殺',
          createdAt: now,
        ),
      );
      remaining -= applied;
      _recomputeTransaction(tx.id);
    }
  }

  // ---------------------------------------------------------------------------
  // 内部：返済済み金額とステータスの再計算
  // ---------------------------------------------------------------------------

  void _recomputeTransaction(String id) {
    final tx = _transactions[id];
    if (tx == null) return;
    final repaid = _repayments
        .where((r) => r.transactionId == id)
        .fold<int>(0, (sum, r) => sum + r.amount);

    TransactionStatus status;
    if (tx.status == TransactionStatus.cancelled) {
      status = TransactionStatus.cancelled;
    } else if (repaid >= tx.amount) {
      status = TransactionStatus.settled;
    } else if (repaid > 0) {
      status = TransactionStatus.partial;
    } else {
      status = TransactionStatus.unpaid;
    }

    _transactions[id] = tx.copyWith(repaidAmount: repaid, status: status);
  }
}
