import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../ai/domain/ai_models.dart';
import 'captain_providers.dart';
import 'captain_widgets.dart';

/// Demander un plan de mission au professeur IA (facultatif). Le plan est
/// validé strictement puis présenté dans la table de navigation.
class AiPlanScreen extends ConsumerStatefulWidget {
  const AiPlanScreen({super.key});
  @override
  ConsumerState<AiPlanScreen> createState() => _AiPlanScreenState();
}

class _AiPlanScreenState extends ConsumerState<AiPlanScreen> {
  final _goal = TextEditingController();
  String? _project;
  bool _busy = false;
  AiProposal? _proposal;
  String? _error;

  @override
  void dispose() {
    _goal.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    setState(() {
      _busy = true;
      _error = null;
      _proposal = null;
    });
    try {
      final r = await ref.read(captainControllerProvider.notifier).proposeWithAi(_goal.text, _project!);
      if (mounted) setState(() => _proposal = r);
    } on AiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final pr = _proposal;
    return Scaffold(
      appBar: AppBar(title: Text(l.cpAiTitle)),
      body: ListView(
        padding: const EdgeInsets.all(CambuseSpacing.md),
        children: [
          Text(l.cpAiIntro, style: TextStyle(color: p.textSecondary)),
          const SizedBox(height: CambuseSpacing.md),
          ProjectPicker(value: _project, onChanged: (v) => setState(() => _project = v)),
          const SizedBox(height: CambuseSpacing.sm),
          TextField(
            controller: _goal,
            minLines: 2,
            maxLines: 5,
            maxLength: 500,
            decoration: InputDecoration(labelText: l.cpAiGoal, hintText: l.cpAiGoalHint),
            onChanged: (_) => setState(() {}),
          ),
          FilledButton.icon(
            onPressed: _busy || _project == null || _goal.text.trim().length < 8 ? null : _ask,
            icon: const Icon(Icons.smart_toy_outlined),
            label: Text(l.cpAiAsk),
          ),
          if (_busy) const Padding(padding: EdgeInsets.only(top: CambuseSpacing.sm), child: LinearProgressIndicator()),
          if (_error != null) Padding(
            padding: const EdgeInsets.only(top: CambuseSpacing.sm),
            child: SelectableText(_error!, style: TextStyle(color: p.alert)),
          ),
          if (pr != null) ...[
            const SizedBox(height: CambuseSpacing.md),
            if (pr.usage != null)
              Text(l.cpAiUsage(pr.usage!.inputTokens, pr.usage!.outputTokens, pr.cost == null ? '—' : '≈ ${pr.cost!.toStringAsFixed(4)} \$'),
                  style: TextStyle(color: p.textSecondary, fontSize: 12)),
            if (!pr.result.ok) ...[
              Text(l.cpAiRejected, style: TextStyle(color: p.alert, fontWeight: FontWeight.w600)),
              for (final e in pr.result.errors) Text('• $e', style: TextStyle(color: p.alert)),
            ] else ...[
              Text(l.cpAiAccepted(pr.result.plan!.title, pr.result.plan!.steps.length), style: TextStyle(color: p.turquoise)),
              const SizedBox(height: CambuseSpacing.sm),
              FilledButton.icon(
                icon: const Icon(Icons.map_outlined),
                label: Text(l.cpAiReview),
                onPressed: () {
                  ref.read(captainControllerProvider.notifier).setDraft(pr.result.plan!);
                  context.go(Uri(path: '/capitaine/plan', queryParameters: {'mission': 'ia', 'chemin': _project}).toString());
                },
              ),
            ],
          ],
        ],
      ),
    );
  }
}
