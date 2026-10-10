import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsuketori/models/transaction_type.dart';
import 'package:tsuketori/repositories/app_repository.dart';
import 'package:tsuketori/screens/person/person_detail_screen.dart';
import 'package:tsuketori/screens/settings/backup_screen.dart';
import 'package:tsuketori/screens/stats/stats_screen.dart';
import 'package:tsuketori/services/backup_codec.dart';
import 'package:tsuketori/services/backup_files.dart';
import 'package:tsuketori/state/app_state.dart';
import 'package:tsuketori/theme/app_theme.dart';

class FakeFiles extends BackupFiles {
  Uint8List? selected;
  Uint8List? exported;
  bool fail = false;
  int pickCount = 0;
  int saveCount = 0;
  Completer<Uint8List?>? pending;
  BackupSaveResult saveResult = BackupSaveResult.saved;

  @override
  Future<Uint8List?> pick() async {
    pickCount++;
    if (fail) throw StateError('fixture read failure');
    return pending == null ? selected : pending!.future;
  }

  @override
  Future<BackupSaveResult> save(Uint8List bytes) async {
    saveCount++;
    if (fail) throw StateError('fixture save failure');
    exported = bytes;
    return saveResult;
  }
}

class FakeRepository extends AppRepository {
  bool fail = false;
  @override
  Future<void> save(AppData data) async {
    if (fail) throw StateError('fixture storage failure');
    await super.save(data);
  }
}

void main() {
  late AppState state;
  late FakeFiles files;
  late FakeRepository repository;
  late String personId;

  setUp(() async {
    await initializeDateFormatting('ja');
    SharedPreferences.setMockInitialValues({});
    repository = FakeRepository();
    state = AppState(repository: repository);
    await state.load();
    personId = (await state.addPerson(name: 'Fixture current')).id;
    files = FakeFiles();
    files.selected = BackupCodec.encode(const AppData.empty());
  });

  Future<void> pump(WidgetTester tester, [Widget? screen]) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: screen ?? BackupScreen(files: files),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.tap(find.text(text).last);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(tester.takeException(), isNull);
  }

  testWidgets('export writes a validated file and does not change the ledger', (
    tester,
  ) async {
    await pump(tester);
    await tap(tester, 'ファイルに書き出す');
    expect(
      BackupCodec.decode(files.exported!).data.people.single.name,
      'Fixture current',
    );
    expect(state.allPeople, hasLength(1));
    expect(find.text('バックアップを保存しました'), findsOneWidget);
  });

  testWidgets(
    'picker cancellation preserves data without opening confirmation',
    (tester) async {
      files.selected = null;
      await pump(tester);
      await tap(tester, 'ファイルを選んで復元');
      expect(find.byType(AlertDialog), findsNothing);
      expect(state.allPeople, hasLength(1));
      expect(files.pickCount, 1);
    },
  );

  testWidgets('confirmation cancellation leaves current data untouched', (
    tester,
  ) async {
    await pump(tester);
    await tap(tester, 'ファイルを選んで復元');
    expect(find.textContaining('相手0人・取引0件・返済0件'), findsOneWidget);
    await tap(tester, 'キャンセル');
    expect(state.person(personId), isNotNull);
    final reloaded = AppState();
    await tester.runAsync(() => reloaded.load());
    expect(reloaded.person(personId), isNotNull);
  });

  testWidgets(
    'confirmed empty backup intentionally clears ledger and persists',
    (tester) async {
      await pump(tester);
      await tap(tester, 'ファイルを選んで復元');
      await tap(tester, '置き換えて復元');
      expect(state.allPeople, isEmpty);
      final reloaded = AppState();
      await tester.runAsync(() => reloaded.load());
      expect(reloaded.allPeople, isEmpty);
      expect(find.text('バックアップから復元しました'), findsOneWidget);
    },
  );

  testWidgets('invalid file is rejected before confirmation', (tester) async {
    files.selected = Uint8List.fromList([0, 1, 2]);
    await pump(tester);
    await tap(tester, 'ファイルを選んで復元');
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.textContaining('バックアップが破損'), findsOneWidget);
    expect(state.allPeople, hasLength(1));
  });

  testWidgets('failed restore retains data and reenables retry', (
    tester,
  ) async {
    await pump(tester);
    await tap(tester, 'ファイルを選んで復元');
    repository.fail = true;
    await tap(tester, '置き換えて復元');
    expect(state.allPeople, hasLength(1));
    expect(find.textContaining('現在の台帳を保持'), findsOneWidget);
    repository.fail = false;
    await tap(tester, 'ファイルを選んで復元');
    await tap(tester, '置き換えて復元');
    expect(state.allPeople, isEmpty);
  });

  testWidgets('repeated clicks cannot open two file pickers', (tester) async {
    files.pending = Completer<Uint8List?>();
    await pump(tester);
    final callback =
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed!;
    callback();
    callback();
    await tester.pump();
    expect(files.pickCount, 1);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    files.pending!.complete(null);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
    expect(state.allPeople, hasLength(1));
  });

  testWidgets('export failure is visible and leaves data intact', (
    tester,
  ) async {
    files.fail = true;
    await pump(tester);
    await tap(tester, 'ファイルに書き出す');
    expect(find.textContaining('書き出せませんでした'), findsOneWidget);
    expect(state.allPeople, hasLength(1));
  });

  testWidgets('equal unpaid loans show zero difference, not settled', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (final type in TransactionType.values) {
        await state.addTransaction(
          personId: personId,
          type: type,
          amount: 1000,
          date: DateTime(2026),
        );
      }
    });
    await pump(tester, PersonDetailScreen(personId: personId));
    expect(find.text('差額なし（未精算の取引あり）'), findsOneWidget);
    expect(find.text('精算済み'), findsNothing);
  });

  testWidgets(
    'stats label period totals separately and include hidden all-time balances',
    (tester) async {
      await tester.runAsync(() async {
        await state.addTransaction(
          personId: personId,
          type: TransactionType.lend,
          amount: 1000,
          date: DateTime(2001),
        );
        await state.hidePerson(personId);
      });
      await pump(tester, const StatsScreen());
      expect(find.text('期間内に記録した貸付・借入の差額'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Fixture current（非表示）'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('現在の相手別残高（全期間）'), findsOneWidget);
      expect(find.text('Fixture current（非表示）'), findsOneWidget);
      expect(find.text('+1,000円'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
