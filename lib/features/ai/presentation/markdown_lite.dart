import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../../app/theme/tokens.dart';

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


/// Rendu du Markdown simplifié (titres, paragraphes, puces, code). Rien n'est
/// cliquable : aucun lien n'est ouvert depuis un texte rendu. [plain] affiche
/// le texte brut (messages de l'apprenant).
class MarkdownLiteView extends StatelessWidget {
  const MarkdownLiteView({super.key, required this.text, this.plain = false, this.muted = false, this.selectable = true});
  final String text;
  final bool plain;
  final bool muted;

  /// Texte sélectionnable (chat). Dans un document de lecture, seul le code
  /// reste sélectionnable (pour copier une commande), avec une cible ≥ 48 dp.
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final p = CambuseTheme.of(context);
    final base = TextStyle(height: 1.4, color: muted ? p.textSecondary : p.text);
    final children = <Widget>[];
    Widget rich(TextSpan span) => selectable ? SelectableText.rich(span) : Text.rich(span);
    final blocks = plain ? [MdParagraph(text)] : parseMarkdownLite(text);
    for (final b in blocks) {
      switch (b) {
        case MdCode(:final code):
          children.add(Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: CambuseSpacing.minTouchTarget),
            margin: const EdgeInsets.symmetric(vertical: CambuseSpacing.xs),
            padding: const EdgeInsets.all(CambuseSpacing.sm),
            decoration: BoxDecoration(
              color: p.night,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: p.turquoise.withValues(alpha: 0.5)),
            ),
            child: SelectableText(code, style: TextStyle(fontFamily: 'monospace', color: p.turquoise)),
          ));
        case MdHeading(:final text, :final level):
          children.add(Padding(
            padding: const EdgeInsets.only(top: CambuseSpacing.sm, bottom: CambuseSpacing.xs),
            child: Semantics(
              header: true,
              child: rich(TextSpan(
                  children: inlineSpans(
                      text, base.copyWith(color: p.gold, fontWeight: FontWeight.w700, fontSize: level <= 2 ? 19 : 17), p.turquoise))),
            ),
          ));
        case MdBullet(:final text, :final marker):
          children.add(Padding(
            padding: const EdgeInsets.only(left: CambuseSpacing.sm, bottom: CambuseSpacing.xs),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 22, child: Text(marker, style: base.copyWith(color: p.copper))),
              Expanded(child: rich(TextSpan(children: inlineSpans(text, base, p.turquoise)))),
            ]),
          ));
        case MdParagraph(:final text):
          children.add(Padding(
            padding: const EdgeInsets.only(bottom: CambuseSpacing.xs),
            child: plain
                ? (selectable ? SelectableText(text, style: base) : Text(text, style: base))
                : rich(TextSpan(children: inlineSpans(text, base, p.turquoise))),
          ));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}
