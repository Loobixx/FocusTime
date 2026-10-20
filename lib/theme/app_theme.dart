import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Palette et styles partagés par l'application FocusTime.
///
/// Les widgets peuvent garder leur taille adaptée au contexte ; les styles ne
/// désactivent pas le TextScaler fourni par le système.
abstract final class AppColors {
  static const Color darkBlue = Color(0xFF143063);
  static const Color focusOrange = Color(0xFFFF8C00);
  static const Color transitGreen = Color(0xFF2E7D32);
  static const Color transitGreenBright = Color(0xFF4CAF50);

  static const Color backgroundLight = Color(0xFFF4F7FC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEAF0F8);
  static const Color outlineLight = Color(0xFF8797AC);
  static const Color backgroundDarkTheme = Color(0xFF101521);
  static const Color surfaceDarkTheme = Color(0xFF171E2B);
  static const Color surfaceMutedDarkTheme = Color(0xFF252F40);
  static const Color primaryDarkTheme = Color(0xFFAFC7FF);
  static const Color secondaryDarkTheme = Color(0xFFFFB74D);
  static const Color transitGreenDarkTheme = Color(0xFF8BDFA0);
  static const Color textPrimaryDarkTheme = Color(0xFFF2F5FA);
  static const Color textSecondaryDarkTheme = Color(0xFFB6C0CE);

  static const Color backgroundDark = Color(0xFF12121C);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textPrimary = Color(0xFF1E2430);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF607080);

  static const Color stopped = Color(0xFFE040FB);
  static const Color traversed = Color(0xFFFFB300);
  static const Color reachable = Color(0xFF00E676);
  static const Color unreachable = Color(0xFFFF6B81);
  static const Color stoppedTextOnLight = Color(0xFF8E24AA);
  static const Color traversedTextOnLight = Color(0xFF805000);
  static const Color reachableTextOnLight = Color(0xFF1B5E20);
  static const Color unreachableTextOnLight = Color(0xFFB3261E);
  static const Color error = Color(0xFFB3261E);
  static const Color errorOnDark = Color(0xFFFF6B6B);
}

abstract final class AppTextStyles {
  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      color: AppColors.darkBlue,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.2,
    ),
    headlineLarge: TextStyle(
      color: AppColors.darkBlue,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.2,
    ),
    headlineMedium: TextStyle(
      color: AppColors.darkBlue,
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.25,
    ),
    titleLarge: TextStyle(
      color: AppColors.darkBlue,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.3,
    ),
    titleMedium: TextStyle(
      color: AppColors.darkBlue,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.35,
    ),
    bodyLarge: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 16,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 14,
      height: 1.45,
    ),
    bodySmall: TextStyle(
      color: AppColors.textSecondary,
      fontSize: 12,
      height: 1.4,
    ),
    labelLarge: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    labelMedium: TextStyle(
      color: AppColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
  );

  static final TextTheme darkTextTheme = textTheme.copyWith(
    displayLarge: textTheme.displayLarge?.copyWith(color: AppColors.textPrimaryDarkTheme),
    headlineLarge: textTheme.headlineLarge?.copyWith(color: AppColors.textPrimaryDarkTheme),
    headlineMedium: textTheme.headlineMedium?.copyWith(color: AppColors.textPrimaryDarkTheme),
    titleLarge: textTheme.titleLarge?.copyWith(color: AppColors.textPrimaryDarkTheme),
    titleMedium: textTheme.titleMedium?.copyWith(color: AppColors.textPrimaryDarkTheme),
    bodyLarge: textTheme.bodyLarge?.copyWith(color: AppColors.textPrimaryDarkTheme),
    bodyMedium: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimaryDarkTheme),
    bodySmall: textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryDarkTheme),
    labelLarge: textTheme.labelLarge?.copyWith(color: AppColors.textPrimaryDarkTheme),
    labelMedium: textTheme.labelMedium?.copyWith(color: AppColors.textSecondaryDarkTheme),
  );
}

abstract final class AppTheme {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    canvasColor: AppColors.backgroundLight,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: AppColors.darkBlue,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.darkBlue,
          onPrimary: AppColors.textOnDark,
          secondary: AppColors.focusOrange,
          onSecondary: AppColors.textPrimary,
          tertiary: AppColors.transitGreen,
          onTertiary: AppColors.textOnDark,
          error: AppColors.error,
          onError: AppColors.textOnDark,
          surface: AppColors.surfaceLight,
          onSurface: AppColors.textPrimary,
          surfaceContainerHighest: AppColors.surfaceMuted,
          outline: AppColors.outlineLight,
        ),
    textTheme: AppTextStyles.textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundLight,
      foregroundColor: AppColors.darkBlue,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    iconTheme: const IconThemeData(color: AppColors.darkBlue),
    dividerColor: AppColors.outlineLight.withValues(alpha: 0.35),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.darkBlue,
        foregroundColor: AppColors.textOnDark,
        disabledBackgroundColor: AppColors.surfaceMuted,
        disabledForegroundColor: AppColors.textSecondary,
        minimumSize: const Size(48, 48),
        textStyle: AppTextStyles.textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.darkBlue,
        minimumSize: const Size(48, 48),
        side: const BorderSide(color: AppColors.outlineLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.darkBlue,
        minimumSize: const Size(48, 48),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.focusOrange,
      linearTrackColor: AppColors.surfaceMuted,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.darkBlue,
      contentTextStyle: TextStyle(color: AppColors.textOnDark),
      behavior: SnackBarBehavior.floating,
    ),
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundDarkTheme,
    canvasColor: AppColors.backgroundDarkTheme,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryDarkTheme,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.primaryDarkTheme,
      onPrimary: AppColors.backgroundDarkTheme,
      secondary: AppColors.secondaryDarkTheme,
      onSecondary: AppColors.textPrimary,
      tertiary: AppColors.transitGreenDarkTheme,
      onTertiary: AppColors.backgroundDarkTheme,
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
      surface: AppColors.surfaceDarkTheme,
      onSurface: AppColors.textPrimaryDarkTheme,
      surfaceContainerHighest: AppColors.surfaceMutedDarkTheme,
      outline: const Color(0xFF8994A5),
    ),
    textTheme: AppTextStyles.darkTextTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundDarkTheme,
      foregroundColor: AppColors.textPrimaryDarkTheme,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    iconTheme: const IconThemeData(color: AppColors.primaryDarkTheme),
    dividerColor: const Color(0xFF8994A5),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryDarkTheme,
        foregroundColor: AppColors.backgroundDarkTheme,
        disabledBackgroundColor: AppColors.surfaceMutedDarkTheme,
        disabledForegroundColor: AppColors.textSecondaryDarkTheme,
        minimumSize: const Size(48, 48),
        textStyle: AppTextStyles.darkTextTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryDarkTheme,
        minimumSize: const Size(48, 48),
        side: const BorderSide(color: Color(0xFF8994A5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryDarkTheme,
        minimumSize: const Size(48, 48),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.secondaryDarkTheme,
      linearTrackColor: AppColors.surfaceMutedDarkTheme,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surfaceMutedDarkTheme,
      contentTextStyle: TextStyle(color: AppColors.textPrimaryDarkTheme),
      behavior: SnackBarBehavior.floating,
    ),
  );

  /// Compatibilité avec les écrans qui utilisent encore `AppTheme.theme`.
  static ThemeData get theme => light;
}

abstract final class AppThemeController {
  static const String _preferenceKey = 'app_theme_mode';
  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  static Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedMode = preferences.getString(_preferenceKey);
    mode.value = switch (savedMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static Future<void> setMode(ThemeMode newMode) async {
    mode.value = newMode;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, switch (newMode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }
}
