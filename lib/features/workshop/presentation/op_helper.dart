import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../companion_link/presentation/companion_screen.dart';
import '../../logbook/domain/audit_outcome.dart';

/// Résultat d'une demande : null si l'utilisateur a refusé.
class OpOutcome {
  const OpOutcome(this.status, {this.rejected = false});
  final OpStatus? status;
  final bool rejected;
  bool get ok => status?.state == OpState.succeeded;
}

/// Soumet une opération au compagnon ; pour une mutation, affiche le panneau
/// d'approbation (commande exacte) et n'exécute qu'après « Autoriser ».
/// Chaque étape est consignée au journal de bord. Les erreurs
/// ([CompanionException]) remontent à l'appelant.
Future<OpOutcome> runCompanionOp(BuildContext context, WidgetRef ref, OpRequest req) async {
  final client = ref.read(companionClientProvider);
  final log = ref.read(logbookRepositoryProvider);
  final where = req.root ?? '';
  var st = await client.submit(req);
  if (st.state == OpState.awaitingApproval) {
    if (!context.mounted) return const OpOutcome(null, rejected: true);
    final ok = await showApprovalDialog(context, st);
    if (ok != true) {
      await client.reject(st.id);
      await log.record(category: 'atelier', action: 'Opération refusée', details: '${req.type} — $where', outcome: AuditOutcome.cancelled);
      return const OpOutcome(null, rejected: true);
    }
    await client.approve(st.id);
    await log.record(category: 'atelier', action: 'Opération autorisée', details: '${req.type} — $where', outcome: AuditOutcome.info);
  }
  st = await client.waitFor(st.id, max: const Duration(minutes: 6));
  final type = OpType.fromCode(req.type);
  if (type != null && (type.mutating || type == OpType.projectBackup)) {
    await log.record(
      category: 'atelier',
      action: 'Opération ${req.type}',
      details: '$where → ${st.state.code}${st.error == null ? '' : ' : ${st.error!.split('\n').first}'}',
      outcome: st.state == OpState.succeeded ? AuditOutcome.success : AuditOutcome.failure,
    );
  }
  return OpOutcome(st);
}
