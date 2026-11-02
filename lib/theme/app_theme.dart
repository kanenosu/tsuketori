import 'package:flutter/material.dart';

import 'app_colors.dart';

/// ライト／ダークのテーマ定義（要件 11章・11.4）。
///
/// PayPay App Style Guide の Global Rule に合わせる：
/// 角丸 8px、アクション色 #3895FF、テキスト #242323、
/// 影は真上光源の Low-Shadow、フォームは下線スタイル。
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static const _radius = 8.0;
  static const String _font = 'Manrope';
  static const _fallback = ['Hiragino Sans', 'Noto Sans CJK JP'];

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final text = isDark ? Colors.white : AppColors.textBlack;
    final subText = isDark ? const Color(0xFFB0B0B0) : AppColors.textGray;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final line = isDark ? const Color(0xFF2E2E2E) : AppColors.line;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      error: AppColors.overdue,
      surface: card,
      onSurface: text,
      outline: AppColors.placeholder,
      outlineVariant: line,
    );

    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final textTheme = base.textTheme
        .apply(bodyColor: text, displayColor: text, fontFamily: _font)
        .apply(fontFamilyFallback: _fallback);

    const buttonText = TextStyle(
      fontFamily: _font,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamilyFallback: _fallback,
      textTheme: textTheme,
      hintColor: isDark ? const Color(0xFF8A8A8A) : AppColors.subtextGray,
      splashFactory: NoSplash.splashFactory,
      highlightColor: isDark ? Colors.white10 : AppColors.pressed,
      scaffoldBackgroundColor:
          isDark ? AppColors.darkScaffold : AppColors.lightScaffold,
      // Header（Regular）：白背景・タイトル H16 中央。
      appBarTheme: AppBarTheme(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: text, size: 24),
        actionsIconTheme: IconThemeData(color: text, size: 24),
        titleTextStyle: TextStyle(
          fontFamily: _font,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 60,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: _font,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.primary : AppColors.subtextGray,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? AppColors.primary : AppColors.subtextGray,
          );
        }),
      ),
      // Primary ボタン：#3895FF（押下 #3286FF）・白文字 L14 Bold・角丸 8。
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
          elevation: const WidgetStatePropertyAll(0),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(_radius)),
            ),
          ),
          textStyle: const WidgetStatePropertyAll(buttonText),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return isDark ? const Color(0xFF2E2E2E) : AppColors.line;
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.primaryPressed;
            }
            return AppColors.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.placeholder;
            }
            return Colors.white;
          }),
        ),
      ),
      // Secondary ボタン：白背景＋1px #3895FF。
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: AppColors.primary,
          backgroundColor: card,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
          textStyle: buttonText,
        ),
      ),
      // Tertiary ボタン。
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
          textStyle: buttonText,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
      ),
      // Form：下線（Empty 1px #BABABA / Editing 2px #3895FF / Error #FD5C5C）。
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        labelStyle: TextStyle(fontSize: 14, color: subText),
        floatingLabelStyle: TextStyle(fontSize: 12, color: subText),
        hintStyle: const TextStyle(fontSize: 16, color: AppColors.placeholder),
        helperStyle: TextStyle(fontSize: 12, color: subText),
        errorStyle: const TextStyle(fontSize: 12, color: AppColors.overdue),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.placeholder),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.placeholder),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.overdue),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.overdue, width: 2),
        ),
        disabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: line),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: isDark ? Colors.white70 : AppColors.navy,
        titleTextStyle: TextStyle(fontFamily: _font, fontSize: 16, color: text),
        subtitleTextStyle: TextStyle(
          fontFamily: _font,
          fontSize: 14,
          color: subText,
        ),
      ),
      // Toggle Switch：ON #3895FF / OFF #EEEEEE。
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        trackColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected)
                  ? AppColors.primary
                  : (isDark ? const Color(0xFF3A3A3A) : AppColors.line),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primary : null,
        ),
        side: const BorderSide(color: AppColors.placeholder),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.placeholder,
        ),
      ),
      // Select Button：高さ30・角丸15、選択 #3895FF 白文字／非選択 枠 #BABABA。
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(
          side: BorderSide(color: AppColors.placeholder),
        ),
        backgroundColor: card,
        selectedColor: AppColors.primary,
        showCheckmark: false,
        labelStyle: WidgetStateTextStyle.resolveWith(
          (s) => TextStyle(
            fontFamily: _font,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color:
                s.contains(WidgetState.selected)
                    ? Colors.white
                    : AppColors.subtextGray,
          ),
        ),
      ),
      // Half Sheet：上左右角丸 20、オーバーレイ #000 α0.6。
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: const Color(0x99000000),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
      ),
      // Toast：背景 #3895FF・白文字 14、アクションなし。
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: const TextStyle(
          fontFamily: _font,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
      ),
      // Tab：選択 #3895FF＋下線2px／非選択 #606060。
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: subText,
        indicatorColor: AppColors.primary,
        dividerColor: line,
        labelStyle: buttonText,
        unselectedLabelStyle: buttonText,
      ),
      dividerTheme: DividerThemeData(space: 1, thickness: 1, color: line),
    );
  }
}
