import 'package:eddembe_mobile/app.dart';
import 'package:eddembe_mobile/config/situations.dart';
import 'package:eddembe_mobile/models/results.dart';
import 'package:eddembe_mobile/services/app_state.dart';
import 'package:flutter/widgets.dart';
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
}
