import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/person.dart';
import '../../models/transaction_type.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/yen_amount.dart';
import '../../widgets/person_avatar_row.dart';
import '../../widgets/type_segment.dart';
import '../person/person_select_screen.dart';
import 'transaction_detail_screen.dart';

/// 新規取引登録画面（要件 6.2・モックアップ準拠）。
class NewTransactionScreen extends StatefulWidget {
  const NewTransactionScreen({super.key});

  @override
  State<NewTransactionScreen> createState() => _NewTransactionScreenState();
}

class _NewTransactionScreenState extends State<NewTransactionScreen> {
  late TransactionType _type;
  Person? _person;
  final _amountController = TextEditingController();
  DateTime _date = DateTime.now();
  DateTime? _dueDate;
  final _memoController = TextEditingController();

  String? _amountError;
  String? _personError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = context.read<AppState>().lastUsedType;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Color get _accent =>
      _type == TransactionType.lend ? AppColors.lend : AppColors.borrow;

  int? get _amount {
    final digits = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  Future<void> _pickPerson() async {
    final selected = await Navigator.of(context).push<Person>(
      MaterialPageRoute(builder: (_) => const PersonSelectScreen()),
    );
    if (selected != null) {
      setState(() {
        _person = selected;
        _personError = null;
      });
    }
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

  bool _validate() {
    setState(() {
      _personError = _person == null ? '相手を選択してください' : null;
      final amount = _amount;
      if (amount == null) {
        _amountError = '金額を入力してください';
      } else if (amount <= 0) {
        _amountError = '1円以上の金額を入力してください';
      } else if (amount > 9999999999) {
        _amountError = '金額が上限を超えています';
      } else {
        _amountError = null;
      }
    });
    return _personError == null && _amountError == null;
  }

  Future<void> _save() async {
    if (!_validate() || _saving) return;
    setState(() => _saving = true);
    final appState = context.read<AppState>();
    try {
      final tx = await appState.addTransaction(
        personId: _person!.id,
        type: _type,
        amount: _amount!,
        date: _date,
        dueDate: _dueDate,
        memo:
            _memoController.text.trim().isEmpty
                ? null
                : _memoController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TransactionDetailScreen(transactionId: tx.id),
        ),
      );
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '閉じる',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('取引を追加'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                TypeSegment(
                  value: _type,
                  onChanged: (v) => setState(() => _type = v),
                ),
                const SizedBox(height: 24),
                _label('相手'),
                _FieldCard(
                  error: _personError,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
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
                            Text(
                              '相手を選択',
                              style: TextStyle(
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          const Spacer(),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _label('金額'),
                _FieldCard(
                  error: _amountError,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        hintText: '0',
                        // 価格表示ルール：数字 32px → 円 16px。
                        suffixIcon: YenSuffix(),
                        suffixIconConstraints: YenSuffix.constraints,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (_) {
                        if (_amountError != null) {
                          setState(() => _amountError = null);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _label('日付'),
                _FieldCard(
                  child: _tappable(
                    _formatDate(_date),
                    Icons.calendar_today_outlined,
                    _pickDate,
                  ),
                ),
                const SizedBox(height: 18),
                _label('返済期限（任意）'),
                _DueDatePicker(
                  dueDate: _dueDate,
                  baseDate: _date,
                  accent: _accent,
                  onSelected: (d) => setState(() => _dueDate = d),
                  onPickDate: _pickDueDate,
                ),
                const SizedBox(height: 18),
                _label('メモ（任意）'),
                _FieldCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _memoController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText:
                            _type == TransactionType.lend
                                ? '例）ランチ代を立て替えた'
                                : '例）飲み会の前払い',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Sticky Button（キーボード表示中はその直上に固定される）。
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  offset: Offset(0, -2),
                  blurRadius: 6,
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(
              24,
              12,
              24,
              12 + MediaQuery.paddingOf(context).bottom,
            ),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child:
                  _saving
                      ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text('保存する'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, color: AppColors.textGray),
    ),
  );

  Widget _tappable(String label, IconData icon, VoidCallback onTap) => InkWell(
    borderRadius: BorderRadius.circular(8),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).hintColor),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 15)),
        ],
      ),
    ),
  );

  static String _formatDate(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
}

/// フィールドを囲む白いカード（エラー表示付き）。
class _FieldCard extends StatelessWidget {
  const _FieldCard({required this.child, this.error});

  final Widget child;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          child: child,
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

/// 返済期限の選択（期限なし／1週間後／1か月後／日付指定・要件 6.2.5）。
class _DueDatePicker extends StatelessWidget {
  const _DueDatePicker({
    required this.dueDate,
    required this.baseDate,
    required this.accent,
    required this.onSelected,
    required this.onPickDate,
  });

  final DateTime? dueDate;
  final DateTime baseDate;
  final Color accent;
  final ValueChanged<DateTime?> onSelected;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final week = baseDate.add(const Duration(days: 7));
    final month = DateTime(baseDate.year, baseDate.month + 1, baseDate.day);

    bool sameDay(DateTime? a, DateTime b) =>
        a != null && a.year == b.year && a.month == b.month && a.day == b.day;

    final isCustom =
        dueDate != null && !sameDay(dueDate, week) && !sameDay(dueDate, month);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('期限なし'),
          selected: dueDate == null,
          onSelected: (_) => onSelected(null),
        ),
        ChoiceChip(
          label: const Text('1週間後'),
          selected: sameDay(dueDate, week),
          onSelected: (_) => onSelected(week),
        ),
        ChoiceChip(
          label: const Text('1か月後'),
          selected: sameDay(dueDate, month),
          onSelected: (_) => onSelected(month),
        ),
        ActionChip(
          avatar: Icon(Icons.calendar_today, size: 16, color: accent),
          label: Text(
            isCustom
                ? '${dueDate!.year}/${dueDate!.month}/${dueDate!.day}'
                : '日付指定',
          ),
          onPressed: onPickDate,
        ),
      ],
    );
  }
}
