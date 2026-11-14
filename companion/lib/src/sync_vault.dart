import 'dart:convert';
import 'dart:io';

import 'package:cambuse_protocol/cambuse_protocol.dart';

import 'store.dart';

/// Progression d'apprentissage partagée entre les appareils appairés
/// (sync.json, 0600, écriture atomique). Ne contient aucun secret.
class SyncVault {
  SyncVault(Directory dataDir) : file = File('${dataDir.path}/sync.json');

  final File file;

  ProgressSnapshot read() {
    if (!file.existsSync()) return const ProgressSnapshot();
    try {
      return ProgressSnapshot.fromJson(jsonDecode(file.readAsStringSync()) as Map<String, dynamic>);
    } on Object {
      // Fichier illisible : on ne l'écrase pas, on le met de côté.
      file.renameSync('${file.path}.illisible-${DateTime.now().millisecondsSinceEpoch}');
      return const ProgressSnapshot();
    }
  }

  /// Fusionne [incoming] avec la progression stockée et renvoie le résultat.
  ProgressSnapshot merge(ProgressSnapshot incoming) {
    final merged = mergeProgress(read(), incoming);
    final tmp = File('${file.path}.tmp')..writeAsStringSync(jsonEncode(merged.toJson()), flush: true);
    setOwnerOnly(tmp.path);
    tmp.renameSync(file.path);
    return merged;
  }
}
