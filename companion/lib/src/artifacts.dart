import 'dart:io';

import 'package:crypto/crypto.dart';

/// Empreinte SHA-256 d'un fichier (lecture en flux).
Future<String> sha256OfFile(File f) async => (await sha256.bind(f.openRead()).first).toString();

/// Outils de vérification de signature APK trouvés sur l'hôte.
class ApkTools {
  ApkTools({this.apksigner, this.javaHome});

  final String? apksigner;
  final String? javaHome;

  static ApkTools detect() {
    final env = Platform.environment;
    final sdk = env['ANDROID_HOME'] ?? env['ANDROID_SDK_ROOT'] ?? '${env['HOME']}/Android/Sdk';
    String? signer;
    final bt = Directory('$sdk/build-tools');
    if (bt.existsSync()) {
      final versions = bt.listSync().whereType<Directory>().map((d) => d.path).toList()..sort();
      for (final v in versions.reversed) {
        if (File('$v/apksigner').existsSync()) {
          signer = '$v/apksigner';
          break;
        }
      }
    }
    String? java = env['JAVA_HOME'];
    if (java == null && File('/opt/android-studio/jbr/bin/java').existsSync()) java = '/opt/android-studio/jbr';
    return ApkTools(apksigner: signer, javaHome: java);
  }
}

/// Signature d'un APK : « debug » (certificat Android Debug), « release »,
/// « invalide » ou « inconnue » (outil absent). Jamais de supposition.
Future<Map<String, dynamic>> apkSignature(File apk, ApkTools tools) async {
  if (tools.apksigner == null) return {'status': 'inconnue', 'detail': 'apksigner introuvable sur l\'hôte'};
  final env = {
    'PATH': [if (tools.javaHome != null) '${tools.javaHome}/bin', Platform.environment['PATH'] ?? '/usr/bin:/bin'].join(':'),
    'HOME': Platform.environment['HOME'] ?? '/tmp',
    'JAVA_HOME': ?tools.javaHome,
  };
  final r = await Process.run(tools.apksigner!, ['verify', '--print-certs', apk.path],
      environment: env, includeParentEnvironment: false).timeout(const Duration(minutes: 1));
  final out = '${r.stdout}';
  if (r.exitCode != 0) return {'status': 'invalide', 'detail': '${r.stderr}'.trim().split('\n').first};
  final dn = RegExp(r'certificate DN: (.+)').firstMatch(out)?.group(1)?.trim() ?? '';
  final digest = RegExp(r'certificate SHA-256 digest: ([0-9a-f]+)').firstMatch(out)?.group(1);
  return {
    'status': dn.contains('CN=Android Debug') ? 'debug' : 'release',
    'certificate': dn,
    'certificateSha256': ?digest,
  };
}

/// ABI natives embarquées (dossiers `lib/<abi>/` de l'archive).
Future<List<String>> apkAbis(File apk) async {
  try {
    final r = await Process.run('unzip', ['-Z1', apk.path]);
    if (r.exitCode != 0) return const [];
    final all = <String>{}, flutter = <String>{};
    for (final l in '${r.stdout}'.split('\n')) {
      final m = RegExp(r'^lib/([^/]+)/([^/]+\.so)$').firstMatch(l.trim());
      if (m == null) continue;
      all.add(m.group(1)!);
      if (m.group(2) == 'libflutter.so') flutter.add(m.group(1)!);
    }
    // Pour une application Flutter, seule une ABI qui embarque le moteur peut
    // réellement s'exécuter : les autres dossiers ne contiennent que des greffons.
    return (flutter.isNotEmpty ? flutter : all).toList()..sort();
  } catch (_) {
    return const [];
  }
}

/// Artefacts connus d'un projet : APK, AAB, bundle Linux, paquets et archives
/// de dist/. Tailles et SHA-256 ; signature et ABI pour les APK.
Future<Map<String, dynamic>> listArtifacts(String root, {ApkTools? tools}) async {
  final t = tools ?? ApkTools.detect();
  final found = <Map<String, dynamic>>[];
  Future<void> add(File f, String kind) async {
    final entry = <String, dynamic>{
      'path': f.path.substring(root.length + 1),
      'kind': kind,
      'bytes': f.lengthSync(),
      'modified': f.lastModifiedSync().toIso8601String(),
      'sha256': await sha256OfFile(f),
    };
    if (kind == 'apk') {
      entry['signature'] = await apkSignature(f, t);
      entry['abis'] = await apkAbis(f);
    }
    found.add(entry);
  }

  final apkDir = Directory('$root/build/app/outputs/flutter-apk');
  if (apkDir.existsSync()) {
    for (final f in apkDir.listSync().whereType<File>().where((f) => f.path.endsWith('.apk'))) {
      await add(f, 'apk');
    }
  }
  final aabDir = Directory('$root/build/app/outputs/bundle');
  if (aabDir.existsSync()) {
    for (final f in aabDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.aab'))) {
      await add(f, 'aab');
    }
  }
  final bundle = Directory('$root/build/linux/x64/release/bundle');
  if (bundle.existsSync()) {
    final exe = bundle.listSync().whereType<File>().where((f) => (f.statSync().mode & 0x40) != 0).firstOrNull;
    if (exe != null) await add(exe, 'linux-bundle');
  }
  final dist = Directory('$root/dist');
  if (dist.existsSync()) {
    for (final f in dist.listSync().whereType<File>()) {
      final n = f.path.split('/').last;
      final kind = n.endsWith('.deb')
          ? 'deb'
          : n.endsWith('.zip')
              ? 'zip'
              : n.endsWith('.apk')
                  ? 'apk'
                  : n == 'SHA256SUMS'
                      ? 'checksums'
                      : null;
      if (kind != null) await add(f, kind);
    }
  }
  return {'artifacts': found, 'apksigner': t.apksigner != null};
}
