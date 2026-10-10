import 'package:flutter/material.dart';

/// アプリ共通の色（要件 11.2）。
///
/// - 貸した：深緑
/// - 借りた：茶
/// - 返済済み：緑
/// - 期限超過：赤
class AppColors {
  const AppColors._();

  /// メインカラー（青）。
  static const Color primary = Color(0xFF007AFF);

  /// 貸した（受け取る予定）。
  static const Color lend = Color(0xFF287B68);

  /// 借りた（返す予定）。
  static const Color borrow = Color(0xFFA55D3A);

  /// 返済済み：緑。
  static const Color settled = Color(0xFF34816D);

  /// 期限超過：赤。
  static const Color overdue = Color(0xFFDC2626);

  /// 一部返済：オレンジ（注意喚起）。
  static const Color partial = Color(0xFFAD712D);

  /// 未返済：グレー。
  static const Color unpaid = Color(0xFF8E8E93);

  static const Color lightScaffold = Color(0xFFF2F2F7);
  static const Color lightCard = Colors.white;
  static const Color darkScaffold = Color(0xFF000000);
  static const Color darkCard = Color(0xFF1C1C1E);
}
