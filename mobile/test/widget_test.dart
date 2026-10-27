import 'package:eddembe_mobile/app.dart';
import 'package:eddembe_mobile/config/situations.dart';
import 'package:eddembe_mobile/models/results.dart';
import 'package:eddembe_mobile/screens/guided_flow_screen.dart';
import 'package:eddembe_mobile/screens/home_situations_screen.dart';
import 'package:eddembe_mobile/services/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpApp(WidgetTester tester) async {
  // A typical Android phone screen.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  // Firebase is not available in tests; the app carries on without it.
  final state = await AppState.load();
  await tester.pumpWidget(ChangeNotifierProvider.value(value: state, child: const EddembeApp()));
  await tester.pump();
}

/// Lets animations and page transitions finish; unlike pumpAndSettle it also works while a spinner runs.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('first launch shows the language picker', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(() => pumpApp(tester));
    expect(find.text('Choose your language'), findsOneWidget);
    expect(find.text('Runyankole'), findsOneWidget);
  });

  testWidgets('a saved language opens the situations', (tester) async {
    SharedPreferences.setMockInitialValues({'selected_language_code': 'eng'});
    await tester.runAsync(() => pumpApp(tester));
    expect(find.text('My landlord wants me out'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Something else'), 200);
    expect(find.text('Something else'), findsOneWidget);
  });

  testWidgets('the whole situation card opens its questions', (tester) async {
    SharedPreferences.setMockInitialValues({'selected_language_code': 'eng'});
    await tester.runAsync(() => pumpApp(tester));
    expect(find.text('Housing'), findsOneWidget);
    // Tapping the description, not the title or arrow, still opens the guided flow.
    await tester.tap(find.text('Eviction notices, rent, deposits or locked doors.'));
    await settle(tester);
    expect(find.byType(GuidedFlowScreen), findsOneWidget);
  });

  testWidgets('each situation card is one button for screen readers', (tester) async {
    SharedPreferences.setMockInitialValues({'selected_language_code': 'eng'});
    final semantics = tester.ensureSemantics();
    await tester.runAsync(() => pumpApp(tester));
    expect(
      tester.getSemantics(find.text('Problem at work')),
      matchesSemantics(
        label: 'Work\nProblem at work\nUnpaid wages, dismissal, contracts or unfair treatment.',
        isButton: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('a guided answer is one selectable row', (tester) async {
    SharedPreferences.setMockInitialValues({'selected_language_code': 'eng'});
    final semantics = tester.ensureSemantics();
    await tester.runAsync(() => pumpApp(tester));
    await tester.tap(find.text('My landlord wants me out'));
    await settle(tester);
    expect(tester.getSemantics(find.text('The rent was raised')), matchesSemantics(
      label: 'The rent was raised',
      isButton: true,
      hasSelectedState: true,
      isSelected: false,
      hasTapAction: true,
      hasFocusAction: true,
      isFocusable: true,
    ));
    await tester.tap(find.text('The rent was raised'));
    await settle(tester);
    expect(tester.getSemantics(find.text('The rent was raised')).flagsCollection.isSelected, isTrue);
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the bottom navigation switches tabs and marks the selected one', (tester) async {
    SharedPreferences.setMockInitialValues({'selected_language_code': 'eng'});
    await tester.runAsync(() => pumpApp(tester));
    int selected() => tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;
    expect(selected(), 0);
    await tester.tap(find.text('Scan').last);
    await settle(tester);
    expect(selected(), 2);
    await tester.tap(find.text('My cases').last);
    await settle(tester);
    expect(selected(), 3);
    await tester.tap(find.text('Home').last);
    await settle(tester);
    expect(selected(), 0);
  });

  test('guided answers become one plain question', () {
    final eviction = situationById('eviction')!;
    final q = eviction.buildQuestion({
      0: eviction.steps[0].choices[0],
      1: eviction.steps[1].choices[1],
      2: eviction.steps[2].choices[0],
    });
    expect(q, contains('My landlord gave me a notice to leave.'));
    expect(q, contains('I pay rent every month.'));
    expect(q, contains('less than 7 days'));
    expect(q, endsWith('what should I do next?'));
  });

  test('scan turns become English history for follow-ups', () {
    final scan = AnalyzeResult.fromJson({
      'document_type': 'Notice to Vacate',
      'summary': 'Ekiwandiiko...',
      'summary_en': 'A notice asking the tenant to leave in 3 days.',
      'red_flags': ['Ekiseera ekimpimpi'],
      'red_flags_en': ['Extremely short deadline (3 days)'],
      'related_sections': [
        {'law_name': 'Landlord and Tenant Act, 2022', 'section_number': '38', 'excerpt': '', 'red_flags': ['Extremely short deadline (3 days)'], 'explanation': '...'},
      ],
      'question_en': 'Is this allowed?',
      'question_answer_en': 'No.',
    });
    expect(scan.sectionsForFlag(0).single.sectionNumber, '38');
    final history = Turn.scan(question: 'Kino kikkirizibwa?', scan: scan).toHistory();
    expect(history['question'], 'I scanned a document. Is this allowed?');
    expect(history['answer'], contains('Extremely short deadline'));
  });

  testWidgets('every tab and the guided flow fit at 200% text size', (tester) async {
    SharedPreferences.setMockInitialValues({'selected_language_code': 'eng'});
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.runAsync(() => pumpApp(tester));
    // Any RenderFlex overflow is reported as a test failure.
    for (final tab in ['Ask', 'Scan', 'My cases', 'Home']) {
      await tester.tap(find.text(tab).last);
      await settle(tester);
    }
    // Every tab's list stays alive in the tab stack, so scroll Home's own list.
    await tester.drag(
      find.descendant(of: find.byType(HomeSituationsScreen), matching: find.byType(Scrollable)).first,
      const Offset(0, -300),
    );
    await settle(tester);
    await tester.tap(find.text('My landlord wants me out'));
    await settle(tester);
    expect(find.text('What is happening?'), findsOneWidget);
    await tester.drag(
      find.descendant(of: find.byType(GuidedFlowScreen), matching: find.byType(Scrollable)).first,
      const Offset(0, -600),
    );
    await settle(tester);
    await tester.tap(find.text('Next'));
    await settle(tester);
    expect(find.text('How do you pay rent?'), findsOneWidget);
  });

  test('a saved chat turn comes back the same', () {
    final ask = AskResult.fromJson({
      'answer': 'Owner wa nnyumba alina okukuwa ennaku 30.',
      'answer_en': 'Your landlord must give you 30 days.',
      'next_steps': ['Kebera endagaano yo.'],
      'next_steps_en': ['Check your agreement.'],
      'citations': [
        {'law_name': 'Landlord and Tenant Act, 2022', 'section_number': '38', 'excerpt': 'thirty days'},
      ],
      'confidence': 'high',
    });
    final saved = Turn.ask(question: 'Kiki?', ask: ask, heard: 'Kiki?', questionEn: 'What?').toJson();
    final back = Turn.fromJson(saved);
    expect(back.question, 'Kiki?');
    expect(back.heard, 'Kiki?');
    expect(back.ask!.answer, ask.answer);
    expect(back.citations.single.sectionNumber, '38');
    expect(back.toHistory(), {'question': 'What?', 'answer': 'Your landlord must give you 30 days.'});
  });
}
