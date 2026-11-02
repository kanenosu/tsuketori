import 'package:flutter/material.dart';

import '../../utils/formatters.dart';
import 'history_filter.dart';

/// フィルター画面（要件 6.6.3 / 6.6.4・モックアップ⑦準拠）。
/// 適用された [HistoryQuery] を pop で返す。
class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key, required this.initial});

  final HistoryQuery initial;

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late HistoryQuery _query;

  @override
  void initState() {
    super.initState();
    _query = widget.initial;
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _query.customRange,
    );
    if (range != null) {
      setState(() {
        _query = _query.copyWith(
          period: HistoryPeriod.custom,
          customRange: range,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('フィルター'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => setState(() => _query = const HistoryQuery()),
            child: const Text('リセット'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _section('取引の種類'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                HistoryTypeFilter.values
                    .map(
                      (t) => ChoiceChip(
                        label: Text(t.label),
                        selected: _query.typeFilter == t,
                        onSelected:
                            (_) => setState(
                              () => _query = _query.copyWith(typeFilter: t),
                            ),
                      ),
                    )
                    .toList(),
          ),
          _section('期間'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                HistoryPeriod.values.map((p) {
                  final selected = _query.period == p;
                  final label =
                      p == HistoryPeriod.custom && _query.customRange != null
                          ? '${Formatters.dateShort(_query.customRange!.start)}〜'
                              '${Formatters.dateShort(_query.customRange!.end)}'
                          : p.label;
                  return ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) {
                      if (p == HistoryPeriod.custom) {
                        _pickCustomRange();
                      } else {
                        setState(
                          () =>
                              _query = _query.copyWith(
                                period: p,
                                clearCustomRange: true,
                              ),
                        );
                      }
                    },
                  );
                }).toList(),
          ),
          _section('ステータス'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                HistoryStatusFilter.values
                    .map(
                      (s) => ChoiceChip(
                        label: Text(s.label),
                        selected: _query.statusFilter == s,
                        onSelected:
                            (_) => setState(
                              () => _query = _query.copyWith(statusFilter: s),
                            ),
                      ),
                    )
                    .toList(),
          ),
          _section('並び替え'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                HistorySort.values
                    .map(
                      (s) => ChoiceChip(
                        label: Text(s.label),
                        selected: _query.sort == s,
                        onSelected:
                            (_) => setState(
                              () => _query = _query.copyWith(sort: s),
                            ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_query),
            child: const Text('この条件で表示'),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10, left: 2),
    child: Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    ),
  );
}
