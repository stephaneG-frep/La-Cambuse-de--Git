import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/core/logging/redactor.dart';

void main() {
  const r = Redactor();

  final secrets = {
    'jeton GitHub classique': 'push avec ghp_${'a' * 36}',
    'jeton GitHub fine-grained': 'github_pat_${'B1' * 20}',
    'jeton GitLab': 'glpat-${'x' * 20}',
    'clé sk-': 'clé sk-ant-${'z' * 30}',
    'clé AWS': 'AKIAABCDEFGHIJKLMNOP',
    'en-tête Bearer': 'Authorization: Bearer abc.def.ghi123456',
    'affectation api_key': 'API_KEY="s3cr3tvaleur"',
    'mot de passe': 'password: hunter2xx',
    'URL avec identifiants': 'git clone https://moi:motdepasse@github.com/a/b.git',
    'clé privée': '-----BEGIN OPENSSH PRIVATE KEY-----\nabc\n-----END OPENSSH PRIVATE KEY-----',
  };

  secrets.forEach((name, input) {
    test('masque : $name', () {
      final out = r.redact(input);
      expect(out, contains(Redactor.mask));
      expect(r.containsSecret(input), isTrue);
    });
  });

  test('ne laisse aucune trace du jeton GitHub', () {
    final token = 'ghp_${'Q' * 36}';
    expect(r.redact('erreur: $token refusé'), isNot(contains(token)));
  });

  test("conserve l'hôte d'une URL à identifiants", () {
    expect(r.redact('https://u:p@gitlab.com/x'), 'https://${Redactor.mask}@gitlab.com/x');
  });

  test('laisse intact un texte sans secret', () {
    const text = 'git commit -m "Ajout du module tokenizer" sur main';
    expect(r.redact(text), text);
    expect(r.containsSecret(text), isFalse);
  });
}
