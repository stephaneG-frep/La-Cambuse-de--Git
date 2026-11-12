# Bilan — Phase 1 : fondations et design

Date : 2026-11-12. Toutes les commandes listées ont été exécutées sur la machine de développement (Ubuntu 22.04, Flutter 3.47.2).

## 1. Fonctionnalités livrées et réellement testées

| Fonctionnalité | Testée comment |
|---|---|
| Thème à jetons + contraste renforcé | `test/app/contrast_test.dart` : 6 couleurs × 2 fonds × 2 palettes ≥ 4,5:1 |
| Navigation adaptative | widget : barre sur 400 px, rail sur 1280 px |
| Raccourcis Ctrl+2, Ctrl+5, Ctrl+, | widget (événements clavier simulés) |
| i18n FR/EN | widget : bascule en anglais, libellés changés |
| Persistance Drift | fichier temporaire fermé/rouvert ; **binaire Linux lancé 2 fois → 2 entrées en base** |
| Atomicité des paramètres | transaction annulée → aucune écriture |
| Profil local | validation, création, renommage, consignation |
| Journal de bord | filtre, ordre, export JSON, effacement après confirmation (annulation testée) |
| Masquage des secrets | 10 familles de secrets + absence de faux positif sur texte courant |
| Accessibilité | `androidTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline` (téléphone et bureau) ; texte à 200 % sans débordement |

Sections Académie (phase 2), Atelier (phase 5) et Capitaine (phase 10) : écrans **explicitement marqués « en construction — phase N »**, sans bouton ni fonctionnalité simulée.

## 2. Commandes et résultats exacts

| Commande | Résultat |
|---|---|
| `flutter analyze --fatal-infos` | `No issues found!` |
| `flutter test` | `+61: All tests passed!` (52 unitaires/BD + 9 widgets) |
| `flutter build linux --release` | `✓ Built build/linux/x64/release/bundle/la_cambuse` |
| Lancement réel du binaire Linux | fenêtre affichée (capture vérifiée), base créée dans `~/.local/share/fr.lacambuse.la_cambuse/` |
| `flutter build apk --debug --target-platform android-arm64` | `✓ Built build/app/outputs/flutter-apk/app-debug.apk` (100 Mo) |
| `apksigner verify --print-certs` | signataire `CN=Android Debug` → **APK de test, non distribuable** |
| Validation YAML de la CI | `yaml.safe_load` OK |

Sommes SHA-256 (artefacts locaux, non versionnés) :

```
22cfe313e0084f9c70c815d8c57d9be09a07864c8bee4743c141feb3ad91fe78  app-debug.apk (arm64-v8a)
402e2e5cd65f2709803c54e3be22244c26163fc5b83057251280066e9ba6b557  bundle/la_cambuse
9574b0414e1b32bcbabc2925cf58cb0aa89b839171500fed040fe520ebb4f8d1  bundle/lib/libapp.so
```

## 3. Non exécuté (explicitement)

- **CI sur GitHub** : aucun dépôt distant configuré, rien n'a été poussé. Les mêmes commandes ont été lancées localement.
- **Installation de l'APK sur l'appareil** `MTN-NX1M` : appareil détecté mais installation non faite sans votre accord.
- Lecteur d'écran réel (TalkBack / Orca) : seules les règles automatiques Flutter ont été vérifiées.
- Saisie dans l'app Linux réelle : non automatisée (pas de `xdotool`) ; le parcours profil est couvert par les tests de widgets.

## 4. Problèmes trouvés et corrigés pendant la phase

1. `drift_flutter` créait la base dans `~/Documents` → déplacée vers le dossier de support ; le fichier créé par l'essai a été supprimé.
2. Curseur de taille de texte : une écriture + une entrée de journal par mouvement → aperçu non persistant, enregistrement au relâchement.
3. Tests de widgets bloqués à la fermeture de Drift dans le temps simulé → fermeture via `tester.runAsync`.
4. Titre de fenêtre Linux et libellé Android « la_cambuse » → « La Cambuse de Git ».

## 5. Limites et risques ouverts

- L'APK contient des bibliothèques natives complètes **uniquement pour arm64-v8a** (cible prioritaire de la SPEC).
- Actions GitHub épinglées par étiquette (`@v4`, `@v2`) et non par SHA : à durcir en phase 8.
- Illustrations originales des personnages (Capitaine Commit, Mousse Byte) : non réalisées ; prévues avec le contenu de l'Académie.
- Thème clair optionnel, recherche globale et panneaux redimensionnables : non livrés (recherche utile seulement quand le contenu existera, phase 2).
- `.deb` : prévu en phase 8 (dpkg-deb et fakeroot disponibles ; lintian absent).

## 6. Prérequis de la phase 2 : satisfaits

Persistance, navigation, thème, i18n et tests sont en place pour accueillir le module Git, ses leçons, quiz et la progression.
