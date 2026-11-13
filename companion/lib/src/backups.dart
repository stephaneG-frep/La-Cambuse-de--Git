import 'dart:convert';
import 'dart:io';

import 'project_audit.dart' show skippedDirs;
import 'store.dart' show randomToken, setOwnerOnly;

/// Sauvegardes gérées par le compagnon, dans son dossier de données (0700).
///
/// - `files` : copie de fichiers précis, faite automatiquement avant toute
///   opération qui écrase du travail (ex. `git restore`).
/// - `project` : archive tar.gz du projet (dossiers générés exclus, `.git`
///   inclus). Sa restauration crée **un nouveau dossier** : rien n'est écrasé.
class BackupManager {
  BackupManager(this.dataDir, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final Directory dataDir;
  final DateTime Function() _clock;
  static const maxProjectBytes = 500 * 1024 * 1024;

  Directory get _base => Directory('${dataDir.path}/backups');

  String _stamp() {
    final t = _clock();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}${two(t.month)}${two(t.day)}-${two(t.hour)}${two(t.minute)}${two(t.second)}';
  }

  Directory _new(String kind) {
    final dir = Directory('${_base.path}/${_stamp()}-${randomToken(4)}')..createSync(recursive: true);
    Process.runSync('chmod', ['700', _base.path]);
    return dir;
  }

  void _writeMeta(Directory dir, Map<String, dynamic> meta) {
    final f = File('${dir.path}/meta.json')..writeAsStringSync(jsonEncode(meta), flush: true);
    setOwnerOnly(f.path);
  }

  /// Copie [relPaths] (relatifs à [project]) avant une opération destructrice.
  Map<String, dynamic> backupFiles(String project, List<String> relPaths, {required String reason}) {
    final dir = _new('files');
    final saved = <String>[];
    for (final rel in relPaths) {
      final src = File('$project/$rel');
      if (!src.existsSync()) continue;
      final dst = File('${dir.path}/files/$rel')..parent.createSync(recursive: true);
      src.copySync(dst.path);
      saved.add(rel);
    }
    final meta = {
      'id': dir.path.split('/').last,
      'kind': 'files',
      'project': project,
      'createdAt': _clock().toIso8601String(),
      'reason': reason,
      'files': saved,
    };
    _writeMeta(dir, meta);
    return meta;
  }

  Future<Map<String, dynamic>> backupProject(String project) async {
    final size = _measure(Directory(project));
    if (size > maxProjectBytes) {
      throw StateError('Projet trop volumineux pour une sauvegarde automatique '
          '(${(size / 1048576).toStringAsFixed(0)} Mo > 500 Mo).');
    }
    final dir = _new('project');
    final name = project.split('/').last;
    final parent = File(project).parent.path;
    final archive = '${dir.path}/projet.tar.gz';
    final r = await Process.run('tar', [
      '-czf', archive,
      for (final s in skippedDirs.where((s) => s != '.git')) '--exclude=$name/$s',
      '-C', parent, name,
    ]);
    if (r.exitCode != 0) throw StateError('tar a échoué : ${r.stderr}');
    setOwnerOnly(archive);
    final meta = {
      'id': dir.path.split('/').last,
      'kind': 'project',
      'project': project,
      'createdAt': _clock().toIso8601String(),
      'reason': 'Sauvegarde du projet demandée',
      'bytes': File(archive).lengthSync(),
    };
    _writeMeta(dir, meta);
    return meta;
  }

  int _measure(Directory d) {
    var total = 0;
    for (final e in d.listSync(recursive: false, followLinks: false)) {
      final n = e.path.split('/').last;
      if (e is Directory && skippedDirs.contains(n) && n != '.git') continue;
      if (e is Directory) {
        total += _measure(e);
      } else if (e is File) {
        total += e.lengthSync();
      }
      if (total > maxProjectBytes) return total;
    }
    return total;
  }

  List<Map<String, dynamic>> list({String? project}) {
    if (!_base.existsSync()) return const [];
    final out = <Map<String, dynamic>>[];
    for (final d in _base.listSync().whereType<Directory>()) {
      final f = File('${d.path}/meta.json');
      if (!f.existsSync()) continue;
      final m = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      if (project == null || m['project'] == project) out.add(m);
    }
    out.sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));
    return out;
  }

  Map<String, dynamic> get(String id) {
    if (!RegExp(r'^[\w-]+$').hasMatch(id)) throw ArgumentError('identifiant invalide');
    final f = File('${_base.path}/$id/meta.json');
    if (!f.existsSync()) throw ArgumentError('Sauvegarde introuvable : $id');
    return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  }

  /// Restaure une sauvegarde **dans un nouveau dossier** frère du projet.
  Future<String> restoreToNewFolder(String id) async {
    final meta = get(id);
    final project = meta['project'] as String;
    final parent = File(project).parent.path;
    final target = '$parent/${project.split('/').last}-restauration-${_stamp()}';
    if (FileSystemEntity.typeSync(target) != FileSystemEntityType.notFound) {
      throw StateError('Le dossier cible existe déjà : $target');
    }
    if (meta['kind'] == 'project') {
      final tmp = Directory('${_base.path}/$id/extract-${randomToken(4)}')..createSync();
      final r = await Process.run('tar', ['-xzf', '${_base.path}/$id/projet.tar.gz', '--no-same-owner', '-C', tmp.path]);
      if (r.exitCode != 0) throw StateError('tar a échoué : ${r.stderr}');
      final extracted = tmp.listSync().whereType<Directory>().single;
      extracted.renameSync(target);
      tmp.deleteSync(recursive: true);
    } else {
      Directory(target).createSync();
      final src = Directory('${_base.path}/$id/files');
      for (final f in src.listSync(recursive: true).whereType<File>()) {
        final rel = f.path.substring(src.path.length + 1);
        final dst = File('$target/$rel')..parent.createSync(recursive: true);
        f.copySync(dst.path);
      }
    }
    return target;
  }
}
