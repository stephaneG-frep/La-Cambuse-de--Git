import 'package:flutter/material.dart';

import '../../../../app/theme/theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/course.dart';
import '../../domain/goals.dart';

enum _LineKind { command, output, error, info }

/// Salle des machines : console du bac à sable et étapes guidées.
class ExerciseView extends StatefulWidget {
  const ExerciseView({
    super.key,
    required this.exercise,
    required this.onCompleted,
    this.alreadyDone = false,
  });

  final Exercise exercise;
  final VoidCallback onCompleted;
  final bool alreadyDone;

  @override
  State<ExerciseView> createState() => _ExerciseViewState();
}

class _ExerciseViewState extends State<ExerciseView> {
  late ExerciseSession _session;
  final _lines = <(_LineKind, String)>[];
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  bool _hint = false;
  bool _solution = false;
  bool _notified = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _session = ExerciseSession(widget.exercise);
    _lines
      ..clear()
      ..add((_LineKind.info, widget.exercise.intro));
    _hint = false;
    _solution = false;
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _submit() {
    final cmd = _input.text;
    if (cmd.trim().isEmpty) return;
    final before = _session.completedSteps;
    final r = _session.submit(cmd);
    setState(() {
      if (r.clearScreen || cmd.trim() == 'clear') {
        _lines.clear();
      } else {
        _lines.add((_LineKind.command, '\$ ${cmd.trim()}'));
        if (r.output.isNotEmpty) {
          _lines.add((r.ok ? _LineKind.output : _LineKind.error, r.output));
        }
      }
      if (_session.completedSteps > before) {
        _hint = false;
        _solution = false;
      }
    });
    _input.clear();
    _focus.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
    if (_session.isComplete && !_notified) {
      _notified = true;
      widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final steps = widget.exercise.steps;
    final current = _session.currentStep;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    final stepsPanel = ListView(
      padding: const EdgeInsets.all(CambuseSpacing.md),
      children: [
        Row(children: [
          Icon(Icons.shield_outlined, color: p.turquoise, size: 18),
          const SizedBox(width: CambuseSpacing.xs),
          Expanded(child: Text(l.sandboxBanner, style: TextStyle(color: p.textSecondary))),
        ]),
        const SizedBox(height: CambuseSpacing.sm),
        if (_session.isComplete || widget.alreadyDone)
          Card(
            child: ListTile(
              leading: Icon(Icons.smart_toy, color: p.gold),
              title: Text(l.exerciseDone),
            ),
          ),
        if (!_session.isComplete)
          Text(l.exerciseStep(_session.completedSteps + 1, steps.length),
              style: Theme.of(context).textTheme.titleSmall),
        for (final (i, s) in steps.indexed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              i < _session.completedSteps
                  ? Icons.check_circle
                  : (identical(s, current) ? Icons.play_circle : Icons.circle_outlined),
              color: i < _session.completedSteps
                  ? p.turquoise
                  : (identical(s, current) ? p.gold : p.textSecondary),
            ),
            title: Text(s.instruction,
                style: TextStyle(
                    color: identical(s, current) || i < _session.completedSteps
                        ? p.text
                        : p.textSecondary)),
          ),
        if (current != null)
          Wrap(spacing: CambuseSpacing.sm, children: [
            TextButton.icon(
              onPressed: () => setState(() => _hint = !_hint),
              icon: const Icon(Icons.lightbulb_outline),
              label: Text(l.sandboxHint),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _solution = !_solution),
              icon: const Icon(Icons.visibility_outlined),
              label: Text(l.sandboxSolution),
            ),
          ]),
        if (current != null && _hint) Text('💡 ${current.hint}'),
        if (current != null && _solution)
          SelectableText(
            current.solution.join('\n'),
            style: TextStyle(fontFamily: 'monospace', color: p.turquoise),
          ),
      ],
    );

    final console = Container(
      margin: const EdgeInsets.all(CambuseSpacing.sm),
      decoration: BoxDecoration(
        color: p.night,
        borderRadius: BorderRadius.circular(CambuseSpacing.radius / 2),
        border: Border.all(color: p.copper, width: p.borderWidth),
      ),
      child: Column(
        children: [
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(CambuseSpacing.sm),
                itemCount: _lines.length,
                itemBuilder: (_, i) {
                  final (kind, txt) = _lines[i];
                  return SelectableText(
                    txt,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      height: 1.3,
                      color: switch (kind) {
                        _LineKind.command => p.gold,
                        _LineKind.output => p.text,
                        _LineKind.error => p.alert,
                        _LineKind.info => p.textSecondary,
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1),
          Row(children: [
            const SizedBox(width: CambuseSpacing.sm),
            Text('\$', style: TextStyle(fontFamily: 'monospace', color: p.gold)),
            const SizedBox(width: CambuseSpacing.sm),
            Expanded(
              child: TextField(
                controller: _input,
                focusNode: _focus,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.send,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: l.sandboxInputHint,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            IconButton(
              tooltip: l.sandboxRun,
              icon: Icon(Icons.keyboard_return, color: p.turquoise),
              onPressed: _submit,
            ),
            IconButton(
              tooltip: l.sandboxReset,
              icon: Icon(Icons.restart_alt, color: p.textSecondary),
              onPressed: () => setState(() {
                _reset();
                _notified = false;
              }),
            ),
          ]),
        ],
      ),
    );

    if (wide) {
      return Row(children: [
        SizedBox(width: 380, child: stepsPanel),
        const VerticalDivider(width: 1),
        Expanded(child: console),
      ]);
    }
    return Column(children: [
      Expanded(flex: 4, child: stepsPanel),
      Expanded(flex: 5, child: console),
    ]);
  }
}
