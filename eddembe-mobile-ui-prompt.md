# UI Prompt: Make the Eddembe app follow Material Design 3

The Eddembe app is running at http://localhost:8686/ and works, but the interface does not look like a professional product. Your job is to redesign the interface only, so it follows Google's Material Design 3 (M3) guidelines the way well-built Google apps do.

Read this whole file first. Then do Step 0 and show me a short plan before changing anything.

## Step 0: Check what you are working on

1. Confirm what is serving port 8686. We expect it is the Flutter app in `mobile/` running on web (`flutter run -d web-server --web-port 8686` or similar). If it is something else (for example the React app in `web/`), stop and tell me.
2. List every screen and the widgets each one uses.
3. Take a screenshot of every screen at phone width (390 x 844) and at laptop width (1280 x 800) before you change anything, so we can compare before and after. Save them in `mobile/docs/ui/before/`.
4. If you have the Dart and Flutter MCP server (from the official Flutter plugin), use it to inspect the running app's widget tree and to run `dart analyze` and tests.

## Rules

1. **Interface only.** Do not change the server, API calls, request or response shapes, Firebase data structure, or app logic. Every feature that works now must still work after.
2. **One design system: Material Design 3.** Flutter's Material library is Google's own implementation of M3, so use its built-in M3 components instead of custom-drawn ones. Do not mix in Microsoft Fluent, Apple Cupertino or another style.
3. **Our own brand, not Google's.** Follow M3 rules for layout, spacing, type, components and motion. Do not use Google's logo, Google product names as app names, or copy the look of a specific Google app. It must look like Eddembe.
4. **Check the guidelines, do not guess.** When you are unsure how a component should look or behave, check https://m3.material.io and https://docs.flutter.dev/ui/design/material. Put `TODO(verify)` where you could not confirm something.
5. **No new UI kits or animation libraries.** Use Flutter's Material widgets and the Material Symbols / Material Icons that come with Flutter.
6. Mobile first. Most users have cheap Android phones. It must also look right in a laptop browser for the demo.

## Theme (`lib/theme.dart`)

One theme for the whole app, applied in `MaterialApp`:

- `useMaterial3: true` (the default in current Flutter, but set it explicitly).
- Colour: `ColorScheme.fromSeed(seedColor: Color(0xFF1B5E20))` for light, and the same seed with `brightness: Brightness.dark` for dark. Use the generated roles (`primary`, `onPrimary`, `primaryContainer`, `secondaryContainer`, `surface`, `surfaceContainer...`, `error`, `outline`, `outlineVariant`) instead of hardcoded colours across the app.
- Amber `#F9A825` only as a highlight (set it as the tertiary seed or use it for one accent such as the "Built"/"Verified" badges). Never put white text on amber.
- Red flags use the `error` / `errorContainer` roles, not a custom red.
- Typography: use the M3 type scale from `Theme.of(context).textTheme` (`displaySmall`, `headlineMedium`, `titleLarge`, `titleMedium`, `bodyLarge`, `bodyMedium`, `labelLarge`). Do not set raw font sizes in widgets. Roboto is fine (Flutter's default on Android).
- Shapes: M3 defaults (cards about 12dp corners, buttons fully rounded, sheets and dialogs larger). Set them once in the theme.
- Support dark mode by following the system setting, with a manual Light / Dark / System choice in Settings.
- Remove all hardcoded colours, font sizes and paddings from screens once the theme covers them.

## Layout

- **Spacing on the 4dp grid**, mostly multiples of 8: 8, 12, 16, 24, 32. Screen side padding 16dp on phones, 24dp on wider screens.
- **Adaptive layout using M3 window size classes:** compact (under 600dp wide), medium (600 to 839dp), expanded (840dp and up).
  - Compact: `NavigationBar` at the bottom (M3, with the pill indicator), not the old `BottomNavigationBar`.
  - Medium and expanded: `NavigationRail` on the left with the same destinations.
  - On expanded screens, keep reading content to a max width of about 840dp and centre it, or use two panes (for example the result on the left and citations on the right).
- **Top app bar:** M3 `AppBar` (small, centre-aligned title on Home is fine). Title "Eddembe", language and settings as icon buttons with tooltips.
- Keep the same four destinations: Home (situations), Ask, Scan, My cases.

## Components to use (M3)

Replace custom widgets with these where they fit:

| Need | M3 widget |
|---|---|
| Main action (Ask, Explain this document, Generate letter) | `FilledButton` |
| Secondary action (Copy, Change photo) | `OutlinedButton` or `FilledButton.tonal` |
| Low-emphasis action (Listen, Skip) | `TextButton` |
| Mic and play | `IconButton.filled` / `IconButton.filledTonal`, at least 48dp, with tooltip |
| Situation choices on Home | `Card.filled` or `Card.outlined` tiles in a grid, each with an icon, title and one-line description, the whole card tappable (`InkWell`) |
| Guided flow answers | `ChoiceChip` or radio `ListTile`s, one question per step, progress shown with `LinearProgressIndicator` |
| Suggested questions | `ActionChip` |
| Language switch | `SegmentedButton` for 2 to 3 options, otherwise a searchable list in a bottom sheet |
| Citations | `Card.outlined`: law name in `titleSmall`, section as a small chip, excerpt in `bodyMedium` with `onSurfaceVariant` |
| Red flags | `ListTile` on `errorContainer` with a warning icon |
| Missing items | `ListTile` with an info icon |
| Result sections | One `Card` per section, clear headings, `Divider` only where it helps |
| Get help organisations | `ListTile` with a "Verified" badge, call and directions as trailing icon buttons |
| Map | Full-width map with a draggable bottom sheet of results |
| Choosing a document | `ModalBottomSheet` with Camera, Photos, Files |
| Confirmations and short messages | `SnackBar` ("Copied", "Saved") |
| Consent before a referral | `AlertDialog` with a clear checkbox and plain words |
| Loading | `CircularProgressIndicator` in the button plus skeleton cards, and status text ("Reading your document...", "Checking the law...") |
| Empty states | A large outlined icon, one sentence, and one action button |
| Errors | Plain words plus a "Try again" button. Never show raw errors or stack traces |
| Community Voice | One `Card` with `ChoiceChip`s and a Skip `TextButton` |

## Content and writing

- Short, plain sentences. Sentence case for titles and buttons ("Explain this document", not "EXPLAIN THIS DOCUMENT").
- Buttons say what happens ("Generate letter", "Play answer"), not "Submit" or "OK".
- Every answer and letter keeps the disclaimer: "Eddembe gives legal information, not legal advice." Show it as small `bodySmall` text, not hidden.
- Long waits are normal (10 to 90 seconds). Show progress and what is happening so the screen never looks frozen.

## Accessibility (required)

- Touch targets at least 48 x 48dp.
- Text contrast at least 4.5:1 (M3 colour roles meet this if you use the matching "on" colours).
- Every icon-only button has a `tooltip` and semantic label.
- Works with large text: test with the system text size at 200%. Nothing should be cut off; let text wrap and let screens scroll.
- Images have semantic labels. Decorative images are excluded from semantics.
- Logical focus order for keyboard use on web.
- Language names shown in their own spelling (Luganda, Runyankole).

## Motion

- Use Flutter's default M3 page transitions and component animations. No custom animations.
- Respect the system "reduce motion" setting.

## Test before you finish

1. Screenshots of every screen after the change at 390 x 844 and 1280 x 800, light and dark, saved in `mobile/docs/ui/after/`.
2. Run the full demo flow: pick Luganda, situation flow, scan the sample eviction notice with a voice question, follow-up question, generate and save a letter, Get help map, Community Voice. Confirm nothing broke.
3. `dart analyze` with no new warnings, and existing tests still pass.
4. Tell me what changed, screen by screen, and anything that still does not follow M3.

## When you are unsure

Ask me. I would rather answer a question than undo a wrong guess.
