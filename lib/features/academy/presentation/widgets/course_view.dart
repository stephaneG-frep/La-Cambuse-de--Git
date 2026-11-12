import 'package:flutter/material.dart';

import '../../../../app/theme/theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/course.dart';

/// Rendu du contenu d'une leçon : texte, code, astuce, avertissement.
class CourseView extends StatelessWidget {
  const CourseView({super.key, required this.lesson, this.footer});

  final Lesson lesson;

  /// Affiché après le contenu (ex. lien vers la leçon suivante).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    return ListView(
      padding: const EdgeInsets.all(CambuseSpacing.md),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(CambuseSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.lessonObjectives, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: CambuseSpacing.sm),
                for (final o in lesson.objectives)
                  Padding(
                    padding: const EdgeInsets.only(bottom: CambuseSpacing.xs),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.check, size: 18, color: p.turquoise),
                      const SizedBox(width: CambuseSpacing.sm),
                      Expanded(child: Text(o)),
                    ]),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: CambuseSpacing.md),
        for (final s in lesson.sections) ...[
          SectionBlock(section: s),
          const SizedBox(height: CambuseSpacing.md),
        ],
        ?footer,
      ],
    );
  }
}

class SectionBlock extends StatelessWidget {
  const SectionBlock({super.key, required this.section});

  final LessonSection section;

  @override
  Widget build(BuildContext context) {
    final p = CambuseTheme.of(context);
    switch (section.kind) {
      case SectionKind.text:
        return Text(section.body, style: const TextStyle(height: 1.5));
      case SectionKind.code:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (section.caption != null)
              Padding(
                padding: const EdgeInsets.only(bottom: CambuseSpacing.xs),
                child: Text(section.caption!, style: TextStyle(color: p.textSecondary)),
              ),
            Container(
              padding: const EdgeInsets.all(CambuseSpacing.md),
              decoration: BoxDecoration(
                color: p.night,
                borderRadius: BorderRadius.circular(CambuseSpacing.radius / 2),
                border: Border.all(color: p.turquoise.withValues(alpha: 0.6)),
              ),
              child: SelectableText(
                section.body,
                style: TextStyle(fontFamily: 'monospace', color: p.turquoise, height: 1.4),
              ),
            ),
          ],
        );
      case SectionKind.tip:
      case SectionKind.warning:
        final warn = section.kind == SectionKind.warning;
        final color = warn ? p.alert : p.gold;
        return Container(
          padding: const EdgeInsets.all(CambuseSpacing.md),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(CambuseSpacing.radius / 2),
            border: Border(left: BorderSide(color: color, width: 5)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(warn ? Icons.warning_amber : Icons.lightbulb_outline,
                color: color, semanticLabel: warn ? 'Attention' : 'Astuce'),
            const SizedBox(width: CambuseSpacing.sm),
            Expanded(child: Text(section.body, style: const TextStyle(height: 1.4))),
          ]),
        );
    }
  }
}
