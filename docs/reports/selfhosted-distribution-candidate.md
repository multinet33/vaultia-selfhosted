# Candidat de distribution auto-hébergée — rapport de validation

Date : 26/09/2026. Pré-version `0.1.0-rc.1` : **pas** une version finale (aucun tag `v1.0.0`,
version applicative `0.1.0`, aucun `latest`).

## 1. Références exactes

| Élément | Valeur |
| --- | --- |
| Source Vaultia (dépôt privé `multinet33/Vaultia`) | `150c5a6678c6065c04e4adfd7d426e003ed11361` |
| Image | `ghcr.io/multinet33/vaultia:0.1.0-rc.1` — aussi `:sha-150c5a6678c6065c04e4adfd7d426e003ed11361` (immuables) et `:rc` (mobile) |
| Digest de l'index multi-architecture | `sha256:61b4d5945735edfdeb0a65577cc40d0f3f68eda372190775095b16df0b3ef0cb` |
| Manifeste `linux/amd64` | `sha256:14030b48f26b2765b603deb5700836a66b389d07cddad65bd8c1a4783c0d66a5` |
| Manifeste `linux/arm64` | `sha256:029521a180046c3931d568574b60e775a1d30789b3f7837199f8605a279bb696` |
| Attestations | provenance (buildx `mode=max`) et SBOM, attachées à l'index |
| Annotations / étiquettes OCI | `revision` = SHA source complet, `version` = `0.1.0-rc.1` (index) / `0.1.0` (image), `licenses` = `PolyForm-Noncommercial-1.0.0`, `source`, `created` |
| Publication | workflow `Image candidate` (GitHub Actions, run `36243337618`), jeton `GITHUB_TOKEN`, aucun secret stocké |
| Visibilité | paquet **public** : tirage anonyme vérifié (jeton anonyme du registre, HTTP 200 sur le manifeste) |
| Distribution validée | `vaultia-selfhosted` `d03986b3803e4d65ca70c3028f52ea660bfc62b7` |
| CI source | `CI` vert sur `150c5a6` (run `36242983750`) : lint, types, **2228/2228** unitaires sans aucun test sauté (modèle obligatoire, Tesseract présent), intégration Intelligence, E2E capture + Intelligence sur build de production **10/10** |

## 2. Architectures construites

| Architecture | Construction | Vérification |
| --- | --- | --- |
| `linux/amd64` | GitHub Actions (runner `ubuntu-24.04`, amd64 natif) | job `smoke-amd64` sur **vrai Linux amd64** (machine virtuelle GitHub, sans émulation) : `runtime-smoke` 8/8, provisionnement du modèle, `Vaultia Vision: READY` avec inférence réelle, second provisionnement sans téléchargement |
| `linux/arm64` | GitHub Actions : build Next.js natif (amd64), dépendances d'exécution installées pour arm64 sous QEMU | ce rapport : validation complète sur Linux arm64 **en machine virtuelle Docker Desktop (Apple Silicon)** et smoke sur runner GitHub arm64 — exécution arm64 native, **pas** un hôte Linux arm64 réel (§ 14) |


## 3. Installation propre

Environnement : macOS arm64, Docker Desktop 27.3.1 (VM Linux arm64, 8 CPU, 7,7 Gio). Nouveau
projet Compose, **aucun volume** préexistant, image Vaultia retirée du cache avant le test, clone
neuf de `vaultia-selfhosted` depuis GitHub (le dépôt source n'est pas cloné). README suivi à la
lettre : `cp .env.example .env`, les deux secrets générés par les commandes documentées, puis
`docker compose pull` / `docker compose up -d`.

Écarts imposés par la machine de test, sans effet sur ce qui est validé : nom de projet
`-p vaultia-lot4` et port `3400` (le projet `vaultia` et le port 3000 sont déjà utilisés par
l'environnement de développement de ce poste) ; `VAULTIA_SUBNET` distinct par instance.

| Mesure | Valeur |
| --- | --- |
| Tirage de l'image | 28 s (les couches de base `node:24-bookworm-slim` étaient déjà en cache local ; un premier tirage complet télécharge ~612 Mio) |
| Application saine (`healthy`, `/api/health` 200) | 13 s après `up -d` |
| Vision prête (`"vision":"ready"`) | 13 s après `up -d` |
| Provisionnement du modèle | 2,2 s (90,2 Mio, connexion rapide ; la durée dépend du débit) |
| Premier compte | `POST /api/auth/sign-up/account` → 200 ; second compte sans invitation → **403 `SIGN_UP_CLOSED`** (`first-user` par défaut) |

## 4. Volume de téléchargement et empreinte disque

| Élément | Téléchargé (compressé) | Sur disque |
| --- | --- | --- |
| Image Vaultia | 611,7 Mio (arm64) / 616,0 Mio (amd64) | 1,68 Go |
| Image `postgres:18-alpine` | 112,4 Mio (arm64) / 114,5 Mio (amd64) | 298 Mo |
| Modèle SigLIP 2 | 90,2 Mio | 94,6 Mo (volume `models`) |
| **Total premier démarrage** | **≈ 814 Mio (arm64) / ≈ 821 Mio (amd64)** | **≈ 2,1 Go** avant données |
| Base avec le jeu de données du § 6 | — | 72 Mo |

## 5. Ressources (mesures ponctuelles, pas des performances garanties)

| État | Vaultia | PostgreSQL |
| --- | --- | --- |
| Au repos, après démarrage | 258 Mio | 60 Mio |
| Pendant l'inférence (3 × `vision-status`, 13 échantillons) | pic 534 Mio | — |
| Inférence SigLIP 2 (CPU, 1 image) | 0,6 à 1,9 s selon la charge | — |

## 6. Jeu de données fonctionnel

Données **synthétiques** créées par les parcours du produit : compte par la route d'inscription
HTTP, puis la fixture « Espace complet » du dépôt source (`tests/support/full-workspace.ts`),
exécutée **dans le conteneur de l'image candidate**, qui passe par les services de l'application
(aucune écriture SQL directe).

| Entité | Nombre |
| --- | --- |
| Utilisateur / Espace / Propriété / Espace (pièce) | 1 / 1 / 1 / 1 |
| Objets (dont imbriqués) / Collection | 7 / 1 |
| Véhicule / interventions véhicule / dépense véhicule | 1 / 2 / 1 |
| Documents du coffre : portée Espace / portée **PERSONAL** | 1 / 1 |
| Médias : JPEG / PDF / texte | 5 / 4 / 1 |
| Valorisations : objet / propriété / véhicule | 3 / 1 / 1 |
| Dépenses / entretiens d'objet | 4 / 1 |

Référence de comparaison : empreinte de **chaque** table (82 tables : nombre de lignes et md5 du
contenu trié), stable à 20 s d'intervalle.

## 7. Inventaire des modèles

| Modèle | Révision | Taille | SHA-256 | Provisionné |
| --- | --- | --- | --- | --- |
| SigLIP 2 base patch16-224, encodeur d'image ONNX int8 (`onnx-community/siglip2-base-patch16-224-ONNX`) | `ba1f3b0843f24bc5417d38e19c37b287d719b2f4` | 94 553 333 o | `5f2b401c1a4fc095702a5d45348e17ad46c4f87064085365b43c6e8eaa5c0070` | automatiquement, au premier démarrage |

C'est **le seul** artefact de modèle de la pile locale (inventaire complet :
[distribution-audit.md § 3](distribution-audit.md#3-inventaire-exhaustif-vision--intelligence)).
Tesseract (`fra`, `eng`), ZXing (WASM), pdf.js et les règles d'extraction sont dans l'image.

## 8. Matrice Vision

### 8.1 Moteurs réels, dans le conteneur de distribution (FR / EN)

| Capacité | Entrée | Moteur | Résultat | Verdict |
| --- | --- | --- | --- | --- |
| VISION_CLASSIFICATION (FR) | photo de canapé | siglip2-vision | « Canapé » (concept `sofa`) | PASS |
| VISION_CLASSIFICATION (EN) | photo de canapé | siglip2-vision | « Sofa » (concept `sofa`) | PASS |
| VISION_CLASSIFICATION (FR, EN) | photo de guitare | siglip2-vision | concept `acoustic-guitar` | PASS |
| VISION_ATTRIBUTES (FR) | aplat rouge | siglip2-vision | `color: Rouge` | PASS |
| VISION_ATTRIBUTES (EN) | aplat rouge | siglip2-vision | `color: Red` | PASS |
| OCR (FR) | étiquette « Numéro de série : BX-2291 » | tesseract-ocr | texte reconnu | PASS |
| OCR (EN) | étiquette « Serial number: BX-2291 » | tesseract-ocr | texte reconnu | PASS |
| BARCODE | EAN-13 `4006381333931` sur une étiquette photo | zxing-barcode | décodé | PASS |
| BARCODE | QR code | zxing-barcode | décodé | PASS |
| DOCUMENT_EXTRACTION (FR) | facture PDF française (texte natif, pdf.js) | document-rules | ÉLECTRO CONFORT SAS · F-2026-00123 · 1486.80 EUR | PASS |
| DOCUMENT_EXTRACTION (EN) | facture PDF américaine | document-rules | 389.68 USD · 2026-09-12 · Sony WH-1000XM5 | PASS |
| OCR + DOCUMENT_EXTRACTION (FR) | facture PDF **scannée** (rendu pdf.js → Tesseract → règles) | tesseract-ocr + document-rules | ÉLECTRO CONFORT SAS · 1486.80 | PASS |
| Contrôle complet | `vaultia vision-status` | tous les moteurs locaux | `Vaultia Vision: READY` | PASS |

### 8.2 Parcours E2E du produit contre l'image candidate

`capture.spec.ts`, `intelligence.spec.ts`, `documents.spec.ts`, `scanner.spec.ts` (Chromium,
0 nouvel essai), lancés contre une **seconde instance de la même image et du même
`compose.yaml`**, avec une surcouche de test : base publiée sur la boucle locale et fichiers en
montage lié, pour que les fixtures Playwright écrivent comme la suite habituelle. L'instance de
distribution n'est pas modifiée.

| Parcours (intégrations Objet et justificatifs comprises) | Verdict |
| --- | --- |
| photo → analyse réelle → revue → **objet** créé par les services, photo promue | PASS |
| code scanné par le navigateur : identifiant proposé, doublon signalé | PASS |
| **facture PDF → analyse réelle (OCR, extraction) → revue → achat** enregistré, justificatif rattaché | PASS |
| PDF protégé : refus explicite | PASS |
| suivi des traitements : suggestions, avancement, annulation, relance refusée | PASS |
| scanner : caméra, code connu/inconnu, QR Vaultia (génération, scan, refus), repli WASM sans BarcodeDetector | PASS |
| Vision désactivée (défaut d'un Espace) : saisie manuelle ; lecteur : refus | PASS |
| 375 px sans débordement (capture, justificatifs, réglages) | PASS |
| **Total** | **24 PASS, 1 écart attendu, 1 sauté attendu** |

Écarts, dus à la configuration de distribution (aucun fournisseur externe) et non à un défaut :

- `intelligence.spec.ts:49` attend « Traitement externe non autorisé » sur la ligne « Données
  produit » : la suite décrit l'instance de **développement**, où `open-facts` (externe) est
  installé. La distribution ne l'installe pas : la ligne affiche « Aucun moteur · À venir ».
  Relancé avec `open-facts` installé (refusé en mode local, aucun appel réseau) : **5/5 PASS**.
- `scanner.spec.ts:610` se saute lui-même sans `open-facts` : recherche produit **externe**
  (classe C), hors de la vision locale.

Intégration du coffre de documents : l'analyse des justificatifs rattache le PDF (parcours
ci-dessus) ; les documents du coffre en portées Espace et PERSONAL du jeu de données sont vérifiés
par `storage-verify`, la sauvegarde et la restauration (§ 11).

## 9. Inférence locale hors ligne

Sortie Internet du conteneur Vaultia coupée (iptables dans son espace réseau : seuls la boucle
locale et le réseau interne restent permis), modèles déjà installés. Vérifié : `huggingface.co` et
`world.openproductsfacts.org` injoignables depuis le conteneur.

| Contrôle | Résultat |
| --- | --- |
| `vaultia vision-status` (inférence réelle) | `Vaultia Vision: READY` |
| E2E des 4 specs Vision | **24 PASS**, mêmes écarts attendus qu'en ligne |
| Instance démarrée hors ligne **sans** modèle (LOT 2) | application `healthy`, `vision: failed`, nouvel essai à 30 s puis 60 s, message « source du modèle injoignable », **0 redémarrage** du conteneur |

Aucune capacité locale n'a besoin d'Internet après installation. Aucune n'appelle de service
d'IA tiers. `open-facts`, seul fournisseur externe, n'est pas installé par défaut. Télémétrie :
Next.js, Prisma et ONNX Runtime (`ORT_DISABLE_TELEMETRY=1`, ajouté pendant ce lot après
constatation d'une tentative d'envoi HTTPS d'ONNX Runtime, seulement empêchée par l'absence de
certificats système) sont désactivés dans l'image.

## 10. Persistance

| Épreuve | Données (82 tables) | Fichiers (`storage-verify`) | Modèle | Vision |
| --- | --- | --- | --- | --- |
| `docker compose restart` | 80 identiques ; 2 changées (voir note) | 10/10 intègres | non retéléchargé (date inchangée) | READY |
| `docker compose down` + `up -d` (sans `-v`) | idem | 10/10 intègres | « déjà présent et intègre » | READY |
| Redémarrage de l'hôte | **NON TESTÉ** : poste de développement macOS, pas d'hôte ni de VM Linux dédiés redémarrables ici. À faire sur l'hôte Oracle ARM64. | | | |

Note : `webhook_deliveries` et `webhook_subscriptions` gardent le même nombre de lignes. Leur
contenu change parce que le worker retente au démarrage la livraison vers la destination
volontairement injoignable de la fixture (compteurs d'essais, prochaine tentative). C'est un état
de fonctionnement, pas une donnée métier.

## 11. Sauvegarde et restauration

`COMPOSE="docker compose -p vaultia-lot4" ./scripts/backup.sh` (script de la distribution, repris
de `deploy/backup.sh`) :

| Contrôle | Résultat |
| --- | --- |
| `pg_dump` | `database.dump` 482 Kio |
| Fichiers | `media.tar` (17 entrées) |
| `storage-verify` avant copie | `storage_verify=ok` |
| `SHA256SUMS` | `database.dump: OK`, `media.tar: OK` |
| `MANIFEST` | version 0.1.0, PostgreSQL 18.6, 54 migrations |
| Modèle dans la sauvegarde | **non** (artefact d'exécution, comme documenté) |
| Restauration (`scripts/restore.sh`) sur une instance neuve, même `.env` | 82 tables **identiques** à l'original, `storage-verify` 10/10, modèle réinstallé seul, `vision: ready`, connexion du compte restauré 200 |

## 12. Altérations

| Épreuve | Détection | Reprise | Données métier |
| --- | --- | --- | --- |
| Modèle : 1 octet modifié dans le volume | `/api/health` → `vision: missing` ; `models-verify` → `ALTÉRÉ (SHA-256)` ; `vision-status` → `NOT READY` | au redémarrage : « altéré (empreinte), nouveau téléchargement » → vérifié → `READY` (réparation manuelle `models-provision` validée au LOT 2) | 82 tables identiques |
| Fichier : 1 JPEG modifié, 1 PDF supprimé | `storage-verify` : `altéré …jpg`, `manquant …pdf`, code de sortie **1** | fichiers remis → 0 manquant, 0 altéré, code **0** | — |

## 13. Mise à jour

Aucun candidat antérieur publié : `0.1.0-rc.1` est le premier. Aucun changement de schéma entre les
builds disponibles (54 migrations). Épreuve réalisée : **remplacement d'image à schéma inchangé**.

| Étape | Résultat |
| --- | --- |
| Candidat N : image pré-version du LOT 2 (`vaultia-candidate:arm64`, support des modèles), choisie par `VAULTIA_IMAGE` | instance saine, Vision prête, jeu de données complet |
| Sauvegarde (`scripts/backup.sh`) | `storage_verify=ok` |
| Candidat N+1 : `VAULTIA_IMAGE` vidé (image épinglée `0.1.0-rc.1@sha256:61b4…`), `docker compose pull` + `up -d` | révision `150c5a6…` en service |
| Migrations | « 54 migrations found … No pending migrations to apply » |
| Données | 82 tables **identiques** avant / après |
| Fichiers / modèle / Vision | `storage-verify` 10/10 ; modèle « déjà présent et intègre », non retéléchargé ; READY |

Limite : une mise à jour **avec** migrations entre deux candidats n'a pas encore pu être exercée
par la distribution. Le mécanisme (`prisma migrate deploy` au démarrage) est celui validé en V1
(48 → 49 migrations, rapport Step 18 du dépôt source).

## 14. Architectures (LOT 5)

### 14.1 Manifeste multi-architecture

Vérifié **anonymement** sur le registre (jeton anonyme, API OCI) :

| Référence | Digest résolu |
| --- | --- |
| `0.1.0-rc.1` | `sha256:61b4d5945735edfdeb0a65577cc40d0f3f68eda372190775095b16df0b3ef0cb` |
| `sha-150c5a6678c6065c04e4adfd7d426e003ed11361` | idem |
| `rc` | idem |
| `latest` | **absent** (404) |

L'index contient `linux/amd64` (`sha256:14030b48…66a5`), `linux/arm64` (`sha256:029521a1…b696`)
et deux manifestes d'attestation (provenance, SBOM). Chaque runner a tiré la variante de son
architecture (`docker image inspect` : `amd64` / `arm64`, révision `150c5a6…`).

### 14.2 Smoke test de la distribution sur runners GitHub

Workflow public `Distribution smoke` (`.github/workflows/distribution-smoke.yml`, run
`36245970441`, distribution `572d004`) : README suivi sur une machine neuve, tirage **anonyme** de
l'image épinglée, santé, Vision, traitements locaux, politique d'inscription, redémarrage,
sauvegarde.

| Contrôle | `ubuntu-24.04` | `ubuntu-24.04-arm` |
| --- | --- | --- |
| `uname -m` | `x86_64` | `aarch64` |
| Tirage des images | 26,8 s | 27,7 s |
| Image lancée | `amd64`, révision `150c5a6…` | `arm64`, révision `150c5a6…` |
| `/api/health` `status: ok` + `vision: ready` | 5 s | 5 s |
| Conteneur `healthy` | oui | oui |
| `vision-status` (inférence réelle) | READY, 503 ms | READY, 423 ms |
| `runtime-smoke` | 8/8 | 8/8 |
| Premier compte / second sans invitation | 200 / 403 | 200 / 403 |
| `restart` : modèle non retéléchargé, compte conservé, READY | oui | oui |
| `scripts/backup.sh` : `storage_verify=ok`, SHA-256 | OK | OK |
| RAM Vaultia en fin de test | 308 Mio | 270 Mio |

Le premier passage (run `36245879324`) avait échoué sur arm64 à cause d'une assertion du
workflow : l'état Docker `healthy` était exigé avant le premier contrôle de santé de l'image
(intervalle 30 s), alors que la Vision était déjà prête. Corrigé dans le workflow (`572d004`),
sans modification de l'image ni de la distribution.

### 14.3 Classement

| Architecture | Statut | Preuves |
| --- | --- | --- |
| `linux/amd64` | **RÉEL** (Linux x86_64, machine virtuelle GitHub, sans émulation) | smoke de la distribution (§ 14.2) ; job `smoke-amd64` de la publication ; CI source (build de production, unitaires, intégration, E2E capture/Intelligence) sur `ubuntu-24.04` |
| `linux/amd64` | ÉMULÉ (QEMU, poste Apple Silicon) | LOT 2 : build de l'image, `runtime-smoke` 8/8, `vision-status` READY — complément, pas une preuve de l'exécution réelle |
| `linux/arm64` | **EXÉCUTION NATIVE EN MACHINE VIRTUELLE** | validation complète des §§ 3 à 13 (VM Linux de Docker Desktop, Apple Silicon) ; smoke de la distribution sur `ubuntu-24.04-arm` (§ 14.2) |
| `linux/arm64` | **PENDING ORACLE** : hôte Linux ARM64 réel, redémarrage de l'hôte | prochaine étape, avec cette image publiée et ce dépôt, sans build propre à Oracle |
| Redémarrage réel d'un hôte | NOT TESTED | ni sur amd64 ni sur arm64 |

Aucune incompatibilité connue sur l'une ou l'autre architecture : les binaires natifs (Prisma
`schema-engine`, Argon2, sharp/libvips, ONNX Runtime, Tesseract) ont chacun leur variante chargée
et exercée par `runtime-smoke`, les migrations, l'inscription (Argon2) et l'inférence SigLIP 2.

## 15. Limites connues

- Redémarrage réel de l'hôte : non testé (§ 10).
- Exécution arm64 validée en machines virtuelles (Docker Desktop, runner GitHub arm64), pas sur
  un hôte Linux arm64 réel : réservée à Oracle (§ 14.3).
- Reverse proxys : seul l'accès `http://localhost` est validé par la distribution ; l'exemple
  Caddy reprend la configuration validée par le dépôt source, les autres ne sont pas testés.
- Les E2E qui décrivent `open-facts` supposent l'instance de développement (§ 8.2).
- Mise à jour avec migrations entre candidats : non exercée (§ 13).
- Pas de réinitialisation de mot de passe par e-mail (limite produit V1).

## 16. Points bloquants non résolus

Aucun.
