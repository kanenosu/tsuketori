import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/repayment.dart';
import '../../state/app_state.dart';
import '../../utils/formatters.dart';
import '../../widgets/yen_amount.dart';
import '../transaction/new_transaction_screen.dart';

/// 返済登録画面（要件 6.3.4 / 6.4）。
class RepaymentScreen extends StatefulWidget {
  const RepaymentScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  State<RepaymentScreen> createState() => _RepaymentScreenState();
}

class _RepaymentScreenState extends State<RepaymentScreen> {
  final _amountController = TextEditingController();
  DateTime _date = DateTime.now();
  RepaymentMethod? _method;
  final _memoController = TextEditingController();
  String? _amountError;
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  int? get _amount {
    final digits = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save(int remaining) async {
    final amount = _amount;
    if (amount == null || amount <= 0) {
      setState(() => _amountError = '1円以上の金額を入力してください');
      return;
    }
    if (amount > remaining) {
      // 過剰返済防止（要件 6.4.4）。
      setState(() => _amountError = '返済額が残りの金額を超えています');
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<AppState>().addRepayment(
        transactionId: widget.transactionId,
        amount: amount,
        date: _date,
        method: _method,
        memo:
            _memoController.text.trim().isEmpty
                ? null
                : _memoController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } on ArgumentError catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _amountError = e.message.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final tx = appState.transaction(widget.transactionId);
    if (tx == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('返済を記録')),
        body: const Center(child: Text('取引が見つかりません')),
      );
    }
    final remaining = tx.remainingAmount;

    return Scaffold(
      appBar: AppBar(title: const Text('返済を記録')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '残額',
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.yenSuffix(remaining),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _label('返済金額'),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              suffixIcon: const YenSuffix(),
              suffixIconConstraints: YenSuffix.constraints,
              hintText: '0',
              errorText: _amountError,
            ),
            onChanged: (_) {
              if (_amountError != null) setState(() => _amountError = null);
            },
          ),
          const SizedBox(height: 8),
          // 全額返済のショートカット（要件 6.4.3）。
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _amountController.text = remaining.toString();
                  _amountError = null;
                });
              },
              icon: const Icon(Icons.done_all, size: 18),
              label: Text('全額返済（${Formatters.yenSuffix(remaining)}）'),
            ),
          ),
          const SizedBox(height: 20),
          _label('返済日'),
          Material(
            color: Theme.of(context).inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _pickDate,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 12),
                    Text(Formatters.date(_date)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _label('返済方法（任意）'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                RepaymentMethod.values.map((m) {
                  return ChoiceChip(
                    label: Text(m.label),
                    selected: _method == m,
                    onSelected:
                        (sel) => setState(() => _method = sel ? m : null),
                  );
                }).toList(),
          ),
          const SizedBox(height: 20),
          _label('メモ（任意）'),
          TextField(
            controller: _memoController,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'メモ（任意）'),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _saving ? null : () => _save(remaining),
            child:
                _saving
                    ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('返済を保存する'),
          ),
          const SizedBox(height: 12),
          // 残額を超える精算は別取引で（要件 6.4.4）。
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const NewTransactionScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('残額を超える精算は別取引を作成'),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    ),
  );
}
