import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsuketori/models/transaction_type.dart';
import 'package:tsuketori/repositories/app_repository.dart';
import 'package:tsuketori/services/backup_codec.dart';
import 'package:tsuketori/state/app_state.dart';

class RejectingRepository extends AppRepository {
  bool reject = false;
  @override
  Future<void> save(AppData data) async {
    if (reject) throw StateError('fixture write failure');
    await super.save(data);
  }
}

void main() {
  late AppState state;
  late RejectingRepository repository;
  late Uint8List bytes;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = RejectingRepository();
    state = AppState(repository: repository);
    await state.load();
    final person = await state.addPerson(
      name: 'Fixture A',
      phone: '000',
      memo: '架空データ',
    );
    final transaction = await state.addTransaction(
      personId: person.id,
      type: TransactionType.lend,
      amount: 5000,
      date: DateTime(2026, 1, 1),
    );
    await state.addRepayment(
      transactionId: transaction.id,
      amount: 2000,
      date: DateTime(2026, 1, 2),
    );
    await state.hidePerson(person.id);
    bytes = await state.exportBackup();
  });

  Uint8List altered(void Function(Map<String, dynamic>) change) {
    final value = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    change(value);
    return Uint8List.fromList(utf8.encode(jsonEncode(value)));
  }

  test('round trip includes hidden people, contact fields and repayments', () {
    final backup = BackupCodec.decode(bytes);
    expect(backup.data.people.single.isHidden, isTrue);
    expect(backup.data.people.single.phone, '000');
    expect(backup.data.transactions.single.remainingAmount, 3000);
    expect(backup.data.repayments.single.amount, 2000);
    expect(() => backup.data.people.clear(), throwsUnsupportedError);
  });

  final invalidCases = <String, void Function(Map<String, dynamic>)>{
    'wrong format': (v) => v['format'] = 'other-app',
    'future version': (v) => v['version'] = 2,
    'non integer version': (v) => v['version'] = 1.0,
    'wrong currency': (v) => v['currency'] = 'USD',
    'missing array': (v) => v.remove('people'),
    'duplicate person': (v) => (v['people'] as List).add(v['people'][0]),
    'duplicate transaction':
        (v) => (v['transactions'] as List).add(v['transactions'][0]),
    'duplicate repayment':
        (v) => (v['repayments'] as List).add(v['repayments'][0]),
    'unknown person': (v) => v['transactions'][0]['personId'] = 'missing',
    'unknown transaction':
        (v) => v['repayments'][0]['transactionId'] = 'missing',
    'zero amount': (v) => v['transactions'][0]['amount'] = 0,
    'negative repayment': (v) => v['repayments'][0]['amount'] = -1,
    'fractional amount': (v) => v['transactions'][0]['amount'] = 5000.5,
    'amount over limit': (v) => v['transactions'][0]['amount'] = 10000000000,
    'repayment sum mismatch': (v) => v['repayments'][0]['amount'] = 1000,
    'remaining mismatch': (v) => v['transactions'][0]['remainingAmount'] = 5000,
    'overpayment': (v) {
      v['transactions'][0]['repaidAmount'] = 6000;
      v['repayments'][0]['amount'] = 6000;
    },
    'status mismatch': (v) => v['transactions'][0]['status'] = 'settled',
    'unknown status': (v) => v['transactions'][0]['status'] = 'unknown',
    'derived status persisted':
        (v) => v['transactions'][0]['status'] = 'overdue',
    'unknown type': (v) => v['transactions'][0]['type'] = 'unknown',
    'unknown method': (v) => v['repayments'][0]['method'] = 'unknown',
    'invalid date':
        (v) => v['transactions'][0]['date'] = '2026-02-31T00:00:00.000',
    'blank name': (v) => v['people'][0]['name'] = '  ',
    'wrong field type': (v) => v['people'][0]['isHidden'] = 'true',
  };
  for (final entry in invalidCases.entries) {
    test('reject ${entry.key} without changing the ledger', () {
      expect(
        () => BackupCodec.decode(altered(entry.value)),
        throwsFormatException,
      );
      expect(state.allPeople.single.name, 'Fixture A');
      expect(state.summary().overallBalance, 3000);
    });
  }

  test('reject malformed JSON, UTF8, empty and oversized files', () {
    for (final value in [
      Uint8List(0),
      Uint8List.fromList([255]),
      Uint8List.fromList(utf8.encode('{broken')),
      Uint8List(BackupCodec.maxBytes + 1),
    ]) {
      expect(() => BackupCodec.decode(value), throwsFormatException);
    }
  });

  test(
    'cancelled records are preserved rather than silently reactivated',
    () async {
      final archive = BackupCodec.decode(
        altered((v) => v['transactions'][0]['status'] = 'cancelled'),
      );
      await state.restoreBackup(archive, expectedRevision: state.revision);
      expect(state.transactions.single.isCancelled, isTrue);
      expect(state.summary().overallBalance, 0);
      await expectLater(
        state.addRepayment(
          transactionId: state.transactions.single.id,
          amount: 1,
          date: DateTime(2026),
        ),
        throwsArgumentError,
      );
    },
  );

  test('restore replaces data; repeating does not append duplicates', () async {
    final archive = BackupCodec.decode(bytes);
    await state.addPerson(name: 'To replace');
    await state.restoreBackup(archive, expectedRevision: state.revision);
    await state.restoreBackup(archive, expectedRevision: state.revision);
    final restored = AppState();
    await restored.load();
    expect(restored.allPeople, hasLength(1));
    expect(restored.transactions, hasLength(1));
    expect(
      restored.repaymentsForTransaction(restored.transactions.single.id),
      hasLength(1),
    );
    expect(restored.summary().overallBalance, 3000);
  });

  test(
    'reload is ordered with restore and cannot overwrite restored state',
    () async {
      final archive = BackupCodec.decode(bytes);
      await state.addPerson(name: 'Replace fixture');
      final restore = state.restoreBackup(
        archive,
        expectedRevision: state.revision,
      );
      final reload = state.load();
      await Future.wait([restore, reload]);
      expect(state.allPeople, hasLength(1));
      expect(state.summary().overallBalance, 3000);
    },
  );

  test(
    'stale confirmation and concurrent duplicate restore are rejected',
    () async {
      final archive = BackupCodec.decode(bytes);
      final oldRevision = state.revision;
      await state.addPerson(name: 'Keep newer data');
      await expectLater(
        state.restoreBackup(archive, expectedRevision: oldRevision),
        throwsArgumentError,
      );
      expect(state.allPeople, hasLength(2));
      final revision = state.revision;
      final first = state.restoreBackup(archive, expectedRevision: revision);
      final second = state.restoreBackup(archive, expectedRevision: revision);
      await expectLater(second, throwsArgumentError);
      await first;
      expect(state.allPeople, hasLength(1));
    },
  );

  test(
    'failed restore preserves both in-memory and persisted data and can retry',
    () async {
      final archive = BackupCodec.decode(bytes);
      await state.addPerson(name: 'Must survive failure');
      final beforeRevision = state.revision;
      repository.reject = true;
      await expectLater(
        state.restoreBackup(archive, expectedRevision: beforeRevision),
        throwsStateError,
      );
      expect(state.allPeople, hasLength(2));
      expect(state.revision, beforeRevision);
      final reloaded = AppState();
      await reloaded.load();
      expect(reloaded.allPeople, hasLength(2));
      repository.reject = false;
      await state.restoreBackup(archive, expectedRevision: beforeRevision);
      expect(state.allPeople, hasLength(1));
    },
  );
}
