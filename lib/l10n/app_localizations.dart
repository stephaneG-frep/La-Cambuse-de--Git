import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'La Cambuse de Git'**
  String get appTitle;

  /// No description provided for @navBridge.
  ///
  /// In fr, this message translates to:
  /// **'Pont'**
  String get navBridge;

  /// No description provided for @navAcademy.
  ///
  /// In fr, this message translates to:
  /// **'Académie'**
  String get navAcademy;

  /// No description provided for @navWorkshop.
  ///
  /// In fr, this message translates to:
  /// **'Atelier'**
  String get navWorkshop;

  /// No description provided for @navCaptain.
  ///
  /// In fr, this message translates to:
  /// **'Capitaine'**
  String get navCaptain;

  /// No description provided for @navLogbook.
  ///
  /// In fr, this message translates to:
  /// **'Journal'**
  String get navLogbook;

  /// No description provided for @navSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get navSettings;

  /// No description provided for @bridgeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le pont du navire'**
  String get bridgeTitle;

  /// No description provided for @bridgeWelcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue à bord, {name} !'**
  String bridgeWelcome(String name);

  /// No description provided for @createProfileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre profil de matelot'**
  String get createProfileTitle;

  /// No description provided for @createProfileHint.
  ///
  /// In fr, this message translates to:
  /// **'Votre nom ou pseudonyme'**
  String get createProfileHint;

  /// No description provided for @createProfileAction.
  ///
  /// In fr, this message translates to:
  /// **'Embarquer'**
  String get createProfileAction;

  /// No description provided for @createProfileInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Entre 1 et 40 caractères.'**
  String get createProfileInvalid;

  /// No description provided for @profileLocalNote.
  ///
  /// In fr, this message translates to:
  /// **'Profil stocké uniquement sur cet appareil. Aucune donnée n\'est envoyée.'**
  String get profileLocalNote;

  /// No description provided for @bridgeLogbookCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune entrée au journal} =1{1 entrée au journal} other{{count} entrées au journal}}'**
  String bridgeLogbookCount(int count);

  /// No description provided for @sectionAcademyDesc.
  ///
  /// In fr, this message translates to:
  /// **'Apprendre Git, GitHub, GitLab, Docker et DevOps de zéro à expert.'**
  String get sectionAcademyDesc;

  /// No description provided for @sectionWorkshopDesc.
  ///
  /// In fr, this message translates to:
  /// **'Importer un projet, l\'auditer sans le modifier et préparer Git et la CI.'**
  String get sectionWorkshopDesc;

  /// No description provided for @sectionCaptainDesc.
  ///
  /// In fr, this message translates to:
  /// **'Orchestration supervisée : plan, validations, pause et arrêt d\'urgence.'**
  String get sectionCaptainDesc;

  /// No description provided for @openSection.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir'**
  String get openSection;

  /// No description provided for @plannedPhaseTitle.
  ///
  /// In fr, this message translates to:
  /// **'En construction'**
  String get plannedPhaseTitle;

  /// No description provided for @plannedPhaseBody.
  ///
  /// In fr, this message translates to:
  /// **'Cette section sera livrée en phase {phase} de la feuille de route. Aucune fonctionnalité n\'est simulée ici.'**
  String plannedPhaseBody(int phase);

  /// No description provided for @logbookTitle.
  ///
  /// In fr, this message translates to:
  /// **'Journal de bord'**
  String get logbookTitle;

  /// No description provided for @logbookEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Le journal est vide.'**
  String get logbookEmpty;

  /// No description provided for @logbookFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get logbookFilterAll;

  /// No description provided for @logbookExport.
  ///
  /// In fr, this message translates to:
  /// **'Copier en JSON'**
  String get logbookExport;

  /// No description provided for @logbookExported.
  ///
  /// In fr, this message translates to:
  /// **'Journal copié dans le presse-papiers ({count} entrées).'**
  String logbookExported(int count);

  /// No description provided for @logbookClear.
  ///
  /// In fr, this message translates to:
  /// **'Effacer le journal'**
  String get logbookClear;

  /// No description provided for @logbookClearConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Effacer le journal de bord ?'**
  String get logbookClearConfirmTitle;

  /// No description provided for @logbookClearConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'{count} entrées seront supprimées définitivement de cet appareil. Une entrée indiquant l\'effacement sera conservée.'**
  String logbookClearConfirmBody(int count);

  /// No description provided for @logbookCleared.
  ///
  /// In fr, this message translates to:
  /// **'{count} entrées effacées.'**
  String logbookCleared(int count);

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @confirmDelete.
  ///
  /// In fr, this message translates to:
  /// **'Effacer définitivement'**
  String get confirmDelete;

  /// No description provided for @outcomeSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Réussi'**
  String get outcomeSuccess;

  /// No description provided for @outcomeFailure.
  ///
  /// In fr, this message translates to:
  /// **'Échec'**
  String get outcomeFailure;

  /// No description provided for @outcomeInfo.
  ///
  /// In fr, this message translates to:
  /// **'Info'**
  String get outcomeInfo;

  /// No description provided for @outcomeCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulé'**
  String get outcomeCancelled;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settingsTitle;

  /// No description provided for @settingsTextScale.
  ///
  /// In fr, this message translates to:
  /// **'Taille du texte'**
  String get settingsTextScale;

  /// No description provided for @settingsReduceMotion.
  ///
  /// In fr, this message translates to:
  /// **'Réduire les animations'**
  String get settingsReduceMotion;

  /// No description provided for @settingsReduceMotionDesc.
  ///
  /// In fr, this message translates to:
  /// **'Désactive les transitions et animations décoratives.'**
  String get settingsReduceMotionDesc;

  /// No description provided for @settingsHighContrast.
  ///
  /// In fr, this message translates to:
  /// **'Contraste renforcé'**
  String get settingsHighContrast;

  /// No description provided for @settingsHighContrastDesc.
  ///
  /// In fr, this message translates to:
  /// **'Fond plus sombre, texte plus clair, bordures plus épaisses.'**
  String get settingsHighContrastDesc;

  /// No description provided for @settingsLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get settingsLanguage;

  /// No description provided for @languageFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageEnglish.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @errorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue : {message}'**
  String errorGeneric(String message);

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement…'**
  String get loading;

  /// No description provided for @shortcutsHint.
  ///
  /// In fr, this message translates to:
  /// **'Raccourcis clavier : Ctrl+1 à Ctrl+5 pour changer de section, Ctrl+, pour les paramètres.'**
  String get shortcutsHint;

  /// No description provided for @academyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Carte des îles'**
  String get academyTitle;

  /// No description provided for @academySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Chaque île est un module, du terminal Linux jusqu\'au SRE. Tout est disponible hors ligne ; les prérequis sont des conseils, pas des verrous.'**
  String get academySubtitle;

  /// No description provided for @academySearch.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get academySearch;

  /// No description provided for @academyGlossary.
  ///
  /// In fr, this message translates to:
  /// **'Glossaire'**
  String get academyGlossary;

  /// No description provided for @academyReviews.
  ///
  /// In fr, this message translates to:
  /// **'Révisions'**
  String get academyReviews;

  /// No description provided for @reviewsDue.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune révision due} =1{1 révision due} other{{count} révisions dues}}'**
  String reviewsDue(int count);

  /// No description provided for @islandAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Disponible hors ligne'**
  String get islandAvailable;

  /// No description provided for @islandPlanned.
  ///
  /// In fr, this message translates to:
  /// **'En brume — prévu en phase {phase}'**
  String islandPlanned(int phase);

  /// No description provided for @moduleObjectives.
  ///
  /// In fr, this message translates to:
  /// **'Objectifs'**
  String get moduleObjectives;

  /// No description provided for @modulePrerequisites.
  ///
  /// In fr, this message translates to:
  /// **'Prérequis'**
  String get modulePrerequisites;

  /// No description provided for @moduleLessons.
  ///
  /// In fr, this message translates to:
  /// **'Leçons'**
  String get moduleLessons;

  /// No description provided for @moduleProgress.
  ///
  /// In fr, this message translates to:
  /// **'Progression du module'**
  String get moduleProgress;

  /// No description provided for @moduleComplete.
  ///
  /// In fr, this message translates to:
  /// **'Module terminé ! Bravo, moussaillon.'**
  String get moduleComplete;

  /// No description provided for @lessonMinutes.
  ///
  /// In fr, this message translates to:
  /// **'{minutes} min'**
  String lessonMinutes(int minutes);

  /// No description provided for @lessonStatusDone.
  ///
  /// In fr, this message translates to:
  /// **'Validée'**
  String get lessonStatusDone;

  /// No description provided for @lessonStatusStarted.
  ///
  /// In fr, this message translates to:
  /// **'Commencée'**
  String get lessonStatusStarted;

  /// No description provided for @lessonStatusNew.
  ///
  /// In fr, this message translates to:
  /// **'À découvrir'**
  String get lessonStatusNew;

  /// No description provided for @lessonTabCourse.
  ///
  /// In fr, this message translates to:
  /// **'Cours'**
  String get lessonTabCourse;

  /// No description provided for @lessonTabExercise.
  ///
  /// In fr, this message translates to:
  /// **'Exercice'**
  String get lessonTabExercise;

  /// No description provided for @lessonTabQuiz.
  ///
  /// In fr, this message translates to:
  /// **'Quiz'**
  String get lessonTabQuiz;

  /// No description provided for @lessonObjectives.
  ///
  /// In fr, this message translates to:
  /// **'À la fin de cette leçon, vous saurez :'**
  String get lessonObjectives;

  /// No description provided for @lessonNoExercise.
  ///
  /// In fr, this message translates to:
  /// **'Pas d\'exercice dans le simulateur pour cette leçon : elle se pratique sur un vrai dépôt jetable dans l\'Atelier (phase 5).'**
  String get lessonNoExercise;

  /// No description provided for @lessonNext.
  ///
  /// In fr, this message translates to:
  /// **'Leçon suivante'**
  String get lessonNext;

  /// No description provided for @lessonCompleteHint.
  ///
  /// In fr, this message translates to:
  /// **'Pour valider la leçon : quiz ≥ 70 % et exercice réussi.'**
  String get lessonCompleteHint;

  /// No description provided for @lessonCompleteHintNoEx.
  ///
  /// In fr, this message translates to:
  /// **'Pour valider la leçon : quiz ≥ 70 %.'**
  String get lessonCompleteHintNoEx;

  /// No description provided for @lessonValidated.
  ///
  /// In fr, this message translates to:
  /// **'Leçon validée'**
  String get lessonValidated;

  /// No description provided for @bestScore.
  ///
  /// In fr, this message translates to:
  /// **'Meilleur score : {score} %'**
  String bestScore(int score);

  /// No description provided for @sandboxBanner.
  ///
  /// In fr, this message translates to:
  /// **'Simulateur pédagogique : aucune commande réelle n\'est exécutée, aucun fichier n\'est touché.'**
  String get sandboxBanner;

  /// No description provided for @sandboxInputHint.
  ///
  /// In fr, this message translates to:
  /// **'Tapez une commande (ex. git status)'**
  String get sandboxInputHint;

  /// No description provided for @sandboxRun.
  ///
  /// In fr, this message translates to:
  /// **'Exécuter'**
  String get sandboxRun;

  /// No description provided for @sandboxReset.
  ///
  /// In fr, this message translates to:
  /// **'Recommencer'**
  String get sandboxReset;

  /// No description provided for @sandboxHint.
  ///
  /// In fr, this message translates to:
  /// **'Indice'**
  String get sandboxHint;

  /// No description provided for @sandboxSolution.
  ///
  /// In fr, this message translates to:
  /// **'Solution'**
  String get sandboxSolution;

  /// No description provided for @exerciseStep.
  ///
  /// In fr, this message translates to:
  /// **'Étape {current} sur {total}'**
  String exerciseStep(int current, int total);

  /// No description provided for @exerciseDone.
  ///
  /// In fr, this message translates to:
  /// **'Exercice réussi ! Mousse Byte est fier de vous.'**
  String get exerciseDone;

  /// No description provided for @quizQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Question {current} sur {total}'**
  String quizQuestion(int current, int total);

  /// No description provided for @quizValidate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get quizValidate;

  /// No description provided for @quizNext.
  ///
  /// In fr, this message translates to:
  /// **'Question suivante'**
  String get quizNext;

  /// No description provided for @quizFinish.
  ///
  /// In fr, this message translates to:
  /// **'Voir le résultat'**
  String get quizFinish;

  /// No description provided for @quizCorrect.
  ///
  /// In fr, this message translates to:
  /// **'Bonne réponse !'**
  String get quizCorrect;

  /// No description provided for @quizWrong.
  ///
  /// In fr, this message translates to:
  /// **'Pas tout à fait.'**
  String get quizWrong;

  /// No description provided for @quizMultipleHint.
  ///
  /// In fr, this message translates to:
  /// **'Plusieurs réponses possibles.'**
  String get quizMultipleHint;

  /// No description provided for @quizCommandHint.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez la commande'**
  String get quizCommandHint;

  /// No description provided for @quizResult.
  ///
  /// In fr, this message translates to:
  /// **'Score : {score} %'**
  String quizResult(int score);

  /// No description provided for @quizPassed.
  ///
  /// In fr, this message translates to:
  /// **'Quiz réussi.'**
  String get quizPassed;

  /// No description provided for @quizFailed.
  ///
  /// In fr, this message translates to:
  /// **'Il faut 70 % pour valider. Relisez le cours et retentez votre chance !'**
  String get quizFailed;

  /// No description provided for @quizRetry.
  ///
  /// In fr, this message translates to:
  /// **'Recommencer le quiz'**
  String get quizRetry;

  /// No description provided for @expectedAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Réponse attendue : {answer}'**
  String expectedAnswer(String answer);

  /// No description provided for @reviewsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Révisions du jour'**
  String get reviewsTitle;

  /// No description provided for @reviewsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune révision prévue maintenant. Les questions reviennent selon la répétition espacée (1, 2, 4, 8 puis 16 jours).'**
  String get reviewsEmpty;

  /// No description provided for @reviewsDone.
  ///
  /// In fr, this message translates to:
  /// **'Révisions terminées : à demain !'**
  String get reviewsDone;

  /// No description provided for @glossaryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Glossaire'**
  String get glossaryTitle;

  /// No description provided for @searchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une leçon ou un terme'**
  String get searchHint;

  /// No description provided for @searchNoResult.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat.'**
  String get searchNoResult;

  /// No description provided for @searchLessons.
  ///
  /// In fr, this message translates to:
  /// **'Leçons'**
  String get searchLessons;

  /// No description provided for @searchGlossary.
  ///
  /// In fr, this message translates to:
  /// **'Glossaire'**
  String get searchGlossary;

  /// No description provided for @projectTitle.
  ///
  /// In fr, this message translates to:
  /// **'Projet final'**
  String get projectTitle;

  /// No description provided for @projectRubric.
  ///
  /// In fr, this message translates to:
  /// **'Grille d\'auto-évaluation'**
  String get projectRubric;

  /// No description provided for @projectSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer mon évaluation'**
  String get projectSubmit;

  /// No description provided for @projectSaved.
  ///
  /// In fr, this message translates to:
  /// **'Évaluation enregistrée.'**
  String get projectSaved;

  /// No description provided for @projectExerciseFirst.
  ///
  /// In fr, this message translates to:
  /// **'Réalisez d\'abord le projet dans le simulateur pour débloquer la grille.'**
  String get projectExerciseFirst;

  /// No description provided for @projectDone.
  ///
  /// In fr, this message translates to:
  /// **'Projet réalisé'**
  String get projectDone;

  /// No description provided for @resumeLesson.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre : {title}'**
  String resumeLesson(String title);

  /// No description provided for @academyProgressTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre progression'**
  String get academyProgressTitle;

  /// No description provided for @settingsProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get settingsProfile;

  /// No description provided for @settingsProfileRename.
  ///
  /// In fr, this message translates to:
  /// **'Renommer'**
  String get settingsProfileRename;

  /// No description provided for @settingsProfileSaved.
  ///
  /// In fr, this message translates to:
  /// **'Profil renommé.'**
  String get settingsProfileSaved;

  /// No description provided for @contentLanguageNote.
  ///
  /// In fr, this message translates to:
  /// **'Le contenu des cours est en français pour l\'instant.'**
  String get contentLanguageNote;

  /// No description provided for @aiTeacher.
  ///
  /// In fr, this message translates to:
  /// **'Professeur IA'**
  String get aiTeacher;

  /// No description provided for @aiNewConversation.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle conversation'**
  String get aiNewConversation;

  /// No description provided for @aiConversations.
  ///
  /// In fr, this message translates to:
  /// **'Conversations'**
  String get aiConversations;

  /// No description provided for @aiNoConversations.
  ///
  /// In fr, this message translates to:
  /// **'Aucune conversation pour l\'instant.'**
  String get aiNoConversations;

  /// No description provided for @aiDeleteConversation.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la conversation'**
  String get aiDeleteConversation;

  /// No description provided for @aiDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement cette conversation de cet appareil ?'**
  String get aiDeleteConfirm;

  /// No description provided for @aiNoKeyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Professeur IA non configuré'**
  String get aiNoKeyTitle;

  /// No description provided for @aiNoKeyBody.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez une clé API dans Paramètres → Professeur IA. Tout le reste de l\'application fonctionne sans IA, hors ligne.'**
  String get aiNoKeyBody;

  /// No description provided for @aiOpenSettings.
  ///
  /// In fr, this message translates to:
  /// **'Configurer'**
  String get aiOpenSettings;

  /// No description provided for @aiLevel.
  ///
  /// In fr, this message translates to:
  /// **'Niveau'**
  String get aiLevel;

  /// No description provided for @aiLevelBeginner.
  ///
  /// In fr, this message translates to:
  /// **'Débutant'**
  String get aiLevelBeginner;

  /// No description provided for @aiLevelIntermediate.
  ///
  /// In fr, this message translates to:
  /// **'Intermédiaire'**
  String get aiLevelIntermediate;

  /// No description provided for @aiLevelExpert.
  ///
  /// In fr, this message translates to:
  /// **'Expert'**
  String get aiLevelExpert;

  /// No description provided for @aiInputHint.
  ///
  /// In fr, this message translates to:
  /// **'Votre question au Capitaine Commit'**
  String get aiInputHint;

  /// No description provided for @aiSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get aiSend;

  /// No description provided for @aiStop.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter'**
  String get aiStop;

  /// No description provided for @aiThinking.
  ///
  /// In fr, this message translates to:
  /// **'Le Capitaine réfléchit…'**
  String get aiThinking;

  /// No description provided for @aiDisclaimer.
  ///
  /// In fr, this message translates to:
  /// **'Les réponses de l\'IA peuvent contenir des erreurs. Rien n\'est exécuté automatiquement : vérifiez chaque commande.'**
  String get aiDisclaimer;

  /// No description provided for @aiPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Vos questions sont envoyées à {provider} via Internet. N\'y mettez aucune donnée sensible.'**
  String aiPrivacy(String provider);

  /// No description provided for @aiSecretMasked.
  ///
  /// In fr, this message translates to:
  /// **'Un secret probable a été masqué avant l\'envoi. Pensez à le révoquer.'**
  String get aiSecretMasked;

  /// No description provided for @aiUsageLine.
  ///
  /// In fr, this message translates to:
  /// **'{tokens} jetons · {model}'**
  String aiUsageLine(int tokens, String model);

  /// No description provided for @aiCostLine.
  ///
  /// In fr, this message translates to:
  /// **'≈ {cost} \$'**
  String aiCostLine(String cost);

  /// No description provided for @aiTokensToday.
  ///
  /// In fr, this message translates to:
  /// **'Jetons aujourd\'hui : {used} / {budget}'**
  String aiTokensToday(int used, int budget);

  /// No description provided for @aiTokensTodayUnlimited.
  ///
  /// In fr, this message translates to:
  /// **'Jetons aujourd\'hui : {used} (sans plafond)'**
  String aiTokensTodayUnlimited(int used);

  /// No description provided for @aiContextLesson.
  ///
  /// In fr, this message translates to:
  /// **'Contexte : {title}'**
  String aiContextLesson(String title);

  /// No description provided for @aiAsk.
  ///
  /// In fr, this message translates to:
  /// **'Demander au professeur'**
  String get aiAsk;

  /// No description provided for @aiErrAuth.
  ///
  /// In fr, this message translates to:
  /// **'Clé API refusée (401). Vérifiez-la dans Paramètres → Professeur IA.'**
  String get aiErrAuth;

  /// No description provided for @aiErrPermission.
  ///
  /// In fr, this message translates to:
  /// **'Accès refusé (403) pour cette clé.'**
  String get aiErrPermission;

  /// No description provided for @aiErrBilling.
  ///
  /// In fr, this message translates to:
  /// **'Problème de facturation sur le compte du fournisseur (402).'**
  String get aiErrBilling;

  /// No description provided for @aiErrNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Modèle introuvable ou non disponible pour ce compte (404).'**
  String get aiErrNotFound;

  /// No description provided for @aiErrInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Requête refusée (400) : {message}'**
  String aiErrInvalid(String message);

  /// No description provided for @aiErrTooLarge.
  ///
  /// In fr, this message translates to:
  /// **'Conversation trop longue (413). Commencez une nouvelle conversation.'**
  String get aiErrTooLarge;

  /// No description provided for @aiErrRate.
  ///
  /// In fr, this message translates to:
  /// **'Trop de requêtes (429). Réessayez dans un instant.'**
  String get aiErrRate;

  /// No description provided for @aiErrOverloaded.
  ///
  /// In fr, this message translates to:
  /// **'Service surchargé (529). Réessayez dans un instant.'**
  String get aiErrOverloaded;

  /// No description provided for @aiErrServer.
  ///
  /// In fr, this message translates to:
  /// **'Erreur du service ({code}). Réessayez plus tard.'**
  String aiErrServer(String code);

  /// No description provided for @aiErrNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion : le professeur IA nécessite Internet. Les cours, quiz et exercices restent disponibles hors ligne.'**
  String get aiErrNetwork;

  /// No description provided for @aiErrTimeout.
  ///
  /// In fr, this message translates to:
  /// **'Délai dépassé. Vérifiez votre connexion.'**
  String get aiErrTimeout;

  /// No description provided for @aiErrRefusal.
  ///
  /// In fr, this message translates to:
  /// **'Le modèle a refusé de répondre. Reformulez la question.'**
  String get aiErrRefusal;

  /// No description provided for @aiErrBudget.
  ///
  /// In fr, this message translates to:
  /// **'Budget quotidien de jetons atteint. Modifiable dans Paramètres → Professeur IA.'**
  String get aiErrBudget;

  /// No description provided for @aiErrCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Réponse annulée.'**
  String get aiErrCancelled;

  /// No description provided for @aiErrNoKey.
  ///
  /// In fr, this message translates to:
  /// **'Aucune clé API enregistrée.'**
  String get aiErrNoKey;

  /// No description provided for @aiErrUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Erreur inattendue : {message}'**
  String aiErrUnknown(String message);

  /// No description provided for @aiSettingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Professeur IA'**
  String get aiSettingsTitle;

  /// No description provided for @aiProvider.
  ///
  /// In fr, this message translates to:
  /// **'Fournisseur'**
  String get aiProvider;

  /// No description provided for @aiProviderAnthropic.
  ///
  /// In fr, this message translates to:
  /// **'Anthropic (Claude)'**
  String get aiProviderAnthropic;

  /// No description provided for @aiProviderOpenAi.
  ///
  /// In fr, this message translates to:
  /// **'Compatible OpenAI (OpenAI, Mistral, Ollama…)'**
  String get aiProviderOpenAi;

  /// No description provided for @aiModel.
  ///
  /// In fr, this message translates to:
  /// **'Modèle'**
  String get aiModel;

  /// No description provided for @aiModelCustom.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant du modèle'**
  String get aiModelCustom;

  /// No description provided for @aiBaseUrl.
  ///
  /// In fr, this message translates to:
  /// **'URL de base (ex. https://api.mistral.ai/v1)'**
  String get aiBaseUrl;

  /// No description provided for @aiApiKey.
  ///
  /// In fr, this message translates to:
  /// **'Clé API'**
  String get aiApiKey;

  /// No description provided for @aiKeyStored.
  ///
  /// In fr, this message translates to:
  /// **'Clé enregistrée dans le coffre du système ({hint})'**
  String aiKeyStored(String hint);

  /// No description provided for @aiKeyNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune clé enregistrée'**
  String get aiKeyNone;

  /// No description provided for @aiKeySave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer la clé'**
  String get aiKeySave;

  /// No description provided for @aiKeyDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la clé'**
  String get aiKeyDelete;

  /// No description provided for @aiKeySaved.
  ///
  /// In fr, this message translates to:
  /// **'Clé enregistrée dans le coffre du système.'**
  String get aiKeySaved;

  /// No description provided for @aiKeyDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Clé supprimée.'**
  String get aiKeyDeleted;

  /// No description provided for @aiEffort.
  ///
  /// In fr, this message translates to:
  /// **'Effort de réflexion'**
  String get aiEffort;

  /// No description provided for @aiEffortDesc.
  ///
  /// In fr, this message translates to:
  /// **'Plus d\'effort : réponses plus approfondies, mais plus lentes et plus coûteuses.'**
  String get aiEffortDesc;

  /// No description provided for @aiBudget.
  ///
  /// In fr, this message translates to:
  /// **'Budget quotidien (jetons, 0 = illimité)'**
  String get aiBudget;

  /// No description provided for @aiTest.
  ///
  /// In fr, this message translates to:
  /// **'Tester la connexion'**
  String get aiTest;

  /// No description provided for @aiTestOk.
  ///
  /// In fr, this message translates to:
  /// **'Connexion réussie : {model} est disponible.'**
  String aiTestOk(String model);

  /// No description provided for @aiPricesNote.
  ///
  /// In fr, this message translates to:
  /// **'Coûts estimés d\'après les tarifs publics relevés le 2026-11-03 ; seule la facture du fournisseur fait foi.'**
  String get aiPricesNote;

  /// No description provided for @aiSaveSettings.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get aiSaveSettings;

  /// No description provided for @aiSettingsSaved.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres IA enregistrés.'**
  String get aiSettingsSaved;

  /// No description provided for @aiKeyStorageError.
  ///
  /// In fr, this message translates to:
  /// **'Coffre du système indisponible : {message}'**
  String aiKeyStorageError(String message);

  /// No description provided for @aiEffortLow.
  ///
  /// In fr, this message translates to:
  /// **'Faible'**
  String get aiEffortLow;

  /// No description provided for @aiEffortMedium.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get aiEffortMedium;

  /// No description provided for @aiEffortHigh.
  ///
  /// In fr, this message translates to:
  /// **'Élevé'**
  String get aiEffortHigh;

  /// No description provided for @compTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compagnon Linux'**
  String get compTitle;

  /// No description provided for @compIntro.
  ///
  /// In fr, this message translates to:
  /// **'Le compagnon est un petit service qui tourne sur votre PC Linux. L\'application ne lance jamais de commande elle-même : elle demande au compagnon des opérations typées, limitées aux dossiers que vous avez autorisés, et chaque modification exige votre accord.'**
  String get compIntro;

  /// No description provided for @compHostSteps.
  ///
  /// In fr, this message translates to:
  /// **'Sur le PC Linux :'**
  String get compHostSteps;

  /// No description provided for @compAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse du compagnon'**
  String get compAddress;

  /// No description provided for @compFingerprint.
  ///
  /// In fr, this message translates to:
  /// **'Empreinte TLS (HTTPS uniquement)'**
  String get compFingerprint;

  /// No description provided for @compDeviceName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de cet appareil'**
  String get compDeviceName;

  /// No description provided for @compCode.
  ///
  /// In fr, this message translates to:
  /// **'Code d\'appairage (6 chiffres)'**
  String get compCode;

  /// No description provided for @compCheck.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier la connexion'**
  String get compCheck;

  /// No description provided for @compPair.
  ///
  /// In fr, this message translates to:
  /// **'Appairer'**
  String get compPair;

  /// No description provided for @compPaired.
  ///
  /// In fr, this message translates to:
  /// **'Appairé avec {address}'**
  String compPaired(String address);

  /// No description provided for @compScopes.
  ///
  /// In fr, this message translates to:
  /// **'Portées : {scopes}'**
  String compScopes(String scopes);

  /// No description provided for @compReachable.
  ///
  /// In fr, this message translates to:
  /// **'Compagnon joignable (API v{version}).'**
  String compReachable(String version);

  /// No description provided for @compInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations du compagnon'**
  String get compInfo;

  /// No description provided for @compRoots.
  ///
  /// In fr, this message translates to:
  /// **'Dossiers autorisés'**
  String get compRoots;

  /// No description provided for @compFolder.
  ///
  /// In fr, this message translates to:
  /// **'Dossier (dans un dossier autorisé)'**
  String get compFolder;

  /// No description provided for @compGitStatus.
  ///
  /// In fr, this message translates to:
  /// **'État Git'**
  String get compGitStatus;

  /// No description provided for @compDetect.
  ///
  /// In fr, this message translates to:
  /// **'Détecter le projet'**
  String get compDetect;

  /// No description provided for @compGitInit.
  ///
  /// In fr, this message translates to:
  /// **'Initialiser Git'**
  String get compGitInit;

  /// No description provided for @compReadOnly.
  ///
  /// In fr, this message translates to:
  /// **'Lecture seule'**
  String get compReadOnly;

  /// No description provided for @compMutating.
  ///
  /// In fr, this message translates to:
  /// **'Modification (accord demandé)'**
  String get compMutating;

  /// No description provided for @compResult.
  ///
  /// In fr, this message translates to:
  /// **'Résultat'**
  String get compResult;

  /// No description provided for @compState.
  ///
  /// In fr, this message translates to:
  /// **'État : {state}'**
  String compState(String state);

  /// No description provided for @compAudit.
  ///
  /// In fr, this message translates to:
  /// **'Journal du compagnon'**
  String get compAudit;

  /// No description provided for @compAuditEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun événement pour cet appareil.'**
  String get compAuditEmpty;

  /// No description provided for @compForget.
  ///
  /// In fr, this message translates to:
  /// **'Oublier ce compagnon'**
  String get compForget;

  /// No description provided for @compForgetBody.
  ///
  /// In fr, this message translates to:
  /// **'Les jetons seront supprimés de cet appareil. Pour révoquer aussi l\'accès côté PC : cambuse-companion revoke {id}'**
  String compForgetBody(String id);

  /// No description provided for @compApproveTitle.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser cette opération ?'**
  String get compApproveTitle;

  /// No description provided for @compApproveWarning.
  ///
  /// In fr, this message translates to:
  /// **'Cette opération modifie le dépôt. Rien n\'est fait sans votre accord.'**
  String get compApproveWarning;

  /// No description provided for @compApprove.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser'**
  String get compApprove;

  /// No description provided for @compReject.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get compReject;

  /// No description provided for @compRejected.
  ///
  /// In fr, this message translates to:
  /// **'Opération refusée : rien n\'a été modifié.'**
  String get compRejected;

  /// No description provided for @compSettingsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Appairage et opérations sur le PC Linux'**
  String get compSettingsSubtitle;

  /// No description provided for @compPairedOk.
  ///
  /// In fr, this message translates to:
  /// **'Appareil appairé.'**
  String get compPairedOk;

  /// No description provided for @compGit.
  ///
  /// In fr, this message translates to:
  /// **'Git : {version}'**
  String compGit(String version);

  /// No description provided for @wsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Chantier naval'**
  String get wsTitle;

  /// No description provided for @wsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos projets sur le PC Linux, via le compagnon. Rien n\'est modifié sans votre accord.'**
  String get wsSubtitle;

  /// No description provided for @wsNotPaired.
  ///
  /// In fr, this message translates to:
  /// **'L\'Atelier passe par le compagnon Linux : l\'application n\'agit jamais seule sur vos fichiers.'**
  String get wsNotPaired;

  /// No description provided for @wsOpenCompanion.
  ///
  /// In fr, this message translates to:
  /// **'Configurer le compagnon'**
  String get wsOpenCompanion;

  /// No description provided for @wsProjects.
  ///
  /// In fr, this message translates to:
  /// **'Projets'**
  String get wsProjects;

  /// No description provided for @wsNoProjects.
  ///
  /// In fr, this message translates to:
  /// **'Aucun sous-dossier dans ce dossier autorisé.'**
  String get wsNoProjects;

  /// No description provided for @wsGitRepo.
  ///
  /// In fr, this message translates to:
  /// **'Dépôt Git'**
  String get wsGitRepo;

  /// No description provided for @wsNoGit.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de Git'**
  String get wsNoGit;

  /// No description provided for @wsRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get wsRefresh;

  /// No description provided for @wsTabAudit.
  ///
  /// In fr, this message translates to:
  /// **'Audit'**
  String get wsTabAudit;

  /// No description provided for @wsTabChanges.
  ///
  /// In fr, this message translates to:
  /// **'Changements'**
  String get wsTabChanges;

  /// No description provided for @wsTabHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get wsTabHistory;

  /// No description provided for @wsTabBackups.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegardes'**
  String get wsTabBackups;

  /// No description provided for @wsRunAudit.
  ///
  /// In fr, this message translates to:
  /// **'Lancer l\'audit (lecture seule)'**
  String get wsRunAudit;

  /// No description provided for @wsAuditIntro.
  ///
  /// In fr, this message translates to:
  /// **'L\'audit lit le projet sans rien modifier : secrets, gros fichiers, artefacts, .gitignore, licence et état Git.'**
  String get wsAuditIntro;

  /// No description provided for @wsBlocking.
  ///
  /// In fr, this message translates to:
  /// **'Bloquant'**
  String get wsBlocking;

  /// No description provided for @wsWarning.
  ///
  /// In fr, this message translates to:
  /// **'Attention'**
  String get wsWarning;

  /// No description provided for @wsInfo.
  ///
  /// In fr, this message translates to:
  /// **'Info'**
  String get wsInfo;

  /// No description provided for @wsFilesCount.
  ///
  /// In fr, this message translates to:
  /// **'{files} fichiers analysés · {size}'**
  String wsFilesCount(int files, String size);

  /// No description provided for @wsNoFindings.
  ///
  /// In fr, this message translates to:
  /// **'Aucun problème détecté. Bon vent !'**
  String get wsNoFindings;

  /// No description provided for @wsPlan.
  ///
  /// In fr, this message translates to:
  /// **'Plan proposé'**
  String get wsPlan;

  /// No description provided for @wsStepBackup.
  ///
  /// In fr, this message translates to:
  /// **'1. Sauvegarder le projet'**
  String get wsStepBackup;

  /// No description provided for @wsStepInit.
  ///
  /// In fr, this message translates to:
  /// **'2. Initialiser Git (branche main)'**
  String get wsStepInit;

  /// No description provided for @wsStepGitignore.
  ///
  /// In fr, this message translates to:
  /// **'3. Compléter le .gitignore (+{count} lignes)'**
  String wsStepGitignore(int count);

  /// No description provided for @wsStepFixBlocking.
  ///
  /// In fr, this message translates to:
  /// **'Corrigez d\'abord les {count} problème(s) bloquant(s) : aucun commit ne sera possible avec un secret.'**
  String wsStepFixBlocking(int count);

  /// No description provided for @wsStepCommit.
  ///
  /// In fr, this message translates to:
  /// **'4. Indexer et valider dans l\'onglet Changements'**
  String get wsStepCommit;

  /// No description provided for @wsDone.
  ///
  /// In fr, this message translates to:
  /// **'Fait'**
  String get wsDone;

  /// No description provided for @wsDo.
  ///
  /// In fr, this message translates to:
  /// **'Exécuter'**
  String get wsDo;

  /// No description provided for @wsClean.
  ///
  /// In fr, this message translates to:
  /// **'Copie de travail propre : rien à valider.'**
  String get wsClean;

  /// No description provided for @wsSelectAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout sélectionner'**
  String get wsSelectAll;

  /// No description provided for @wsStage.
  ///
  /// In fr, this message translates to:
  /// **'Indexer'**
  String get wsStage;

  /// No description provided for @wsUnstage.
  ///
  /// In fr, this message translates to:
  /// **'Désindexer'**
  String get wsUnstage;

  /// No description provided for @wsDiscard.
  ///
  /// In fr, this message translates to:
  /// **'Annuler les modifications'**
  String get wsDiscard;

  /// No description provided for @wsDiscardHint.
  ///
  /// In fr, this message translates to:
  /// **'Une sauvegarde automatique est faite avant.'**
  String get wsDiscardHint;

  /// No description provided for @wsCommitMessage.
  ///
  /// In fr, this message translates to:
  /// **'Message de commit (impératif, ex. « Ajoute l\'écran d\'accueil »)'**
  String get wsCommitMessage;

  /// No description provided for @wsCommit.
  ///
  /// In fr, this message translates to:
  /// **'Valider (commit)'**
  String get wsCommit;

  /// No description provided for @wsStaged.
  ///
  /// In fr, this message translates to:
  /// **'Indexé'**
  String get wsStaged;

  /// No description provided for @wsUnstagedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Non indexé'**
  String get wsUnstagedLabel;

  /// No description provided for @wsUntracked.
  ///
  /// In fr, this message translates to:
  /// **'Non suivi'**
  String get wsUntracked;

  /// No description provided for @wsDiffUntracked.
  ///
  /// In fr, this message translates to:
  /// **'Fichier non suivi : indexez-le pour voir son contenu dans le diff.'**
  String get wsDiffUntracked;

  /// No description provided for @wsNoDiff.
  ///
  /// In fr, this message translates to:
  /// **'Aucune différence.'**
  String get wsNoDiff;

  /// No description provided for @wsBranches.
  ///
  /// In fr, this message translates to:
  /// **'Branches'**
  String get wsBranches;

  /// No description provided for @wsNewBranch.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle branche'**
  String get wsNewBranch;

  /// No description provided for @wsCreateBranch.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get wsCreateBranch;

  /// No description provided for @wsSwitch.
  ///
  /// In fr, this message translates to:
  /// **'Basculer'**
  String get wsSwitch;

  /// No description provided for @wsCommits.
  ///
  /// In fr, this message translates to:
  /// **'Derniers commits'**
  String get wsCommits;

  /// No description provided for @wsNoCommits.
  ///
  /// In fr, this message translates to:
  /// **'Aucun commit pour l\'instant.'**
  String get wsNoCommits;

  /// No description provided for @wsBackupNow.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder maintenant'**
  String get wsBackupNow;

  /// No description provided for @wsNoBackups.
  ///
  /// In fr, this message translates to:
  /// **'Aucune sauvegarde pour ce projet.'**
  String get wsNoBackups;

  /// No description provided for @wsRestore.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer dans un nouveau dossier'**
  String get wsRestore;

  /// No description provided for @wsRestoredTo.
  ///
  /// In fr, this message translates to:
  /// **'Restauré dans : {path}'**
  String wsRestoredTo(String path);

  /// No description provided for @wsBackupFiles.
  ///
  /// In fr, this message translates to:
  /// **'Fichiers ({count})'**
  String wsBackupFiles(int count);

  /// No description provided for @wsBackupProject.
  ///
  /// In fr, this message translates to:
  /// **'Projet complet'**
  String get wsBackupProject;

  /// No description provided for @wsOpDone.
  ///
  /// In fr, this message translates to:
  /// **'{op} : terminé.'**
  String wsOpDone(String op);

  /// No description provided for @wsOpFailed.
  ///
  /// In fr, this message translates to:
  /// **'{op} : échec.'**
  String wsOpFailed(String op);

  /// No description provided for @wsBranchLabel.
  ///
  /// In fr, this message translates to:
  /// **'Branche : {branch}'**
  String wsBranchLabel(String branch);

  /// No description provided for @fgTitle.
  ///
  /// In fr, this message translates to:
  /// **'GitHub et GitLab'**
  String get fgTitle;

  /// No description provided for @fgSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Jetons à portée minimale, rangés dans le coffre du système'**
  String get fgSubtitle;

  /// No description provided for @fgTokenHelp.
  ///
  /// In fr, this message translates to:
  /// **'Créez un jeton « fine-grained » limité à vos dépôts de test, avec seulement Contents, Pull requests et Issues en lecture-écriture. Ne le partagez jamais.'**
  String get fgTokenHelp;

  /// No description provided for @fgGitlabUrl.
  ///
  /// In fr, this message translates to:
  /// **'URL de l\'instance GitLab'**
  String get fgGitlabUrl;

  /// No description provided for @fgToken.
  ///
  /// In fr, this message translates to:
  /// **'Jeton {forge}'**
  String fgToken(String forge);

  /// No description provided for @fgTest.
  ///
  /// In fr, this message translates to:
  /// **'Tester'**
  String get fgTest;

  /// No description provided for @fgConnectedAs.
  ///
  /// In fr, this message translates to:
  /// **'Connecté à {forge} en tant que {user}.'**
  String fgConnectedAs(String forge, String user);

  /// No description provided for @wsTabPublish.
  ///
  /// In fr, this message translates to:
  /// **'Publication'**
  String get wsTabPublish;

  /// No description provided for @pbNoToken.
  ///
  /// In fr, this message translates to:
  /// **'Aucun jeton {forge} : ajoutez-le dans Paramètres → GitHub et GitLab.'**
  String pbNoToken(String forge);

  /// No description provided for @pbOpenForges.
  ///
  /// In fr, this message translates to:
  /// **'Configurer les jetons'**
  String get pbOpenForges;

  /// No description provided for @pbNoRemote.
  ///
  /// In fr, this message translates to:
  /// **'Ce projet n\'a pas encore de dépôt distant.'**
  String get pbNoRemote;

  /// No description provided for @pbRepoName.
  ///
  /// In fr, this message translates to:
  /// **'Dépôt distant (propriétaire/nom)'**
  String get pbRepoName;

  /// No description provided for @pbLink.
  ///
  /// In fr, this message translates to:
  /// **'Associer comme origin'**
  String get pbLink;

  /// No description provided for @pbCreatePrivate.
  ///
  /// In fr, this message translates to:
  /// **'Créer un dépôt privé'**
  String get pbCreatePrivate;

  /// No description provided for @pbCreateConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer un dépôt privé ?'**
  String get pbCreateConfirmTitle;

  /// No description provided for @pbCreateConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'Le dépôt « {name} » sera créé sur {forge}, en PRIVÉ. Vous pourrez le rendre public plus tard, uniquement depuis {forge}.'**
  String pbCreateConfirmBody(String name, String forge);

  /// No description provided for @pbCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get pbCreate;

  /// No description provided for @pbPrivate.
  ///
  /// In fr, this message translates to:
  /// **'PRIVÉ'**
  String get pbPrivate;

  /// No description provided for @pbPublic.
  ///
  /// In fr, this message translates to:
  /// **'PUBLIC'**
  String get pbPublic;

  /// No description provided for @pbDefaultBranch.
  ///
  /// In fr, this message translates to:
  /// **'Branche par défaut : {branch}'**
  String pbDefaultBranch(String branch);

  /// No description provided for @pbPush.
  ///
  /// In fr, this message translates to:
  /// **'Publier (push)'**
  String get pbPush;

  /// No description provided for @pbPull.
  ///
  /// In fr, this message translates to:
  /// **'Récupérer (pull, avance rapide)'**
  String get pbPull;

  /// No description provided for @pbPanelTitle.
  ///
  /// In fr, this message translates to:
  /// **'Publier sur {repo} ?'**
  String pbPanelTitle(String repo);

  /// No description provided for @pbPanelBranch.
  ///
  /// In fr, this message translates to:
  /// **'Branche : {branch}'**
  String pbPanelBranch(String branch);

  /// No description provided for @pbPanelCommits.
  ///
  /// In fr, this message translates to:
  /// **'Commits envoyés ({count})'**
  String pbPanelCommits(int count);

  /// No description provided for @pbPanelFiles.
  ///
  /// In fr, this message translates to:
  /// **'Fichiers concernés ({count})'**
  String pbPanelFiles(int count);

  /// No description provided for @pbPanelSecretsOk.
  ///
  /// In fr, this message translates to:
  /// **'Analyse des secrets sur tout l\'historique envoyé : aucun secret détecté.'**
  String get pbPanelSecretsOk;

  /// No description provided for @pbPanelSecretsKo.
  ///
  /// In fr, this message translates to:
  /// **'Secret probable dans l\'historique envoyé : publication bloquée.'**
  String get pbPanelSecretsKo;

  /// No description provided for @pbPanelPublicWarning.
  ///
  /// In fr, this message translates to:
  /// **'Attention : ce dépôt est PUBLIC. Tout ce qui est envoyé sera visible par tous.'**
  String get pbPanelPublicWarning;

  /// No description provided for @pbPanelNothing.
  ///
  /// In fr, this message translates to:
  /// **'Rien à envoyer : le dépôt distant est à jour.'**
  String get pbPanelNothing;

  /// No description provided for @pbPanelNewBranch.
  ///
  /// In fr, this message translates to:
  /// **'La branche n\'existe pas encore sur le dépôt distant : elle sera créée.'**
  String get pbPanelNewBranch;

  /// No description provided for @pbPublish.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get pbPublish;

  /// No description provided for @pbPushed.
  ///
  /// In fr, this message translates to:
  /// **'Publié : {count} commit(s) envoyé(s).'**
  String pbPushed(int count);

  /// No description provided for @pbChangeRequests.
  ///
  /// In fr, this message translates to:
  /// **'Demandes de fusion ouvertes'**
  String get pbChangeRequests;

  /// No description provided for @pbNoChangeRequests.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande ouverte.'**
  String get pbNoChangeRequests;

  /// No description provided for @pbNewChangeRequest.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle demande de fusion ({head} → {base})'**
  String pbNewChangeRequest(String head, String base);

  /// No description provided for @pbTitleField.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get pbTitleField;

  /// No description provided for @pbBodyField.
  ///
  /// In fr, this message translates to:
  /// **'Description (facultatif)'**
  String get pbBodyField;

  /// No description provided for @pbOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir'**
  String get pbOpen;

  /// No description provided for @pbIssues.
  ///
  /// In fr, this message translates to:
  /// **'Tickets ouverts'**
  String get pbIssues;

  /// No description provided for @pbNoIssues.
  ///
  /// In fr, this message translates to:
  /// **'Aucun ticket ouvert.'**
  String get pbNoIssues;

  /// No description provided for @pbNewIssue.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau ticket'**
  String get pbNewIssue;

  /// No description provided for @pbCreated.
  ///
  /// In fr, this message translates to:
  /// **'Créé : {url}'**
  String pbCreated(String url);

  /// No description provided for @pbErrAuth.
  ///
  /// In fr, this message translates to:
  /// **'Jeton refusé (401) : vérifiez-le ou régénérez-le.'**
  String get pbErrAuth;

  /// No description provided for @pbErrForbidden.
  ///
  /// In fr, this message translates to:
  /// **'Accès refusé (403) : le jeton n\'a pas cette permission ({message}).'**
  String pbErrForbidden(String message);

  /// No description provided for @pbErrRate.
  ///
  /// In fr, this message translates to:
  /// **'Limite de requêtes atteinte : réessayez plus tard.'**
  String get pbErrRate;

  /// No description provided for @pbErrNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Introuvable (404) : dépôt inexistant ou jeton sans accès à ce dépôt.'**
  String get pbErrNotFound;

  /// No description provided for @pbErrValidation.
  ///
  /// In fr, this message translates to:
  /// **'Refusé : {message}'**
  String pbErrValidation(String message);

  /// No description provided for @pbErrNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion à {forge}.'**
  String pbErrNetwork(String forge);

  /// No description provided for @pbErrNoToken.
  ///
  /// In fr, this message translates to:
  /// **'Aucun jeton enregistré.'**
  String get pbErrNoToken;

  /// No description provided for @pbErrUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {message}'**
  String pbErrUnknown(String message);

  /// No description provided for @pbScopeMissing.
  ///
  /// In fr, this message translates to:
  /// **'Cet appareil n\'a pas la portée « remote » : appairez-le avec --scopes read,git-write,remote.'**
  String get pbScopeMissing;

  /// No description provided for @labStatic.
  ///
  /// In fr, this message translates to:
  /// **'Labo hors ligne : le fichier est analysé, rien n\'est exécuté (aucun conteneur, script ni cluster).'**
  String get labStatic;

  /// No description provided for @labAnalyze.
  ///
  /// In fr, this message translates to:
  /// **'Analyser'**
  String get labAnalyze;

  /// No description provided for @labReset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get labReset;

  /// No description provided for @labGoals.
  ///
  /// In fr, this message translates to:
  /// **'Objectifs'**
  String get labGoals;

  /// No description provided for @labFindings.
  ///
  /// In fr, this message translates to:
  /// **'Constats de l\'analyseur'**
  String get labFindings;

  /// No description provided for @labNoFinding.
  ///
  /// In fr, this message translates to:
  /// **'Aucun constat : bravo.'**
  String get labNoFinding;

  /// No description provided for @labDone.
  ///
  /// In fr, this message translates to:
  /// **'Labo réussi ! Mousse Byte salue votre rigueur.'**
  String get labDone;

  /// No description provided for @labLine.
  ///
  /// In fr, this message translates to:
  /// **'ligne {line}'**
  String labLine(int line);

  /// No description provided for @labFix.
  ///
  /// In fr, this message translates to:
  /// **'Correction : {fix}'**
  String labFix(String fix);

  /// No description provided for @dkRoom.
  ///
  /// In fr, this message translates to:
  /// **'Salle des machines Docker'**
  String get dkRoom;

  /// No description provided for @dkRoomSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Inspection en lecture seule du Docker de votre PC'**
  String get dkRoomSubtitle;

  /// No description provided for @dkUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Docker indisponible sur l\'hôte.'**
  String get dkUnavailable;

  /// No description provided for @dkServer.
  ///
  /// In fr, this message translates to:
  /// **'Docker {version}'**
  String dkServer(String version);

  /// No description provided for @dkRootless.
  ///
  /// In fr, this message translates to:
  /// **'Mode rootless'**
  String get dkRootless;

  /// No description provided for @dkCounts.
  ///
  /// In fr, this message translates to:
  /// **'{containers} conteneur(s) dont {running} en marche · {images} image(s)'**
  String dkCounts(String containers, String running, String images);

  /// No description provided for @dkImages.
  ///
  /// In fr, this message translates to:
  /// **'Images'**
  String get dkImages;

  /// No description provided for @dkContainers.
  ///
  /// In fr, this message translates to:
  /// **'Conteneurs'**
  String get dkContainers;

  /// No description provided for @dkLogs.
  ///
  /// In fr, this message translates to:
  /// **'Journal de {name}'**
  String dkLogs(String name);

  /// No description provided for @dkReadOnly.
  ///
  /// In fr, this message translates to:
  /// **'Lecture seule : La Cambuse ne lance, n\'arrête ni ne supprime aucun conteneur.'**
  String get dkReadOnly;

  /// No description provided for @dkScopeMissing.
  ///
  /// In fr, this message translates to:
  /// **'Cet appareil n\'a pas la portée « docker » : appairez-le avec --scopes …,docker (l\'accès à Docker équivaut à des droits root).'**
  String get dkScopeMissing;

  /// No description provided for @wsTabDocker.
  ///
  /// In fr, this message translates to:
  /// **'Docker'**
  String get wsTabDocker;

  /// No description provided for @dkLintIntro.
  ///
  /// In fr, this message translates to:
  /// **'Analyse statique des fichiers Docker du projet (aucun conteneur lancé).'**
  String get dkLintIntro;

  /// No description provided for @dkRunLint.
  ///
  /// In fr, this message translates to:
  /// **'Analyser les fichiers Docker'**
  String get dkRunLint;

  /// No description provided for @dkNoFiles.
  ///
  /// In fr, this message translates to:
  /// **'Aucun Dockerfile ni compose.yaml dans ce projet.'**
  String get dkNoFiles;

  /// No description provided for @dkGenerate.
  ///
  /// In fr, this message translates to:
  /// **'Générer un Dockerfile ({template})'**
  String dkGenerate(String template);

  /// No description provided for @dkNoDockerignore.
  ///
  /// In fr, this message translates to:
  /// **'Pas de .dockerignore : le contexte de build peut embarquer .git, .env et les dépendances.'**
  String get dkNoDockerignore;

  /// No description provided for @dkOpenRoom.
  ///
  /// In fr, this message translates to:
  /// **'Salle des machines Docker'**
  String get dkOpenRoom;

  /// No description provided for @wsTabBuilds.
  ///
  /// In fr, this message translates to:
  /// **'Builds'**
  String get wsTabBuilds;

  /// No description provided for @bdIntro.
  ///
  /// In fr, this message translates to:
  /// **'Intégration continue, analyse, tests et builds exécutés sur le PC par le compagnon, chacun après votre approbation.'**
  String get bdIntro;

  /// No description provided for @bdScopeMissing.
  ///
  /// In fr, this message translates to:
  /// **'Cet appareil n\'a pas la portée « build » : appairez-le avec --scopes …,build (un build exécute du code du projet).'**
  String get bdScopeMissing;

  /// No description provided for @bdCiTitle.
  ///
  /// In fr, this message translates to:
  /// **'Intégration continue'**
  String get bdCiTitle;

  /// No description provided for @bdCiIntro.
  ///
  /// In fr, this message translates to:
  /// **'Génère un pipeline prêt à relire : actions épinglées, permissions minimales, analyse des secrets. Aucun fichier existant n\'est écrasé.'**
  String get bdCiIntro;

  /// No description provided for @bdCiKind.
  ///
  /// In fr, this message translates to:
  /// **'Type de projet'**
  String get bdCiKind;

  /// No description provided for @bdCiProvider.
  ///
  /// In fr, this message translates to:
  /// **'Plateforme'**
  String get bdCiProvider;

  /// No description provided for @bdCiGenerate.
  ///
  /// In fr, this message translates to:
  /// **'Générer le pipeline'**
  String get bdCiGenerate;

  /// No description provided for @bdRunTitle.
  ///
  /// In fr, this message translates to:
  /// **'Analyse, tests et builds (Flutter)'**
  String get bdRunTitle;

  /// No description provided for @bdAnalyze.
  ///
  /// In fr, this message translates to:
  /// **'flutter analyze'**
  String get bdAnalyze;

  /// No description provided for @bdTest.
  ///
  /// In fr, this message translates to:
  /// **'flutter test'**
  String get bdTest;

  /// No description provided for @bdApkDebug.
  ///
  /// In fr, this message translates to:
  /// **'APK de test (debug)'**
  String get bdApkDebug;

  /// No description provided for @bdLinux.
  ///
  /// In fr, this message translates to:
  /// **'Build Linux (release)'**
  String get bdLinux;

  /// No description provided for @bdApkDebugNote.
  ///
  /// In fr, this message translates to:
  /// **'Un APK debug sert aux tests : il n\'est jamais distribuable. Une release exige votre propre clé de signature.'**
  String get bdApkDebugNote;

  /// No description provided for @bdRunning.
  ///
  /// In fr, this message translates to:
  /// **'En cours sur le PC… un build peut durer plusieurs minutes.'**
  String get bdRunning;

  /// No description provided for @bdResult.
  ///
  /// In fr, this message translates to:
  /// **'{op} : code de sortie {code}'**
  String bdResult(String op, String code);

  /// No description provided for @bdHoldTitle.
  ///
  /// In fr, this message translates to:
  /// **'Cale des artefacts'**
  String get bdHoldTitle;

  /// No description provided for @bdHoldIntro.
  ///
  /// In fr, this message translates to:
  /// **'Fichiers produits (APK, bundle Linux, paquets de dist/) avec taille, SHA-256 et signature vérifiée.'**
  String get bdHoldIntro;

  /// No description provided for @bdHoldRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Inspecter la cale'**
  String get bdHoldRefresh;

  /// No description provided for @bdHoldEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun artefact : lancez un build.'**
  String get bdHoldEmpty;

  /// No description provided for @bdSigDebug.
  ///
  /// In fr, this message translates to:
  /// **'DEBUG — non distribuable'**
  String get bdSigDebug;

  /// No description provided for @bdSigRelease.
  ///
  /// In fr, this message translates to:
  /// **'Signé (release)'**
  String get bdSigRelease;

  /// No description provided for @bdSigInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Signature invalide'**
  String get bdSigInvalid;

  /// No description provided for @bdSigUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Signature non vérifiée (apksigner introuvable)'**
  String get bdSigUnknown;

  /// No description provided for @bdAbis.
  ///
  /// In fr, this message translates to:
  /// **'ABI : {abis}'**
  String bdAbis(String abis);

  /// No description provided for @bdCopySha.
  ///
  /// In fr, this message translates to:
  /// **'Copier le SHA-256'**
  String get bdCopySha;

  /// No description provided for @bdCopied.
  ///
  /// In fr, this message translates to:
  /// **'SHA-256 copié'**
  String get bdCopied;

  /// No description provided for @compApproveWarningBuild.
  ///
  /// In fr, this message translates to:
  /// **'Cette opération exécute du code du projet sur le PC (scripts de build, plugins, tests). Rien n\'est fait sans votre accord.'**
  String get compApproveWarningBuild;

  /// No description provided for @cpTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le Capitaine automatique'**
  String get cpTitle;

  /// No description provided for @cpSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Des missions exécutées étape par étape sous votre supervision : plan affiché, point de contrôle, chaque modification approuvée, pause et arrêt d\'urgence à tout moment.'**
  String get cpSubtitle;

  /// No description provided for @cpNeedsCompanion.
  ///
  /// In fr, this message translates to:
  /// **'Le Capitaine agit sur vos projets via le compagnon Linux : appairez-le d\'abord.'**
  String get cpNeedsCompanion;

  /// No description provided for @cpDecisionWaiting.
  ///
  /// In fr, this message translates to:
  /// **'Une décision vous attend'**
  String get cpDecisionWaiting;

  /// No description provided for @cpMissions.
  ///
  /// In fr, this message translates to:
  /// **'Missions'**
  String get cpMissions;

  /// No description provided for @cpAiTitle.
  ///
  /// In fr, this message translates to:
  /// **'Proposer une mission avec le professeur IA'**
  String get cpAiTitle;

  /// No description provided for @cpAiDesc.
  ///
  /// In fr, this message translates to:
  /// **'Facultatif : l\'IA propose un plan, validé strictement puis soumis à votre approbation.'**
  String get cpAiDesc;

  /// No description provided for @cpHistory.
  ///
  /// In fr, this message translates to:
  /// **'Journal des missions'**
  String get cpHistory;

  /// No description provided for @cpHistoryEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune mission pour l\'instant.'**
  String get cpHistoryEmpty;

  /// No description provided for @cpPlanTitle.
  ///
  /// In fr, this message translates to:
  /// **'Table de navigation'**
  String get cpPlanTitle;

  /// No description provided for @cpPlanMissing.
  ///
  /// In fr, this message translates to:
  /// **'Mission introuvable.'**
  String get cpPlanMissing;

  /// No description provided for @cpPlanFromAi.
  ///
  /// In fr, this message translates to:
  /// **'Plan proposé par le professeur IA : relisez chaque étape. Il a été validé (opérations autorisées, aucun secret) mais pas jugé à votre place.'**
  String get cpPlanFromAi;

  /// No description provided for @cpLimits.
  ///
  /// In fr, this message translates to:
  /// **'Limites : {steps} étapes, {mutations} modifications, {minutes} min au total ; chaque opération a son propre délai.'**
  String cpLimits(int steps, int mutations, int minutes);

  /// No description provided for @cpCostAi.
  ///
  /// In fr, this message translates to:
  /// **'Coût IA : celui de la proposition (affiché à l\'étape précédente) ; l\'exécution n\'appelle pas l\'IA.'**
  String get cpCostAi;

  /// No description provided for @cpCostNone.
  ///
  /// In fr, this message translates to:
  /// **'Coût IA : aucun (mission prédéfinie, fonctionne sans fournisseur).'**
  String get cpCostNone;

  /// No description provided for @cpPlanInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Plan refusé par la validation :'**
  String get cpPlanInvalid;

  /// No description provided for @cpApproveNote.
  ///
  /// In fr, this message translates to:
  /// **'Approuver le plan lance la mission. Chaque modification restera soumise à l\'approbation du compagnon, et toute action externe à un consentement spécifique.'**
  String get cpApproveNote;

  /// No description provided for @cpChooseProject.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un projet'**
  String get cpChooseProject;

  /// No description provided for @cpApproveLaunch.
  ///
  /// In fr, this message translates to:
  /// **'Approuver le plan et lancer'**
  String get cpApproveLaunch;

  /// No description provided for @cpTokenAtRuntime.
  ///
  /// In fr, this message translates to:
  /// **'token : lu dans le coffre au moment de l\'exécution (jamais affiché ni enregistré)'**
  String get cpTokenAtRuntime;

  /// No description provided for @cpComputed.
  ///
  /// In fr, this message translates to:
  /// **'{param} : calculé à l\'exécution ({source})'**
  String cpComputed(String param, String source);

  /// No description provided for @cpMarkReview.
  ///
  /// In fr, this message translates to:
  /// **'Relecture humaine'**
  String get cpMarkReview;

  /// No description provided for @cpMarkConsent.
  ///
  /// In fr, this message translates to:
  /// **'Consentement spécifique'**
  String get cpMarkConsent;

  /// No description provided for @cpMarkApproval.
  ///
  /// In fr, this message translates to:
  /// **'Approbation du compagnon'**
  String get cpMarkApproval;

  /// No description provided for @cpMarkWhen.
  ///
  /// In fr, this message translates to:
  /// **'Si {condition}'**
  String cpMarkWhen(String condition);

  /// No description provided for @cpMarkRequires.
  ///
  /// In fr, this message translates to:
  /// **'Arrêt sauf si {condition}'**
  String cpMarkRequires(String condition);

  /// No description provided for @cpProject.
  ///
  /// In fr, this message translates to:
  /// **'Projet'**
  String get cpProject;

  /// No description provided for @cpRiskRead.
  ///
  /// In fr, this message translates to:
  /// **'Lecture seule'**
  String get cpRiskRead;

  /// No description provided for @cpRiskCheckpoint.
  ///
  /// In fr, this message translates to:
  /// **'Point de contrôle'**
  String get cpRiskCheckpoint;

  /// No description provided for @cpRiskModify.
  ///
  /// In fr, this message translates to:
  /// **'Modifie le projet'**
  String get cpRiskModify;

  /// No description provided for @cpRiskExecute.
  ///
  /// In fr, this message translates to:
  /// **'Exécute du code'**
  String get cpRiskExecute;

  /// No description provided for @cpRiskExternal.
  ///
  /// In fr, this message translates to:
  /// **'Action externe'**
  String get cpRiskExternal;

  /// No description provided for @cpStepTodo.
  ///
  /// In fr, this message translates to:
  /// **'À faire'**
  String get cpStepTodo;

  /// No description provided for @cpStepRunning.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get cpStepRunning;

  /// No description provided for @cpStepDone.
  ///
  /// In fr, this message translates to:
  /// **'Réussie'**
  String get cpStepDone;

  /// No description provided for @cpStepSkipped.
  ///
  /// In fr, this message translates to:
  /// **'Ignorée'**
  String get cpStepSkipped;

  /// No description provided for @cpStepFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échouée'**
  String get cpStepFailed;

  /// No description provided for @cpStepRefused.
  ///
  /// In fr, this message translates to:
  /// **'Refusée'**
  String get cpStepRefused;

  /// No description provided for @cpStepCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get cpStepCancelled;

  /// No description provided for @cpStepUnknown.
  ///
  /// In fr, this message translates to:
  /// **'État inconnu'**
  String get cpStepUnknown;

  /// No description provided for @cpRunReady.
  ///
  /// In fr, this message translates to:
  /// **'Prête'**
  String get cpRunReady;

  /// No description provided for @cpRunRunning.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get cpRunRunning;

  /// No description provided for @cpRunPaused.
  ///
  /// In fr, this message translates to:
  /// **'En pause'**
  String get cpRunPaused;

  /// No description provided for @cpRunDone.
  ///
  /// In fr, this message translates to:
  /// **'Terminée'**
  String get cpRunDone;

  /// No description provided for @cpRunFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échouée'**
  String get cpRunFailed;

  /// No description provided for @cpRunStopped.
  ///
  /// In fr, this message translates to:
  /// **'Arrêtée'**
  String get cpRunStopped;

  /// No description provided for @cpRunInterrupted.
  ///
  /// In fr, this message translates to:
  /// **'Interrompue (reprise possible)'**
  String get cpRunInterrupted;

  /// No description provided for @cpRunTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mission'**
  String get cpRunTitle;

  /// No description provided for @cpProgress.
  ///
  /// In fr, this message translates to:
  /// **'Avancement de la mission'**
  String get cpProgress;

  /// No description provided for @cpPause.
  ///
  /// In fr, this message translates to:
  /// **'Pause'**
  String get cpPause;

  /// No description provided for @cpPauseRequested.
  ///
  /// In fr, this message translates to:
  /// **'Pause demandée (fin de l\'étape en cours)'**
  String get cpPauseRequested;

  /// No description provided for @cpResume.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre'**
  String get cpResume;

  /// No description provided for @cpEmergencyStop.
  ///
  /// In fr, this message translates to:
  /// **'Arrêt d\'urgence'**
  String get cpEmergencyStop;

  /// No description provided for @cpSteps.
  ///
  /// In fr, this message translates to:
  /// **'Étapes'**
  String get cpSteps;

  /// No description provided for @cpRollback.
  ///
  /// In fr, this message translates to:
  /// **'Retour arrière'**
  String get cpRollback;

  /// No description provided for @cpRollbackNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune modification à défaire.'**
  String get cpRollbackNone;

  /// No description provided for @cpRestoreCheckpoint.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer dans un nouveau dossier'**
  String get cpRestoreCheckpoint;

  /// No description provided for @cpRestored.
  ///
  /// In fr, this message translates to:
  /// **'Restauré dans {path}'**
  String cpRestored(String path);

  /// No description provided for @cpCopyReport.
  ///
  /// In fr, this message translates to:
  /// **'Copier le rapport'**
  String get cpCopyReport;

  /// No description provided for @cpReportCopied.
  ///
  /// In fr, this message translates to:
  /// **'Rapport copié'**
  String get cpReportCopied;

  /// No description provided for @cpReport.
  ///
  /// In fr, this message translates to:
  /// **'Rapport de mission'**
  String get cpReport;

  /// No description provided for @cpJournal.
  ///
  /// In fr, this message translates to:
  /// **'Journal horodaté'**
  String get cpJournal;

  /// No description provided for @cpDecApproval.
  ///
  /// In fr, this message translates to:
  /// **'Le compagnon demande votre accord'**
  String get cpDecApproval;

  /// No description provided for @cpDecReview.
  ///
  /// In fr, this message translates to:
  /// **'Relisez avant de continuer'**
  String get cpDecReview;

  /// No description provided for @cpDecConsent.
  ///
  /// In fr, this message translates to:
  /// **'Action externe : consentement spécifique'**
  String get cpDecConsent;

  /// No description provided for @cpDecContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get cpDecContinue;

  /// No description provided for @cpDecPublish.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get cpDecPublish;

  /// No description provided for @cpDecConsentWarn.
  ///
  /// In fr, this message translates to:
  /// **'Cette action sort de votre machine et ne peut pas être annulée automatiquement.'**
  String get cpDecConsentWarn;

  /// No description provided for @cpDecUnderstood.
  ///
  /// In fr, this message translates to:
  /// **'Je comprends que cette publication est visible par d\'autres et non annulable automatiquement.'**
  String get cpDecUnderstood;

  /// No description provided for @cpAiIntro.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez votre objectif. Le professeur IA propose un plan composé uniquement d\'opérations autorisées ; il est validé strictement (aucun shell, aucun secret, chemins confinés) et rien ne s\'exécute sans votre approbation.'**
  String get cpAiIntro;

  /// No description provided for @cpAiGoal.
  ///
  /// In fr, this message translates to:
  /// **'Objectif'**
  String get cpAiGoal;

  /// No description provided for @cpAiGoalHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : créer une branche de travail et commiter mes changements'**
  String get cpAiGoalHint;

  /// No description provided for @cpAiAsk.
  ///
  /// In fr, this message translates to:
  /// **'Demander un plan'**
  String get cpAiAsk;

  /// No description provided for @cpAiUsage.
  ///
  /// In fr, this message translates to:
  /// **'Jetons : {input} en entrée, {output} en sortie — coût estimé {cost}'**
  String cpAiUsage(int input, int output, String cost);

  /// No description provided for @cpAiRejected.
  ///
  /// In fr, this message translates to:
  /// **'Plan refusé par la validation (rien ne sera exécuté) :'**
  String get cpAiRejected;

  /// No description provided for @cpAiAccepted.
  ///
  /// In fr, this message translates to:
  /// **'Plan valide : « {title} », {count} étapes.'**
  String cpAiAccepted(String title, int count);

  /// No description provided for @cpAiReview.
  ///
  /// In fr, this message translates to:
  /// **'Examiner le plan'**
  String get cpAiReview;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
