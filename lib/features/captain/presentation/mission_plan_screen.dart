import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/mission.dart';
import '../domain/missions.dart';
import 'captain_providers.dart';
import 'captain_widgets.dart';

/// Table de navigation : plan d'une mission avant son lancement.
class MissionPlanScreen extends ConsumerStatefulWidget {
  const MissionPlanScreen({super.key, required this.missionId, this.projectPath});
  final String missionId;
  final String? projectPath;
  @override
  ConsumerState<MissionPlanScreen> createState() => _MissionPlanScreenState();
}

class _MissionPlanScreenState extends ConsumerState<MissionPlanScreen> {
  String? _project;
  String _provider = 'github';
  bool _launching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _project = widget.projectPath;
  }

  MissionPlan? get _plan {
    if (widget.missionId == 'ia') return ref.read(captainControllerProvider).draft;
    final t = missionTemplates.where((m) => m.id == widget.missionId).firstOrNull;
    return t?.build(provider: _provider);
  }

  Future<void> _launch(MissionPlan plan) async {
    setState(() {
      _launching = true;
      _error = null;
    });
    try {
      final id = await ref.read(captainControllerProvider.notifier).launch(plan, _project!);
      if (mounted) context.go('/capitaine/execution?id=$id');
    } catch (e) {
      if (mounted) setState(() => _error = '$e'.replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    ref.watch(captainControllerProvider);
    final plan = _plan;
    final template = missionTemplates.where((m) => m.id == widget.missionId).firstOrNull;
    if (plan == null) {
      return Scaffold(appBar: AppBar(title: Text(l.cpPlanTitle)), body: Center(child: Text(l.cpPlanMissing)));
    }
    final errors = validatePlan(plan);
    final counts = {for (final r in StepRisk.values) r: plan.steps.where((s) => _known(s.op) && s.risk == r).length};

    return Scaffold(
      appBar: AppBar(title: Text(l.cpPlanTitle)),
      body: ListView(
        padding: const EdgeInsets.all(CambuseSpacing.md),
        children: [
          Text(plan.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: p.gold)),
          const SizedBox(height: CambuseSpacing.xs),
          Text(plan.summary),
          if (plan.source == PlanSource.ia)
            Card(
              child: ListTile(
                leading: Icon(Icons.smart_toy_outlined, color: p.gold),
                title: Text(l.cpPlanFromAi),
              ),
            ),
          const SizedBox(height: CambuseSpacing.md),
          ProjectPicker(value: _project, onChanged: (v) => setState(() => _project = v)),
          if (template?.providerChoice ?? false) ...[
            const SizedBox(height: CambuseSpacing.sm),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'github', label: Text('GitHub Actions')),
                ButtonSegment(value: 'gitlab', label: Text('GitLab CI')),
              ],
              selected: {_provider},
              onSelectionChanged: (s) => setState(() => _provider = s.first),
            ),
          ],
          const SizedBox(height: CambuseSpacing.md),
          Wrap(spacing: CambuseSpacing.sm, runSpacing: CambuseSpacing.xs, children: [
            for (final e in counts.entries)
              if (e.value > 0) Row(mainAxisSize: MainAxisSize.min, children: [RiskBadge(e.key), Text(' × ${e.value}')]),
          ]),
          const SizedBox(height: CambuseSpacing.xs),
          Text(
            l.cpLimits(plan.limits.maxSteps, plan.limits.maxMutations, plan.limits.maxDuration.inMinutes),
            style: TextStyle(color: p.textSecondary, fontSize: 12),
          ),
          Text(plan.source == PlanSource.ia ? l.cpCostAi : l.cpCostNone, style: TextStyle(color: p.textSecondary, fontSize: 12)),
          const SizedBox(height: CambuseSpacing.md),
          for (final (i, s) in plan.steps.indexed) _StepCard(index: i, step: s),
          if (errors.isNotEmpty) ...[
            const SizedBox(height: CambuseSpacing.sm),
            Text(l.cpPlanInvalid, style: TextStyle(color: p.alert, fontWeight: FontWeight.w600)),
            for (final e in errors) Text('• $e', style: TextStyle(color: p.alert)),
          ],
          if (_error != null) Padding(
            padding: const EdgeInsets.only(top: CambuseSpacing.sm),
            child: Text(_error!, style: TextStyle(color: p.alert)),
          ),
          const SizedBox(height: CambuseSpacing.md),
          Text(l.cpApproveNote, style: TextStyle(color: p.textSecondary)),
          const SizedBox(height: CambuseSpacing.sm),
          FilledButton.icon(
            onPressed: errors.isEmpty && _project != null && !_launching ? () => _launch(plan) : null,
            icon: const Icon(Icons.sailing),
            label: Text(_project == null ? l.cpChooseProject : l.cpApproveLaunch),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.index, required this.step});
  final int index;
  final StepSpec step;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final known = _known(step.op);
    final small = TextStyle(color: p.textSecondary, fontSize: 12);
    return Card(
      margin: const EdgeInsets.only(bottom: CambuseSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(CambuseSpacing.sm),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('${index + 1}. ${step.title}', style: const TextStyle(fontWeight: FontWeight.w600))),
            if (known) RiskBadge(step.risk),
          ]),
          if (step.why.isNotEmpty) Padding(padding: const EdgeInsets.only(top: CambuseSpacing.xs), child: Text(step.why)),
          const SizedBox(height: CambuseSpacing.xs),
          Text(step.op, style: TextStyle(fontFamily: 'monospace', color: p.gold, fontSize: 12)),
          for (final e in step.params.entries) Text('${e.key} : ${e.value}', style: small.copyWith(fontFamily: 'monospace')),
          for (final e in step.bind.entries)
            Text(e.value == 'forge.token' ? l.cpTokenAtRuntime : l.cpComputed(e.key, e.value), style: small),
          Wrap(spacing: CambuseSpacing.md, children: [
            if (step.review) _Marker(Icons.rate_review_outlined, l.cpMarkReview),
            if (known && step.needsSpecificConsent) _Marker(Icons.gpp_maybe_outlined, l.cpMarkConsent),
            if (known && step.type.mutating && step.risk != StepRisk.externe) _Marker(Icons.how_to_reg_outlined, l.cpMarkApproval),
            if (step.when != null) _Marker(Icons.call_split, l.cpMarkWhen(conditionLabel(step.when!))),
            for (final r in step.requires) _Marker(Icons.flag_outlined, l.cpMarkRequires(conditionLabel(r))),
          ]),
        ]),
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    final p = CambuseTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: CambuseSpacing.xs),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: p.turquoise),
        const SizedBox(width: CambuseSpacing.xs),
        Flexible(child: Text(text, style: TextStyle(color: p.turquoise, fontSize: 12))),
      ]),
    );
  }
}

/// L'opération existe-t-elle (un plan IA peut en citer d'inconnues) ?
bool _known(String code) => OpType.fromCode(code) != null;
