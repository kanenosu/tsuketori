import 'package:flutter/material.dart';

/// アプリ共通の色（要件 11.2・PayPay App Style Guide 準拠）。
///
/// - メイン：赤（ヘッダー・主要ボタン）
/// - 貸した：ブルー
/// - 借りた：オレンジ
/// - 返済済み：Success グリーン
/// - 期限超過：Error レッド
/// - 一部返済：Caution イエロー
class AppColors {
  const AppColors._();

  /// メインカラー（赤）。ヘッダー・主要ボタン・選択状態に使う。
  /// ※PayPay の Brand color に近い赤。個人利用前提。公開する場合は色をずらすこと。
  static const Color primary = Color(0xFFFF0033);

  /// 押下時（明度 -5）。
  static const Color primaryPressed = Color(0xFFE6002E);

  /// ヘッダーのグラデーション（縦方向）。
  static const Color gradientStart = Color(0xFFFF0033);
  static const Color gradientEnd = Color(0xFFFF3B62);

  /// ネイビー（サービスアイコン・強調テキスト）。
  static const Color navy = Color(0xFF002970);

  /// 貸した（受け取る予定）。
  static const Color lend = Color(0xFF3895FF);

  /// 借りた（返す予定）。赤のメインカラーと区別するためオレンジ。
  static const Color borrow = Color(0xFFFC6600);

  /// 返済済み（Success）。
  static const Color settled = Color(0xFF20BF7A);

  /// 期限超過（Error）。
  static const Color overdue = Color(0xFFFD5C5C);

  /// 一部返済（Caution）。
  static const Color partial = Color(0xFFFFB900);

  /// 未返済。
  static const Color unpaid = Color(0xFF909090);

  /// テキスト色（用途固定）。
  static const Color textBlack = Color(0xFF242323);
  static const Color textGray = Color(0xFF606060);
  static const Color subtextGray = Color(0xFF909090);
  static const Color placeholder = Color(0xFFBABABA);

  /// 区切り線・無効背景・押下背景。
  static const Color line = Color(0xFFEEEEEE);
  static const Color pressed = Color(0xFFF2F2F2);

  static const Color lightScaffold = Color(0xFFF7F7F7);
  static const Color lightCard = Colors.white;
  static const Color darkScaffold = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);

  /// Low-Shadow（#000 α0.08, Y2, Blur6）。
  static const List<BoxShadow> lowShadow = [
    BoxShadow(color: Color(0x14000000), offset: Offset(0, 2), blurRadius: 6),
  ];

  /// Middle-Shadow（#000 α0.15, Y6, Blur15）。
  static const List<BoxShadow> middleShadow = [
    BoxShadow(color: Color(0x26000000), offset: Offset(0, 6), blurRadius: 15),
  ];
}
