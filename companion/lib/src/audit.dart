import 'dart:convert';
import 'dart:io';

/// Journal d'audit en ajout seul (JSON Lines, 0600). Aucun secret n'y est
/// écrit : seulement l'appareil, l'opération, ses paramètres non sensibles et
/// le résultat.
class AuditLog {
  AuditLog(this.dataDir, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final Directory dataDir;
  final DateTime Function() _clock;

  File get file => File('${dataDir.path}/audit.jsonl');

  void record(String event, {String? deviceId, Map<String, Object?> details = const {}}) {
    final created = !file.existsSync();
    file.writeAsStringSync(
      '${jsonEncode({'ts': _clock().toIso8601String(), 'event': event, 'device': ?deviceId, ...details})}\n',
      mode: FileMode.append,
      flush: true,
    );
    if (created) {
      try {
        Process.runSync('chmod', ['600', file.path]);
      } catch (_) {}
    }
  }

  List<Map<String, dynamic>> tail([int n = 100]) {
    if (!file.existsSync()) return const [];
    final lines = file.readAsLinesSync().where((l) => l.isNotEmpty).toList();
    return [
      for (final l in lines.skip(lines.length > n ? lines.length - n : 0))
        jsonDecode(l) as Map<String, dynamic>,
    ];
  }
}
