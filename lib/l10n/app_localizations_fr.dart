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

  @override
  String get aiTeacher => 'Professeur IA';

  @override
  String get aiNewConversation => 'Nouvelle conversation';

  @override
  String get aiConversations => 'Conversations';

  @override
  String get aiNoConversations => 'Aucune conversation pour l\'instant.';

  @override
  String get aiDeleteConversation => 'Supprimer la conversation';

  @override
  String get aiDeleteConfirm =>
      'Supprimer définitivement cette conversation de cet appareil ?';

  @override
  String get aiNoKeyTitle => 'Professeur IA non configuré';

  @override
  String get aiNoKeyBody =>
      'Ajoutez une clé API dans Paramètres → Professeur IA. Tout le reste de l\'application fonctionne sans IA, hors ligne.';

  @override
  String get aiOpenSettings => 'Configurer';

  @override
  String get aiLevel => 'Niveau';

  @override
  String get aiLevelBeginner => 'Débutant';

  @override
  String get aiLevelIntermediate => 'Intermédiaire';

  @override
  String get aiLevelExpert => 'Expert';

  @override
  String get aiInputHint => 'Votre question au Capitaine Commit';

  @override
  String get aiSend => 'Envoyer';

  @override
  String get aiStop => 'Arrêter';

  @override
  String get aiThinking => 'Le Capitaine réfléchit…';

  @override
  String get aiDisclaimer =>
      'Les réponses de l\'IA peuvent contenir des erreurs. Rien n\'est exécuté automatiquement : vérifiez chaque commande.';

  @override
  String aiPrivacy(String provider) {
    return 'Vos questions sont envoyées à $provider via Internet. N\'y mettez aucune donnée sensible.';
  }

  @override
  String get aiSecretMasked =>
      'Un secret probable a été masqué avant l\'envoi. Pensez à le révoquer.';

  @override
  String aiUsageLine(int tokens, String model) {
    return '$tokens jetons · $model';
  }

  @override
  String aiCostLine(String cost) {
    return '≈ $cost \$';
  }

  @override
  String aiTokensToday(int used, int budget) {
    return 'Jetons aujourd\'hui : $used / $budget';
  }

  @override
  String aiTokensTodayUnlimited(int used) {
    return 'Jetons aujourd\'hui : $used (sans plafond)';
  }

  @override
  String aiContextLesson(String title) {
    return 'Contexte : $title';
  }

  @override
  String get aiAsk => 'Demander au professeur';

  @override
  String get aiErrAuth =>
      'Clé API refusée (401). Vérifiez-la dans Paramètres → Professeur IA.';

  @override
  String get aiErrPermission => 'Accès refusé (403) pour cette clé.';

  @override
  String get aiErrBilling =>
      'Problème de facturation sur le compte du fournisseur (402).';

  @override
  String get aiErrNotFound =>
      'Modèle introuvable ou non disponible pour ce compte (404).';

  @override
  String aiErrInvalid(String message) {
    return 'Requête refusée (400) : $message';
  }

  @override
  String get aiErrTooLarge =>
      'Conversation trop longue (413). Commencez une nouvelle conversation.';

  @override
  String get aiErrRate => 'Trop de requêtes (429). Réessayez dans un instant.';

  @override
  String get aiErrOverloaded =>
      'Service surchargé (529). Réessayez dans un instant.';

  @override
  String aiErrServer(String code) {
    return 'Erreur du service ($code). Réessayez plus tard.';
  }

  @override
  String get aiErrNetwork =>
      'Pas de connexion : le professeur IA nécessite Internet. Les cours, quiz et exercices restent disponibles hors ligne.';

  @override
  String get aiErrTimeout => 'Délai dépassé. Vérifiez votre connexion.';

  @override
  String get aiErrRefusal =>
      'Le modèle a refusé de répondre. Reformulez la question.';

  @override
  String get aiErrBudget =>
      'Budget quotidien de jetons atteint. Modifiable dans Paramètres → Professeur IA.';

  @override
  String get aiErrCancelled => 'Réponse annulée.';

  @override
  String get aiErrNoKey => 'Aucune clé API enregistrée.';

  @override
  String aiErrUnknown(String message) {
    return 'Erreur inattendue : $message';
  }

  @override
  String get aiSettingsTitle => 'Professeur IA';

  @override
  String get aiProvider => 'Fournisseur';

  @override
  String get aiProviderAnthropic => 'Anthropic (Claude)';

  @override
  String get aiProviderOpenAi => 'Compatible OpenAI (OpenAI, Mistral, Ollama…)';

  @override
  String get aiModel => 'Modèle';

  @override
  String get aiModelCustom => 'Identifiant du modèle';

  @override
  String get aiBaseUrl => 'URL de base (ex. https://api.mistral.ai/v1)';

  @override
  String get aiApiKey => 'Clé API';

  @override
  String aiKeyStored(String hint) {
    return 'Clé enregistrée dans le coffre du système ($hint)';
  }

  @override
  String get aiKeyNone => 'Aucune clé enregistrée';

  @override
  String get aiKeySave => 'Enregistrer la clé';

  @override
  String get aiKeyDelete => 'Supprimer la clé';

  @override
  String get aiKeySaved => 'Clé enregistrée dans le coffre du système.';

  @override
  String get aiKeyDeleted => 'Clé supprimée.';

  @override
  String get aiEffort => 'Effort de réflexion';

  @override
  String get aiEffortDesc =>
      'Plus d\'effort : réponses plus approfondies, mais plus lentes et plus coûteuses.';

  @override
  String get aiBudget => 'Budget quotidien (jetons, 0 = illimité)';

  @override
  String get aiTest => 'Tester la connexion';

  @override
  String aiTestOk(String model) {
    return 'Connexion réussie : $model est disponible.';
  }

  @override
  String get aiPricesNote =>
      'Coûts estimés d\'après les tarifs publics relevés le 2026-11-03 ; seule la facture du fournisseur fait foi.';

  @override
  String get aiSaveSettings => 'Enregistrer';

  @override
  String get aiSettingsSaved => 'Paramètres IA enregistrés.';

  @override
  String aiKeyStorageError(String message) {
    return 'Coffre du système indisponible : $message';
  }

  @override
  String get aiEffortLow => 'Faible';

  @override
  String get aiEffortMedium => 'Moyen';

  @override
  String get aiEffortHigh => 'Élevé';

  @override
  String get compTitle => 'Compagnon Linux';

  @override
  String get compIntro =>
      'Le compagnon est un petit service qui tourne sur votre PC Linux. L\'application ne lance jamais de commande elle-même : elle demande au compagnon des opérations typées, limitées aux dossiers que vous avez autorisés, et chaque modification exige votre accord.';

  @override
  String get compHostSteps => 'Sur le PC Linux :';

  @override
  String get compAddress => 'Adresse du compagnon';

  @override
  String get compFingerprint => 'Empreinte TLS (HTTPS uniquement)';

  @override
  String get compDeviceName => 'Nom de cet appareil';

  @override
  String get compCode => 'Code d\'appairage (6 chiffres)';

  @override
  String get compCheck => 'Vérifier la connexion';

  @override
  String get compPair => 'Appairer';

  @override
  String compPaired(String address) {
    return 'Appairé avec $address';
  }

  @override
  String compScopes(String scopes) {
    return 'Portées : $scopes';
  }

  @override
  String compReachable(String version) {
    return 'Compagnon joignable (API v$version).';
  }

  @override
  String get compInfo => 'Informations du compagnon';

  @override
  String get compRoots => 'Dossiers autorisés';

  @override
  String get compFolder => 'Dossier (dans un dossier autorisé)';

  @override
  String get compGitStatus => 'État Git';

  @override
  String get compDetect => 'Détecter le projet';

  @override
  String get compGitInit => 'Initialiser Git';

  @override
  String get compReadOnly => 'Lecture seule';

  @override
  String get compMutating => 'Modification (accord demandé)';

  @override
  String get compResult => 'Résultat';

  @override
  String compState(String state) {
    return 'État : $state';
  }

  @override
  String get compAudit => 'Journal du compagnon';

  @override
  String get compAuditEmpty => 'Aucun événement pour cet appareil.';

  @override
  String get compForget => 'Oublier ce compagnon';

  @override
  String compForgetBody(String id) {
    return 'Les jetons seront supprimés de cet appareil. Pour révoquer aussi l\'accès côté PC : cambuse-companion revoke $id';
  }

  @override
  String get compApproveTitle => 'Autoriser cette opération ?';

  @override
  String get compApproveWarning =>
      'Cette opération modifie le dépôt. Rien n\'est fait sans votre accord.';

  @override
  String get compApprove => 'Autoriser';

  @override
  String get compReject => 'Refuser';

  @override
  String get compRejected => 'Opération refusée : rien n\'a été modifié.';

  @override
  String get compSettingsSubtitle => 'Appairage et opérations sur le PC Linux';

  @override
  String get compPairedOk => 'Appareil appairé.';

  @override
  String compGit(String version) {
    return 'Git : $version';
  }

  @override
  String get wsTitle => 'Chantier naval';

  @override
  String get wsSubtitle =>
      'Vos projets sur le PC Linux, via le compagnon. Rien n\'est modifié sans votre accord.';

  @override
  String get wsNotPaired =>
      'L\'Atelier passe par le compagnon Linux : l\'application n\'agit jamais seule sur vos fichiers.';

  @override
  String get wsOpenCompanion => 'Configurer le compagnon';

  @override
  String get wsProjects => 'Projets';

  @override
  String get wsNoProjects => 'Aucun sous-dossier dans ce dossier autorisé.';

  @override
  String get wsGitRepo => 'Dépôt Git';

  @override
  String get wsNoGit => 'Pas encore de Git';

  @override
  String get wsRefresh => 'Actualiser';

  @override
  String get wsTabAudit => 'Audit';

  @override
  String get wsTabChanges => 'Changements';

  @override
  String get wsTabHistory => 'Historique';

  @override
  String get wsTabBackups => 'Sauvegardes';

  @override
  String get wsRunAudit => 'Lancer l\'audit (lecture seule)';

  @override
  String get wsAuditIntro =>
      'L\'audit lit le projet sans rien modifier : secrets, gros fichiers, artefacts, .gitignore, licence et état Git.';

  @override
  String get wsBlocking => 'Bloquant';

  @override
  String get wsWarning => 'Attention';

  @override
  String get wsInfo => 'Info';

  @override
  String wsFilesCount(int files, String size) {
    return '$files fichiers analysés · $size';
  }

  @override
  String get wsNoFindings => 'Aucun problème détecté. Bon vent !';

  @override
  String get wsPlan => 'Plan proposé';

  @override
  String get wsStepBackup => '1. Sauvegarder le projet';

  @override
  String get wsStepInit => '2. Initialiser Git (branche main)';

  @override
  String wsStepGitignore(int count) {
    return '3. Compléter le .gitignore (+$count lignes)';
  }

  @override
  String wsStepFixBlocking(int count) {
    return 'Corrigez d\'abord les $count problème(s) bloquant(s) : aucun commit ne sera possible avec un secret.';
  }

  @override
  String get wsStepCommit => '4. Indexer et valider dans l\'onglet Changements';

  @override
  String get wsDone => 'Fait';

  @override
  String get wsDo => 'Exécuter';

  @override
  String get wsClean => 'Copie de travail propre : rien à valider.';

  @override
  String get wsSelectAll => 'Tout sélectionner';

  @override
  String get wsStage => 'Indexer';

  @override
  String get wsUnstage => 'Désindexer';

  @override
  String get wsDiscard => 'Annuler les modifications';

  @override
  String get wsDiscardHint => 'Une sauvegarde automatique est faite avant.';

  @override
  String get wsCommitMessage =>
      'Message de commit (impératif, ex. « Ajoute l\'écran d\'accueil »)';

  @override
  String get wsCommit => 'Valider (commit)';

  @override
  String get wsStaged => 'Indexé';

  @override
  String get wsUnstagedLabel => 'Non indexé';

  @override
  String get wsUntracked => 'Non suivi';

  @override
  String get wsDiffUntracked =>
      'Fichier non suivi : indexez-le pour voir son contenu dans le diff.';

  @override
  String get wsNoDiff => 'Aucune différence.';

  @override
  String get wsBranches => 'Branches';

  @override
  String get wsNewBranch => 'Nouvelle branche';

  @override
  String get wsCreateBranch => 'Créer';

  @override
  String get wsSwitch => 'Basculer';

  @override
  String get wsCommits => 'Derniers commits';

  @override
  String get wsNoCommits => 'Aucun commit pour l\'instant.';

  @override
  String get wsBackupNow => 'Sauvegarder maintenant';

  @override
  String get wsNoBackups => 'Aucune sauvegarde pour ce projet.';

  @override
  String get wsRestore => 'Restaurer dans un nouveau dossier';

  @override
  String wsRestoredTo(String path) {
    return 'Restauré dans : $path';
  }

  @override
  String wsBackupFiles(int count) {
    return 'Fichiers ($count)';
  }

  @override
  String get wsBackupProject => 'Projet complet';

  @override
  String wsOpDone(String op) {
    return '$op : terminé.';
  }

  @override
  String wsOpFailed(String op) {
    return '$op : échec.';
  }

  @override
  String wsBranchLabel(String branch) {
    return 'Branche : $branch';
  }

  @override
  String get fgTitle => 'GitHub et GitLab';

  @override
  String get fgSubtitle =>
      'Jetons à portée minimale, rangés dans le coffre du système';

  @override
  String get fgTokenHelp =>
      'Créez un jeton « fine-grained » limité à vos dépôts de test, avec seulement Contents, Pull requests et Issues en lecture-écriture. Ne le partagez jamais.';

  @override
  String get fgGitlabUrl => 'URL de l\'instance GitLab';

  @override
  String fgToken(String forge) {
    return 'Jeton $forge';
  }

  @override
  String get fgTest => 'Tester';

  @override
  String fgConnectedAs(String forge, String user) {
    return 'Connecté à $forge en tant que $user.';
  }

  @override
  String get wsTabPublish => 'Publication';

  @override
  String pbNoToken(String forge) {
    return 'Aucun jeton $forge : ajoutez-le dans Paramètres → GitHub et GitLab.';
  }

  @override
  String get pbOpenForges => 'Configurer les jetons';

  @override
  String get pbNoRemote => 'Ce projet n\'a pas encore de dépôt distant.';

  @override
  String get pbRepoName => 'Dépôt distant (propriétaire/nom)';

  @override
  String get pbLink => 'Associer comme origin';

  @override
  String get pbCreatePrivate => 'Créer un dépôt privé';

  @override
  String get pbCreateConfirmTitle => 'Créer un dépôt privé ?';

  @override
  String pbCreateConfirmBody(String name, String forge) {
    return 'Le dépôt « $name » sera créé sur $forge, en PRIVÉ. Vous pourrez le rendre public plus tard, uniquement depuis $forge.';
  }

  @override
  String get pbCreate => 'Créer';

  @override
  String get pbPrivate => 'PRIVÉ';

  @override
  String get pbPublic => 'PUBLIC';

  @override
  String pbDefaultBranch(String branch) {
    return 'Branche par défaut : $branch';
  }

  @override
  String get pbPush => 'Publier (push)';

  @override
  String get pbPull => 'Récupérer (pull, avance rapide)';

  @override
  String pbPanelTitle(String repo) {
    return 'Publier sur $repo ?';
  }

  @override
  String pbPanelBranch(String branch) {
    return 'Branche : $branch';
  }

  @override
  String pbPanelCommits(int count) {
    return 'Commits envoyés ($count)';
  }

  @override
  String pbPanelFiles(int count) {
    return 'Fichiers concernés ($count)';
  }

  @override
  String get pbPanelSecretsOk =>
      'Analyse des secrets sur tout l\'historique envoyé : aucun secret détecté.';

  @override
  String get pbPanelSecretsKo =>
      'Secret probable dans l\'historique envoyé : publication bloquée.';

  @override
  String get pbPanelPublicWarning =>
      'Attention : ce dépôt est PUBLIC. Tout ce qui est envoyé sera visible par tous.';

  @override
  String get pbPanelNothing => 'Rien à envoyer : le dépôt distant est à jour.';

  @override
  String get pbPanelNewBranch =>
      'La branche n\'existe pas encore sur le dépôt distant : elle sera créée.';

  @override
  String get pbPublish => 'Publier';

  @override
  String pbPushed(int count) {
    return 'Publié : $count commit(s) envoyé(s).';
  }

  @override
  String get pbChangeRequests => 'Demandes de fusion ouvertes';

  @override
  String get pbNoChangeRequests => 'Aucune demande ouverte.';

  @override
  String pbNewChangeRequest(String head, String base) {
    return 'Nouvelle demande de fusion ($head → $base)';
  }

  @override
  String get pbTitleField => 'Titre';

  @override
  String get pbBodyField => 'Description (facultatif)';

  @override
  String get pbOpen => 'Ouvrir';

  @override
  String get pbIssues => 'Tickets ouverts';

  @override
  String get pbNoIssues => 'Aucun ticket ouvert.';

  @override
  String get pbNewIssue => 'Nouveau ticket';

  @override
  String pbCreated(String url) {
    return 'Créé : $url';
  }

  @override
  String get pbErrAuth => 'Jeton refusé (401) : vérifiez-le ou régénérez-le.';

  @override
  String pbErrForbidden(String message) {
    return 'Accès refusé (403) : le jeton n\'a pas cette permission ($message).';
  }

  @override
  String get pbErrRate => 'Limite de requêtes atteinte : réessayez plus tard.';

  @override
  String get pbErrNotFound =>
      'Introuvable (404) : dépôt inexistant ou jeton sans accès à ce dépôt.';

  @override
  String pbErrValidation(String message) {
    return 'Refusé : $message';
  }

  @override
  String pbErrNetwork(String forge) {
    return 'Pas de connexion à $forge.';
  }

  @override
  String get pbErrNoToken => 'Aucun jeton enregistré.';

  @override
  String pbErrUnknown(String message) {
    return 'Erreur : $message';
  }

  @override
  String get pbScopeMissing =>
      'Cet appareil n\'a pas la portée « remote » : appairez-le avec --scopes read,git-write,remote.';
}
