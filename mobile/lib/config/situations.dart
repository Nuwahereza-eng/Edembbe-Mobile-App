// Situation buttons on the home screen and their guided questions.
//
// Only situations the server's laws cover are offered (Landlord and Tenant Act, Employment Act and its
// 2026 amendment, Land Act, Access to Information Act, Constitution). The app never writes legal answers:
// the tap answers below become a plain English question for the Ask endpoint, which answers from the law.
import 'package:flutter/material.dart';

class FlowChoice {
  const FlowChoice(this.label, this.phrase);

  /// What the person taps.
  final String label;

  /// How the choice reads in the question sent to the server. Empty when it adds nothing.
  final String phrase;
}

class FlowStep {
  const FlowStep({required this.prompt, required this.choices});

  final String prompt;
  final List<FlowChoice> choices;
}

class SituationOption {
  const SituationOption({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.icon,
    required this.intro,
    required this.ask,
    required this.steps,
    this.letterType,
  });

  final String id;

  /// One or two words above the title, so the list can be scanned by topic.
  final String category;
  final String title;
  final String description;
  final IconData icon;

  /// Opens the question, before the tapped answers.
  final String intro;

  /// Closes the question.
  final String ask;
  final List<FlowStep> steps;

  /// The server letter type that fits this situation, if any (see server/src/prompts/letter.ts).
  final String? letterType;

  /// Builds the English question for /api/ask from the tapped answers and the optional note.
  String buildQuestion(Map<int, FlowChoice> answers, {String? noteEnglish}) {
    final parts = <String>[intro];
    for (var i = 0; i < steps.length; i++) {
      final phrase = answers[i]?.phrase ?? '';
      if (phrase.isNotEmpty) parts.add(phrase);
    }
    if (noteEnglish != null && noteEnglish.trim().isNotEmpty) {
      parts.add('In my own words: ${noteEnglish.trim()}');
    }
    parts.add(ask);
    return parts.join(' ');
  }
}

const List<SituationOption> situationOptions = [
  SituationOption(
    id: 'eviction',
    category: 'Housing',
    title: 'My landlord wants me out',
    description: 'Eviction notices, rent, deposits or locked doors.',
    icon: Icons.house_outlined,
    intro: 'I rent the house or room where I live.',
    ask: 'What does the law say about my rights as a tenant, and what should I do next?',
    letterType: 'landlord_reply',
    steps: [
      FlowStep(prompt: 'What is happening?', choices: [
        FlowChoice('I got a notice to leave', 'My landlord gave me a notice to leave.'),
        FlowChoice('Told to leave with no notice', 'My landlord told me to leave without giving me any notice.'),
        FlowChoice('Locked out or my things removed', 'My landlord locked me out or removed my things.'),
        FlowChoice('The rent was raised', 'My landlord wants to increase the rent.'),
        FlowChoice('Deposit not returned', 'My landlord will not return my security deposit.'),
      ]),
      FlowStep(prompt: 'How do you pay rent?', choices: [
        FlowChoice('Every week', 'I pay rent every week.'),
        FlowChoice('Every month', 'I pay rent every month.'),
        FlowChoice('Every year', 'I pay rent every year.'),
        FlowChoice('Not sure', ''),
      ]),
      FlowStep(prompt: 'How much time were you given?', choices: [
        FlowChoice('Less than 7 days', 'I was given less than 7 days.'),
        FlowChoice('About 2 weeks', 'I was given about two weeks.'),
        FlowChoice('A month or more', 'I was given a month or more.'),
        FlowChoice('No time was given', 'I was not given any time.'),
      ]),
      FlowStep(prompt: 'Is the rent fully paid?', choices: [
        FlowChoice('Yes, all paid', 'My rent is fully paid.'),
        FlowChoice('I owe some rent', 'I owe some rent.'),
        FlowChoice('Not sure', ''),
      ]),
    ],
  ),
  SituationOption(
    id: 'work',
    category: 'Work',
    title: 'Problem at work',
    description: 'Unpaid wages, dismissal, contracts or unfair treatment.',
    icon: Icons.work_outline,
    intro: 'I have a problem at work.',
    ask: 'What does the law say about my rights as a worker, and what should I do next?',
    letterType: 'employer_complaint',
    steps: [
      FlowStep(prompt: 'What happened?', choices: [
        FlowChoice('I was not paid', 'My employer has not paid my wages.'),
        FlowChoice('I was dismissed', 'My employer dismissed me.'),
        FlowChoice('Problem with my contract', 'I have a problem with my employment contract.'),
        FlowChoice('Harassment or unfair treatment', 'I am being harassed or treated unfairly at work.'),
      ]),
      FlowStep(prompt: 'Was it in writing?', choices: [
        FlowChoice('Yes, I have a letter', 'I received it in writing.'),
        FlowChoice('No, only spoken', 'It was only spoken, nothing in writing.'),
        FlowChoice('Not sure', ''),
      ]),
      FlowStep(prompt: 'How long have you worked there?', choices: [
        FlowChoice('Less than 6 months', 'I have worked there for less than six months.'),
        FlowChoice('6 months to 5 years', 'I have worked there for between six months and five years.'),
        FlowChoice('More than 5 years', 'I have worked there for more than five years.'),
      ]),
    ],
  ),
  SituationOption(
    id: 'land',
    category: 'Land',
    title: 'Land dispute',
    description: 'Boundaries, land purchases or being told to leave.',
    icon: Icons.landscape_outlined,
    intro: 'I have a land problem.',
    ask: 'What does the law say about my rights to this land, and what should I do next?',
    steps: [
      FlowStep(prompt: 'What is the problem?', choices: [
        FlowChoice('Someone says the land is theirs', 'Someone is claiming the land I use is theirs.'),
        FlowChoice('Told to leave land I live on', 'I am being told to leave land I live on.'),
        FlowChoice('Boundary disagreement', 'There is a disagreement about the boundary with a neighbour.'),
        FlowChoice('Buying or selling land', 'I have a problem with buying or selling land.'),
      ]),
      FlowStep(prompt: 'How long have you used the land?', choices: [
        FlowChoice('A few years', 'I have used the land for a few years.'),
        FlowChoice('More than 10 years', 'I have used the land for more than ten years.'),
        FlowChoice('Since before 1995', 'I have used the land since before 1995.'),
        FlowChoice('Not sure', ''),
      ]),
      FlowStep(prompt: 'Do you have papers for the land?', choices: [
        FlowChoice('Title or agreement', 'I have a land title or a written agreement.'),
        FlowChoice('No papers', 'I have no papers for the land.'),
        FlowChoice('Not sure', ''),
      ]),
    ],
  ),
  SituationOption(
    id: 'government',
    category: 'Government information',
    title: 'I need information from government',
    description: 'Request public records or official documents.',
    icon: Icons.account_balance_outlined,
    intro: 'I want information from a government office.',
    ask: 'What does the law say about my right to this information, and how do I ask for it?',
    letterType: 'access_to_information',
    steps: [
      FlowStep(prompt: 'What do you need?', choices: [
        FlowChoice('A document or record', 'I need a document or record from them.'),
        FlowChoice('Information about a decision', 'I want to know how a decision was made.'),
        FlowChoice('Information about a project or money', 'I want information about a public project or how public money was spent.'),
      ]),
      FlowStep(prompt: 'Have you asked already?', choices: [
        FlowChoice('Not yet', 'I have not asked yet.'),
        FlowChoice('Yes, they refused', 'I asked and they refused.'),
        FlowChoice('Yes, no reply', 'I asked but they have not replied.'),
      ]),
    ],
  ),
  SituationOption(
    id: 'other',
    category: 'Other',
    title: 'Something else',
    description: 'Tell us in your own words.',
    icon: Icons.chat_bubble_outline,
    intro: '',
    ask: '',
    steps: [],
  ),
];

SituationOption? situationById(String? id) {
  for (final s in situationOptions) {
    if (s.id == id) return s;
  }
  return null;
}
