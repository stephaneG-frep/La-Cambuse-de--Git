import 'dart:io';

import 'package:cambuse_protocol/cambuse_protocol.dart';

class PathViolation implements Exception {
  PathViolation(this.message);
  final String message;
  final String code = ErrorCodes.pathOutsideRoot;
  @override
  String toString() => message;
}

/// Confinement des chemins aux racines autorisées sur l'hôte.
///
/// Tous les chemins sont résolus (liens symboliques compris) avant la
/// comparaison : un lien qui pointe hors de la racine est refusé.
class RootGuard {
  RootGuard(Iterable<String> roots)
      : roots = [for (final r in roots) Directory(r).resolveSymbolicLinksSync()];

  final List<String> roots;

  static bool _within(String child, String parent) =>
      child == parent || child.startsWith(parent.endsWith('/') ? parent : '$parent/');

  /// Résout un dossier de projet ; il doit exister et être dans une racine.
  String resolveProject(String? raw) {
    if (raw == null || raw.isEmpty) throw PathViolation('Dossier de projet manquant.');
    if (!raw.startsWith('/')) throw PathViolation('Le dossier doit être un chemin absolu.');
    final dir = Directory(raw);
    if (!dir.existsSync()) throw PathViolation('Dossier introuvable : $raw');
    final real = dir.resolveSymbolicLinksSync();
    if (!roots.any((r) => _within(real, r))) {
      throw PathViolation('« $raw » est hors des dossiers autorisés sur l\'hôte.');
    }
    return real;
  }

  /// Valide un chemin relatif de fichier dans un projet déjà confiné. Le fichier
  /// peut ne pas exister (suppression indexée), mais son parent existant le
  /// plus proche doit rester dans le projet une fois résolu.
  static String resolveInProject(String projectReal, String relative) {
    if (relative.isEmpty ||
        relative.startsWith('/') ||
        relative.contains('\u0000') ||
        relative.split('/').any((s) => s == '..')) {
      throw PathViolation('Chemin de fichier refusé : « $relative ».');
    }
    final full = '$projectReal/$relative';
    var probe = full;
    while (FileSystemEntity.typeSync(probe, followLinks: false) == FileSystemEntityType.notFound) {
      final parent = File(probe).parent.path;
      if (parent == probe) break;
      probe = parent;
    }
    final real = File(probe).resolveSymbolicLinksSync();
    if (!_within(real, projectReal)) {
      throw PathViolation('« $relative » sort du projet (lien symbolique ou chemin).');
    }
    if (relative.split('/').first == '.git') {
      throw PathViolation('Le dossier .git ne peut pas être ciblé directement.');
    }
    return relative;
  }
}
