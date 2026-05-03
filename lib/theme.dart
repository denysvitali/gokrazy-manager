import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSpacing {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double s = 12.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 14.0;
  static const double lg = 22.0;
  static const double xl = 32.0;
}

class AppMotion {
  static const Duration fast = Duration(milliseconds: 220);
  static const Duration normal = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 520);
}

class AppBreakpoints {
  static const double tablet = 720.0;
  static const double desktop = 1080.0;
}

class AppPalette {
  static const Color indigo = Color(0xFF6366F1);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color emerald = Color(0xFF10B981);
  static const Color amber = Color(0xFFF59E0B);
  static const Color coral = Color(0xFFFB7185);
  static const Color rose = Color(0xFFF43F5E);
  static const Color sky = Color(0xFF38BDF8);

  static const Color slate900 = Color(0xFF0B1020);
  static const Color slate850 = Color(0xFF111A33);
  static const Color slate800 = Color(0xFF1A2342);
  static const Color slate700 = Color(0xFF2A3358);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate50 = Color(0xFFF8FAFF);
}

enum AppThemeVariant {
  system,
  light,
  dark,
  amoledBlack,
}

const String _themePreferenceKey = 'theme_variant';

final ValueNotifier<AppThemeVariant> appThemeVariant =
    ValueNotifier(AppThemeVariant.system);

Future<void> loadThemePreference() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_themePreferenceKey);
  if (raw == null) {
    return;
  }
  try {
    appThemeVariant.value = AppThemeVariant.values.byName(raw);
  } catch (_) {
    // Ignore unknown values from older builds.
  }
}

Future<void> saveThemePreference(AppThemeVariant value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_themePreferenceKey, value.name);
}

ThemeData buildAppTheme(Brightness brightness, {bool amoledBlack = false}) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppPalette.indigo,
    brightness: brightness,
    primary: AppPalette.indigo,
    secondary: AppPalette.cyan,
    tertiary: AppPalette.violet,
    error: AppPalette.rose,
  );

  final Color pageBg = dark
      ? (amoledBlack ? Colors.black : scheme.surface)
      : scheme.surface;

  final Color cardBg = dark
      ? (amoledBlack ? const Color(0xFF0A0F1F) : AppPalette.slate800)
      : Colors.white;

  final Color outline = scheme.outline.withValues(
    alpha: dark ? 0.34 : 0.12,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
  );
  final textTheme = ThemeData(
    useMaterial3: true,
    brightness: brightness,
  ).textTheme
      .apply(
        bodyColor: dark ? Colors.white : const Color(0xFF111827),
        displayColor: dark ? Colors.white : const Color(0xFF0F172A),
      )
      .copyWith(
        displayLarge: const TextStyle(
            fontSize: 56, fontWeight: FontWeight.w800, height: 1.05, letterSpacing: -1.2),
        displayMedium: const TextStyle(
            fontSize: 44, fontWeight: FontWeight.w800, height: 1.05, letterSpacing: -0.8),
        displaySmall: const TextStyle(
            fontSize: 34, fontWeight: FontWeight.w700, height: 1.1, letterSpacing: -0.4),
        headlineLarge: const TextStyle(
            fontSize: 30, fontWeight: FontWeight.w700, height: 1.15, letterSpacing: -0.3),
        headlineMedium: const TextStyle(
            fontSize: 26, fontWeight: FontWeight.w700, height: 1.18, letterSpacing: -0.2),
        headlineSmall: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.w700, height: 1.22),
        titleLarge: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700, height: 1.25, letterSpacing: -0.2),
        titleMedium: const TextStyle(
            fontSize: 17, fontWeight: FontWeight.w600, height: 1.3),
        titleSmall: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, height: 1.35),
        bodyLarge: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w400, height: 1.45),
        bodyMedium: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w400, height: 1.45),
        bodySmall: const TextStyle(
            fontSize: 12.5, fontWeight: FontWeight.w400, height: 1.4),
        labelLarge: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
        labelMedium: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        labelSmall: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    visualDensity: VisualDensity.standard,
    scaffoldBackgroundColor: pageBg,
    canvasColor: pageBg,
    textTheme: textTheme,
    splashFactory: InkSparkle.splashFactory,
    cardTheme: CardThemeData(
      color: cardBg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: outline),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: pageBg,
      foregroundColor: scheme.onSurface,
      centerTitle: false,
      scrolledUnderElevation: 0,
      elevation: 0,
      toolbarHeight: 60,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
      systemOverlayStyle: dark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: pageBg,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: pageBg,
            ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(AppSpacing.xs)),
        minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.s,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        textStyle: textTheme.labelLarge,
        minimumSize: const Size(0, 48),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.s,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        textStyle: textTheme.labelLarge,
        side: BorderSide(color: outline),
        minimumSize: const Size(0, 48),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        textStyle: textTheme.labelLarge,
        minimumSize: const Size(0, 44),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? AppPalette.slate850 : Colors.white,
      hoverColor: dark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.black.withValues(alpha: 0.02),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: BorderSide(color: outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
      labelStyle: TextStyle(
        color: dark
            ? Colors.white.withValues(alpha: 0.65)
            : Colors.black.withValues(alpha: 0.6),
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(
        color: dark
            ? Colors.white.withValues(alpha: 0.4)
            : Colors.black.withValues(alpha: 0.4),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.m,
      ),
    ),
    chipTheme: ChipThemeData(
      labelStyle: textTheme.labelMedium,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.xxs,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: outline,
      space: 0,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      insetPadding: const EdgeInsets.all(AppSpacing.m),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark
          ? (amoledBlack ? Colors.black : AppPalette.slate850)
          : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: scheme.primary.withValues(alpha: 0.16),
      labelTextStyle: WidgetStatePropertyAll(
        textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: scheme.primary, size: 26);
        }
        return IconThemeData(
          color: dark
              ? Colors.white.withValues(alpha: 0.65)
              : Colors.black.withValues(alpha: 0.6),
          size: 24,
        );
      }),
      indicatorShape: const StadiumBorder(),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: dark ? AppPalette.slate850 : Colors.white,
      selectedIconTheme: IconThemeData(color: scheme.primary, size: 28),
      unselectedIconTheme: IconThemeData(
        color: dark
            ? Colors.white.withValues(alpha: 0.6)
            : Colors.black.withValues(alpha: 0.55),
        size: 24,
      ),
      selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
        color: scheme.primary,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
        color: dark
            ? Colors.white.withValues(alpha: 0.65)
            : Colors.black.withValues(alpha: 0.6),
      ),
      indicatorColor: scheme.primary.withValues(alpha: 0.16),
      indicatorShape: const StadiumBorder(),
      useIndicator: true,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: cardBg,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: cardBg,
      modalElevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: cardBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: dark
          ? Colors.white.withValues(alpha: 0.7)
          : Colors.black.withValues(alpha: 0.65),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.xs,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: dark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06),
      circularTrackColor: dark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      extendedTextStyle: textTheme.labelLarge?.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: const WidgetStatePropertyAll(6),
      thumbColor: WidgetStatePropertyAll(
        dark
            ? Colors.white.withValues(alpha: 0.16)
            : Colors.black.withValues(alpha: 0.18),
      ),
      radius: const Radius.circular(8),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

class AppGradients {
  static LinearGradient hero(ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: dark
          ? [
              const Color(0xFF312E81),
              const Color(0xFF1E3A8A),
              const Color(0xFF0F766E),
            ]
          : [
              const Color(0xFF6366F1),
              const Color(0xFF8B5CF6),
              const Color(0xFF06B6D4),
            ],
      stops: const [0.0, 0.55, 1.0],
    );
  }

  static LinearGradient cardSurface(ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: dark
          ? [
              Colors.white.withValues(alpha: 0.05),
              Colors.white.withValues(alpha: 0.01),
            ]
          : [
              Colors.white.withValues(alpha: 0.7),
              Colors.white.withValues(alpha: 0.4),
            ],
    );
  }

  static LinearGradient ofHue(double hue, {required Brightness brightness}) {
    final dark = brightness == Brightness.dark;
    final hsl = HSLColor.fromAHSL(1, hue, dark ? 0.5 : 0.65, dark ? 0.5 : 0.55);
    final hsl2 = HSLColor.fromAHSL(
      1,
      (hue + 38) % 360,
      dark ? 0.5 : 0.6,
      dark ? 0.45 : 0.6,
    );
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [hsl.toColor(), hsl2.toColor()],
    );
  }
}

void scheduleThemeSave(AppThemeVariant variant) {
  unawaited(saveThemePreference(variant));
}
