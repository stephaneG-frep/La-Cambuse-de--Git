import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Certificat auto-signé pour l'accès réseau local (opt-in). Généré par
/// `openssl` s'il est présent ; l'empreinte SHA-256 est affichée à
/// l'appairage et épinglée par l'application.
class TlsMaterial {
  TlsMaterial(this.certPath, this.keyPath);

  final String certPath;
  final String keyPath;

  static Future<TlsMaterial> ensure(Directory dataDir) async {
    final cert = File('${dataDir.path}/tls-cert.pem');
    final key = File('${dataDir.path}/tls-key.pem');
    if (!cert.existsSync() || !key.existsSync()) {
      final r = await Process.run('openssl', [
        'req', '-x509', '-newkey', 'ec', '-pkeyopt', 'ec_paramgen_curve:prime256v1',
        '-nodes', '-days', '825', '-subj', '/CN=cambuse-companion',
        '-keyout', key.path, '-out', cert.path,
      ]);
      if (r.exitCode != 0) {
        throw StateError('openssl a échoué : ${r.stderr}');
      }
      await Process.run('chmod', ['600', key.path]);
    }
    return TlsMaterial(cert.path, key.path);
  }

  SecurityContext context() => SecurityContext()
    ..useCertificateChain(certPath)
    ..usePrivateKey(keyPath);

  /// Empreinte SHA-256 du certificat (DER), au format AA:BB:….
  String fingerprint() => fingerprintOfPem(File(certPath).readAsStringSync());

  static String fingerprintOfPem(String pem) {
    final b64 = pem
        .split('\n')
        .where((l) => l.isNotEmpty && !l.startsWith('-----'))
        .join();
    return formatFingerprint(sha256.convert(base64.decode(b64)).bytes);
  }

  static String formatFingerprint(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(':');
}
