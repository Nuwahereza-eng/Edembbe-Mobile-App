import 'package:flutter/material.dart';

const Color kGreenPrimary = Color(0xFF1B5E20);
const Color kAmberSecondary = Color(0xFFF9A825);
const Color kErrorRed = Color(0xFFB3261E);
const Color kBackground = Color(0xFFF8F9FA);
const Color kRedFlag = Color(0xFFFCE8E6);

// Material 3 in Eddembe green, Roboto (the Android default). Text at least 14sp, buttons at least 48dp.
final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Roboto',
  colorScheme: ColorScheme.fromSeed(
    seedColor: kGreenPrimary,
    primary: kGreenPrimary,
    secondary: kAmberSecondary,
    error: kErrorRed,
    surface: kBackground,
  ),
  scaffoldBackgroundColor: kBackground,
  appBarTheme: const AppBarTheme(backgroundColor: kBackground, scrolledUnderElevation: 0),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(fontSize: 16),
    bodyMedium: TextStyle(fontSize: 15),
    bodySmall: TextStyle(fontSize: 14),
    labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
    titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(minimumSize: const Size(48, 52), padding: const EdgeInsets.symmetric(horizontal: 20)),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
  ),
  textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(minimumSize: const Size(48, 48))),
  chipTheme: const ChipThemeData(labelStyle: TextStyle(fontSize: 15)),
  inputDecorationTheme: const InputDecorationTheme(filled: true, fillColor: Colors.white),
  cardTheme: CardThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    elevation: 0,
    margin: EdgeInsets.zero,
  ),
);
