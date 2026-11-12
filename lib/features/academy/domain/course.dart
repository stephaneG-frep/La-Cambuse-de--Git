/// Modèle du contenu pédagogique embarqué (assets/courses/*.json).
///
/// La lecture est stricte : un contenu invalide lève une [FormatException]
/// explicite plutôt que d'afficher une leçon tronquée.
library;

T _req<T>(Map<String, dynamic> j, String key, String ctx) {
  final v = j[key];
  if (v is! T) throw FormatException('$ctx : champ « $key » manquant ou invalide');
  return v;
}

List<String> _strings(Map<String, dynamic> j, String key, String ctx, {bool optional = false}) {
  final v = j[key];
  if (v == null && optional) return const [];
  if (v is! List) throw FormatException('$ctx : liste « $key » manquante');
  return v.cast<String>();
}

List<Map<String, dynamic>> _maps(Map<String, dynamic> j, String key, String ctx,
    {bool optional = false}) {
  final v = j[key];
  if (v == null && optional) return const [];
  if (v is! List) throw FormatException('$ctx : liste « $key » manquante');
  return v.cast<Map<String, dynamic>>();
}

enum SectionKind { text, code, tip, warning }

class LessonSection {
  const LessonSection(this.kind, this.body, {this.caption});

  factory LessonSection.fromJson(Map<String, dynamic> j, String ctx) {
    final kind = SectionKind.values.firstWhere(
      (k) => k.name == j['type'],
      orElse: () => throw FormatException('$ctx : type de section inconnu ${j['type']}'),
    );
    return LessonSection(kind, _req<String>(j, 'body', ctx), caption: j['caption'] as String?);
  }

  final SectionKind kind;
  final String body;
  final String? caption;
}

enum QuestionKind { single, multiple, command }

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.kind,
    required this.prompt,
    required this.choices,
    required this.answers,
    required this.accepted,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> j, String ctx) {
    final id = _req<String>(j, 'id', ctx);
    final c = '$ctx/$id';
    final kind = QuestionKind.values.firstWhere(
      (k) => k.name == j['type'],
      orElse: () => throw FormatException('$c : type de question inconnu'),
    );
    final choices = _strings(j, 'choices', c, optional: true);
    final answers = ((j['answer'] as List?) ?? const []).cast<int>();
    final accepted = _strings(j, 'accepted', c, optional: true);
    if (kind == QuestionKind.command) {
      if (accepted.isEmpty) throw FormatException('$c : aucune réponse acceptée');
    } else {
      if (choices.length < 2) throw FormatException('$c : au moins 2 choix requis');
      if (answers.isEmpty || answers.any((a) => a < 0 || a >= choices.length)) {
        throw FormatException('$c : index de bonne réponse invalide');
      }
      if (kind == QuestionKind.single && answers.length != 1) {
        throw FormatException('$c : une seule bonne réponse attendue');
      }
    }
    final explanation = _req<String>(j, 'explanation', c);
    if (explanation.trim().length < 20) {
      throw FormatException('$c : explication trop courte');
    }
    return QuizQuestion(
      id: id,
      kind: kind,
      prompt: _req<String>(j, 'prompt', c),
      choices: choices,
      answers: answers.toSet(),
      accepted: accepted,
      explanation: explanation,
    );
  }

  final String id;
  final QuestionKind kind;
  final String prompt;
  final List<String> choices;
  final Set<int> answers;
  final List<String> accepted;
  final String explanation;

  /// Normalise une commande saisie : espaces, guillemets typographiques.
  static String normalizeCommand(String s) => s
      .trim()
      .replaceAll(RegExp('[«»“”]'), '"')
      .replaceAll(RegExp('[‘’]'), "'")
      .replaceAll("'", '"')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^\$ '), '');

  bool isCorrectChoice(Set<int> selected) =>
      selected.length == answers.length && selected.containsAll(answers);

  bool isCorrectCommand(String input) {
    final n = normalizeCommand(input);
    return accepted.any((a) => normalizeCommand(a) == n);
  }
}

/// Objectif vérifiable sur l'état du bac à sable.
class Goal {
  const Goal(this.type, this.params);

  factory Goal.fromJson(Map<String, dynamic> j, String ctx) {
    final type = _req<String>(j, 'type', ctx);
    return Goal(type, Map<String, dynamic>.of(j)..remove('type'));
  }

  final String type;
  final Map<String, dynamic> params;

  String param(String k) => params[k] as String;
}

class ExerciseStep {
  const ExerciseStep({
    required this.instruction,
    required this.hint,
    required this.solution,
    required this.goals,
  });

  factory ExerciseStep.fromJson(Map<String, dynamic> j, String ctx) => ExerciseStep(
        instruction: _req<String>(j, 'instruction', ctx),
        hint: _req<String>(j, 'hint', ctx),
        solution: _strings(j, 'solution', ctx),
        goals: [for (final g in _maps(j, 'goals', ctx)) Goal.fromJson(g, ctx)],
      );

  final String instruction;
  final String hint;
  final List<String> solution;
  final List<Goal> goals;
}

class Exercise {
  const Exercise({required this.intro, required this.setup, required this.steps});

  factory Exercise.fromJson(Map<String, dynamic> j, String ctx) {
    final steps = [
      for (final (i, s) in _maps(j, 'steps', ctx).indexed)
        ExerciseStep.fromJson(s, '$ctx/étape ${i + 1}'),
    ];
    if (steps.isEmpty) throw FormatException('$ctx : exercice sans étape');
    return Exercise(
      intro: _req<String>(j, 'intro', ctx),
      setup: _strings(j, 'setup', ctx, optional: true),
      steps: steps,
    );
  }

  final String intro;
  final List<String> setup;
  final List<ExerciseStep> steps;
}

class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.minutes,
    required this.objectives,
    required this.sections,
    required this.exercise,
    required this.quiz,
  });

  factory Lesson.fromJson(Map<String, dynamic> j, String ctx) {
    final id = _req<String>(j, 'id', ctx);
    final c = '$ctx/$id';
    final quiz = [for (final q in _maps(j, 'quiz', c)) QuizQuestion.fromJson(q, c)];
    if (quiz.length < 4) throw FormatException('$c : au moins 4 questions de quiz');
    final ex = j['exercise'];
    return Lesson(
      id: id,
      title: _req<String>(j, 'title', c),
      minutes: _req<int>(j, 'minutes', c),
      objectives: _strings(j, 'objectives', c),
      sections: [for (final s in _maps(j, 'sections', c)) LessonSection.fromJson(s, c)],
      exercise: ex == null ? null : Exercise.fromJson(ex as Map<String, dynamic>, '$c/exercice'),
      quiz: quiz,
    );
  }

  final String id;
  final String title;
  final int minutes;
  final List<String> objectives;
  final List<LessonSection> sections;
  final Exercise? exercise;
  final List<QuizQuestion> quiz;

  /// Texte brut pour la recherche.
  String get searchText => [
        title,
        ...objectives,
        for (final s in sections) s.body,
      ].join('\n').toLowerCase();
}

class RubricCriterion {
  const RubricCriterion(this.criterion, this.levels);

  factory RubricCriterion.fromJson(Map<String, dynamic> j, String ctx) {
    final levels = _strings(j, 'levels', ctx);
    if (levels.length < 2) throw FormatException('$ctx : au moins 2 niveaux par critère');
    return RubricCriterion(_req<String>(j, 'criterion', ctx), levels);
  }

  final String criterion;

  /// Du plus faible au plus fort.
  final List<String> levels;
}

class FinalProject {
  const FinalProject({
    required this.title,
    required this.brief,
    required this.exercise,
    required this.rubric,
  });

  factory FinalProject.fromJson(Map<String, dynamic> j, String ctx) => FinalProject(
        title: _req<String>(j, 'title', ctx),
        brief: _req<String>(j, 'brief', ctx),
        exercise: Exercise.fromJson(_req<Map<String, dynamic>>(j, 'exercise', ctx), '$ctx/exercice'),
        rubric: [for (final r in _maps(j, 'rubric', ctx)) RubricCriterion.fromJson(r, ctx)],
      );

  final String title;
  final String brief;
  final Exercise exercise;
  final List<RubricCriterion> rubric;
}

class GlossaryEntry {
  const GlossaryEntry(this.term, this.definition);
  final String term;
  final String definition;
}

class CourseModule {
  const CourseModule({
    required this.id,
    required this.title,
    required this.summary,
    required this.version,
    required this.objectives,
    required this.prerequisites,
    required this.lessons,
    required this.project,
    required this.glossary,
  });

  factory CourseModule.fromJson(Map<String, dynamic> j) {
    final id = _req<String>(j, 'id', 'module');
    final lessons = [for (final l in _maps(j, 'lessons', id)) Lesson.fromJson(l, id)];
    final ids = <String>{};
    for (final l in lessons) {
      if (!ids.add(l.id)) throw FormatException('$id : identifiant de leçon dupliqué ${l.id}');
    }
    final qids = <String>{};
    for (final q in lessons.expand((l) => l.quiz)) {
      if (!qids.add(q.id)) throw FormatException('$id : identifiant de question dupliqué ${q.id}');
    }
    return CourseModule(
      id: id,
      title: _req<String>(j, 'title', id),
      summary: _req<String>(j, 'summary', id),
      version: _req<int>(j, 'version', id),
      objectives: _strings(j, 'objectives', id),
      prerequisites: _strings(j, 'prerequisites', id),
      lessons: lessons,
      project: FinalProject.fromJson(_req<Map<String, dynamic>>(j, 'project', id), '$id/projet'),
      glossary: [
        for (final g in _maps(j, 'glossary', id))
          GlossaryEntry(_req<String>(g, 'term', id), _req<String>(g, 'definition', id)),
      ]..sort((a, b) => a.term.toLowerCase().compareTo(b.term.toLowerCase())),
    );
  }

  final String id;
  final String title;
  final String summary;
  final int version;
  final List<String> objectives;
  final List<String> prerequisites;
  final List<Lesson> lessons;
  final FinalProject project;
  final List<GlossaryEntry> glossary;

  Lesson? lesson(String lessonId) => lessons.where((l) => l.id == lessonId).firstOrNull;

  QuizQuestion? question(String questionId) =>
      lessons.expand((l) => l.quiz).where((q) => q.id == questionId).firstOrNull;
}
