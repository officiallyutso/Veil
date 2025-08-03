import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryLight = Color(0xFF1A73E8);
  static const Color primaryDark = Color(0xFF8AB4F8);

  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primaryLight,
    onPrimary: Colors.white,
    secondary: Color(0xFF03DAC6),
    onSecondary: Colors.black,
    error: Color(0xFFB00020),
    onError: Colors.white,
    background: Colors.white,
    onBackground: Colors.black,
    surface: Colors.white,
    onSurface: Colors.black,
    primaryContainer: Color(0xFFBBDEFB),
    onPrimaryContainer: Colors.black,
    secondaryContainer: Color(0xFFE0F7FA),
    onSecondaryContainer: Colors.black,
    surfaceVariant: Color(0xFFE0E0E0),
    onSurfaceVariant: Colors.black,
    outline: Color(0xFFBDBDBD),
  );

  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primaryDark,
    onPrimary: Colors.black,
    secondary: Color(0xFF03DAC6),
    onSecondary: Colors.black,
    error: Color(0xFFCF6679),
    onError: Colors.black,
    background: Color(0xFF121212),
    onBackground: Colors.white,
    surface: Color(0xFF121212),
    onSurface: Colors.white,
    primaryContainer: Color(0xFF37474F),
    onPrimaryContainer: Colors.white,
    secondaryContainer: Color(0xFF004D40),
    onSecondaryContainer: Colors.white,
    surfaceVariant: Color(0xFF37474F),
    onSurfaceVariant: Colors.white,
    outline: Color(0xFF757575),
  );

  static ThemeData lightTheme([ColorScheme? colorScheme]) {
    final scheme = colorScheme ?? lightColorScheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: MaterialStateProperty.all(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  static ThemeData darkTheme([ColorScheme? colorScheme]) {
    final scheme = colorScheme ?? darkColorScheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: MaterialStateProperty.all(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
