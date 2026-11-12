import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/features/ai/presentation/markdown_lite.dart';

void main() {
  test('titres, listes, code, paragraphes', () {
    final blocks = parseMarkdownLite('''Ohé, matelot !
Suite du paragraphe.

### 🛠️ Git, l'outil
- **Créé par Linus Torvalds en 2005**
1. premier
---
```bash
git init
```''');
    expect(blocks[0], isA<MdParagraph>().having((b) => b.text, 'text', 'Ohé, matelot ! Suite du paragraphe.'));
    expect(blocks[1], isA<MdHeading>().having((b) => b.level, 'level', 3));
    expect(blocks[2], isA<MdBullet>().having((b) => b.text, 'text', '**Créé par Linus Torvalds en 2005**'));
    expect(blocks[3], isA<MdBullet>().having((b) => b.marker, 'marker', '1.'));
    expect(blocks[4], isA<MdCode>().having((b) => b.code, 'code', 'git init'));
    expect(blocks, hasLength(5));
  });

  test('gras, italique et code en ligne sans symboles résiduels', () {
    final span = inlineSpans('**Git** est *distribué* : `git status`', const TextStyle(), Colors.cyan).single as TextSpan;
    final plain = span.toPlainText();
    expect(plain, 'Git est distribué : git status');
    final parts = span.children!.cast<TextSpan>();
    expect(parts.first.style!.fontWeight, FontWeight.w700);
    expect(parts.last.style!.fontFamily, 'monospace');
  });

  test('un astérisque isolé ou une multiplication reste du texte', () {
    final span = inlineSpans('2 * 3 = 6 et *.log', const TextStyle(), Colors.cyan).single as TextSpan;
    expect(span.toPlainText(), '2 * 3 = 6 et *.log');
  });

  test('clôture de code en milieu de ligne', () {
    final blocks = parseMarkdownLite('Voici : ```\ngit status\n```');
    expect(blocks.last, isA<MdCode>().having((b) => b.code, 'code', 'git status'));
  });
}
