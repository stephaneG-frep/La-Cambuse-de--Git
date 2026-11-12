import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import '../data/progress_repository.dart';
import '../domain/course.dart';

final progressRepositoryProvider = Provider(
  (ref) => ProgressRepository(ref.watch(databaseProvider), ref.watch(logbookRepositoryProvider)),
);

/// Chargeur de contenu, surchargeable dans les tests.
final courseLoaderProvider = Provider<Future<String> Function(String)>(
  (ref) => (id) => rootBundle.loadString('assets/courses/$id.json'),
);

/// Module embarqué : disponible hors ligne, validé à la lecture.
final courseProvider = FutureProvider.family<CourseModule, String>((ref, id) async {
  final raw = await ref.watch(courseLoaderProvider)(id);
  return CourseModule.fromJson(jsonDecode(raw) as Map<String, dynamic>);
});

final moduleProgressProvider = StreamProvider.family<Map<String, LessonProgressRow>, String>(
  (ref, moduleId) => ref.watch(progressRepositoryProvider).watchModule(moduleId),
);

final projectProgressProvider = StreamProvider.family<ProjectProgressRow?, String>(
  (ref, moduleId) => ref.watch(progressRepositoryProvider).watchProject(moduleId),
);

final dueCardsProvider = StreamProvider<List<ReviewCard>>(
  (ref) => ref.watch(progressRepositoryProvider).watchDue(DateTime.now()),
);

final lastLessonProvider = StreamProvider<(String, String)?>(
  (ref) => ref.watch(progressRepositoryProvider).watchLastLesson(),
);

/// Avancement d'un module : leçons validées + projet (évaluation enregistrée).
class ModuleStats {
  const ModuleStats(this.completedLessons, this.totalLessons, this.projectDone);

  final int completedLessons;
  final int totalLessons;
  final bool projectDone;

  double get ratio =>
      (completedLessons + (projectDone ? 1 : 0)) / (totalLessons + 1);
  bool get isComplete => completedLessons == totalLessons && projectDone;
}

final moduleStatsProvider = Provider.family<ModuleStats?, String>((ref, moduleId) {
  final course = ref.watch(courseProvider(moduleId)).value;
  final progress = ref.watch(moduleProgressProvider(moduleId)).value;
  final project = ref.watch(projectProgressProvider(moduleId));
  if (course == null || progress == null || project.isLoading) return null;
  final ids = course.lessons.map((l) => l.id).toSet();
  final done = progress.values.where((p) => p.completedAt != null && ids.contains(p.lessonId)).length;
  return ModuleStats(done, course.lessons.length, project.value?.submittedAt != null);
});
