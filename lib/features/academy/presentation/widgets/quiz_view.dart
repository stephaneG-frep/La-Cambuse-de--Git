import 'package:flutter/material.dart';

import '../../../../app/theme/theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/progress_repository.dart';
import '../../domain/course.dart';

/// Quiz question par question avec correction expliquée immédiate.
class QuizView extends StatefulWidget {
  const QuizView({
    super.key,
    required this.questions,
    required this.onFinished,
    this.showScore = true,
    this.emptyMessage,
    this.header,
    this.resultFooter,
  });

  /// Affiché au-dessus de la première question (ex. condition de validation).
  final Widget? header;

  /// Affiché sous le résultat (ex. lien vers la leçon suivante).
  final Widget? resultFooter;

  final List<QuizQuestion> questions;

  /// Appelé une fois à la fin : identifiant de question → réponse juste ?
  final Future<void> Function(Map<String, bool> answers) onFinished;
  final bool showScore;
  final String? emptyMessage;

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> {
  int _index = 0;
  final _selected = <int>{};
  final _command = TextEditingController();
  bool _revealed = false;
  bool _lastCorrect = false;
  final _answers = <String, bool>{};
  bool _finished = false;

  @override
  void dispose() {
    _command.dispose();
    super.dispose();
  }

  QuizQuestion get _q => widget.questions[_index];

  bool get _canValidate => _q.kind == QuestionKind.command
      ? _command.text.trim().isNotEmpty
      : _selected.isNotEmpty;

  void _validate() {
    final ok = _q.kind == QuestionKind.command
        ? _q.isCorrectCommand(_command.text)
        : _q.isCorrectChoice(_selected);
    setState(() {
      _revealed = true;
      _lastCorrect = ok;
      _answers[_q.id] = ok;
    });
  }

  Future<void> _next() async {
    if (_index + 1 < widget.questions.length) {
      setState(() {
        _index++;
        _selected.clear();
        _command.clear();
        _revealed = false;
      });
      return;
    }
    await widget.onFinished(Map.of(_answers));
    if (mounted) setState(() => _finished = true);
  }

  void _restart() => setState(() {
        _index = 0;
        _selected.clear();
        _command.clear();
        _revealed = false;
        _answers.clear();
        _finished = false;
      });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final text = Theme.of(context).textTheme;

    if (widget.questions.isEmpty) {
      return Center(child: Text(widget.emptyMessage ?? ''));
    }

    if (_finished) {
      final correct = _answers.values.where((v) => v).length;
      final score = (correct * 100 / _answers.length).round();
      final passed = score >= ProgressRepository.passScore;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(CambuseSpacing.lg),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(passed ? Icons.emoji_events : Icons.sailing,
                size: 64, color: passed ? p.gold : p.copper),
            const SizedBox(height: CambuseSpacing.md),
            if (widget.showScore) ...[
              Text(l.quizResult(score), style: text.headlineSmall),
              Text('$correct / ${_answers.length}'),
              const SizedBox(height: CambuseSpacing.sm),
              Text(passed ? l.quizPassed : l.quizFailed, textAlign: TextAlign.center),
            ],
            const SizedBox(height: CambuseSpacing.lg),
            OutlinedButton.icon(
              onPressed: _restart,
              icon: const Icon(Icons.replay),
              label: Text(l.quizRetry),
            ),
            if (widget.resultFooter != null) ...[
              const SizedBox(height: CambuseSpacing.sm),
              widget.resultFooter!,
            ],
          ]),
        ),
      );
    }

    final q = _q;
    // Bouton d'action fixe en bas : toujours visible, même sur petit écran
    // quand la correction allonge le contenu.
    final action = _revealed
        ? FilledButton(
            onPressed: _next,
            child: Text(_index + 1 < widget.questions.length ? l.quizNext : l.quizFinish),
          )
        : FilledButton(
            onPressed: _canValidate ? _validate : null,
            child: Text(l.quizValidate),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(CambuseSpacing.md),
            children: [
              if (_index == 0 && !_revealed && widget.header != null) ...[
                widget.header!,
                const SizedBox(height: CambuseSpacing.sm),
              ],
              Text(l.quizQuestion(_index + 1, widget.questions.length),
                  style: TextStyle(color: p.textSecondary)),
              const SizedBox(height: CambuseSpacing.sm),
              Text(q.prompt, style: text.titleLarge),
              if (q.kind == QuestionKind.multiple)
                Text(l.quizMultipleHint, style: TextStyle(color: p.gold)),
              const SizedBox(height: CambuseSpacing.md),
              if (q.kind == QuestionKind.command)
                TextField(
                  controller: _command,
                  enabled: !_revealed,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: const TextStyle(fontFamily: 'monospace'),
                  decoration: InputDecoration(labelText: l.quizCommandHint, prefixText: '\$ '),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _canValidate && !_revealed ? _validate() : null,
                )
              else
                for (final (i, c) in q.choices.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: CambuseSpacing.sm),
                    child: _ChoiceTile(
                      label: c,
                      multiple: q.kind == QuestionKind.multiple,
                      selected: _selected.contains(i),
                      correct: _revealed ? q.answers.contains(i) : null,
                      onTap: _revealed
                          ? null
                          : () => setState(() {
                                if (q.kind == QuestionKind.single) _selected.clear();
                                if (!_selected.remove(i)) _selected.add(i);
                              }),
                    ),
                  ),
              if (_revealed) ...[
                const SizedBox(height: CambuseSpacing.md),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(CambuseSpacing.md),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(_lastCorrect ? Icons.check_circle : Icons.cancel,
                            color: _lastCorrect ? p.turquoise : p.alert),
                        const SizedBox(width: CambuseSpacing.sm),
                        Text(_lastCorrect ? l.quizCorrect : l.quizWrong,
                            style: text.titleMedium?.copyWith(
                                color: _lastCorrect ? p.turquoise : p.alert)),
                      ]),
                      if (!_lastCorrect && q.kind == QuestionKind.command) ...[
                        const SizedBox(height: CambuseSpacing.sm),
                        SelectableText(l.expectedAnswer(q.accepted.first),
                            style: TextStyle(fontFamily: 'monospace', color: p.turquoise)),
                      ],
                      const SizedBox(height: CambuseSpacing.sm),
                      Text(q.explanation, style: const TextStyle(height: 1.4)),
                    ]),
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              CambuseSpacing.md, 0, CambuseSpacing.md, CambuseSpacing.md),
          child: action,
        ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.multiple,
    required this.selected,
    required this.correct,
    required this.onTap,
  });

  final String label;
  final bool multiple;
  final bool selected;

  /// null tant que la correction n'est pas affichée.
  final bool? correct;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = CambuseTheme.of(context);
    final border = correct == null
        ? (selected ? p.turquoise : p.textSecondary)
        : (correct! ? p.turquoise : (selected ? p.alert : p.textSecondary));
    final IconData icon;
    if (correct != null) {
      icon = correct! ? Icons.check : (selected ? Icons.close : (multiple ? Icons.check_box_outline_blank : Icons.radio_button_unchecked));
    } else if (multiple) {
      icon = selected ? Icons.check_box : Icons.check_box_outline_blank;
    } else {
      icon = selected ? Icons.radio_button_checked : Icons.radio_button_unchecked;
    }
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CambuseSpacing.radius / 2),
          side: BorderSide(color: border, width: selected || correct == true ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(CambuseSpacing.radius / 2),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: CambuseSpacing.minTouchTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: CambuseSpacing.md, vertical: CambuseSpacing.sm),
              child: Row(children: [
                Icon(icon, color: border),
                const SizedBox(width: CambuseSpacing.md),
                Expanded(child: Text(label)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
