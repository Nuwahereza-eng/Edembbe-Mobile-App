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
  final scheme = base.copyWith(
    tertiary: amber.primary,
    onTertiary: amber.onPrimary,
    tertiaryContainer: amber.primaryContainer,
    onTertiaryContainer: amber.onPrimaryContainer,
  );
  if (brightness == Brightness.dark) return scheme;
  // In light mode the seed tints every surface green. Calm, warm neutrals keep green for actions and
  // highlights: page (surface), cards (lowest, white), navigation (container), subtle borders (outlineVariant).
  return scheme.copyWith(
    surface: const Color(0xFFF6F7F3),
    surfaceContainerLowest: const Color(0xFFFFFFFF),
    surfaceContainerLow: const Color(0xFFF1F2EE),
    surfaceContainer: const Color(0xFFECEDE8),
    surfaceContainerHigh: const Color(0xFFE6E8E2),
    surfaceContainerHighest: const Color(0xFFE1E3DD),
    outlineVariant: const Color(0xFFD4D9CF),
  );
}

// Touch targets at least 48dp for every button.
const Size _minButton = Size(64, 48);

/// Cards are flat and outlined with this radius; depth comes from the surface and border, not shadows.
const BorderRadius kCardRadius = BorderRadius.all(Radius.circular(16));

/// For cards filled with a container colour (help, errors), which need no outline.
const ShapeBorder kTintedCardShape = RoundedRectangleBorder(borderRadius: kCardRadius);

/// Cards and text fields: white on the warm page in light mode, one step lighter than the page in dark mode.
Color cardSurface(ColorScheme scheme) =>
    scheme.brightness == Brightness.light ? scheme.surfaceContainerLowest : scheme.surfaceContainerLow;

ThemeData _theme(Brightness brightness) {
  final scheme = _scheme(brightness);
  final text = Typography.material2021(platform: TargetPlatform.android).englishLike;
  // Navigation labels stay at 14sp; the selected one is also bolder, so selection never relies on colour alone.
  TextStyle? navLabel(bool selected) => text.labelLarge?.copyWith(
        fontFamily: 'Roboto',
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Roboto',
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    // Page and step headings are a little heavier than M3's default, for a clear hierarchy.
    textTheme: const TextTheme(headlineSmall: TextStyle(fontWeight: FontWeight.w600)),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      // Language and settings stay visible but quieter than the page content.
      actionsIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      scrolledUnderElevation: 3,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      indicatorColor: scheme.secondaryContainer,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) => navLabel(states.contains(WidgetState.selected))),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected) ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
          )),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.secondaryContainer,
      selectedLabelTextStyle: navLabel(true),
      unselectedLabelTextStyle: navLabel(false),
      selectedIconTheme: IconThemeData(size: 24, color: scheme.onSecondaryContainer),
      unselectedIconTheme: IconThemeData(size: 24, color: scheme.onSurfaceVariant),
    ),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: _minButton)),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(minimumSize: _minButton)),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(minimumSize: _minButton)),
    // Fields keep the M3 outline (3:1 against the page) and are filled like cards so they stand out.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardSurface(scheme),
      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    listTileTheme: const ListTileThemeData(minTileHeight: 56),
    // Cards line up with the text around them; screens add their own spacing between cards.
    // Every card variant (plain, filled, outlined) gets the same flat, outlined look.
    cardTheme: CardThemeData(
      margin: EdgeInsets.zero,
      color: cardSurface(scheme),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: kCardRadius, side: BorderSide(color: scheme.outlineVariant)),
    ),
    // A soft green button rather than the solid dark brand green, like the navigation indicator.
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.secondaryContainer,
      foregroundColor: scheme.onSecondaryContainer,
      elevation: 1,
      focusElevation: 1,
      hoverElevation: 2,
      highlightElevation: 1,
    ),
  );
}

final ThemeData lightTheme = _theme(Brightness.light);
final ThemeData darkTheme = _theme(Brightness.dark);
