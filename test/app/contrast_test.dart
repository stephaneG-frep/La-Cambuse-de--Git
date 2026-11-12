import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/app/theme/tokens.dart';

void main() {
  for (final (name, palette) in [
    ('standard', CambusePalette.standard),
    ('contraste renforcé', CambusePalette.highContrast),
  ]) {
    group('Palette $name — WCAG AA (≥ 4,5:1)', () {
      for (final (fg, color) in palette.foregrounds) {
        test('$fg sur fond nuit', () {
          expect(contrastRatio(color, palette.night), greaterThanOrEqualTo(4.5));
        });
        test('$fg sur surface', () {
          expect(contrastRatio(color, palette.surface), greaterThanOrEqualTo(4.5));
        });
      }
      test('texte des boutons (nuit sur cuivre)', () {
        expect(contrastRatio(palette.night, palette.copper), greaterThanOrEqualTo(4.5));
      });
    });
  }

  test('le contraste renforcé est au moins aussi contrasté que le standard', () {
    const s = CambusePalette.standard, h = CambusePalette.highContrast;
    expect(contrastRatio(h.text, h.night), greaterThanOrEqualTo(contrastRatio(s.text, s.night)));
    expect(contrastRatio(h.textSecondary, h.surface),
        greaterThanOrEqualTo(contrastRatio(s.textSecondary, s.surface)));
  });
}
