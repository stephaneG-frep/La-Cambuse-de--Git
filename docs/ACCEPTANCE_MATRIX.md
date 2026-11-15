# Matrice des fonctionnalités et d'acceptation

États : ⬜ non commencé · 🟨 partiel · ✅ réel et testé · ⛔ bloqué

Dernière mise à jour : 2026-11-14 (fin de phase 11)

| Phase | Fonctionnalité | État | Preuve / remarque |
|---|---|---|---|
| 0 | Diagnostic environnement | ✅ | [PHASE0_DIAGNOSTIC.md](PHASE0_DIAGNOSTIC.md) |
| 0 | Décisions, menaces, contrat API, matrice OS | ✅ | idem §2–7 |
| 1 | Projet Flutter Android + Linux | ✅ | builds Linux release et APK debug arm64 réussis |
| 1 | Thème tokens pirate-steampunk, contraste AA | ✅ | tests de contraste ; illustrations personnages non faites |
| 1 | Navigation adaptative (barre / rail) | ✅ | tests widgets + raccourcis clavier ; panneaux redimensionnables non faits |
| 1 | i18n FR (EN préparé) | ✅ | FR + EN interface |
| 1 | Persistance Drift + migrations testées | ✅ | migration v1→v2 testée et réalisée sur appareil réel |
| 1 | Accueil et journal de bord fonctionnels | ✅ | [PHASE1_BILAN.md](PHASE1_BILAN.md) |
| 1 | CI analyse + tests | ✅ | **Correction** : la CI avait tourné et échoué sur le dépôt public (affirmation « non exécutée » erronée) ; corrigée en phase 11, verte sur GitHub (exécution 43637187905) |
| 2 | Module Git complet (≥ 8 leçons, quiz, exercices, projet, grille) | ✅ | 14 leçons, 60 questions, 12 exercices rejoués, projet + grille — [PHASE2_BILAN.md](PHASE2_BILAN.md) |
| 2 | Progression persistante, reprise après redémarrage | ✅ | widget + Honor (base lue après redémarrage) ; répétition espacée Leitner |
| 3 | Agent IA multifournisseur, coffre de clés, mode sans IA | ✅ | Anthropic testé en réel sur Honor ; compatible OpenAI testé sur serveur simulé — [PHASE3_BILAN.md](PHASE3_BILAN.md) |
| 4 | Compagnon Linux, appairage, API v1 | ✅ | 27 tests sécurité + contrat réel ; essai réel Honor (lecture + mutation approuvée) ; LAN TLS essayé depuis le téléphone en phase 11 (empreinte épinglée, fausse empreinte refusée) — [PHASE4_BILAN.md](PHASE4_BILAN.md) |
| 5 | Atelier Git local (import, audit, diff, init, commit) | ✅ | 39 tests compagnon, 174 app ; scénario complet réel sur Honor — [PHASE5_BILAN.md](PHASE5_BILAN.md) |
| 6 | GitHub / GitLab (dépôt privé, push avec consentement) | ✅ | GitHub réel (push, PR #1, ticket #2) ; GitLab réel le 2026-11-15 (projet privé, push, MR !1, ticket #1) — [PHASE6_BILAN.md](PHASE6_BILAN.md) |
| 7 | Docker et Compose | ✅ | modules Docker + Compose (13 labos), analyseurs, inspection lecture seule, génération ; essai réel Honor — [PHASE7_BILAN.md](PHASE7_BILAN.md) |
| 8 | CI/CD générée, APK debug, .deb, checksums | ✅ | CI générée et builds approuvés depuis le Honor, cale « DEBUG », `.deb` construit et vérifié sans installation ; la CI du dépôt échouait en réalité (corrigée en phase 11) — [PHASE8_BILAN.md](PHASE8_BILAN.md) |
| 9 | Académie avancée | ✅ | 8 modules (79 leçons, 316 questions, 48 labos réalisables, 8 projets), 9 analyseurs ; essai réel Honor ; contenu non relu par un expert humain — [PHASE9_BILAN.md](PHASE9_BILAN.md) |
| 10 | Capitaine automatique | ✅ | 4 missions + plan IA validé, point de contrôle, approbations, consentement spécifique, pause, arrêt d'urgence, reprise, rapport, retour arrière ; 20 scénarios de défaillance ; essai réel Honor (mission complète, arrêt pendant un build, publication refusée) — [PHASE10_BILAN.md](PHASE10_BILAN.md) |
| 11+ | Synchronisation de la progression entre appareils | ✅ | portée `sync`, fusion sans perte ; essai réel Honor ↔ application Linux réelle via le compagnon en réseau local — [RAPPORT_FINAL.md](RAPPORT_FINAL.md) §6 bis |
| 11 | Stabilisation et livraison | ✅ | audit (aucun secret réel, faux positifs bloquants corrigés), CI verte sur GitHub (3 jobs), accessibilité testée, guide de bord, mesures de performance, livrables — [PHASE11_BILAN.md](PHASE11_BILAN.md), [RAPPORT_FINAL.md](RAPPORT_FINAL.md) |

## Critères MVP (SPEC §12)

| Critère | État |
|---|---|
| APK debug installé sur appareil + .deb sur Linux, démarrage sans écran blanc | ✅ APK installé et démarré sur Honor MTN-NX1M ; `.deb` installé sur Ubuntu 22.04 (dpkg --verify propre), application installée démarrée en 226 ms, compagnon installé répondant HTTP 200 |
| Profil local, 1 module Git complet, progression conservée | ✅ |
| Chat IA avec fournisseur ; contenu consultable sans fournisseur | ✅ (claude-opus-5-5, essai réel) |
| Import projet Flutter Linux, audit, diff, plan sans mutation non consentie | ✅ (via compagnon ; essai réel depuis le Honor) |
| Git local, dépôt privé de test avec consentement, push, rapport | ✅ (dépôt privé créé via gh avec accord ; push, PR et ticket depuis le Honor) |
| Pipeline analyse/tests + APK de test, limites de signature affichées | ✅ (pipeline généré, analyse/tests/APK debug réels via le compagnon, « DEBUG — non distribuable » affiché) |
| Logs, erreurs, artefacts, historique, reprise après échec | ✅ (journal de bord, cale des artefacts, journal horodaté des missions, reprise d'une mission interrompue après redémarrage) |
