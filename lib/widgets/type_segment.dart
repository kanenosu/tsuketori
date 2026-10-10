import 'package:flutter/material.dart';
import '../models/transaction_type.dart';
import 'pill_tabs.dart';

class TypeSegment extends StatelessWidget {
  const TypeSegment({super.key, required this.value, required this.onChanged});
  final TransactionType value;
  final ValueChanged<TransactionType> onChanged;
  @override
  Widget build(BuildContext context) => PillTabs(
    labels: const ['貸した', '借りた'],
    selectedIndex: value == TransactionType.lend ? 0 : 1,
    onChanged:
        (i) =>
            onChanged(i == 0 ? TransactionType.lend : TransactionType.borrow),
  );
}
