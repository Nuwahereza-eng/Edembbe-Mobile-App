class FlowStep {
  const FlowStep({
    required this.prompt,
    required this.choices,
  });

  final String prompt;
  final List<String> choices;
}

class SituationOption {
  const SituationOption({
    required this.id,
    required this.title,
    required this.description,
    required this.steps,
  });

  final String id;
  final String title;
  final String description;
  final List<FlowStep> steps;
}

const List<SituationOption> situationOptions = [
  SituationOption(
    id: 'eviction',
    title: 'My landlord wants me out',
    description: 'Get help with eviction, notice periods and rent questions.',
    steps: [
      FlowStep(
        prompt: 'What is the issue?',
        choices: ['Notice to leave', 'Rent dispute', 'Illegal eviction', 'Other'],
      ),
      FlowStep(
        prompt: 'How soon do you need to reply?',
        choices: ['Today', 'This week', 'I need time to prepare', 'Not sure'],
      ),
      FlowStep(
        prompt: 'Do you have a written notice or document?',
        choices: ['Yes', 'No', 'I am not sure'],
      ),
    ],
  ),
  SituationOption(
    id: 'work',
    title: 'Problem at work',
    description: 'Questions about pay, dismissal, contracts and unfair treatment.',
    steps: [
      FlowStep(
        prompt: 'What happened at work?',
        choices: ['Pay withheld', 'Dismissal', 'Unsafe work', 'Contract issue'],
      ),
      FlowStep(
        prompt: 'How urgent is it?',
        choices: ['Immediate', 'This month', 'I can wait', 'Not sure'],
      ),
    ],
  ),
  SituationOption(
    id: 'land',
    title: 'Land dispute',
    description: 'Property boundaries, ownership and land rights questions.',
    steps: [
      FlowStep(
        prompt: 'What kind of land issue do you have?',
        choices: ['Boundary dispute', 'Sale agreement', 'Occupation', 'Other'],
      ),
      FlowStep(
        prompt: 'Do you have documents?',
        choices: ['Yes', 'No', 'I am not sure'],
      ),
    ],
  ),
  SituationOption(
    id: 'government',
    title: 'I need information from government',
    description: 'Access to information requests and public records questions.',
    steps: [
      FlowStep(
        prompt: 'What do you need the government to share?',
        choices: ['A document', 'A record', 'A decision', 'Not sure'],
      ),
      FlowStep(
        prompt: 'Have you already asked for it?',
        choices: ['Yes', 'No', 'I am not sure'],
      ),
    ],
  ),
  SituationOption(
    id: 'other',
    title: 'Something else',
    description: 'Let the legal assistant check the law and guide you to support.',
    steps: [
      FlowStep(
        prompt: 'What do you need help with?',
        choices: ['Family matter', 'Police issue', 'School issue', 'Other'],
      ),
    ],
  ),
];
