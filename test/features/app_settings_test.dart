import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/features/settings/domain/app_settings.dart';

void main() {
  test('aller-retour toMap/fromMap', () {
    const s = AppSettings(textScale: 1.5, reduceMotion: true, highContrast: true, languageCode: 'en');
    expect(AppSettings.fromMap(s.toMap()), s);
  });

  test('valeurs corrompues → valeurs par défaut', () {
    final s = AppSettings.fromMap({
      'text_scale': 'NaN',
      'reduce_motion': 'peut-être',
      'language': 'klingon',
    });
    expect(s, AppSettings.defaults);
  });

  test("l'échelle de texte est bornée", () {
    expect(AppSettings.fromMap({'text_scale': '9'}).textScale, AppSettings.maxTextScale);
    expect(AppSettings.defaults.copyWith(textScale: 0.1).textScale, AppSettings.minTextScale);
  });
}
