import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/state_views.dart';
import '../domain/course.dart';
import 'academy_providers.dart';
import 'widgets/course_view.dart';
import 'widgets/exercise_view.dart';
import 'widgets/quiz_view.dart';

class LessonScreen extends ConsumerWidget {
  const LessonScreen({super.key, required this.moduleId, required this.lessonId});

  final String moduleId;
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(courseProvider(moduleId)).when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(error: e),
          data: (m) {
            final lesson = m.lesson(lessonId);
            if (lesson == null) {
              return ErrorView(error: 'Leçon introuvable : $lessonId');
            }
            return _LessonBody(key: ValueKey(lessonId), module: m, lesson: lesson);
          },
        );
  }
}

class _LessonBody extends ConsumerStatefulWidget {
  const _LessonBody({super.key, required this.module, required this.lesson});

  final CourseModule module;
  final Lesson lesson;

  @override
  ConsumerState<_LessonBody> createState() => _LessonBodyState();
}

class _LessonBodyState extends ConsumerState<_LessonBody> {
  @override
  void initState() {
    super.initState();
    // Ouverture = leçon commencée + point de reprise.
    Future.microtask(() =>
        ref.read(progressRepositoryProvider).markStarted(widget.module.id, widget.lesson.id));
  }

  Lesson? get _next {
    final ls = widget.module.lessons;
    final i = ls.indexOf(widget.lesson);
    return i + 1 < ls.length ? ls[i + 1] : null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final lesson = widget.lesson;
    final moduleId = widget.module.id;
    final row = ref.watch(moduleProgressProvider(moduleId)).value?[lesson.id];
    final hasExercise = lesson.exercise != null;
    final done = row?.completedAt != null;
    final next = _next;
    final wide = MediaQuery.sizeOf(context).width >= CambuseBreakpoints.rail;
    final hint = Text(
      hasExercise ? l.lessonCompleteHint : l.lessonCompleteHintNoEx,
      style: TextStyle(color: p.textSecondary),
    );
    final nextButton = next == null
        ? null
        : Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.pushReplacement('/academie/$moduleId/lecon/${next.id}'),
              icon: const Icon(Icons.arrow_forward),
              label: Text('${l.lessonNext} : ${next.title}'),
            ),
          );

    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: lesson.title,
            subtitle: [
              l.lessonMinutes(lesson.minutes),
              if (row != null && row.quizAttempts > 0) l.bestScore(row.bestScore),
            ].join(' · '),
            trailing: done
                ? Chip(
                    avatar: Icon(Icons.check_circle, color: p.turquoise),
                    label: Text(l.lessonValidated),
                  )
                : null,
          ),
          TabBar(
            labelColor: p.gold,
            unselectedLabelColor: p.textSecondary,
            indicatorColor: p.copper,
            // Icônes seulement sur grand écran : sur téléphone, chaque pixel
            // vertical compte pour le contenu.
            tabs: [
              Tab(icon: wide ? const Icon(Icons.menu_book) : null, text: l.lessonTabCourse),
              Tab(
                icon: wide
                    ? Icon(row?.exerciseDone == true ? Icons.check_circle : Icons.terminal)
                    : null,
                text: row?.exerciseDone == true ? '${l.lessonTabExercise} ✓' : l.lessonTabExercise,
              ),
              Tab(icon: wide ? const Icon(Icons.quiz) : null, text: l.lessonTabQuiz),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                CourseView(lesson: lesson, footer: nextButton),
                hasExercise
                    ? ExerciseView(
                        exercise: lesson.exercise!,
                        alreadyDone: row?.exerciseDone ?? false,
                        onCompleted: () => ref
                            .read(progressRepositoryProvider)
                            .markExerciseDone(moduleId, lesson.id, hasExercise: true),
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(CambuseSpacing.lg),
                          child: Text(l.lessonNoExercise, textAlign: TextAlign.center),
                        ),
                      ),
                QuizView(
                  questions: lesson.quiz,
                  header: hint,
                  resultFooter: nextButton,
                  onFinished: (answers) => ref.read(progressRepositoryProvider).recordQuiz(
                        moduleId,
                        lesson.id,
                        answers: answers,
                        hasExercise: hasExercise,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
