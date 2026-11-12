import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/features/logbook/data/logbook_repository.dart';
import 'package:la_cambuse/features/profile/data/profile_repository.dart';

import '../helpers.dart';

void main() {
  test('validation du nom', () {
    expect(ProfileRepository.validate('  Jack   Rackham '), 'Jack Rackham');
    expect(() => ProfileRepository.validate('   '), throwsA(isA<InvalidProfileName>()));
    expect(() => ProfileRepository.validate('x' * 41), throwsA(isA<InvalidProfileName>()));
  });

  test('création puis renommage : un seul profil, deux entrées au journal', () async {
    final db = memoryDb();
    final logbook = LogbookRepository(db);
    final repo = ProfileRepository(db, logbook);
    expect(await repo.current(), isNull);
    await repo.save('Mary');
    await repo.save('Mary Read');
    expect((await db.select(db.profiles).get()).single.displayName, 'Mary Read');
    final actions = (await logbook.watch().first).map((e) => e.action);
    expect(actions, ['Profil renommé', 'Profil créé']);
    await db.close();
  });
}
