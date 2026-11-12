import 'package:flutter/material.dart';

/// Bloc Markdown simplifié.
sealed class MdBlock {
  const MdBlock();
}

class MdHeading extends MdBlock {
  const MdHeading(this.level, this.text);
  final int level;
  final String text;
}

class MdParagraph extends MdBlock {
  const MdParagraph(this.text);
  final String text;
}

class MdBullet extends MdBlock {
  const MdBullet(this.text, {this.marker = '•'});
  final String text;
  final String marker;
}

class MdCode extends MdBlock {
  const MdCode(this.code);
  final String code;
}

/// Analyse un sous-ensemble sûr du Markdown : titres `#`, listes `-`/`*`/`1.`,
/// blocs ``` et paragraphes. Aucun lien n'est rendu cliquable, aucun HTML
/// n'est interprété.
List<MdBlock> parseMarkdownLite(String source) {
  final out = <MdBlock>[];
  // Une clôture ``` en milieu de ligne ouvre/ferme quand même un bloc.
  final normalized = source.replaceAllMapped(RegExp(r'([^\n])```'), (m) => '${m[1]}\n```');
  final lines = normalized.split('\n');
  final para = <String>[];
  void flush() {
    if (para.isNotEmpty) {
      out.add(MdParagraph(para.join(' ').trim()));
      para.clear();
    }
  }

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final t = line.trimLeft();
    if (t.startsWith('```')) {
      flush();
      final code = <String>[];
      i++;
      while (i < lines.length && !lines[i].trimLeft().startsWith('```')) {
        code.add(lines[i]);
        i++;
      }
      out.add(MdCode(code.join('\n').trimRight()));
      continue;
    }
    final h = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(t);
    if (h != null) {
      flush();
      out.add(MdHeading(h.group(1)!.length, h.group(2)!.trim()));
      continue;
    }
    final b = RegExp(r'^[-*•]\s+(.*)$').firstMatch(t);
    if (b != null) {
      flush();
      out.add(MdBullet(b.group(1)!));
      continue;
    }
    final n = RegExp(r'^(\d+)[.)]\s+(.*)$').firstMatch(t);
    if (n != null) {
      flush();
      out.add(MdBullet(n.group(2)!, marker: '${n.group(1)}.'));
      continue;
    }
    if (t.isEmpty || RegExp(r'^(-{3,}|\*{3,})$').hasMatch(t)) {
      flush();
      continue;
    }
    para.add(t);
  }
  flush();
  return out;
}

/// Mise en forme en ligne : **gras**, *italique*, `code`.
List<InlineSpan> inlineSpans(String text, TextStyle base, Color codeColor) {
  final spans = <InlineSpan>[];
  final re = RegExp(r'\*\*(.+?)\*\*|`([^`]+)`|(?<![\w*])\*(?!\s)(.+?)(?<!\s)\*(?![\w*])');
  var last = 0;
  for (final m in re.allMatches(text)) {
    if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
    if (m.group(1) != null) {
      spans.add(TextSpan(text: m.group(1), style: const TextStyle(fontWeight: FontWeight.w700)));
    } else if (m.group(2) != null) {
      spans.add(TextSpan(
          text: m.group(2), style: TextStyle(fontFamily: 'monospace', color: codeColor)));
    } else {
      spans.add(TextSpan(text: m.group(3), style: const TextStyle(fontStyle: FontStyle.italic)));
    }
    last = m.end;
  }
  if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
  return [TextSpan(style: base, children: spans)];
}
