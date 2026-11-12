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
}
