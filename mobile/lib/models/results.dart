// Typed views of the API responses (shapes from server/src/routes/ask.ts and analyze.ts).

List<String> _strings(Object? v) => (v as List? ?? const []).map((e) => e.toString()).toList();
String? _string(Object? v) => v?.toString();

class Citation {
  const Citation({required this.lawName, required this.sectionNumber, required this.excerpt});

  factory Citation.fromJson(Map<String, dynamic> j) => Citation(
        lawName: j['law_name']?.toString() ?? '',
        sectionNumber: j['section_number']?.toString() ?? '',
        excerpt: j['excerpt']?.toString() ?? '',
      );

  final String lawName;
  final String sectionNumber;
  final String excerpt;

  /// The Constitution is divided into articles, the Acts into sections (as on the server).
  String get unit => lawName.startsWith('Constitution') ? 'Article' : 'Section';

  Map<String, dynamic> toJson() => {'law_name': lawName, 'section_number': sectionNumber, 'excerpt': excerpt};
}

class AskResult {
  const AskResult({
    required this.answer,
    required this.answerEn,
    required this.nextSteps,
    required this.nextStepsEn,
    required this.citations,
    required this.confidence,
    this.questionEn,
  });

  factory AskResult.fromJson(Map<String, dynamic> j) => AskResult(
        answer: j['answer']?.toString() ?? '',
        answerEn: j['answer_en']?.toString() ?? j['answer']?.toString() ?? '',
        nextSteps: _strings(j['next_steps']),
        nextStepsEn: _strings(j['next_steps_en']),
        citations: (j['citations'] as List? ?? const [])
            .map((c) => Citation.fromJson(Map<String, dynamic>.from(c as Map)))
            .toList(),
        confidence: j['confidence']?.toString() ?? 'low',
        questionEn: _string(j['question_en']),
      );

  final String answer;
  final String answerEn;
  final List<String> nextSteps;
  final List<String> nextStepsEn;
  final List<Citation> citations;
  final String confidence;
  final String? questionEn;
}

class RelatedSection extends Citation {
  const RelatedSection({
    required super.lawName,
    required super.sectionNumber,
    required super.excerpt,
    required this.redFlagsEn,
    required this.explanation,
  });

  factory RelatedSection.fromJson(Map<String, dynamic> j) => RelatedSection(
        lawName: j['law_name']?.toString() ?? '',
        sectionNumber: j['section_number']?.toString() ?? '',
        excerpt: j['excerpt']?.toString() ?? '',
        redFlagsEn: _strings(j['red_flags']),
        explanation: j['explanation']?.toString() ?? '',
      );

  /// The red flags (in English, as the server matched them) this section relates to.
  final List<String> redFlagsEn;
  final String explanation;
}

class AnalyzeResult {
  const AnalyzeResult({
    required this.documentType,
    required this.transcription,
    required this.summary,
    required this.summaryEn,
    required this.redFlags,
    required this.redFlagsEn,
    required this.missingItems,
    required this.relatedSections,
    this.question,
    this.transcribedQuestion,
    this.questionEn,
    this.questionAnswer,
    this.questionAnswerEn,
  });

  factory AnalyzeResult.fromJson(Map<String, dynamic> j) => AnalyzeResult(
        documentType: j['document_type']?.toString() ?? 'Document',
        transcription: j['transcription']?.toString() ?? '',
        summary: j['summary']?.toString() ?? '',
        summaryEn: j['summary_en']?.toString() ?? j['summary']?.toString() ?? '',
        redFlags: _strings(j['red_flags']),
        redFlagsEn: _strings(j['red_flags_en'] ?? j['red_flags']),
        missingItems: _strings(j['missing_items']),
        relatedSections: (j['related_sections'] as List? ?? const [])
            .map((c) => RelatedSection.fromJson(Map<String, dynamic>.from(c as Map)))
            .toList(),
        question: _string(j['question']),
        transcribedQuestion: _string(j['transcribed_question']),
        questionEn: _string(j['question_en']),
        questionAnswer: _string(j['question_answer']),
        questionAnswerEn: _string(j['question_answer_en']),
      );

  final String documentType;
  final String transcription;
  final String summary;
  final String summaryEn;
  final List<String> redFlags;
  final List<String> redFlagsEn;
  final List<String> missingItems;
  final List<RelatedSection> relatedSections;
  final String? question;
  final String? transcribedQuestion;
  final String? questionEn;
  final String? questionAnswer;
  final String? questionAnswerEn;

  /// Sections linked to the red flag at [index] (red flags come back in the same order in both languages).
  List<RelatedSection> sectionsForFlag(int index) {
    if (index >= redFlagsEn.length) return const [];
    final flag = redFlagsEn[index];
    return relatedSections.where((s) => s.redFlagsEn.contains(flag)).toList();
  }
}

/// One exchange in a conversation: a question and either an answer or a document reading.
class Turn {
  Turn.ask({required this.question, required AskResult this.ask, this.heard, this.questionEn}) : scan = null;
  Turn.scan({required this.question, required AnalyzeResult this.scan, this.heard}) : ask = null, questionEn = null;

  /// What the person asked, in their language (may be empty for a scan with no question).
  final String question;

  /// What we heard, when the question was spoken.
  final String? heard;

  /// The English question, when the app wrote it (guided flows); otherwise the server's translation is used.
  final String? questionEn;
  final AskResult? ask;
  final AnalyzeResult? scan;

  /// The text to read aloud.
  String get spokenText => ask?.answer ?? [scan!.summary, if (scan!.questionAnswer != null) scan!.questionAnswer!].join(' ');

  /// The English version sent back to the server as `history` for a follow-up question.
  Map<String, String> toHistory() {
    if (ask != null) {
      return {'question': _clip(questionEn ?? ask!.questionEn ?? question, 2000), 'answer': _clip(ask!.answerEn, 4000)};
    }
    final s = scan!;
    final asked = s.questionEn ?? 'What does this document mean for me?';
    final answer = [
      'Document: ${s.documentType}. ${s.summaryEn}',
      if (s.redFlagsEn.isNotEmpty) 'Red flags: ${s.redFlagsEn.join('; ')}.',
      if (s.questionAnswerEn != null) s.questionAnswerEn!,
    ].join(' ');
    return {'question': _clip('I scanned a document. $asked', 2000), 'answer': _clip(answer, 4000)};
  }

  List<Citation> get citations => ask?.citations ?? scan!.relatedSections;

  /// The question in English, for prefilling a letter.
  String get englishQuestion => questionEn ?? ask?.questionEn ?? scan?.questionEn ?? question;
}

String _clip(String s, int max) => s.length <= max ? s : s.substring(0, max);
