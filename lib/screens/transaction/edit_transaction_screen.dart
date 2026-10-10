import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/person.dart';
import '../../models/transaction_type.dart';
import '../../state/app_state.dart';
import '../../utils/formatters.dart';
import '../../widgets/person_avatar_row.dart';
import '../../widgets/type_segment.dart';
import '../person/person_select_screen.dart';

/// 取引編集画面（要件 6.3.2）。
class EditTransactionScreen extends StatefulWidget {
  const EditTransactionScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  late TransactionType _type;
  Person? _person;
  late TextEditingController _amountController;
  late DateTime _date;
  DateTime? _dueDate;
  late TextEditingController _memoController;
  late int _repaidAmount;

  String? _amountError;
  bool _initialized = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    final tx = appState.transaction(widget.transactionId);
    if (tx != null) {
      _type = tx.type;
      _person = appState.person(tx.personId);
      _amountController = TextEditingController(text: tx.amount.toString());
      _date = tx.date;
      _dueDate = tx.dueDate;
      _memoController = TextEditingController(text: tx.memo ?? '');
      _repaidAmount = tx.repaidAmount;
      _initialized = true;
    } else {
      _amountController = TextEditingController();
      _memoController = TextEditingController();
      _repaidAmount = 0;
      _date = DateTime.now();
      _type = TransactionType.lend;
    }
  }

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

  Future<void> _pickPerson() async {
    final selected = await Navigator.of(context).push<Person>(
      MaterialPageRoute(builder: (_) => const PersonSelectScreen()),
    );
    if (selected != null) setState(() => _person = selected);
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

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? _date.add(const Duration(days: 7)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (_saving) return;
    final amount = _amount;
    if (amount == null || amount <= 0) {
      setState(() => _amountError = '1円以上の金額を入力してください');
      return;
    }
    // 返済済み金額を下回る金額には変更できない。
    if (amount < _repaidAmount) {
      setState(() {
        _amountError =
            '返済済み ${Formatters.yenSuffix(_repaidAmount)} を下回る金額にはできません';
      });
      return;
    }
    if (_person == null) return;

    setState(() => _saving = true);
    try {
      await context.read<AppState>().updateTransaction(
        widget.transactionId,
        personId: _person!.id,
        type: _type,
        amount: amount,
        date: _date,
        dueDate: _dueDate,
        clearDueDate: _dueDate == null,
        memo: _memoController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } on ArgumentError catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _amountError = e.message.toString();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保存できませんでした。もう一度お試しください')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('取引を編集')),
        body: const Center(child: Text('取引が見つかりません')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('取引を編集')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          TypeSegment(
            value: _type,
            onChanged: (v) => setState(() => _type = v),
          ),
          const SizedBox(height: 24),
          _label('相手'),
          Material(
            color: Theme.of(context).inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickPerson,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    if (_person != null)
                      PersonAvatarRow(person: _person!)
                    else
                      const Text('相手を選択'),
                    const Spacer(),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _label('金額'),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              prefixText: '¥ ',
              errorText: _amountError,
            ),
            onChanged: (_) {
              if (_amountError != null) setState(() => _amountError = null);
            },
          ),
          const SizedBox(height: 20),
          _label('取引日'),
          _tappable(Formatters.date(_date), Icons.calendar_today, _pickDate),
          const SizedBox(height: 20),
          _label('返済期限'),
          Row(
            children: [
              Expanded(
                child: _tappable(
                  _dueDate == null ? 'なし' : Formatters.date(_dueDate!),
                  Icons.event,
                  _pickDueDate,
                ),
              ),
              if (_dueDate != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _dueDate = null),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _label('メモ'),
          TextField(
            controller: _memoController,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'メモ（任意）'),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: const Text('保存する'),
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

  Widget _tappable(String label, IconData icon, VoidCallback onTap) => Material(
    color: Theme.of(context).inputDecorationTheme.fillColor,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    ),
  );
}
