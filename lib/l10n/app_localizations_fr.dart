// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'La Cambuse de Git';

  @override
  String get navBridge => 'Pont';

  @override
  String get navAcademy => 'Académie';

  @override
  String get navWorkshop => 'Atelier';

  @override
  String get navCaptain => 'Capitaine';

  @override
  String get navLogbook => 'Journal';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get bridgeTitle => 'Le pont du navire';

  @override
  String bridgeWelcome(String name) {
    return 'Bienvenue à bord, $name !';
  }

  @override
  String get createProfileTitle => 'Créez votre profil de matelot';

  @override
  String get createProfileHint => 'Votre nom ou pseudonyme';

  @override
  String get createProfileAction => 'Embarquer';

  @override
  String get createProfileInvalid => 'Entre 1 et 40 caractères.';

  @override
  String get profileLocalNote =>
      'Profil stocké uniquement sur cet appareil. Aucune donnée n\'est envoyée.';

  @override
  String bridgeLogbookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entrées au journal',
      one: '1 entrée au journal',
      zero: 'Aucune entrée au journal',
    );
    return '$_temp0';
  }

  @override
  String get sectionAcademyDesc =>
      'Apprendre Git, GitHub, GitLab, Docker et DevOps de zéro à expert.';

  @override
  String get sectionWorkshopDesc =>
      'Importer un projet, l\'auditer sans le modifier et préparer Git et la CI.';

  @override
  String get sectionCaptainDesc =>
      'Orchestration supervisée : plan, validations, pause et arrêt d\'urgence.';

  @override
  String get openSection => 'Ouvrir';

  @override
  String get plannedPhaseTitle => 'En construction';

  @override
  String plannedPhaseBody(int phase) {
    return 'Cette section sera livrée en phase $phase de la feuille de route. Aucune fonctionnalité n\'est simulée ici.';
  }

  @override
  String get logbookTitle => 'Journal de bord';

  @override
  String get logbookEmpty => 'Le journal est vide.';

  @override
  String get logbookFilterAll => 'Toutes';

  @override
  String get logbookExport => 'Copier en JSON';

  @override
  String logbookExported(int count) {
    return 'Journal copié dans le presse-papiers ($count entrées).';
  }

  @override
  String get logbookClear => 'Effacer le journal';

  @override
  String get logbookClearConfirmTitle => 'Effacer le journal de bord ?';

  @override
  String logbookClearConfirmBody(int count) {
    return '$count entrées seront supprimées définitivement de cet appareil. Une entrée indiquant l\'effacement sera conservée.';
  }

  @override
  String logbookCleared(int count) {
    return '$count entrées effacées.';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get confirmDelete => 'Effacer définitivement';

  @override
  String get outcomeSuccess => 'Réussi';

  @override
  String get outcomeFailure => 'Échec';

  @override
  String get outcomeInfo => 'Info';

  @override
  String get outcomeCancelled => 'Annulé';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsTextScale => 'Taille du texte';

  @override
  String get settingsReduceMotion => 'Réduire les animations';

  @override
  String get settingsReduceMotionDesc =>
      'Désactive les transitions et animations décoratives.';

  @override
  String get settingsHighContrast => 'Contraste renforcé';

  @override
  String get settingsHighContrastDesc =>
      'Fond plus sombre, texte plus clair, bordures plus épaisses.';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';

  @override
  String errorGeneric(String message) {
    return 'Une erreur est survenue : $message';
  }

  @override
  String get loading => 'Chargement…';

  @override
  String get shortcutsHint =>
      'Raccourcis clavier : Ctrl+1 à Ctrl+5 pour changer de section, Ctrl+, pour les paramètres.';

  @override
  String get academyTitle => 'Carte des îles';

  @override
  String get academySubtitle =>
      'Chaque île est un module. Les îles en brume arriveront dans une phase ultérieure.';

  @override
  String get academySearch => 'Rechercher';

  @override
  String get academyGlossary => 'Glossaire';

  @override
  String get academyReviews => 'Révisions';

  @override
  String reviewsDue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count révisions dues',
      one: '1 révision due',
      zero: 'Aucune révision due',
    );
    return '$_temp0';
  }

  @override
  String get islandAvailable => 'Disponible hors ligne';

  @override
  String islandPlanned(int phase) {
    return 'En brume — prévu en phase $phase';
  }

  @override
  String get moduleObjectives => 'Objectifs';

  @override
  String get modulePrerequisites => 'Prérequis';

  @override
  String get moduleLessons => 'Leçons';

  @override
  String get moduleProgress => 'Progression du module';

  @override
  String get moduleComplete => 'Module terminé ! Bravo, moussaillon.';

  @override
  String lessonMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get lessonStatusDone => 'Validée';

  @override
  String get lessonStatusStarted => 'Commencée';

  @override
  String get lessonStatusNew => 'À découvrir';

  @override
  String get lessonTabCourse => 'Cours';

  @override
  String get lessonTabExercise => 'Exercice';

  @override
  String get lessonTabQuiz => 'Quiz';

  @override
  String get lessonObjectives => 'À la fin de cette leçon, vous saurez :';

  @override
  String get lessonNoExercise =>
      'Pas d\'exercice dans le simulateur pour cette leçon : elle se pratique sur un vrai dépôt jetable dans l\'Atelier (phase 5).';

  @override
  String get lessonNext => 'Leçon suivante';

  @override
  String get lessonCompleteHint =>
      'Pour valider la leçon : quiz ≥ 70 % et exercice réussi.';

  @override
  String get lessonCompleteHintNoEx => 'Pour valider la leçon : quiz ≥ 70 %.';

  @override
  String get lessonValidated => 'Leçon validée';

  @override
  String bestScore(int score) {
    return 'Meilleur score : $score %';
  }

  @override
  String get sandboxBanner =>
      'Simulateur pédagogique : aucune commande réelle n\'est exécutée, aucun fichier n\'est touché.';

  @override
  String get sandboxInputHint => 'Tapez une commande (ex. git status)';

  @override
  String get sandboxRun => 'Exécuter';

  @override
  String get sandboxReset => 'Recommencer';

  @override
  String get sandboxHint => 'Indice';

  @override
  String get sandboxSolution => 'Solution';

  @override
  String exerciseStep(int current, int total) {
    return 'Étape $current sur $total';
  }

  @override
  String get exerciseDone => 'Exercice réussi ! Mousse Byte est fier de vous.';

  @override
  String quizQuestion(int current, int total) {
    return 'Question $current sur $total';
  }

  @override
  String get quizValidate => 'Valider';

  @override
  String get quizNext => 'Question suivante';

  @override
  String get quizFinish => 'Voir le résultat';

  @override
  String get quizCorrect => 'Bonne réponse !';

  @override
  String get quizWrong => 'Pas tout à fait.';

  @override
  String get quizMultipleHint => 'Plusieurs réponses possibles.';

  @override
  String get quizCommandHint => 'Saisissez la commande';

  @override
  String quizResult(int score) {
    return 'Score : $score %';
  }

  @override
  String get quizPassed => 'Quiz réussi.';

  @override
  String get quizFailed =>
      'Il faut 70 % pour valider. Relisez le cours et retentez votre chance !';

  @override
  String get quizRetry => 'Recommencer le quiz';

  @override
  String expectedAnswer(String answer) {
    return 'Réponse attendue : $answer';
  }

  @override
  String get reviewsTitle => 'Révisions du jour';

  @override
  String get reviewsEmpty =>
      'Aucune révision prévue maintenant. Les questions reviennent selon la répétition espacée (1, 2, 4, 8 puis 16 jours).';

  @override
  String get reviewsDone => 'Révisions terminées : à demain !';

  @override
  String get glossaryTitle => 'Glossaire';

  @override
  String get searchHint => 'Rechercher une leçon ou un terme';

  @override
  String get searchNoResult => 'Aucun résultat.';

  @override
  String get searchLessons => 'Leçons';

  @override
  String get searchGlossary => 'Glossaire';

  @override
  String get projectTitle => 'Projet final';

  @override
  String get projectRubric => 'Grille d\'auto-évaluation';

  @override
  String get projectSubmit => 'Enregistrer mon évaluation';

  @override
  String get projectSaved => 'Évaluation enregistrée.';

  @override
  String get projectExerciseFirst =>
      'Réalisez d\'abord le projet dans le simulateur pour débloquer la grille.';

  @override
  String get projectDone => 'Projet réalisé';

  @override
  String resumeLesson(String title) {
    return 'Reprendre : $title';
  }

  @override
  String get academyProgressTitle => 'Votre progression';

  @override
  String get settingsProfile => 'Profil';

  @override
  String get settingsProfileRename => 'Renommer';

  @override
  String get settingsProfileSaved => 'Profil renommé.';

  @override
  String get contentLanguageNote =>
      'Le contenu des cours est en français pour l\'instant.';
}
