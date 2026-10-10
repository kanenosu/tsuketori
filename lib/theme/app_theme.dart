import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Quiet grouped surfaces, system typography and iOS navigation conventions.
class AppTheme {
  const AppTheme._();
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    // Keep Apple's system face on Apple devices; use a sans-serif fallback on
    // other platforms, where the private SF font name is not installed.
    final apple =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final family = apple ? '.SF UI Text' : 'Roboto';
    const fallback = ['Hiragino Sans', 'Yu Gothic', 'Meiryo', 'sans-serif'];
    final surface = dark ? AppColors.darkCard : Colors.white;
    final background = dark ? AppColors.darkScaffold : AppColors.lightScaffold;
    final ink = dark ? const Color(0xFFF2F2F7) : const Color(0xFF1C1C1E);
    final secondary = dark ? const Color(0xFFAEAEB2) : const Color(0xFF6C6C70);
    final blue = dark ? const Color(0xFF0A84FF) : AppColors.primary;
    final line = dark ? const Color(0xFF38383A) : const Color(0xFFDCDCE0);
    final scheme = ColorScheme.fromSeed(
      seedColor: blue,
      brightness: brightness,
    ).copyWith(
      primary: blue,
      onPrimary: Colors.white,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: secondary,
      outline: secondary,
      outlineVariant: line,
      surfaceTint: Colors.transparent,
    );
    return ThemeData(
      useMaterial3: true,
      platform: TargetPlatform.iOS,
      fontFamily: family,
      fontFamilyFallback: fallback,
      brightness: brightness,
      colorScheme: scheme,
      typography: Typography.material2021(
        platform: TargetPlatform.iOS,
        colorScheme: scheme,
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: blue,
      ),
      scaffoldBackgroundColor: background,
      cardColor: surface,
      hintColor: secondary,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: blue,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        toolbarHeight: 52,
        titleTextStyle: TextStyle(
          fontFamily: family,
          fontFamilyFallback: fallback,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: secondary, fontWeight: FontWeight.w400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: blue.withValues(alpha: 0.10),
        side: BorderSide.none,
        showCheckmark: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: TextStyle(fontSize: 13, color: ink),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        iconColor: blue,
        textColor: ink,
        titleTextStyle: TextStyle(
          fontSize: 16,
          color: ink,
          fontWeight: FontWeight.w400,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(space: 1, thickness: 0.5, color: line),
    );
  }
}
