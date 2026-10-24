import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/situations.dart';
import '../models/results.dart';
import '../services/api_client.dart';
import '../services/app_state.dart';
import '../widgets/citation_card.dart';
import '../widgets/community_voice_card.dart';
import '../widgets/disclaimer_footer.dart';
import '../widgets/loading_panel.dart';
import '../widgets/mic_button.dart';
import '../widgets/play_answer_button.dart';
import '../widgets/red_flag_tile.dart';
import '../widgets/tr.dart';
import 'get_help_screen.dart';
import 'letter_editor_screen.dart';

/// One conversation, shared by Ask, Scan and the guided flows: the first answer, then any follow-up
/// questions, which send the earlier turns as history so the server keeps the context.
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.firstRequest, this.situationId, this.isScan = false});

  final Future<Turn> Function() firstRequest;
  final String? situationId;
  final bool isScan;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final List<Turn> _turns = [];
  final _followUp = TextEditingController();
  final _scroll = ScrollController();
  Future<Turn> Function()? _pending;
  String? _error;
  String? _heard;

  @override
  void initState() {
    super.initState();
    _run(widget.firstRequest);
  }

  @override
  void dispose() {
    _followUp.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _run(Future<Turn> Function() request) async {
    setState(() {
      _pending = request;
      _error = null;
    });
    try {
      final turn = await request();
      if (!mounted) return;
      setState(() {
        _turns.add(turn);
        _pending = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      debugPrint('Request failed: $e');
      if (mounted) setState(() => _error = 'Something went wrong. Please try again.');
    }
  }

  void _askFollowUp() {
    final app = context.read<AppState>();
    final question = _followUp.text.trim();
    if (question.length < 3) return;
    final history = _turns.map((t) => t.toHistory()).toList();
    final heard = _heard == question ? _heard : null;
    _followUp.clear();
    _heard = null;
    FocusScope.of(context).unfocus();
    _run(() async {
      final result = await app.api.ask(question, language: app.language.code, history: history);
      return Turn.ask(question: question, ask: result, heard: heard);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  /// The letter type that fits: from the situation, or from the laws the answers cite.
  String? _letterType() {
    final fromSituation = situationById(widget.situationId)?.letterType;
    if (fromSituation != null) return fromSituation;
    final laws = _turns.expand((t) => t.citations).map((c) => c.lawName).join(' ');
    if (laws.contains('Landlord and Tenant')) return 'landlord_reply';
    if (laws.contains('Employment')) return 'employer_complaint';
    if (laws.contains('Access to Information')) return 'access_to_information';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final busy = _pending != null && _error == null;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr(widget.isScan ? 'Your document' : 'Your answer'))),
      body: SafeArea(
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.all(18),
          children: [
            for (final turn in _turns) _TurnView(turn: turn),
            if (busy)
              LoadingPanel(
                messages: widget.isScan && _turns.isEmpty
                    ? const ['Reading your document...', 'Checking the law...', 'Linking problems to the law...', 'Almost done...']
                    : const ['Understanding your question...', 'Checking the law...', 'Writing a simple answer...', 'Almost done...'],
              ),
            if (_error != null) ErrorPanel(message: _error!, onRetry: () => _run(_pending!)),
            if (_turns.isNotEmpty && !busy) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (_letterType() != null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_document),
                        label: Text(context.tr('Write a letter')),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LetterEditorScreen(
                              letterType: _letterType(),
                              facts: _turns.map((t) => t.englishQuestion).join('\n'),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.support_agent),
                      label: Text(context.tr('Get help')),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GetHelpScreen(
                            situationId: widget.situationId,
                            summary: _turns.first.englishQuestion,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GetHelpCard(situationId: widget.situationId, summary: _turns.first.englishQuestion),
              const SizedBox(height: 16),
              CommunityVoiceCard(situationId: widget.situationId),
              const SizedBox(height: 16),
              Text(context.tr('Ask a follow-up question'), style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _followUp,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _askFollowUp(),
                decoration: InputDecoration(
                  hintText: context.tr('For example: What if I already paid this month?'),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: _askFollowUp),
                ),
              ),
              const SizedBox(height: 8),
              MicButton(
                onText: (text) => setState(() {
                  _heard = text;
                  _followUp.text = text;
                }),
              ),
            ],
            const SizedBox(height: 16),
            const DisclaimerFooter(),
          ],
        ),
      ),
    );
  }
}

class _TurnView extends StatelessWidget {
  const _TurnView({required this.turn});

  final Turn turn;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    final ask = turn.ask;
    final scan = turn.scan;
    final scanQuestion = scan?.question;
    final question = turn.question.isNotEmpty ? turn.question : (scanQuestion ?? '');
    final heard = turn.heard ?? scan?.transcribedQuestion;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (question.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.only(left: 40, bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (heard != null)
                      Text(context.tr('We heard:'), style: const TextStyle(fontSize: 14, color: Colors.black54)),
                    Text(question, style: const TextStyle(fontSize: 15)),
                  ],
                ),
              ),
            ),
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (scan != null) ...[
                    Text(scan.documentType, style: titleStyle),
                    const SizedBox(height: 8),
                    Text(scan.summary, style: const TextStyle(fontSize: 16, height: 1.4)),
                    if (scan.questionAnswer != null) ...[
                      const Divider(height: 24),
                      Text(context.tr('Your question'), style: titleStyle),
                      const SizedBox(height: 6),
                      Text(scan.questionAnswer!, style: const TextStyle(fontSize: 16, height: 1.4)),
                    ],
                  ],
                  if (ask != null) Text(ask.answer, style: const TextStyle(fontSize: 16, height: 1.4)),
                  if (ask != null && ask.confidence == 'low')
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        context.tr('Our laws may not fully cover this. Please also talk to a legal aid clinic.'),
                        style: const TextStyle(fontSize: 14, color: Color(0xFF8D6E00), fontWeight: FontWeight.w600),
                      ),
                    ),
                  const SizedBox(height: 12),
                  PlayAnswerButton(text: turn.spokenText),
                ],
              ),
            ),
          ),
          if (scan != null && scan.redFlags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(context.tr('Red flags'), style: titleStyle),
            const SizedBox(height: 8),
            for (var i = 0; i < scan.redFlags.length; i++)
              RedFlagTile(text: scan.redFlags[i], sections: scan.sectionsForFlag(i)),
          ],
          if (scan != null && scan.missingItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(context.tr('What is missing'), style: titleStyle),
            const SizedBox(height: 4),
            for (final item in scan.missingItems)
              ListTile(
                contentPadding: EdgeInsets.zero,
                minTileHeight: 40,
                leading: const Icon(Icons.help_outline, color: Color(0xFF8D6E00)),
                title: Text(item, style: const TextStyle(fontSize: 15)),
              ),
          ],
          if (turn.citations.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(context.tr('The law'), style: titleStyle),
            const SizedBox(height: 8),
            for (final c in turn.citations)
              CitationCard(citation: c, explanation: c is RelatedSection ? c.explanation : null),
          ],
          if (ask != null && ask.nextSteps.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(context.tr('What you can do next'), style: titleStyle),
            const SizedBox(height: 4),
            for (final (i, step) in ask.nextSteps.indexed)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(radius: 14, child: Text('${i + 1}', style: const TextStyle(fontSize: 14))),
                title: Text(step, style: const TextStyle(fontSize: 15)),
              ),
          ],
          const SizedBox(height: 8),
          const DisclaimerFooter(),
        ],
      ),
    );
  }
}
