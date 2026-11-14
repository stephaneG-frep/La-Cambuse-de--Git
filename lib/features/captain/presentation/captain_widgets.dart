import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../workshop/presentation/workshop_screen.dart';
import '../domain/engine.dart';
import '../domain/mission.dart';

/// Libellé localisé d'un niveau de risque.
String riskLabel(AppLocalizations l, StepRisk r) => switch (r) {
      StepRisk.lecture => l.cpRiskRead,
      StepRisk.controle => l.cpRiskCheckpoint,
      StepRisk.modification => l.cpRiskModify,
      StepRisk.execution => l.cpRiskExecute,
      StepRisk.externe => l.cpRiskExternal,
    };

/// Badge de risque : icône + texte (jamais la couleur seule).
class RiskBadge extends StatelessWidget {
  const RiskBadge(this.risk, {super.key});
  final StepRisk risk;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final (icon, color) = switch (risk) {
      StepRisk.lecture => (Icons.visibility_outlined, p.turquoise),
      StepRisk.controle => (Icons.save_outlined, p.gold),
      StepRisk.modification => (Icons.edit_note, p.copper),
      StepRisk.execution => (Icons.play_circle_outline, p.gold),
      StepRisk.externe => (Icons.public, p.alert),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: CambuseSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CambuseSpacing.radius),
        border: Border.all(color: color, width: p.borderWidth),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: CambuseSpacing.xs),
        Text(riskLabel(l, risk), style: TextStyle(color: color, fontSize: 12)),
      ]),
    );
  }
}

/// Icône et libellé d'un état d'étape.
(IconData, String) stepStateView(AppLocalizations l, MissionStepState s) => switch (s) {
      MissionStepState.aFaire => (Icons.radio_button_unchecked, l.cpStepTodo),
      MissionStepState.enCours => (Icons.sync, l.cpStepRunning),
      MissionStepState.reussie => (Icons.check_circle, l.cpStepDone),
      MissionStepState.ignoree => (Icons.skip_next, l.cpStepSkipped),
      MissionStepState.echouee => (Icons.error, l.cpStepFailed),
      MissionStepState.refusee => (Icons.block, l.cpStepRefused),
      MissionStepState.annulee => (Icons.cancel, l.cpStepCancelled),
      MissionStepState.inconnue => (Icons.help, l.cpStepUnknown),
    };

String runStateLabel(AppLocalizations l, RunState s) => switch (s) {
      RunState.pret => l.cpRunReady,
      RunState.enCours => l.cpRunRunning,
      RunState.enPause => l.cpRunPaused,
      RunState.termine => l.cpRunDone,
      RunState.echoue => l.cpRunFailed,
      RunState.arrete => l.cpRunStopped,
      RunState.interrompu => l.cpRunInterrupted,
    };

/// Choix du projet parmi ceux visibles par le compagnon.
class ProjectPicker extends ConsumerWidget {
  const ProjectPicker({super.key, required this.value, required this.onChanged});
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final projects = ref.watch(workshopProjectsProvider);
    return projects.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('$e', style: TextStyle(color: p.alert)),
      data: (roots) {
        final all = [for (final (_, list) in roots) ...list];
        if (all.isEmpty) return Text(l.wsNoProjects);
        return DropdownMenu<String>(
          initialSelection: value,
          expandedInsets: EdgeInsets.zero,
          label: Text(l.cpProject),
          onSelected: onChanged,
          dropdownMenuEntries: [for (final pr in all) DropdownMenuEntry(value: pr['path'] as String, label: pr['name'] as String)],
        );
      },
    );
  }
}
