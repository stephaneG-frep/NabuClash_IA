import 'package:flutter/material.dart';

class NabuTheme {
  static const violet = Color(0xffb899ff),
      cyan = Color(0xff6ee7ef),
      pink = Color(0xffff82c4),
      night = Color(0xff0c0b1c);
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: night,
    colorScheme: ColorScheme.fromSeed(
      seedColor: violet,
      brightness: Brightness.dark,
      primary: violet,
      secondary: cyan,
      surface: const Color(0xff19172d),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
      ),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(fontSize: 17, height: 1.5),
      bodyMedium: TextStyle(fontSize: 15, height: 1.45),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xff211d37),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.all(18),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    appBarTheme: const AppBarTheme(backgroundColor: night, centerTitle: false),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Color(0xff171429),
      indicatorColor: Color(0xff483164),
    ),
  );
}
