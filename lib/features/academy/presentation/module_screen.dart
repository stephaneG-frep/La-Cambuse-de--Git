import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/db/database.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/gauge_progress.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/state_views.dart';
import '../domain/course.dart';
import 'academy_providers.dart';

class ModuleScreen extends ConsumerWidget {
  const ModuleScreen({super.key, required this.moduleId});

  final String moduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(courseProvider(moduleId)).when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(error: e),
          data: (m) => _ModuleBody(module: m),
        );
  }
}

class _ModuleBody extends ConsumerWidget {
  const _ModuleBody({required this.module});

  final CourseModule module;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final text = Theme.of(context).textTheme;
    final progress = ref.watch(moduleProgressProvider(module.id)).value ?? const {};
    final stats = ref.watch(moduleStatsProvider(module.id));
    final project = ref.watch(projectProgressProvider(module.id)).value;

    Widget bullets(String title, List<String> items) => Card(
          child: Padding(
            padding: const EdgeInsets.all(CambuseSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium),
                const SizedBox(height: CambuseSpacing.sm),
                for (final i in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: CambuseSpacing.xs),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.anchor, size: 16, color: p.copper),
                      const SizedBox(width: CambuseSpacing.sm),
                      Expanded(child: Text(i)),
                    ]),
                  ),
              ],
            ),
          ),
        );

    return ListView(
      padding: const EdgeInsets.only(bottom: CambuseSpacing.xl),
      children: [
        PageHeader(title: module.title, subtitle: module.summary),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: CambuseSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (stats != null) ...[
                GaugeProgress(value: stats.ratio, label: l.moduleProgress),
                if (stats.isComplete)
                  Padding(
                    padding: const EdgeInsets.only(top: CambuseSpacing.sm),
                    child: Text(l.moduleComplete,
                        style: TextStyle(color: p.gold, fontWeight: FontWeight.w700)),
                  ),
              ],
              const SizedBox(height: CambuseSpacing.md),
              bullets(l.moduleObjectives, module.objectives),
              const SizedBox(height: CambuseSpacing.md),
              bullets(l.modulePrerequisites, module.prerequisites),
              const SizedBox(height: CambuseSpacing.md),
              Text(l.moduleLessons, style: text.titleLarge),
              const SizedBox(height: CambuseSpacing.sm),
              Card(
                child: Column(
                  children: [
                    for (final (i, lesson) in module.lessons.indexed) ...[
                      if (i > 0) const Divider(height: 1),
                      _LessonTile(
                        index: i + 1,
                        lesson: lesson,
                        progress: progress[lesson.id],
                        onTap: () => context.go('/academie/${module.id}/lecon/${lesson.id}'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: CambuseSpacing.md),
              Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(CambuseSpacing.md),
                  leading: Icon(Icons.flag, color: p.gold, size: 32),
                  title: Text('${l.projectTitle} — ${module.project.title}'),
                  subtitle: Text(
                    project?.submittedAt != null
                        ? l.lessonStatusDone
                        : project?.exerciseCompletedAt != null
                            ? l.projectDone
                            : l.lessonStatusNew,
                    style: TextStyle(color: p.textSecondary),
                  ),
                  trailing: Icon(Icons.chevron_right, color: p.turquoise),
                  onTap: () => context.go('/academie/${module.id}/projet'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.index,
    required this.lesson,
    required this.progress,
    required this.onTap,
  });

  final int index;
  final Lesson lesson;
  final LessonProgressRow? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final done = progress?.completedAt != null;
    final started = progress != null;
    final (icon, color, status) = done
        ? (Icons.check_circle, p.turquoise, l.lessonStatusDone)
        : started
            ? (Icons.timelapse, p.gold, l.lessonStatusStarted)
            : (Icons.radio_button_unchecked, p.textSecondary, l.lessonStatusNew);
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: p.night,
        foregroundColor: p.copper,
        child: Text('$index'),
      ),
      title: Text(lesson.title),
      subtitle: Text(
        [
          l.lessonMinutes(lesson.minutes),
          status,
          if (progress != null && progress!.quizAttempts > 0) l.bestScore(progress!.bestScore),
        ].join(' · '),
        style: TextStyle(color: p.textSecondary),
      ),
      trailing: Icon(icon, color: color, semanticLabel: status),
    );
  }
}
