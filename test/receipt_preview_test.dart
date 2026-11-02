import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsuketori/models/transaction_type.dart';
import 'package:tsuketori/repositories/app_repository.dart';
import 'package:tsuketori/screens/receipt/receipt_preview_screen.dart';
import 'package:tsuketori/state/app_state.dart';

void main() {
  testWidgets('paper record shows amounts, party, repayments and disclaimer', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState(repository: AppRepository());
    await state.load();
    final person = await state.addPerson(name: '鈴木 一郎');
    final transaction = await state.addTransaction(
      personId: person.id,
      type: TransactionType.lend,
      amount: 12000,
      date: DateTime(2026, 10, 4, 17, 45),
      memo: '立替分',
    );
    await state.addRepayment(
      transactionId: transaction.id,
      amount: 4000,
      date: DateTime(2026, 10, 5),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          home: ReceiptPreviewScreen(transactionId: transaction.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('取 引 記 録'), findsOneWidget);
    expect(find.text('鈴木 一郎'), findsOneWidget);
    expect(find.text('12,000円'), findsOneWidget);
    expect(find.text('4,000円'), findsWidgets);
    expect(find.text('8,000円'), findsOneWidget);
    expect(find.textContaining('公的機関・金融機関・決済事業者'), findsOneWidget);
    expect(find.text('画像で共有'), findsOneWidget);
    expect(find.text('PDFで共有'), findsOneWidget);
  });
}
