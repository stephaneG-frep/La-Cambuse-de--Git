
LA CAMBUSE DE GIT — DESIGN.md
Version 1.0 — Direction artistique et UX
Intention
Une cambuse de navire pirate reconvertie en laboratoire DevOps : cuivre, bois sombre, cadrans, câbles lumineux, terminaux, cartes marines transformées en graphes Git. Une identité mémorable, expressive et amusante, mais jamais au détriment de la lisibilité.
Personnages
- Capitaine Commit : pirate-informaticien excentrique, pédagogue, lunettes techniques, tricorne et bras-outil. Il guide sans infantiliser.
- Mousse Byte : petit robot énergique qui montre erreurs, astuces et réussites.
  Créer des illustrations originales ; ne pas copier de personnages protégés.
Palette proposée
Fond nuit #101927 ; surface #1B2B3B ; cuivre #D58B45 ; turquoise #42D8C9 ; or #F4C66A ; alerte #EF6A62 ; texte #F3F6F7 ; texte secondaire #B9C7D0. Respecter contrastes WCAG AA et mode contraste renforcé.
Typographie et composants
Police sans-serif lisible pour interface, monospace pour code. Titres expressifs, jamais au détriment des écrans techniques. Cartes arrondies avec bordures cuivre, onglets en forme de plaques de navire, barres de progression inspirées de jauges, badges de rang. Animations discrètes et désactivables.
Navigation
Accueil = pont du navire. Trois accès visibles : Académie, Atelier, Capitaine automatique. Navigation adaptée téléphone (barre inférieure) et Linux (rail latéral + panneaux redimensionnables). Une action principale par écran ; états chargement/vide/erreur/succès ; recherche globale ; raccourcis clavier Linux.
Écrans signatures
1. Carte des îles de compétences : chaque île représente un module, avec prérequis et avancement.
2. Salle des machines : console d'apprentissage, code exécutable uniquement en bac à sable et sortie expliquée.
3. Chantier naval : cartes des projets, état Git, santé des builds, connecteurs.
4. Table de navigation : plan des actions IA, étapes, risques, coûts, demandes de validation.
5. Cale des artefacts : APK, .deb, ZIP, checksums, statut signature et tests.
6. Journal de bord : actions, diff, décisions, erreurs et reprise.
Ton rédactionnel
Humour pirate léger dans les titres, précision technique dans les instructions. Ex. « Hissez les tests ! » mais message d'erreur concret : « flutter test a échoué : 2 tests sur 18. Voir les logs. »
Accessibilité et adaptation
Taille texte dynamique, navigation clavier, cibles tactiles ≥ 48dp, sémantique lecteur d'écran, réduction du mouvement, indicateurs de progression non fondés uniquement sur la couleur, mode paysage et écrans étroits, contrastes vérifiés.
Interactions sensibles
Avant un push ou une publication : panneau montrant dépôt, branche, visibilité, fichiers ajoutés, détection de secrets, action exacte et bouton de confirmation. Jamais de confirmation trompeuse ni de « oui à tout » permanent.
Livrables design
Tokens Flutter centralisés, composants réutilisables, icônes cohérentes, maquettes téléphone et bureau, états de chaque écran, thème clair optionnel et guide de microcopies.