import 'package:flutter/material.dart';

// Eddembe's Material 3 theme. Screens use these colour roles and the M3 type scale
// (Theme.of(context).textTheme), never raw colours or font sizes.

const Color kBrandGreen = Color(0xFF1B5E20);

/// Amber is only a highlight (for example the Verified badge). It is used through the tertiary
/// roles, so text on it always uses the matching "on" colour and is never white on amber.
const Color kBrandAmber = Color(0xFFF9A825);

ColorScheme _scheme(Brightness brightness) {
  // The fidelity variant keeps the primary close to the brand green instead of a muted tone.
  final base = ColorScheme.fromSeed(
    seedColor: kBrandGreen,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
  );
  final amber = ColorScheme.fromSeed(
    seedColor: kBrandAmber,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
  );
  return base.copyWith(
    tertiary: amber.primary,
    onTertiary: amber.onPrimary,
    tertiaryContainer: amber.primaryContainer,
    onTertiaryContainer: amber.onPrimaryContainer,
  );
}

// Touch targets at least 48dp for every button.
const Size _minButton = Size(64, 48);

ThemeData _theme(Brightness brightness) {
  final scheme = _scheme(brightness);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Roboto',
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      scrolledUnderElevation: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: _minButton)),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(minimumSize: _minButton)),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(minimumSize: _minButton)),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    listTileTheme: const ListTileThemeData(minTileHeight: 56),
    // Cards line up with the text around them; screens add their own spacing between cards.
    cardTheme: const CardThemeData(margin: EdgeInsets.zero),
  );
}

final ThemeData lightTheme = _theme(Brightness.light);
final ThemeData darkTheme = _theme(Brightness.dark);
