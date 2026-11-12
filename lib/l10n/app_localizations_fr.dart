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
}
