import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/situations.dart';
import '../models/results.dart';
import '../services/api_client.dart';
import '../services/app_state.dart';
import '../widgets/citation_card.dart';
import '../widgets/community_voice_card.dart';
import '../widgets/disclaimer_footer.dart';
import '../widgets/layout.dart';
import '../widgets/loading_panel.dart';
import '../widgets/message_composer.dart';
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
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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
    final expanded = windowClassOf(context) == WindowClass.expanded;
    final letterType = _letterType();
    return Scaffold(
      appBar: AppBar(title: Text(context.tr(widget.isScan ? 'Your document' : 'Your answer'))),
      // Once there is an answer, the follow-up message bar stays at the bottom, like a chat. It is part of
      // the body (not the bottom bar slot) so it moves up with the keyboard.
      body: Column(
        children: [
          Expanded(
            child: PageBody(
              controller: _scroll,
              maxWidth: expanded ? 1200 : kMaxContentWidth,
              children: [
                for (final turn in _turns) _TurnView(turn: turn, twoPane: expanded),
                if (busy)
                  LoadingPanel(
                    messages: widget.isScan && _turns.isEmpty
                        ? const [
                            'Reading your document...',
                            'Checking the law...',
                            'Linking problems to the law...',
                            'Almost done...',
                          ]
                        : const [
                            'Understanding your question...',
                            'Checking the law...',
                            'Writing a simple answer...',
                            'Almost done...',
                          ],
                  ),
                if (_error != null) ErrorPanel(message: _error!, onRetry: () => _run(_pending!)),
                if (_turns.isNotEmpty && !busy) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (letterType != null)
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.edit_document),
                          label: Text(context.tr('Write a letter')),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LetterEditorScreen(
                                letterType: letterType,
                                facts: _turns.map((t) => t.englishQuestion).join('\n'),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: kGap),
                  GetHelpCard(situationId: widget.situationId, summary: _turns.first.englishQuestion),
                  const SizedBox(height: kGap),
                  CommunityVoiceCard(situationId: widget.situationId),
                ],
                const DisclaimerFooter(),
              ],
            ),
          ),
          if (_turns.isNotEmpty && !busy)
            MessageComposer(
              controller: _followUp,
              hintText: 'Ask a follow-up, e.g. What if I already paid?',
              sendTooltip: 'Ask follow-up',
              onSend: _askFollowUp,
              onTranscribed: (text) => _heard = text,
            ),
        ],
      ),
    );
  }
}

class _TurnView extends StatelessWidget {
  const _TurnView({required this.turn, required this.twoPane});

  final Turn turn;
  final bool twoPane;

  @override
  Widget build(BuildContext context) {
    final answer = _answerColumn(context);
    final law = _lawColumn(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _questionBubble(context),
          if (twoPane && law.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: answer),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: law),
                ),
              ],
            )
          else ...[
            ...answer,
            ...law,
          ],
          const DisclaimerFooter(),
          const Divider(),
        ],
      ),
    );
  }

  Widget _questionBubble(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final question = turn.question.isNotEmpty ? turn.question : (turn.scan?.question ?? '');
    if (question.isEmpty) return const SizedBox.shrink();
    final heard = turn.heard ?? turn.scan?.transcribedQuestion;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: const EdgeInsetsDirectional.only(start: 48, bottom: 16, top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (heard != null)
              Text(
                context.tr('We heard:'),
                style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSecondaryContainer),
              ),
            Text(question, style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSecondaryContainer)),
          ],
        ),
      ),
    );
  }

  List<Widget> _answerColumn(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ask = turn.ask;
    final scan = turn.scan;
    return [
      Card.filled(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (scan != null) ...[
                Text(scan.documentType, style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(scan.summary, style: theme.textTheme.bodyLarge),
                if (scan.questionAnswer != null) ...[
                  const Divider(height: 32),
                  Text(context.tr('Your question'), style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(scan.questionAnswer!, style: theme.textTheme.bodyLarge),
                ],
              ],
              if (ask != null) Text(ask.answer, style: theme.textTheme.bodyLarge),
              if (ask != null && ask.confidence == 'low') ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(child: Icon(Icons.info_outline, size: 20, color: scheme.tertiary)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr('Our laws may not fully cover this. Please also talk to a legal aid clinic.'),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              PlayAnswerButton(text: turn.spokenText),
            ],
          ),
        ),
      ),
      if (scan != null && scan.redFlags.isNotEmpty) ...[
        SectionTitle(context.tr('Red flags')),
        for (var i = 0; i < scan.redFlags.length; i++)
          RedFlagTile(text: scan.redFlags[i], sections: scan.sectionsForFlag(i)),
      ],
      if (scan != null && scan.missingItems.isNotEmpty) ...[
        SectionTitle(context.tr('What is missing')),
        Card.outlined(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [for (final item in scan.missingItems) MissingItemTile(text: item)]),
          ),
        ),
      ],
      if (ask != null && ask.nextSteps.isNotEmpty) ...[
        SectionTitle(context.tr('What you can do next')),
        Card.outlined(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, step) in ask.nextSteps.indexed)
                ListTile(
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                    child: Text('${i + 1}', style: theme.textTheme.labelLarge),
                  ),
                  title: Text(step),
                ),
            ],
          ),
        ),
      ],
    ];
  }

  List<Widget> _lawColumn(BuildContext context) {
    if (turn.citations.isEmpty) return const [];
    return [
      if (!twoPane) SectionTitle(context.tr('The law')) else _paneTitle(context, context.tr('The law')),
      for (final c in turn.citations)
        CitationCard(citation: c, explanation: c is RelatedSection ? c.explanation : null),
    ];
  }

  Widget _paneTitle(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Semantics(header: true, child: Text(text, style: Theme.of(context).textTheme.titleMedium)),
  );
}
