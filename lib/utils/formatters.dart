import 'package:intl/intl.dart';

/// 金額・日付の表示フォーマット（要件 6.1.1 / 11章）。
class Formatters {
  const Formatters._();

  static final NumberFormat _yen = NumberFormat('#,##0', 'ja_JP');

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

  static final DateFormat _date = DateFormat('yyyy/MM/dd', 'ja_JP');
  static final DateFormat _dateShort = DateFormat('MM/dd', 'ja_JP');
  static final DateFormat _month = DateFormat('yyyy年MM月', 'ja_JP');
  static final DateFormat _dateTime = DateFormat('yyyy/MM/dd HH:mm', 'ja_JP');

  static String date(DateTime d) => _date.format(d);

  static String dateShort(DateTime d) => _dateShort.format(d);

  static String month(DateTime d) => _month.format(d);

  static String dateTime(DateTime d) => _dateTime.format(d);
}
