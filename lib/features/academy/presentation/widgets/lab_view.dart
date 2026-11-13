import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/course.dart';
import '../../domain/lab_eval.dart';

/// Labo fichier : éditeur, analyse statique, objectifs. Hors ligne et sûr.
class LabView extends StatefulWidget {
  const LabView({super.key, required this.lab, required this.onCompleted, this.alreadyDone = false});

  final FileLab lab;
  final VoidCallback onCompleted;
  final bool alreadyDone;

  @override
  State<LabView> createState() => _LabViewState();
}

class _LabViewState extends State<LabView> {
  late final _editor = TextEditingController(text: widget.lab.starter);
  LabResult? _result;
  bool _hint = false;
  bool _solution = false;
  bool _notified = false;

  @override
  void dispose() {
    _editor.dispose();
    super.dispose();
  }

  void _analyze() {
    final r = evaluateLab(widget.lab, _editor.text);
    setState(() => _result = r);
    if (r.complete && !_notified) {
      _notified = true;
      widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final lab = widget.lab;
    final r = _result;
    final done = widget.alreadyDone || (r?.complete ?? false);
    const mono = TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.35);

    return ListView(
      padding: const EdgeInsets.all(CambuseSpacing.md),
      children: [
        Row(children: [
          Icon(Icons.shield_outlined, color: p.turquoise, size: 18),
          const SizedBox(width: CambuseSpacing.xs),
          Expanded(child: Text(l.labStatic, style: TextStyle(color: p.textSecondary))),
        ]),
        const SizedBox(height: CambuseSpacing.sm),
        Text(lab.intro),
        if (done)
          Card(child: ListTile(leading: Icon(Icons.smart_toy, color: p.gold), title: Text(l.labDone))),
        const SizedBox(height: CambuseSpacing.sm),
        Text(lab.fileName, style: TextStyle(fontFamily: 'monospace', color: p.gold)),
        Container(
          decoration: BoxDecoration(
            color: p.night,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: p.copper, width: p.borderWidth),
          ),
          child: TextField(
            controller: _editor,
            maxLines: null,
            minLines: 8,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.multiline,
            style: mono.copyWith(color: p.text),
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.all(CambuseSpacing.sm),
            ),
          ),
        ),
        const SizedBox(height: CambuseSpacing.sm),
        Wrap(spacing: CambuseSpacing.sm, runSpacing: CambuseSpacing.sm, children: [
          FilledButton.icon(onPressed: _analyze, icon: const Icon(Icons.fact_check), label: Text(l.labAnalyze)),
          OutlinedButton.icon(
            onPressed: () => setState(() {
              _editor.text = lab.starter;
              _result = null;
            }),
            icon: const Icon(Icons.restart_alt),
            label: Text(l.labReset),
          ),
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
        if (_hint) Text('💡 ${lab.hint}'),
        if (_solution)
          Container(
            margin: const EdgeInsets.only(top: CambuseSpacing.sm),
            padding: const EdgeInsets.all(CambuseSpacing.sm),
            color: p.night,
            child: SelectableText(lab.solution, style: mono.copyWith(color: p.turquoise)),
          ),
        const SizedBox(height: CambuseSpacing.md),
        Text(l.labGoals, style: Theme.of(context).textTheme.titleMedium),
        for (final (i, g) in lab.goals.indexed)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              r == null ? Icons.circle_outlined : (r.goalsMet[i] ? Icons.check_circle : Icons.cancel_outlined),
              color: r == null ? p.textSecondary : (r.goalsMet[i] ? p.turquoise : p.alert),
            ),
            title: Text(g.label),
          ),
        if (r != null) ...[
          const SizedBox(height: CambuseSpacing.sm),
          Text(l.labFindings, style: Theme.of(context).textTheme.titleMedium),
          if (r.findings.isEmpty) Text(l.labNoFinding, style: TextStyle(color: p.turquoise)),
          for (final f in r.findings)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                switch (f.severity) {
                  LintSeverity.blocking => Icons.dangerous,
                  LintSeverity.warning => Icons.warning_amber,
                  LintSeverity.info => Icons.info_outline,
                },
                color: switch (f.severity) {
                  LintSeverity.blocking => p.alert,
                  LintSeverity.warning => p.gold,
                  LintSeverity.info => p.textSecondary,
                },
                semanticLabel: switch (f.severity) {
                  LintSeverity.blocking => l.wsBlocking,
                  LintSeverity.warning => l.wsWarning,
                  LintSeverity.info => l.wsInfo,
                },
              ),
              title: Text('${f.rule} · ${f.message}'),
              subtitle: Text(
                [if (f.line != null) l.labLine(f.line!), if (f.fix != null) l.labFix(f.fix!)].join(' — '),
                style: TextStyle(color: p.textSecondary, fontSize: 12),
              ),
            ),
        ],
      ],
    );
  }
}
