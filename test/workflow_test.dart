import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsuketori/main.dart';
import 'package:tsuketori/models/transaction_type.dart';
import 'package:tsuketori/screens/history/history_filter.dart';
import 'package:tsuketori/screens/person/person_detail_screen.dart';
import 'package:tsuketori/screens/person/person_edit_screen.dart';
import 'package:tsuketori/state/app_state.dart';
import 'package:tsuketori/state/settings_state.dart';
import 'package:tsuketori/theme/app_theme.dart';

void main() {
  late AppState state;
  late SettingsState settings;

  setUp(() async {
    await initializeDateFormatting('ja');
    SharedPreferences.setMockInitialValues({});
    state = AppState();
    settings = SettingsState();
    await state.load();
    await settings.load();
  });

  Future<void> showApp(WidgetTester tester) async {
    await tester.pumpWidget(TsuketoriApp(settings: settings, appState: state));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final target = find.text(text).last;
    if (find.text(text).evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        find.text(text),
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(target);
    await tester.tap(target);
    // SharedPreferences and the serialized write queue may complete in the
    // real async zone established by fixture setup.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets(
    'create a person and loan, repay partially then fully, restore and search',
    (tester) async {
      await showApp(tester);
      await tester.tap(find.byTooltip('取引を追加'));
      await tester.pumpAndSettle();
      await tapText(tester, '相手を選択');
      await tapText(tester, '新しい相手を追加');
      await tester.enterText(find.byType(TextField).at(0), '山田テスト');
      await tapText(tester, '追加する');
      await tester.enterText(find.byType(TextField).first, '5000');
      await tapText(tester, '保存する');
      expect(state.transactions, hasLength(1));
      final id = state.transactions.single.id;
      await tapText(tester, '返済を記録する');
      await tapText(tester, '一部返済を記録する');
      await tester.enterText(find.byType(TextField).first, '2000');
      await tapText(tester, '返済を保存する');
      expect(state.transaction(id)!.remainingAmount, 3000);
      await tapText(tester, '返済を記録する');
      await tapText(tester, '返済済みにする');
      expect(state.transaction(id)!.remainingAmount, 0);
      final restored = AppState();
      await tester.runAsync(() => restored.load());
      expect(restored.repaymentsForTransaction(id), hasLength(2));
      expect(restored.summary().overallBalance, 0);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tapText(tester, '履歴');
      await tester.enterText(find.byType(TextField).first, '存在しない相手');
      await tester.pumpAndSettle();
      expect(find.text('該当する取引がありません'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '山田');
      await tester.pumpAndSettle();
      expect(find.text('山田テスト'), findsOneWidget);
    },
  );

  testWidgets('hidden person without transactions can be found and restored', (
    tester,
  ) async {
    final person =
        (await tester.runAsync(() => state.addPerson(name: '復帰する相手')))!;
    await showApp(tester);
    await tapText(tester, '人');
    await tapText(tester, '復帰する相手');
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tapText(tester, '非表示にする');
    expect(state.people, isEmpty);
    await tester.tap(find.byTooltip('非表示の相手'));
    await tester.pumpAndSettle();
    await tapText(tester, '復帰する相手');
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tapText(tester, '再表示する');
    expect(state.person(person.id)!.isHidden, isFalse);
    final restored = AppState();
    await tester.runAsync(() => restored.load());
    expect(restored.people.single.id, person.id);
  });

  testWidgets('editing a person can clear all optional contact fields', (
    tester,
  ) async {
    final person =
        (await tester.runAsync(
          () => state.addPerson(
            name: '連絡先',
            phone: '123',
            email: 'test@example.invalid',
            memo: '消す',
          ),
        ))!;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(home: PersonEditScreen(person: person)),
      ),
    );
    for (var i = 1; i <= 3; i++) {
      await tester.enterText(find.byType(TextField).at(i), '');
    }
    await tapText(tester, '保存する');
    final restored = AppState();
    await tester.runAsync(() => restored.load());
    expect(restored.person(person.id)!.phone, isEmpty);
    expect(restored.person(person.id)!.email, isEmpty);
    expect(restored.person(person.id)!.memo, isEmpty);
  });

  testWidgets(
    'person offset is usable on a narrow phone and persists both sides',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final person =
          (await tester.runAsync(() => state.addPerson(name: '相殺テスト')))!;
      for (final type in TransactionType.values) {
        await tester.runAsync(
          () => state.addTransaction(
            personId: person.id,
            type: type,
            amount: type == TransactionType.lend ? 5000 : 2000,
            date: DateTime(2026),
          ),
        );
      }
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: PersonDetailScreen(personId: person.id),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tapText(tester, '相殺');
      await tapText(tester, '相殺する');
      expect(state.balanceForPerson(person.id).lentOutstanding, 3000);
      expect(state.balanceForPerson(person.id).borrowedOutstanding, 0);
    },
  );

  test('history overdue filter uses the supplied reference day', () async {
    final person = await state.addPerson(name: '期限テスト');
    await state.addTransaction(
      personId: person.id,
      type: TransactionType.lend,
      amount: 1000,
      date: DateTime(2026, 1, 1),
      dueDate: DateTime(2026, 1, 10),
    );
    const query = HistoryQuery(statusFilter: HistoryStatusFilter.overdue);
    expect(
      query.apply(state.transactions, (_) => '', now: DateTime(2026, 1, 10)),
      isEmpty,
    );
    expect(
      query.apply(state.transactions, (_) => '', now: DateTime(2026, 1, 11)),
      hasLength(1),
    );
  });
}
