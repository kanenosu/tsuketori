import 'package:flutter/material.dart';

/// アプリ共通の色（要件 11.2）。
///
/// - 貸した：青
/// - 借りた：赤／ピンク
/// - 返済済み：緑
/// - 期限超過：赤
class AppColors {
  const AppColors._();

  /// メインカラー（青）。
  static const Color primary = Color(0xFF3B6EF5);

  /// 残高カードのグラデーション（青→インディゴ／パープル）。
  static const Color gradientStart = Color(0xFF4C7DF7);
  static const Color gradientEnd = Color(0xFF7C6FF0);

  /// 貸した（受け取る予定）：青。
  static const Color lend = Color(0xFF3B6EF5);

  /// 借りた（返す予定）：赤／ピンク。
  static const Color borrow = Color(0xFFF4526B);

  /// 返済済み：緑。
  static const Color settled = Color(0xFF16A34A);

  /// 期限超過：赤。
  static const Color overdue = Color(0xFFDC2626);

  /// 一部返済：オレンジ（注意喚起）。
  static const Color partial = Color(0xFFEA580C);

  /// 未返済：グレー。
  static const Color unpaid = Color(0xFF64748B);

  static const Color lightScaffold = Color(0xFFF5F7FA);
  static const Color lightCard = Colors.white;
  static const Color darkScaffold = Color(0xFF121417);
  static const Color darkCard = Color(0xFF1E2126);
}
