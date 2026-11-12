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
  /// **'Chaque île est un module. Les îles en brume arriveront dans une phase ultérieure.'**
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
