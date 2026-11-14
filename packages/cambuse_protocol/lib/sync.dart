/// Synchronisation explicite de la progression entre appareils, via le
/// compagnon. Seule la progression d'apprentissage circule : ni conversations
/// IA, ni journal, ni secrets.
///
/// [mergeProgress] est commutative, associative et idempotente : l'ordre des
/// synchronisations n'a pas d'importance et rien n'est jamais perdu.
library;

DateTime? _dt(Object? v) => v == null ? null : DateTime.parse('$v').toUtc();
String? _iso(DateTime? d) => d?.toUtc().toIso8601String();

DateTime? _minDate(DateTime? a, DateTime? b) => a == null ? b : (b == null ? a : (a.isBefore(b) ? a : b));
DateTime? _maxDate(DateTime? a, DateTime? b) => a == null ? b : (b == null ? a : (a.isAfter(b) ? a : b));

class SyncLesson {
  const SyncLesson({
    required this.moduleId,
    required this.lessonId,
    required this.startedAt,
    this.completedAt,
    this.bestScore = 0,
    this.quizAttempts = 0,
    this.exerciseDone = false,
  });

  final String moduleId;
  final String lessonId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int bestScore;
  final int quizAttempts;
  final bool exerciseDone;

  String get key => '$moduleId/$lessonId';

  /// Une leçon terminée le reste ; meilleur score et exercice conservés.
  SyncLesson merge(SyncLesson o) => SyncLesson(
        moduleId: moduleId,
        lessonId: lessonId,
        startedAt: _minDate(startedAt, o.startedAt)!,
        completedAt: _minDate(completedAt, o.completedAt),
        bestScore: bestScore > o.bestScore ? bestScore : o.bestScore,
        quizAttempts: quizAttempts > o.quizAttempts ? quizAttempts : o.quizAttempts,
        exerciseDone: exerciseDone || o.exerciseDone,
      );

  Map<String, dynamic> toJson() => {
        'moduleId': moduleId,
        'lessonId': lessonId,
        'startedAt': _iso(startedAt),
        'completedAt': ?_iso(completedAt),
        'bestScore': bestScore,
        'quizAttempts': quizAttempts,
        'exerciseDone': exerciseDone,
      };

  factory SyncLesson.fromJson(Map<String, dynamic> j) => SyncLesson(
        moduleId: _str(j, 'moduleId'),
        lessonId: _str(j, 'lessonId'),
        startedAt: _dt(j['startedAt']) ?? (throw const FormatException('startedAt manquant')),
        completedAt: _dt(j['completedAt']),
        bestScore: _int(j['bestScore']),
        quizAttempts: _int(j['quizAttempts']),
        exerciseDone: j['exerciseDone'] == true,
      );
}

class SyncReview {
  const SyncReview({
    required this.questionId,
    required this.moduleId,
    required this.box,
    required this.dueAt,
    this.correctCount = 0,
    this.wrongCount = 0,
  });

  final String questionId;
  final String moduleId;
  final int box;
  final DateTime dueAt;
  final int correctCount;
  final int wrongCount;

  /// Nombre de révisions : croît à chaque passage, sert de version.
  int get reviews => correctCount + wrongCount;

  /// La carte qui a le plus d'historique l'emporte ; à égalité, choix
  /// déterministe (échéance puis boîte la plus haute).
  SyncReview merge(SyncReview o) {
    if (reviews != o.reviews) return reviews > o.reviews ? this : o;
    if (dueAt != o.dueAt) return dueAt.isAfter(o.dueAt) ? this : o;
    if (box != o.box) return box > o.box ? this : o;
    return correctCount >= o.correctCount ? this : o;
  }

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'moduleId': moduleId,
        'box': box,
        'dueAt': _iso(dueAt),
        'correctCount': correctCount,
        'wrongCount': wrongCount,
      };

  factory SyncReview.fromJson(Map<String, dynamic> j) => SyncReview(
        questionId: _str(j, 'questionId'),
        moduleId: _str(j, 'moduleId'),
        box: _int(j['box']).clamp(1, 10),
        dueAt: _dt(j['dueAt']) ?? (throw const FormatException('dueAt manquant')),
        correctCount: _int(j['correctCount']),
        wrongCount: _int(j['wrongCount']),
      );
}

class SyncProject {
  const SyncProject({required this.moduleId, this.exerciseCompletedAt, this.rubricJson = '{}', this.submittedAt});

  final String moduleId;
  final DateTime? exerciseCompletedAt;
  final String rubricJson;
  final DateTime? submittedAt;

  /// Exercice réussi conservé ; la soumission la plus récente l'emporte.
  SyncProject merge(SyncProject o) {
    final SyncProject newer;
    if (submittedAt != o.submittedAt) {
      newer = _maxDate(submittedAt, o.submittedAt) == submittedAt ? this : o;
    } else {
      newer = rubricJson.compareTo(o.rubricJson) >= 0 ? this : o;
    }
    return SyncProject(
      moduleId: moduleId,
      exerciseCompletedAt: _minDate(exerciseCompletedAt, o.exerciseCompletedAt),
      rubricJson: newer.rubricJson,
      submittedAt: _maxDate(submittedAt, o.submittedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'moduleId': moduleId,
        'exerciseCompletedAt': ?_iso(exerciseCompletedAt),
        'rubricJson': rubricJson,
        'submittedAt': ?_iso(submittedAt),
      };

  factory SyncProject.fromJson(Map<String, dynamic> j) => SyncProject(
        moduleId: _str(j, 'moduleId'),
        exerciseCompletedAt: _dt(j['exerciseCompletedAt']),
        rubricJson: j['rubricJson'] is String && (j['rubricJson'] as String).length <= 20000 ? j['rubricJson'] as String : '{}',
        submittedAt: _dt(j['submittedAt']),
      );
}

String _str(Map<String, dynamic> j, String k) {
  final v = j[k];
  if (v is! String || v.isEmpty || v.length > 200) throw FormatException('$k invalide');
  return v;
}

int _int(Object? v) => v is int && v >= 0 ? (v > 1000000 ? 1000000 : v) : 0;

/// Instantané de progression échangé avec le compagnon.
class ProgressSnapshot {
  const ProgressSnapshot({this.lessons = const [], this.reviews = const [], this.projects = const []});

  final List<SyncLesson> lessons;
  final List<SyncReview> reviews;
  final List<SyncProject> projects;

  static const maxItems = 20000;

  bool get isEmpty => lessons.isEmpty && reviews.isEmpty && projects.isEmpty;

  Map<String, dynamic> toJson() => {
        'format': 1,
        'lessons': [for (final l in lessons) l.toJson()],
        'reviews': [for (final r in reviews) r.toJson()],
        'projects': [for (final p in projects) p.toJson()],
      };

  /// Lecture stricte : une entrée invalide fait refuser tout l'instantané.
  factory ProgressSnapshot.fromJson(Map<String, dynamic> j) {
    List<Map<String, dynamic>> list(String k) {
      final v = j[k] ?? const [];
      if (v is! List || v.length > maxItems) throw FormatException('$k invalide');
      return [for (final e in v) (e as Map).cast<String, dynamic>()];
    }

    return ProgressSnapshot(
      lessons: [for (final e in list('lessons')) SyncLesson.fromJson(e)],
      reviews: [for (final e in list('reviews')) SyncReview.fromJson(e)],
      projects: [for (final e in list('projects')) SyncProject.fromJson(e)],
    );
  }
}

Map<String, T> _byKey<T>(Iterable<T> items, String Function(T) key, T Function(T, T) merge) {
  final out = <String, T>{};
  for (final i in items) {
    final k = key(i);
    out[k] = out.containsKey(k) ? merge(out[k] as T, i) : i;
  }
  return out;
}

/// Fusion sans perte de deux instantanés (ordre indifférent).
ProgressSnapshot mergeProgress(ProgressSnapshot a, ProgressSnapshot b) {
  final lessons = _byKey<SyncLesson>([...a.lessons, ...b.lessons], (l) => l.key, (x, y) => x.merge(y));
  final reviews = _byKey<SyncReview>([...a.reviews, ...b.reviews], (r) => r.questionId, (x, y) => x.merge(y));
  final projects = _byKey<SyncProject>([...a.projects, ...b.projects], (p) => p.moduleId, (x, y) => x.merge(y));
  List<T> sorted<T>(Map<String, T> m) => [for (final k in (m.keys.toList()..sort())) m[k] as T];
  return ProgressSnapshot(lessons: sorted(lessons), reviews: sorted(reviews), projects: sorted(projects));
}
