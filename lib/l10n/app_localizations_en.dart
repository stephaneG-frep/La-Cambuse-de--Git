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

  @override
  String get aiTeacher => 'AI teacher';

  @override
  String get aiNewConversation => 'New conversation';

  @override
  String get aiConversations => 'Conversations';

  @override
  String get aiNoConversations => 'No conversations yet.';

  @override
  String get aiDeleteConversation => 'Delete conversation';

  @override
  String get aiDeleteConfirm =>
      'Permanently delete this conversation from this device?';

  @override
  String get aiNoKeyTitle => 'AI teacher not configured';

  @override
  String get aiNoKeyBody =>
      'Add an API key in Settings → AI teacher. Everything else in the app works offline, without AI.';

  @override
  String get aiOpenSettings => 'Configure';

  @override
  String get aiLevel => 'Level';

  @override
  String get aiLevelBeginner => 'Beginner';

  @override
  String get aiLevelIntermediate => 'Intermediate';

  @override
  String get aiLevelExpert => 'Expert';

  @override
  String get aiInputHint => 'Your question for Captain Commit';

  @override
  String get aiSend => 'Send';

  @override
  String get aiStop => 'Stop';

  @override
  String get aiThinking => 'The Captain is thinking…';

  @override
  String get aiDisclaimer =>
      'AI answers may contain mistakes. Nothing is executed automatically: check every command.';

  @override
  String aiPrivacy(String provider) {
    return 'Your questions are sent to $provider over the Internet. Do not include sensitive data.';
  }

  @override
  String get aiSecretMasked =>
      'A likely secret was masked before sending. Remember to revoke it.';

  @override
  String aiUsageLine(int tokens, String model) {
    return '$tokens tokens · $model';
  }

  @override
  String aiCostLine(String cost) {
    return '≈ $cost \$';
  }

  @override
  String aiTokensToday(int used, int budget) {
    return 'Tokens today: $used / $budget';
  }

  @override
  String aiTokensTodayUnlimited(int used) {
    return 'Tokens today: $used (no limit)';
  }

  @override
  String aiContextLesson(String title) {
    return 'Context: $title';
  }

  @override
  String get aiAsk => 'Ask the teacher';

  @override
  String get aiErrAuth =>
      'API key rejected (401). Check it in Settings → AI teacher.';

  @override
  String get aiErrPermission => 'Access denied (403) for this key.';

  @override
  String get aiErrBilling => 'Billing problem on the provider account (402).';

  @override
  String get aiErrNotFound =>
      'Model not found or not available for this account (404).';

  @override
  String aiErrInvalid(String message) {
    return 'Request rejected (400): $message';
  }

  @override
  String get aiErrTooLarge =>
      'Conversation too long (413). Start a new conversation.';

  @override
  String get aiErrRate => 'Too many requests (429). Try again shortly.';

  @override
  String get aiErrOverloaded => 'Service overloaded (529). Try again shortly.';

  @override
  String aiErrServer(String code) {
    return 'Service error ($code). Try again later.';
  }

  @override
  String get aiErrNetwork =>
      'No connection: the AI teacher needs the Internet. Lessons, quizzes and exercises remain available offline.';

  @override
  String get aiErrTimeout => 'Timed out. Check your connection.';

  @override
  String get aiErrRefusal =>
      'The model declined to answer. Rephrase your question.';

  @override
  String get aiErrBudget =>
      'Daily token budget reached. Change it in Settings → AI teacher.';

  @override
  String get aiErrCancelled => 'Answer cancelled.';

  @override
  String get aiErrNoKey => 'No API key saved.';

  @override
  String aiErrUnknown(String message) {
    return 'Unexpected error: $message';
  }

  @override
  String get aiSettingsTitle => 'AI teacher';

  @override
  String get aiProvider => 'Provider';

  @override
  String get aiProviderAnthropic => 'Anthropic (Claude)';

  @override
  String get aiProviderOpenAi => 'OpenAI-compatible (OpenAI, Mistral, Ollama…)';

  @override
  String get aiModel => 'Model';

  @override
  String get aiModelCustom => 'Model ID';

  @override
  String get aiBaseUrl => 'Base URL (e.g. https://api.mistral.ai/v1)';

  @override
  String get aiApiKey => 'API key';

  @override
  String aiKeyStored(String hint) {
    return 'Key stored in the system keychain ($hint)';
  }

  @override
  String get aiKeyNone => 'No key saved';

  @override
  String get aiKeySave => 'Save key';

  @override
  String get aiKeyDelete => 'Delete key';

  @override
  String get aiKeySaved => 'Key saved in the system keychain.';

  @override
  String get aiKeyDeleted => 'Key deleted.';

  @override
  String get aiEffort => 'Thinking effort';

  @override
  String get aiEffortDesc =>
      'More effort: deeper answers, but slower and more expensive.';

  @override
  String get aiBudget => 'Daily budget (tokens, 0 = unlimited)';

  @override
  String get aiTest => 'Test connection';

  @override
  String aiTestOk(String model) {
    return 'Connection OK: $model is available.';
  }

  @override
  String get aiPricesNote =>
      'Costs estimated from public prices recorded on 2026-11-03; only the provider\'s invoice is authoritative.';

  @override
  String get aiSaveSettings => 'Save';

  @override
  String get aiSettingsSaved => 'AI settings saved.';

  @override
  String aiKeyStorageError(String message) {
    return 'System keychain unavailable: $message';
  }

  @override
  String get aiEffortLow => 'Low';

  @override
  String get aiEffortMedium => 'Medium';

  @override
  String get aiEffortHigh => 'High';

  @override
  String get compTitle => 'Linux companion';

  @override
  String get compIntro =>
      'The companion is a small service running on your Linux PC. The app never runs commands itself: it asks the companion for typed operations, restricted to folders you allowed, and every change requires your approval.';

  @override
  String get compHostSteps => 'On the Linux PC:';

  @override
  String get compAddress => 'Companion address';

  @override
  String get compFingerprint => 'TLS fingerprint (HTTPS only)';

  @override
  String get compDeviceName => 'Name of this device';

  @override
  String get compCode => 'Pairing code (6 digits)';

  @override
  String get compCheck => 'Check connection';

  @override
  String get compPair => 'Pair';

  @override
  String compPaired(String address) {
    return 'Paired with $address';
  }

  @override
  String compScopes(String scopes) {
    return 'Scopes: $scopes';
  }

  @override
  String compReachable(String version) {
    return 'Companion reachable (API v$version).';
  }

  @override
  String get compInfo => 'Companion information';

  @override
  String get compRoots => 'Allowed folders';

  @override
  String get compFolder => 'Folder (inside an allowed folder)';

  @override
  String get compGitStatus => 'Git status';

  @override
  String get compDetect => 'Detect project';

  @override
  String get compGitInit => 'Initialise Git';

  @override
  String get compReadOnly => 'Read-only';

  @override
  String get compMutating => 'Change (approval required)';

  @override
  String get compResult => 'Result';

  @override
  String compState(String state) {
    return 'State: $state';
  }

  @override
  String get compAudit => 'Companion log';

  @override
  String get compAuditEmpty => 'No events for this device.';

  @override
  String get compForget => 'Forget this companion';

  @override
  String compForgetBody(String id) {
    return 'Tokens will be deleted from this device. To also revoke access on the PC: cambuse-companion revoke $id';
  }

  @override
  String get compApproveTitle => 'Allow this operation?';

  @override
  String get compApproveWarning =>
      'This operation changes the repository. Nothing happens without your approval.';

  @override
  String get compApprove => 'Allow';

  @override
  String get compReject => 'Reject';

  @override
  String get compRejected => 'Operation rejected: nothing was changed.';

  @override
  String get compSettingsSubtitle => 'Pairing and operations on the Linux PC';

  @override
  String get compPairedOk => 'Device paired.';

  @override
  String compGit(String version) {
    return 'Git: $version';
  }

  @override
  String get wsTitle => 'Shipyard';

  @override
  String get wsSubtitle =>
      'Your projects on the Linux PC, through the companion. Nothing changes without your approval.';

  @override
  String get wsNotPaired =>
      'The Workshop goes through the Linux companion: the app never acts on your files by itself.';

  @override
  String get wsOpenCompanion => 'Set up the companion';

  @override
  String get wsProjects => 'Projects';

  @override
  String get wsNoProjects => 'No subfolder in this allowed folder.';

  @override
  String get wsGitRepo => 'Git repository';

  @override
  String get wsNoGit => 'No Git yet';

  @override
  String get wsRefresh => 'Refresh';

  @override
  String get wsTabAudit => 'Audit';

  @override
  String get wsTabChanges => 'Changes';

  @override
  String get wsTabHistory => 'History';

  @override
  String get wsTabBackups => 'Backups';

  @override
  String get wsRunAudit => 'Run audit (read-only)';

  @override
  String get wsAuditIntro =>
      'The audit reads the project without changing anything: secrets, large files, artefacts, .gitignore, licence and Git state.';

  @override
  String get wsBlocking => 'Blocking';

  @override
  String get wsWarning => 'Warning';

  @override
  String get wsInfo => 'Info';

  @override
  String wsFilesCount(int files, String size) {
    return '$files files scanned · $size';
  }

  @override
  String get wsNoFindings => 'No problem found. Fair winds!';

  @override
  String get wsPlan => 'Proposed plan';

  @override
  String get wsStepBackup => '1. Back up the project';

  @override
  String get wsStepInit => '2. Initialise Git (main branch)';

  @override
  String wsStepGitignore(int count) {
    return '3. Complete .gitignore (+$count lines)';
  }

  @override
  String wsStepFixBlocking(int count) {
    return 'Fix the $count blocking problem(s) first: no commit is possible with a secret.';
  }

  @override
  String get wsStepCommit => '4. Stage and commit in the Changes tab';

  @override
  String get wsDone => 'Done';

  @override
  String get wsDo => 'Run';

  @override
  String get wsClean => 'Working tree clean: nothing to commit.';

  @override
  String get wsSelectAll => 'Select all';

  @override
  String get wsStage => 'Stage';

  @override
  String get wsUnstage => 'Unstage';

  @override
  String get wsDiscard => 'Discard changes';

  @override
  String get wsDiscardHint => 'An automatic backup is made first.';

  @override
  String get wsCommitMessage =>
      'Commit message (imperative, e.g. \"Add home screen\")';

  @override
  String get wsCommit => 'Commit';

  @override
  String get wsStaged => 'Staged';

  @override
  String get wsUnstagedLabel => 'Not staged';

  @override
  String get wsUntracked => 'Untracked';

  @override
  String get wsDiffUntracked =>
      'Untracked file: stage it to see its content in the diff.';

  @override
  String get wsNoDiff => 'No differences.';

  @override
  String get wsBranches => 'Branches';

  @override
  String get wsNewBranch => 'New branch';

  @override
  String get wsCreateBranch => 'Create';

  @override
  String get wsSwitch => 'Switch';

  @override
  String get wsCommits => 'Latest commits';

  @override
  String get wsNoCommits => 'No commits yet.';

  @override
  String get wsBackupNow => 'Back up now';

  @override
  String get wsNoBackups => 'No backup for this project.';

  @override
  String get wsRestore => 'Restore into a new folder';

  @override
  String wsRestoredTo(String path) {
    return 'Restored into: $path';
  }

  @override
  String wsBackupFiles(int count) {
    return 'Files ($count)';
  }

  @override
  String get wsBackupProject => 'Full project';

  @override
  String wsOpDone(String op) {
    return '$op: done.';
  }

  @override
  String wsOpFailed(String op) {
    return '$op: failed.';
  }

  @override
  String wsBranchLabel(String branch) {
    return 'Branch: $branch';
  }
}
