import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsuketori/main.dart';
import 'package:tsuketori/repositories/app_repository.dart';
import 'package:tsuketori/state/app_state.dart';
import 'package:tsuketori/state/settings_state.dart';

Future<void> pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final settings = SettingsState();
  final appState = AppState(repository: AppRepository());
  await Future.wait([settings.load(), appState.load()]);
  await tester.pumpWidget(
    TsuketoriApp(settings: settings, appState: appState),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('ホーム画面が表示され、空状態を案内する', (tester) async {
    await pumpApp(tester);

    expect(find.text('貸し借り'), findsOneWidget);
    expect(find.text('あなたの残高'), findsOneWidget);
    expect(find.text('取引がまだありません'), findsOneWidget);
    // 下部タブ。
    expect(find.text('ホーム'), findsWidgets);
    expect(find.text('履歴'), findsWidgets);
    expect(find.text('人'), findsWidgets);
    expect(find.text('設定'), findsWidgets);
  });

  testWidgets('＋ボタンから新規取引画面へ遷移できる', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('新しい取引'), findsOneWidget);
    expect(find.text('貸した'), findsWidgets);
    expect(find.text('借りた'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('保存する'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('保存する'), findsOneWidget);
  });

  testWidgets('相手・金額未入力の保存でバリデーションエラーが出る', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.add));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('保存する'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    expect(find.text('相手を選択してください'), findsOneWidget);
    expect(find.text('金額を入力してください'), findsOneWidget);
  });

  testWidgets('設定タブでテーマ設定を変更できる', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('テーマ設定'), findsOneWidget);
    expect(find.text('通貨の設定'), findsOneWidget);

    // テーマ設定をタップするとボトムシートで選択肢が出る。
    await tester.tap(find.text('テーマ設定'));
    await tester.pumpAndSettle();
    expect(find.text('ダークモード'), findsWidgets);
  });
}
