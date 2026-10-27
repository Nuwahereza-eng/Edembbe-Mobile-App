import 'package:eddembe_mobile/app.dart';
import 'package:eddembe_mobile/services/app_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Back on the first guided step returns to Home', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'selected_language_code': 'eng'});
    final state = await tester.runAsync(AppState.load);
    await tester.pumpWidget(ChangeNotifierProvider.value(value: state!, child: const EddembeApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My landlord wants me out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('How do you pay rent?'), findsOneWidget);
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 / 5'), findsOneWidget);
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 / 5'), findsNothing, reason: 'second Back should leave the guided flow');
    });

  testWidgets('The app bar back arrow steps back, then leaves the guided flow', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'selected_language_code': 'eng'});
    final state = await tester.runAsync(AppState.load);
    await tester.pumpWidget(ChangeNotifierProvider.value(value: state!, child: const EddembeApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My landlord wants me out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 / 5'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 / 5'), findsNothing, reason: 'second back arrow should leave the guided flow');
  });
}
