import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1A237E);
  static const Color accentColor = Color(0xFF00C853);
  static const Color errorColor = Color(0xFFD32F2F);

  static const Color darkBg = Color(0xFF0D1117);
  static const Color darkCard = Color(0xFF161B22);
  static const Color darkSurface = Color(0xFF21262D);

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;

  static const EdgeInsets paddingSm = EdgeInsets.all(12);
  static const EdgeInsets paddingMd = EdgeInsets.all(16);
  static const EdgeInsets paddingLg = EdgeInsets.all(20);
  static const EdgeInsets paddingH = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets paddingV = EdgeInsets.symmetric(vertical: 12);

  static const gapXs = SizedBox(height: 4);
  static const gapSm = SizedBox(height: 8);
  static const gapMd = SizedBox(height: 12);
  static const gapLg = SizedBox(height: 16);
  static const gapXl = SizedBox(height: 24);
  static const gap2xl = SizedBox(height: 32);

  static const gapWSm = SizedBox(width: 8);
  static const gapWMd = SizedBox(width: 12);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      error: errorColor,
      surface: Colors.white,
      onSurface: const Color(0xFF1A1A2E),
    ),
    scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      prefixIconColor: Colors.grey,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
      contentTextStyle: const TextStyle(fontSize: 14),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      indicatorColor: Colors.white,
      labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 14),
    ),
    dividerTheme: DividerThemeData(
      space: 1,
      thickness: 1,
      color: Colors.grey.shade200,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF5C6BC0),
      secondary: accentColor,
      error: errorColor,
      surface: darkCard,
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: darkBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF161B22),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF161B22),
      selectedItemColor: Color(0xFF5C6BC0),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5C6BC0),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        side: const BorderSide(color: Color(0xFF5C6BC0)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: const BorderSide(color: Color(0xFF5C6BC0), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      prefixIconColor: Colors.grey,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
      contentTextStyle: const TextStyle(fontSize: 14),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      indicatorColor: Colors.white,
      labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 14),
    ),
    dividerTheme: DividerThemeData(
      space: 1,
      thickness: 1,
      color: Colors.grey.shade800,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
  );
}
