// Languages Eddembe offers, from Sunbird AI's language list (https://docs.sunbird.ai/languages,
// checked October 2026). The server keeps the same lists in server/src/services/languages.ts.
//
// canTranslate: questions and answers can be translated (every language here).
// canSpeak: the person can speak a question (Sunbird speech-to-text). Hides the mic when false.
// canListen: answers can be read aloud (Sunbird text-to-speech with a Ugandan voice). Hides play when false.
class LanguageOption {
  const LanguageOption({
    required this.code,
    required this.name,
    this.canTranslate = true,
    this.canSpeak = false,
    this.canListen = false,
  });

  /// Sunbird (ISO 639-3) code, sent to the API as `language`.
  final String code;
  final String name;
  final bool canTranslate;
  final bool canSpeak;
  final bool canListen;

  bool get isEnglish => code == 'eng';
}

const String voiceInputUnavailable = 'Voice input is not yet available in this language. Please type.';

const List<LanguageOption> languageOptions = [
  // The most used first, then the rest in alphabetical order.
  LanguageOption(code: 'eng', name: 'English', canSpeak: true),
  LanguageOption(code: 'lug', name: 'Luganda', canSpeak: true, canListen: true),
  LanguageOption(code: 'nyn', name: 'Runyankole', canSpeak: true, canListen: true),
  LanguageOption(code: 'ach', name: 'Acholi', canSpeak: true, canListen: true),
  LanguageOption(code: 'teo', name: 'Ateso', canSpeak: true, canListen: true),
  LanguageOption(code: 'swa', name: 'Swahili', canSpeak: true),
  LanguageOption(code: 'alz', name: 'Alur'),
  LanguageOption(code: 'luc', name: 'Aringa'),
  LanguageOption(code: 'ikx', name: 'Ik'),
  LanguageOption(code: 'adh', name: 'Jopadhola'),
  LanguageOption(code: 'keo', name: 'Kakwa'),
  LanguageOption(code: 'kdj', name: 'Karamojong'),
  LanguageOption(code: 'kdi', name: 'Kumam'),
  LanguageOption(code: 'kpz', name: 'Kupsabiny'),
  LanguageOption(code: 'rwm', name: 'Kwamba', canSpeak: true),
  LanguageOption(code: 'laj', name: 'Lango'),
  LanguageOption(code: 'tlj', name: 'Lubwisi'),
  // Lugbara is listed for text-to-speech but has no voices yet, so canListen stays false.
  LanguageOption(code: 'lgg', name: 'Lugbara', canSpeak: true),
  LanguageOption(code: 'rub', name: 'Lugungu'),
  LanguageOption(code: 'gwr', name: 'Lugwere'),
  LanguageOption(code: 'myx', name: 'Lumasaba', canSpeak: true),
  LanguageOption(code: 'nuj', name: 'Lunyole'),
  LanguageOption(code: 'xog', name: 'Lusoga', canSpeak: true),
  LanguageOption(code: 'mhi', name: "Ma'di"),
  LanguageOption(code: 'pok', name: 'Pokot'),
  LanguageOption(code: 'cgg', name: 'Rukiga', canSpeak: true),
  LanguageOption(code: 'koo', name: 'Rukonjo', canSpeak: true),
  LanguageOption(code: 'nyo', name: 'Runyoro'),
  LanguageOption(code: 'ruc', name: 'Ruruuli', canSpeak: true),
  LanguageOption(code: 'ttj', name: 'Rutooro', canSpeak: true),
  LanguageOption(code: 'lsm', name: 'Samia'),
];

/// Older builds saved the web app's codes ("en", "lg").
const Map<String, String> _legacyCodes = {'en': 'eng', 'lg': 'lug'};

LanguageOption? findLanguage(String? code) {
  if (code == null) return null;
  final normalised = _legacyCodes[code] ?? code;
  for (final language in languageOptions) {
    if (language.code == normalised) return language;
  }
  return null;
}

LanguageOption languageForCode(String code) => findLanguage(code) ?? languageOptions.first;
