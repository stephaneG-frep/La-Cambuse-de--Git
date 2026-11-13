import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  for (final kind in ciTemplateKinds) {
    for (final provider in ciProviders) {
      test('$kind / $provider : YAML valide, sûr, sans secret', () {
        final t = ciTemplate(kind, provider, flutterVersion: '3.47.2')!;
        final doc = loadYaml(t) as YamlMap;
        expect(scanContent(ciFileName(provider), t), isEmpty, reason: 'aucun secret');
        if (provider == 'github') {
          expect(doc['permissions'], {'contents': 'read'});
          final jobs = doc['jobs'] as YamlMap;
          expect(jobs.keys, contains('secrets'));
          for (final j in jobs.values) {
            expect((j as YamlMap)['timeout-minutes'], isNotNull);
          }
          // Toute action est épinglée par une empreinte de 40 caractères.
          for (final m in RegExp(r'uses:\s*(\S+)').allMatches(t)) {
            expect(m.group(1), matches(RegExp(r'^[\w.-]+/[\w.-]+@[0-9a-f]{40}$')), reason: m.group(1));
          }
          expect(t, contains('persist-credentials: false'));
        } else {
          expect(t, contains('Secret-Detection'));
          expect(t, contains('timeout:'));
          expect(t, isNot(contains(':latest')));
        }
        if (kind == 'flutter') {
          expect(t, contains('--debug'));
          expect(t, contains('DEBUG-non-distribuable'));
          expect(t, contains('sha256sum'));
          expect(t, contains('3.47.2'));
          expect(t, isNot(contains('--release')));
        }
      });
    }
  }

  test('version Flutter invalide remplacée ; combinaison inconnue', () {
    expect(ciTemplate('flutter', 'github', flutterVersion: '3.x; rm -rf /'), isNot(contains('rm -rf')));
    expect(ciTemplate('cobol', 'github'), isNull);
    expect(ciFileName('github'), '.github/workflows/ci.yml');
  });
}
