import 'package:intl/intl.dart';

/// 金額・日付の表示フォーマット（要件 6.1.1 / 11章）。
class Formatters {
  const Formatters._();

  static final NumberFormat _yen = NumberFormat('#,##0');

  /// 3桁ごとにカンマを付けた金額文字列（記号なし）。例: 5000 -> "5,000"。
  static String number(int amount) => _yen.format(amount);

  /// 「¥5,000」形式。
  static String yen(int amount) => '¥${_yen.format(amount)}';

  /// 「5,000円」形式。
  static String yenSuffix(int amount) => '${_yen.format(amount)}円';

  /// 符号付きの金額（残高表示用）。例: +5000 -> "+5,000", -2000 -> "-2,000"。
  static String signed(int amount) {
    if (amount > 0) return '+${_yen.format(amount)}';
    if (amount < 0) return '-${_yen.format(amount.abs())}';
    return _yen.format(0);
  }

  static final DateFormat _date = DateFormat('yyyy/MM/dd');
  static final DateFormat _dateShort = DateFormat('MM/dd');
  static final DateFormat _month = DateFormat('yyyy年MM月');
  static final DateFormat _monthLabel = DateFormat('yyyy年M月');
  static final DateFormat _dateTime = DateFormat('yyyy/MM/dd HH:mm');

  static String date(DateTime d) => _date.format(d);

  static String dateShort(DateTime d) => _dateShort.format(d);

  static String month(DateTime d) => _month.format(d);

  /// 「2024年5月」形式（月ナビゲーション用）。
  static String monthLabel(DateTime d) => _monthLabel.format(d);

  static String dateTime(DateTime d) => _dateTime.format(d);

  /// 「2024年5月9日（木）」形式。
  static String longDate(DateTime d) {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    return '${d.year}年${d.month}月${d.day}日（${weekdays[d.weekday - 1]}）';
  }

  /// 「今日」「昨日」「N日前」「N週間前」などの相対表記。
  static String relative(DateTime d, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final day = DateTime(d.year, d.month, d.day);
    final today = DateTime(current.year, current.month, current.day);
    final diff = today.difference(day).inDays;

    if (diff == 0) return '今日';
    if (diff == 1) return '昨日';
    if (diff < 0) {
      // 未来日付。
      if (diff == -1) return '明日';
      return dateShort(d);
    }
    if (diff < 7) return '$diff日前';
    if (diff < 30) return '${diff ~/ 7}週間前';
    if (diff < 365) return '${diff ~/ 30}か月前';
    return date(d);
  }
}
