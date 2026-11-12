import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:crypto/crypto.dart';

String randomToken([int bytes = 32]) {
  final r = Random.secure();
  return base64Url.encode(List.generate(bytes, (_) => r.nextInt(256))).replaceAll('=', '');
}

String sha256Hex(String s) => sha256.convert(utf8.encode(s)).toString();

/// Comparaison en temps constant (évite les attaques temporelles).
bool constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}

class Device {
  Device({
    required this.id,
    required this.name,
    required this.scopes,
    required this.refreshHash,
    required this.createdAt,
    this.lastSeen,
  });

  factory Device.fromJson(Map<String, dynamic> j) => Device(
        id: j['id'] as String,
        name: j['name'] as String,
        scopes: Scope.parseList((j['scopes'] as List).join(',')),
        refreshHash: j['refreshHash'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        lastSeen: j['lastSeen'] == null ? null : DateTime.parse(j['lastSeen'] as String),
      );

  final String id;
  final String name;
  final Set<Scope> scopes;
  String refreshHash;
  final DateTime createdAt;
  DateTime? lastSeen;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'scopes': [for (final s in scopes) s.code],
        'refreshHash': refreshHash,
        'createdAt': createdAt.toIso8601String(),
        if (lastSeen != null) 'lastSeen': lastSeen!.toIso8601String(),
      };
}

class _AccessToken {
  _AccessToken(this.deviceId, this.expiresAt);
  final String deviceId;
  final DateTime expiresAt;
}

class _PairingCode {
  _PairingCode(this.code, this.scopes, this.expiresAt);
  final String code;
  final Set<Scope> scopes;
  final DateTime expiresAt;
  int attempts = 0;
}

class PairingError implements Exception {
  PairingError(this.code, this.message);
  final String code;
  final String message;
}

/// Appareils appairés, jetons et codes d'appairage.
///
/// Persistance : `devices.json` en 0600, ne contient que des empreintes
/// SHA-256 des jetons de rafraîchissement. Les jetons d'accès (15 min) ne
/// vivent qu'en mémoire.
class DeviceStore {
  DeviceStore(this.dataDir, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    _load();
  }

  final Directory dataDir;
  final DateTime Function() _clock;
  final _devices = <String, Device>{};
  final _access = <String, _AccessToken>{};
  _PairingCode? _pending;

  static const accessTtl = Duration(minutes: 15);
  static const codeTtl = Duration(minutes: 2);
  static const maxCodeAttempts = 5;

  File get _file => File('${dataDir.path}/devices.json');

  List<Device> get devices => _devices.values.toList();

  void _load() {
    if (!_file.existsSync()) return;
    final list = jsonDecode(_file.readAsStringSync()) as List;
    for (final d in list) {
      final dev = Device.fromJson(d as Map<String, dynamic>);
      _devices[dev.id] = dev;
    }
  }

  /// Écriture atomique (fichier temporaire puis renommage), permissions 0600.
  void _save() {
    final tmp = File('${_file.path}.tmp');
    tmp.writeAsStringSync(jsonEncode([for (final d in _devices.values) d.toJson()]), flush: true);
    setOwnerOnly(tmp.path);
    tmp.renameSync(_file.path);
  }

  /// Nouveau code à 6 chiffres (remplace le précédent).
  String startPairing(Set<Scope> scopes) {
    final code = (Random.secure().nextInt(900000) + 100000).toString();
    _pending = _PairingCode(code, {Scope.read, ...scopes}, _clock().add(codeTtl));
    return code;
  }

  PairResult completePairing(String code, String deviceName) {
    final p = _pending;
    if (p == null || _clock().isAfter(p.expiresAt)) {
      _pending = null;
      throw PairingError(ErrorCodes.invalidCode, 'Aucun code valide : générez-en un sur l\'hôte.');
    }
    if (!constantTimeEquals(p.code, code.trim())) {
      p.attempts++;
      if (p.attempts >= maxCodeAttempts) {
        _pending = null;
        throw PairingError(ErrorCodes.pairingLocked,
            'Trop d\'essais : code invalidé. Générez-en un nouveau sur l\'hôte.');
      }
      throw PairingError(ErrorCodes.invalidCode, 'Code incorrect.');
    }
    _pending = null; // usage unique
    final name = deviceName.trim().isEmpty ? 'Appareil' : deviceName.trim();
    final id = randomToken(9);
    final refresh = randomToken();
    final dev = Device(
      id: id,
      name: name.length > 60 ? name.substring(0, 60) : name,
      scopes: p.scopes,
      refreshHash: sha256Hex(refresh),
      createdAt: _clock(),
    );
    _devices[id] = dev;
    _save();
    return PairResult(
      deviceId: id,
      accessToken: _issueAccess(id),
      refreshToken: refresh,
      accessExpiresInSeconds: accessTtl.inSeconds,
      scopes: dev.scopes,
    );
  }

  String _issueAccess(String deviceId) {
    final t = randomToken();
    _access[sha256Hex(t)] = _AccessToken(deviceId, _clock().add(accessTtl));
    return t;
  }

  /// Rotation : l'ancien jeton de rafraîchissement devient invalide.
  PairResult? refresh(String deviceId, String refreshToken) {
    final dev = _devices[deviceId];
    if (dev == null || !constantTimeEquals(dev.refreshHash, sha256Hex(refreshToken))) return null;
    final next = randomToken();
    dev.refreshHash = sha256Hex(next);
    _save();
    return PairResult(
      deviceId: deviceId,
      accessToken: _issueAccess(deviceId),
      refreshToken: next,
      accessExpiresInSeconds: accessTtl.inSeconds,
      scopes: dev.scopes,
    );
  }

  Device? authenticate(String? bearer) {
    if (bearer == null) return null;
    final key = sha256Hex(bearer);
    final t = _access[key];
    if (t == null) return null;
    if (_clock().isAfter(t.expiresAt)) {
      _access.remove(key);
      return null;
    }
    final dev = _devices[t.deviceId];
    if (dev == null) {
      _access.remove(key);
      return null;
    }
    dev.lastSeen = _clock();
    return dev;
  }

  bool revoke(String deviceId) {
    final removed = _devices.remove(deviceId) != null;
    _access.removeWhere((_, t) => t.deviceId == deviceId);
    if (removed) _save();
    return removed;
  }
}

/// chmod 600 (Linux). Silencieux si chmod est indisponible.
void setOwnerOnly(String path) {
  try {
    Process.runSync('chmod', ['600', path]);
  } catch (_) {}
}
