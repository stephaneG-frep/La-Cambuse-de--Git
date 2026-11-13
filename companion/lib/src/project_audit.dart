import 'dart:convert';
import 'dart:io';

import 'package:cambuse_protocol/cambuse_protocol.dart';

import 'ops.dart' show detectProject;

/// Dossiers lourds ou générés : non parcourus (signalés seulement).
const skippedDirs = {
  '.git', 'build', '.dart_tool', 'node_modules', '.gradle', 'Pods', '.venv', 'venv',
  '__pycache__', '.idea', '.vscode-test', 'dist', 'target', '.cxx',
};

/// Lignes `.gitignore` recommandées selon les technologies détectées.
List<String> recommendedGitignore(List<String> kinds) => [
      '.env',
      '*.log',
      '.DS_Store',
      if (kinds.contains('flutter') || kinds.contains('dart')) ...[
        '.dart_tool/',
        'build/',
        '.flutter-plugins-dependencies',
        '*.iml',
        '.idea/',
        'android/key.properties',
        '*.jks',
        '*.keystore',
      ],
      if (kinds.contains('node')) ...['node_modules/', 'dist/'],
      if (kinds.contains('python')) ...['__pycache__/', '.venv/'],
    ];

const _artifactExt = {'.apk', '.aab', '.ipa', '.so', '.jar', '.class', '.exe', '.o', '.dll', '.dylib'};
const warnBytes = 10 * 1024 * 1024;
const blockBytes = 100 * 1024 * 1024;

Map<String, dynamic> _finding(String severity, String code, String message, {String? file, int? line}) =>
    {'severity': severity, 'code': code, 'message': message, 'file': ?file, 'line': ?line};

/// Audit **en lecture seule** : rien n'est écrit, aucune commande ne modifie
/// le projet. Git n'est appelé qu'en lecture, avec la configuration durcie.
Future<Map<String, dynamic>> auditProject(
  String root, {
  required Future<ProcessResult> Function(List<String> args) git,
  int maxFiles = 20000,
}) async {
  final detected = detectProject(root);
  final kinds = (detected['kinds'] as List).cast<String>();
  final findings = <Map<String, dynamic>>[];
  final giFile = File('$root/.gitignore');
  final giContent = giFile.existsSync() ? giFile.readAsStringSync() : '';
  final matcher = GitignoreMatcher(giContent);
  final present = giContent.split('\n').map((l) => l.trim()).toSet();
  final missing = [for (final l in recommendedGitignore(kinds)) if (!present.contains(l)) l];

  var files = 0, bytes = 0;
  var truncated = false;
  final skipped = <String>[];

  void walk(Directory d, String rel) {
    for (final e in d.listSync(followLinks: false)) {
      if (files >= maxFiles) {
        truncated = true;
        return;
      }
      final name = e.path.split('/').last;
      final path = rel.isEmpty ? name : '$rel/$name';
      if (e is Link) continue;
      if (e is Directory) {
        if (skippedDirs.contains(name)) {
          if (name != '.git') skipped.add(path);
          continue;
        }
        walk(e, path);
        continue;
      }
      if (e is! File) continue;
      files++;
      final size = e.lengthSync();
      bytes += size;
      final ignored = matcher.ignores(path);
      final kind = sensitiveFileKind(path);
      if (kind != null) {
        findings.add(ignored
            ? _finding('info', 'secret_file_ignored', '$kind, déjà ignoré par .gitignore.', file: path)
            : _finding('blocking', 'secret_file', '$kind non ignoré : il serait publié avec le dépôt.', file: path));
      }
      if (size >= blockBytes && !ignored) {
        findings.add(_finding('blocking', 'huge_file',
            'Fichier de ${(size / 1048576).toStringAsFixed(0)} Mo : refusé par GitHub (limite 100 Mo).', file: path));
      } else if (size >= warnBytes && !ignored) {
        findings.add(_finding('warning', 'large_file',
            'Fichier de ${(size / 1048576).toStringAsFixed(1)} Mo : alourdit l\'historique (envisagez Git LFS).', file: path));
      }
      final ext = name.contains('.') ? name.substring(name.lastIndexOf('.')).toLowerCase() : '';
      if (_artifactExt.contains(ext) && !ignored) {
        findings.add(_finding('warning', 'build_artifact', 'Artefact compilé : à générer par la CI, pas à versionner.', file: path));
      }
      if (size <= 1024 * 1024 && !ignored) {
        final raw = e.readAsBytesSync();
        if (!looksBinary(raw)) {
          for (final s in scanContent(path, utf8.decode(raw, allowMalformed: true), maxFindings: 5)) {
            findings.add(_finding('blocking', 'secret_content',
                '${s.kind} probable (valeur masquée).', file: path, line: s.line));
          }
        }
      }
    }
  }

  walk(Directory(root), '');

  if (!giFile.existsSync()) {
    findings.add(_finding('warning', 'no_gitignore', 'Pas de .gitignore : les fichiers générés et secrets risquent d\'être versionnés.'));
  } else if (missing.isNotEmpty) {
    findings.add(_finding('info', 'gitignore_incomplete', 'Lignes recommandées absentes du .gitignore : ${missing.join(', ')}'));
  }
  final hasLicense = Directory(root).listSync().any((e) => e is File && RegExp(r'^(LICENSE|LICENCE|COPYING)', caseSensitive: false).hasMatch(e.path.split('/').last));
  if (!hasLicense) {
    findings.add(_finding('info', 'no_license', 'Aucune licence : sans elle, personne n\'a légalement le droit de réutiliser le code.'));
  }

  Map<String, dynamic>? gitInfo;
  if (detected['git'] == true) {
    // symbolic-ref fonctionne aussi sur une branche sans commit (dépôt neuf).
    final branch = await git(['symbolic-ref', '--short', '-q', 'HEAD']);
    final remotes = await git(['remote']);
    final status = await git(['status', '--porcelain=v1']);
    final commits = await git(['rev-list', '--count', 'HEAD']);
    gitInfo = {
      'branch': branch.exitCode == 0 ? (branch.stdout as String).trim() : 'HEAD détachée',
      'remotes': (remotes.stdout as String).split('\n').where((l) => l.trim().isNotEmpty).toList(),
      'changes': (status.stdout as String).split('\n').where((l) => l.trim().isNotEmpty).length,
      'commits': commits.exitCode == 0 ? int.tryParse((commits.stdout as String).trim()) ?? 0 : 0,
    };
  }

  const order = {'blocking': 0, 'warning': 1, 'info': 2};
  findings.sort((a, b) => order[a['severity']]!.compareTo(order[b['severity']]!));
  return {
    ...detected,
    'gitInfo': gitInfo,
    'findings': findings,
    'gitignoreMissing': missing,
    'stats': {'files': files, 'bytes': bytes, 'truncated': truncated, 'skipped': skipped},
    'blocking': findings.where((f) => f['severity'] == 'blocking').length,
  };
}
