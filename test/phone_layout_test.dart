import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsuketori/main.dart';
import 'package:tsuketori/models/transaction_type.dart';
import 'package:tsuketori/state/app_state.dart';
import 'package:tsuketori/state/settings_state.dart';

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('small phone with larger text: ${mode.name}', (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      SharedPreferences.setMockInitialValues({});
      await initializeDateFormatting('ja');
      final state = AppState();
      final settings = SettingsState();
      await state.load();
      await settings.load();
      await settings.setThemeMode(mode);
      final person = await state.addPerson(name: '表示確認用の長い名前');
      await state.addTransaction(
        personId: person.id,
        type: TransactionType.lend,
        amount: 9999999999,
        date: DateTime(2026, 10, 4),
      );
      await tester.pumpWidget(
        TsuketoriApp(settings: settings, appState: state),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final icon in [
        CupertinoIcons.list_bullet,
        CupertinoIcons.person_2,
        CupertinoIcons.gear,
      ]) {
        await tester.tap(find.byIcon(icon).first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
}
