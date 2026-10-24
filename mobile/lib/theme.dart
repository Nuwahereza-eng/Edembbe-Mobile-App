import 'package:flutter/material.dart';

const Color kGreenPrimary = Color(0xFF1B5E20);
const Color kAmberSecondary = Color(0xFFF9A825);
const Color kErrorRed = Color(0xFFB3261E);
const Color kBackground = Color(0xFFF8F9FA);
const Color kRedFlag = Color(0xFFFCE8E6);

ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: kGreenPrimary,
    primary: kGreenPrimary,
    secondary: kAmberSecondary,
    error: kErrorRed,
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: kBackground,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(fontSize: 16),
    bodyMedium: TextStyle(fontSize: 14),
    labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
  ),
  cardTheme: CardThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    elevation: 0,
    margin: EdgeInsets.zero,
  ),
);
