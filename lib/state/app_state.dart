import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/balance.dart';
import '../models/person.dart';
import '../models/repayment.dart';
import '../models/transaction.dart';
import '../models/transaction_status.dart';
import '../models/transaction_type.dart';
import '../repositories/app_repository.dart';

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
    _people
      ..clear()
      ..addEntries(data.people.map((p) => MapEntry(p.id, p)));
    _transactions
      ..clear()
      ..addEntries(data.transactions.map((t) => MapEntry(t.id, t)));
    _repayments
      ..clear()
      ..addAll(data.repayments);
    _loaded = true;
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
    final now = DateTime.now();
    final person = Person(
      id: _uuid.v4(),
      name: name,
      phone: phone,
      email: email,
      memo: memo,
      iconPath: iconPath,
      createdAt: now,
      updatedAt: now,
    );
    _people[person.id] = person;
    await _repository.savePeople(_people.values.toList());
    notifyListeners();
    return person;
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
    _people[id] = existing.copyWith(
      name: name,
      phone: phone,
      email: email,
      memo: memo,
      iconPath: iconPath,
      isHidden: isHidden,
      updatedAt: DateTime.now(),
    );
    await _repository.savePeople(_people.values.toList());
    notifyListeners();
  }

  bool personHasTransactions(String id) =>
      _transactions.values.any((t) => t.personId == id);

  /// 相手を非表示にする（要件 13.3）。
  Future<void> hidePerson(String id) => updatePerson(id, isHidden: true);

  Future<void> unhidePerson(String id) => updatePerson(id, isHidden: false);

  /// 相手を取引ごと削除する（要件 13.3）。
  Future<void> deletePersonWithTransactions(String id) async {
    final txIds =
        _transactions.values
            .where((t) => t.personId == id)
            .map((t) => t.id)
            .toSet();
    _transactions.removeWhere((_, t) => t.personId == id);
    _repayments.removeWhere((r) => txIds.contains(r.transactionId));
    _people.remove(id);
    await Future.wait([
      _repository.savePeople(_people.values.toList()),
      _repository.saveTransactions(_transactions.values.toList()),
      _repository.saveRepayments(_repayments),
    ]);
    notifyListeners();
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
    _transactions[tx.id] = tx;
    lastUsedType = type;
    await _repository.saveTransactions(_transactions.values.toList());
    notifyListeners();
    return tx;
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
    await _repository.saveTransactions(_transactions.values.toList());
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.remove(id);
    _repayments.removeWhere((r) => r.transactionId == id);
    await Future.wait([
      _repository.saveTransactions(_transactions.values.toList()),
      _repository.saveRepayments(_repayments),
    ]);
    notifyListeners();
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
    _repayments.add(repayment);
    _recomputeTransaction(transactionId);
    await Future.wait([
      _repository.saveRepayments(_repayments),
      _repository.saveTransactions(_transactions.values.toList()),
    ]);
    notifyListeners();
    return repayment;
  }

  Future<void> deleteRepayment(String repaymentId) async {
    final index = _repayments.indexWhere((r) => r.id == repaymentId);
    if (index < 0) return;
    final txId = _repayments[index].transactionId;
    _repayments.removeAt(index);
    _recomputeTransaction(txId);
    await Future.wait([
      _repository.saveRepayments(_repayments),
      _repository.saveTransactions(_transactions.values.toList()),
    ]);
    notifyListeners();
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

    final now = DateTime.now();
    _applyOffset(personId, TransactionType.lend, offset, now);
    _applyOffset(personId, TransactionType.borrow, offset, now);

    await Future.wait([
      _repository.saveRepayments(_repayments),
      _repository.saveTransactions(_transactions.values.toList()),
    ]);
    notifyListeners();
    return offset;
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
              (t) => t.personId == personId && t.type == type && t.isOutstanding,
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    for (final tx in targets) {
      if (remaining <= 0) break;
      final applied = remaining < tx.remainingAmount
          ? remaining
          : tx.remainingAmount;
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
