class LanguageOption {
  const LanguageOption({
    required this.code,
    required this.name,
    required this.flag,
    required this.canTranslate,
    required this.canSpeak,
    required this.canListen,
  });

  final String code;
  final String name;
  final String flag;
  final bool canTranslate;
  final bool canSpeak;
  final bool canListen;
}

const List<LanguageOption> languageOptions = [
  LanguageOption(
    code: 'lg',
    name: 'Luganda',
    flag: '🇺🇬',
    canTranslate: true,
    canSpeak: true,
    canListen: true,
  ),
  LanguageOption(
    code: 'en',
    name: 'English',
    flag: '🇬🇧',
    canTranslate: true,
    canSpeak: true,
    canListen: true,
  ),
  LanguageOption(
    code: 'nyn',
    name: 'Runyankole',
    flag: '🇺🇬',
    canTranslate: true,
    canSpeak: true,
    canListen: true,
  ),
];

LanguageOption languageForCode(String code) {
  return languageOptions.firstWhere(
    (language) => language.code == code,
    orElse: () => languageOptions.first,
  );
}
