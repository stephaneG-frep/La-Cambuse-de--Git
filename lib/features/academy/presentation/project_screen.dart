import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/progress_repository.dart';
import '../domain/course.dart';
import 'academy_providers.dart';
import 'widgets/exercise_view.dart';

class ProjectScreen extends ConsumerWidget {
  const ProjectScreen({super.key, required this.moduleId});

  final String moduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(courseProvider(moduleId)).when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(error: e),
          data: (m) => _ProjectBody(module: m),
        );
  }
}

class _ProjectBody extends ConsumerWidget {
  const _ProjectBody({required this.module});

  final CourseModule module;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final progress = ref.watch(projectProgressProvider(module.id));
    final project = module.project;

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(title: project.title, subtitle: l.projectTitle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CambuseSpacing.md),
            child: Text(project.brief),
          ),
          TabBar(
            labelColor: p.gold,
            unselectedLabelColor: p.textSecondary,
            indicatorColor: p.copper,
            tabs: [
              Tab(icon: const Icon(Icons.terminal), text: l.lessonTabExercise),
              Tab(icon: const Icon(Icons.grading), text: l.projectRubric),
            ],
          ),
          Expanded(
            child: progress.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(error: e),
              data: (row) => TabBarView(children: [
                ExerciseView(
                  exercise: project.exercise,
                  alreadyDone: row?.exerciseCompletedAt != null,
                  onCompleted: () =>
                      ref.read(progressRepositoryProvider).markProjectExercise(module.id),
                ),
                row?.exerciseCompletedAt == null
                    ? EmptyView(message: l.projectExerciseFirst, icon: Icons.lock_outline)
                    : _RubricForm(
                        moduleId: module.id,
                        rubric: project.rubric,
                        initial: ProgressRepository.decodeRubric(row!.rubricJson),
                      ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _RubricForm extends ConsumerStatefulWidget {
  const _RubricForm({required this.moduleId, required this.rubric, required this.initial});

  final String moduleId;
  final List<RubricCriterion> rubric;
  final Map<String, int> initial;

  @override
  ConsumerState<_RubricForm> createState() => _RubricFormState();
}

class _RubricFormState extends ConsumerState<_RubricForm> {
  late final Map<String, int> _levels = Map.of(widget.initial);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final complete = widget.rubric.every((c) => _levels.containsKey(c.criterion));
    return ListView(
      padding: const EdgeInsets.all(CambuseSpacing.md),
      children: [
        for (final c in widget.rubric)
          Card(
            margin: const EdgeInsets.only(bottom: CambuseSpacing.md),
            child: Padding(
              padding: const EdgeInsets.all(CambuseSpacing.md),
              child: RadioGroup<int>(
                groupValue: _levels[c.criterion],
                onChanged: (v) => setState(() => _levels[c.criterion] = v!),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.criterion, style: Theme.of(context).textTheme.titleMedium),
                    for (final (i, level) in c.levels.indexed)
                      RadioListTile<int>(
                        value: i,
                        contentPadding: EdgeInsets.zero,
                        title: Text(level),
                        subtitle: Text('${i + 1} / ${c.levels.length}',
                            style: TextStyle(color: p.textSecondary)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        FilledButton.icon(
          onPressed: complete
              ? () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await ref
                      .read(progressRepositoryProvider)
                      .submitRubric(widget.moduleId, Map.of(_levels));
                  messenger.showSnackBar(SnackBar(content: Text(l.projectSaved)));
                }
              : null,
          icon: const Icon(Icons.save),
          label: Text(l.projectSubmit),
        ),
      ],
    );
  }
}
