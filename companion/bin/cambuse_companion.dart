import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:cambuse_companion/cambuse_companion.dart';
import 'package:cambuse_protocol/cambuse_protocol.dart';

String defaultDataDir() =>
    '${Platform.environment['XDG_DATA_HOME'] ?? '${Platform.environment['HOME']}/.local/share'}/cambuse-companion';

Future<void> main(List<String> argv) async {
  final parser = ArgParser()
    ..addOption('data-dir', defaultsTo: defaultDataDir(), help: 'Dossier des données (0700).')
    ..addOption('port', defaultsTo: '$defaultLoopbackPort', help: 'Port loopback (127.0.0.1).')
    ..addFlag('help', abbr: 'h', negatable: false);
  parser.addCommand('serve', ArgParser()
    ..addMultiOption('root', help: 'Dossier autorisé (répétable). Obligatoire.')
    ..addFlag('lan', negatable: false, help: 'Écoute aussi sur le réseau local, en TLS uniquement.')
    ..addOption('lan-port', defaultsTo: '$defaultLanPort')
    ..addMultiOption('remote-host', defaultsTo: ['github.com', 'gitlab.com'],
        help: 'Hôte HTTPS autorisé pour push/pull (répétable, ex. GitLab auto-hébergé).'));
  parser.addCommand('pair', ArgParser()
    ..addOption('scopes', defaultsTo: 'read', help: 'Portées : read, git-write, remote, docker, build (séparées par des virgules).'));
  parser.addCommand('devices');
  parser.addCommand('revoke');
  parser.addCommand('audit', ArgParser()..addOption('limit', abbr: 'n', defaultsTo: '30'));

  final ArgResults args;
  try {
    args = parser.parse(argv);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    exit(64);
  }
  final cmd = args.command;
  if (args['help'] == true || cmd == null) {
    stdout.writeln('cambuse-companion — compagnon Linux de La Cambuse de Git\n\n'
        'Commandes : serve --root DIR [--lan] [--remote-host H] | pair [--scopes read,git-write,remote] | devices | revoke ID | audit\n\n'
        '${parser.usage}');
    exit(cmd == null && args['help'] != true ? 64 : 0);
  }
  final dataDir = Directory(args['data-dir'] as String);
  final port = int.parse(args['port'] as String);

  switch (cmd.name) {
    case 'serve':
      _refuseRoot();
      final roots = (cmd['root'] as List<String>);
      if (roots.isEmpty) {
        stderr.writeln('Indiquez au moins un dossier autorisé : --root /chemin/vers/projets');
        exit(64);
      }
      for (final r in roots) {
        if (!Directory(r).existsSync()) {
          stderr.writeln('Dossier introuvable : $r');
          exit(66);
        }
      }
      final server = CompanionServer(CompanionConfig(
        dataDir: dataDir,
        roots: roots,
        port: port,
        lan: cmd['lan'] as bool,
        lanPort: int.parse(cmd['lan-port'] as String),
        remoteHosts: (cmd['remote-host'] as List<String>).map((h) => h.toLowerCase()).toSet(),
      ));
      try {
        await server.start();
      } on SocketException catch (e) {
        stderr.writeln('Impossible d\'ouvrir le port ${e.port ?? port} : ${e.osError?.message ?? e.message}. '
            'Un autre compagnon tourne-t-il déjà ? (choisissez un autre port avec --port)');
        exit(75);
      }
      stdout.writeln('Compagnon prêt sur http://127.0.0.1:${server.port}/v1');
      stdout.writeln('Dossiers autorisés : ${server.runner.guard.roots.join(', ')}');
      if (server.lanPort != null) {
        stdout.writeln('Réseau local (TLS) : port ${server.lanPort}');
        stdout.writeln('Empreinte du certificat : ${server.tlsFingerprint}');
      }
      stdout.writeln('Pour appairer un appareil : cambuse-companion pair   (Ctrl+C pour arrêter)');
      ProcessSignal.sigint.watch().first.then((_) async {
        await server.stop();
        exit(0);
      });
      ProcessSignal.sigterm.watch().first.then((_) async {
        await server.stop();
        exit(0);
      });
    case 'pair':
      final r = await _admin(dataDir, port, 'POST', '/v1/pair/start', {'scopes': cmd['scopes']});
      stdout.writeln('Code d\'appairage : ${r['code']}  (valable ${r['expiresIn']} s, usage unique)');
      if (r['fingerprint'] != null) stdout.writeln('Empreinte TLS à vérifier : ${r['fingerprint']}');
    case 'devices':
      final list = await _admin(dataDir, port, 'GET', '/v1/devices') as List;
      if (list.isEmpty) stdout.writeln('Aucun appareil appairé.');
      for (final d in list) {
        stdout.writeln('${d['id']}  ${d['name']}  [${(d['scopes'] as List).join(',')}]  vu : ${d['lastSeen'] ?? 'jamais'}');
      }
    case 'revoke':
      if (cmd.rest.isEmpty) {
        stderr.writeln('Usage : cambuse-companion revoke ID');
        exit(64);
      }
      await _admin(dataDir, port, 'DELETE', '/v1/devices/${cmd.rest.first}');
      stdout.writeln('Appareil révoqué.');
    case 'audit':
      final n = int.parse(cmd['limit'] as String);
      for (final e in AuditLog(dataDir).tail(n)) {
        stdout.writeln(jsonEncode(e));
      }
  }
}

void _refuseRoot() {
  final r = Process.runSync('id', ['-u']);
  if ((r.stdout as String).trim() == '0') {
    stderr.writeln('Refus : le compagnon ne doit pas tourner en root (privilèges minimaux).');
    exit(77);
  }
}

Future<dynamic> _admin(Directory dataDir, int port, String method, String path, [Map<String, dynamic>? body]) async {
  final tokenFile = File('${dataDir.path}/admin.token');
  if (!tokenFile.existsSync()) {
    stderr.writeln('Compagnon non démarré (lancez d\'abord : cambuse-companion serve --root …).');
    exit(69);
  }
  final client = HttpClient();
  try {
    final req = await client.openUrl(method, Uri.parse('http://127.0.0.1:$port$path'));
    req.headers.set('x-cambuse-admin', tokenFile.readAsStringSync().trim());
    req.headers.contentType = ContentType.json;
    if (body != null) req.write(jsonEncode(body));
    final res = await req.close();
    final json = jsonDecode(await utf8.decodeStream(res)) as Map<String, dynamic>;
    if (json['ok'] != true) {
      stderr.writeln('Erreur : ${(json['error'] as Map)['message']}');
      exit(1);
    }
    return json['data'];
  } on SocketException {
    stderr.writeln('Impossible de joindre le compagnon sur le port $port.');
    exit(69);
  } finally {
    client.close();
  }
}
