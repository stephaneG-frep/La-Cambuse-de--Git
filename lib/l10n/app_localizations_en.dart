// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'La Cambuse de Git';

  @override
  String get navBridge => 'Bridge';

  @override
  String get navAcademy => 'Academy';

  @override
  String get navWorkshop => 'Workshop';

  @override
  String get navCaptain => 'Captain';

  @override
  String get navLogbook => 'Logbook';

  @override
  String get navSettings => 'Settings';

  @override
  String get bridgeTitle => 'The ship\'s bridge';

  @override
  String bridgeWelcome(String name) {
    return 'Welcome aboard, $name!';
  }

  @override
  String get createProfileTitle => 'Create your sailor profile';

  @override
  String get createProfileHint => 'Your name or nickname';

  @override
  String get createProfileAction => 'Come aboard';

  @override
  String get createProfileInvalid => 'Between 1 and 40 characters.';

  @override
  String get profileLocalNote =>
      'Profile stored only on this device. No data is sent.';

  @override
  String bridgeLogbookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count logbook entries',
      one: '1 logbook entry',
      zero: 'No logbook entries',
    );
    return '$_temp0';
  }

  @override
  String get sectionAcademyDesc =>
      'Learn Git, GitHub, GitLab, Docker and DevOps from zero to expert.';

  @override
  String get sectionWorkshopDesc =>
      'Import a project, audit it without changing it, and prepare Git and CI.';

  @override
  String get sectionCaptainDesc =>
      'Supervised orchestration: plan, approvals, pause and emergency stop.';

  @override
  String get openSection => 'Open';

  @override
  String get plannedPhaseTitle => 'Under construction';

  @override
  String plannedPhaseBody(int phase) {
    return 'This section will ship in phase $phase of the roadmap. Nothing is simulated here.';
  }

  @override
  String get logbookTitle => 'Logbook';

  @override
  String get logbookEmpty => 'The logbook is empty.';

  @override
  String get logbookFilterAll => 'All';

  @override
  String get logbookExport => 'Copy as JSON';

  @override
  String logbookExported(int count) {
    return 'Logbook copied to clipboard ($count entries).';
  }

  @override
  String get logbookClear => 'Clear logbook';

  @override
  String get logbookClearConfirmTitle => 'Clear the logbook?';

  @override
  String logbookClearConfirmBody(int count) {
    return '$count entries will be permanently deleted from this device. An entry recording the deletion will be kept.';
  }

  @override
  String logbookCleared(int count) {
    return '$count entries cleared.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get confirmDelete => 'Delete permanently';

  @override
  String get outcomeSuccess => 'Success';

  @override
  String get outcomeFailure => 'Failure';

  @override
  String get outcomeInfo => 'Info';

  @override
  String get outcomeCancelled => 'Cancelled';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTextScale => 'Text size';

  @override
  String get settingsReduceMotion => 'Reduce motion';

  @override
  String get settingsReduceMotionDesc =>
      'Turns off transitions and decorative animations.';

  @override
  String get settingsHighContrast => 'High contrast';

  @override
  String get settingsHighContrastDesc =>
      'Darker background, brighter text, thicker borders.';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';

  @override
  String errorGeneric(String message) {
    return 'An error occurred: $message';
  }

  @override
  String get loading => 'Loading…';

  @override
  String get shortcutsHint =>
      'Keyboard shortcuts: Ctrl+1 to Ctrl+5 to switch sections, Ctrl+, for settings.';

  @override
  String get academyTitle => 'Island map';

  @override
  String get academySubtitle =>
      'Each island is a module. Islands in the mist will arrive in a later phase.';

  @override
  String get academySearch => 'Search';

  @override
  String get academyGlossary => 'Glossary';

  @override
  String get academyReviews => 'Reviews';

  @override
  String reviewsDue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews due',
      one: '1 review due',
      zero: 'No reviews due',
    );
    return '$_temp0';
  }

  @override
  String get islandAvailable => 'Available offline';

  @override
  String islandPlanned(int phase) {
    return 'In the mist — planned for phase $phase';
  }

  @override
  String get moduleObjectives => 'Objectives';

  @override
  String get modulePrerequisites => 'Prerequisites';

  @override
  String get moduleLessons => 'Lessons';

  @override
  String get moduleProgress => 'Module progress';

  @override
  String get moduleComplete => 'Module complete! Well done, sailor.';

  @override
  String lessonMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get lessonStatusDone => 'Passed';

  @override
  String get lessonStatusStarted => 'Started';

  @override
  String get lessonStatusNew => 'New';

  @override
  String get lessonTabCourse => 'Lesson';

  @override
  String get lessonTabExercise => 'Exercise';

  @override
  String get lessonTabQuiz => 'Quiz';

  @override
  String get lessonObjectives =>
      'By the end of this lesson, you will be able to:';

  @override
  String get lessonNoExercise =>
      'No simulator exercise for this lesson: it is practised on a real disposable repository in the Workshop (phase 5).';

  @override
  String get lessonNext => 'Next lesson';

  @override
  String get lessonCompleteHint =>
      'To pass the lesson: quiz ≥ 70% and exercise completed.';

  @override
  String get lessonCompleteHintNoEx => 'To pass the lesson: quiz ≥ 70%.';

  @override
  String get lessonValidated => 'Lesson passed';

  @override
  String bestScore(int score) {
    return 'Best score: $score%';
  }

  @override
  String get sandboxBanner =>
      'Teaching simulator: no real command is executed, no file is touched.';

  @override
  String get sandboxInputHint => 'Type a command (e.g. git status)';

  @override
  String get sandboxRun => 'Run';

  @override
  String get sandboxReset => 'Start over';

  @override
  String get sandboxHint => 'Hint';

  @override
  String get sandboxSolution => 'Solution';

  @override
  String exerciseStep(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get exerciseDone => 'Exercise complete! Mousse Byte is proud of you.';

  @override
  String quizQuestion(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String get quizValidate => 'Check';

  @override
  String get quizNext => 'Next question';

  @override
  String get quizFinish => 'See result';

  @override
  String get quizCorrect => 'Correct!';

  @override
  String get quizWrong => 'Not quite.';

  @override
  String get quizMultipleHint => 'Several answers possible.';

  @override
  String get quizCommandHint => 'Type the command';

  @override
  String quizResult(int score) {
    return 'Score: $score%';
  }

  @override
  String get quizPassed => 'Quiz passed.';

  @override
  String get quizFailed =>
      'You need 70% to pass. Review the lesson and try again!';

  @override
  String get quizRetry => 'Retake the quiz';

  @override
  String expectedAnswer(String answer) {
    return 'Expected answer: $answer';
  }

  @override
  String get reviewsTitle => 'Today\'s reviews';

  @override
  String get reviewsEmpty =>
      'No reviews due now. Questions come back with spaced repetition (1, 2, 4, 8 then 16 days).';

  @override
  String get reviewsDone => 'Reviews done: see you tomorrow!';

  @override
  String get glossaryTitle => 'Glossary';

  @override
  String get searchHint => 'Search a lesson or a term';

  @override
  String get searchNoResult => 'No results.';

  @override
  String get searchLessons => 'Lessons';

  @override
  String get searchGlossary => 'Glossary';

  @override
  String get projectTitle => 'Final project';

  @override
  String get projectRubric => 'Self-assessment rubric';

  @override
  String get projectSubmit => 'Save my assessment';

  @override
  String get projectSaved => 'Assessment saved.';

  @override
  String get projectExerciseFirst =>
      'Complete the project in the simulator first to unlock the rubric.';

  @override
  String get projectDone => 'Project completed';

  @override
  String resumeLesson(String title) {
    return 'Resume: $title';
  }

  @override
  String get academyProgressTitle => 'Your progress';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsProfileRename => 'Rename';

  @override
  String get settingsProfileSaved => 'Profile renamed.';

  @override
  String get contentLanguageNote =>
      'Course content is currently in French only.';
}
