# Audit de distribution auto-hébergée — LOT 1

Date : 26/09/2026. Audit en lecture seule : aucun fichier du dépôt source n'a été modifié.

## 1. Références

| Élément | Valeur |
| --- | --- |
| Dépôt source | `github.com/multinet33/Vaultia` — **privé** — chemin local `~/Code/Vaultia` |
| SHA source audité | `f62ae4b4517aab32abfbe2505b524a98e3e3f220` (`main` = `origin/main`, arbre propre) |
| Version applicative | `0.1.0` (`package.json`) ; aucun tag Git |
| Dépôt de distribution | `github.com/multinet33/vaultia-selfhosted` — **public** — chemin local `~/Code/vaultia-selfhosted` |
| SHA initial de distribution | aucun : dépôt vide (aucun commit) ; ce rapport en est le premier |
| Instructions lues | `~/Code/CLAUDE.md` (règles communes : noms de fichiers ASCII), `Vaultia/CLAUDE.md` (non versionné, ignoré par `.gitignore:67`). `vaultia-selfhosted` n'a pas de `CLAUDE.md`. |

## 2. Architecture de déploiement existante (Step 18, rapport `docs/reports/production-readiness-self-host-v1.md`)

Déjà prêt pour la production, à **réutiliser tel quel** :

| Élément | État | Détail |
| --- | --- | --- |
| `Dockerfile` | prêt | multi-étapes `node:24.21.0-bookworm-slim` ; `next start` (jamais `next dev`) ; utilisateur `node` (uid 1000) ; `tini` en PID 1 ; Tesseract 5 + `fra` + `eng` ; aucun téléchargement au démarrage ; labels OCI `version`/`revision`/`licenses` ; `HEALTHCHECK` sur `/api/health` |
| `.dockerignore` | prêt | exclut `.env*`, `storage/`, `tests/`, `e2e/`, `tools/`, `docs/`, `CLAUDE.md` |
| `deploy/docker-entrypoint.sh` | prêt | `serve` = `check-config` → `prisma migrate deploy` → `next start` ; sous-commandes `check-config`, `migrate`, `storage-verify`, `storage-reconcile`, `runtime-smoke` ; tout échec arrête le conteneur |
| Migrations | prêt | `prisma migrate deploy` à chaque démarrage (idempotent) ; jamais `migrate reset` |
| `/api/health` | prêt (vivacité) | `200 {status:"ok",database:"up"}` si PostgreSQL répond, `503` sinon ; **ne dit rien de la Vision** |
| `deploy/compose.yaml` | prêt, mais **construit depuis les sources** (`build: context: ..`) et image locale `vaultia:${VAULTIA_VERSION}` | PostgreSQL 18 non publié, réseau interne à sous-réseau fixe, Vaultia publié sur `127.0.0.1:3000` par défaut |
| `deploy/compose.caddy.yaml` + `Caddyfile` | prêt, facultatif | reverse proxy de référence ; non obligatoire |
| `deploy/init-env.sh` | prêt, mais lit `../package.json` (suppose le dépôt source) | génère `POSTGRES_PASSWORD` (`openssl rand -hex 24`) et `BETTER_AUTH_SECRET` (`openssl rand -base64 32`) |
| `deploy/backup.sh` | prêt | sauvegarde d'infrastructure = `pg_dump` custom + `tar` du volume médias + `storage-verify` + `SHA256SUMS` + `MANIFEST` ; arrête Vaultia pendant la copie ; paramétrable par `COMPOSE="docker compose -f …"` |
| `deploy/restore.sh` | prêt | refuse une base ou un stockage non vides ; `pg_restore` + extraction ; `storage-verify` final |
| `storage-verify` | prêt | relit chaque fichier référencé et compare son SHA-256 à la base ; lecture seule |
| Proxys de confiance | prêt | `TRUSTED_PROXIES` (IP/CIDR, jamais `0.0.0.0/0`) ; HSTS via `HSTS_MAX_AGE` |
| Politique d'inscription | prêt | `VAULTIA_SIGNUP_POLICY=first-user` par défaut (premier compte libre, ensuite invitation) ; `invite`, `open` |
| Stockage des fichiers | prêt | système de fichiers local `MEDIA_STORAGE_DIR=/var/lib/vaultia/media` (volume) ; pas de S3 |
| Télémétrie | aucune | `NEXT_TELEMETRY_DISABLED=1`, `CHECKPOINT_DISABLE=1` |
| Documentation d'exploitation | prête (FR) | `docs/operations/` : install, configuration, update, backup-restore, disaster-recovery, reverse-proxy, secret-rotation, troubleshooting, known-issues |

**Travail de distribution restant (constaté) :**

1. Aucun workflow GitHub Actions (`.github/` absent) : ni CI, ni publication d'image.
2. Aucune image publiée : `deploy/compose.yaml` construit l'image depuis les sources.
3. La Vision (`siglip2-vision`) est **explicitement non prise en charge** en auto-hébergement :
   `known-issues.md` (« modèle non fourni par l'image »), `configuration.md:76`, `.env.example`
   (`INTELLIGENCE_PROVIDERS` sans `siglip2-vision`). Aucun volume de modèles dans le Compose.
4. Le téléchargeur de modèles `tools/intelligence/download-models.mts` est dans `tools/`, **exclu de
   l'image** par `.dockerignore` : il n'existe aucun moyen de provisionner le modèle depuis l'image.
5. `/api/health` ne distingue pas « application saine » de « Vision prête ».
6. `backup.sh` / `restore.sh` / `init-env.sh` supposent l'arborescence `deploy/` du dépôt source.
7. Les tests Vision réels (`tests/unit/intelligence/providers/siglip2-vision.test.ts`,
   `e2e/capture.spec.ts`, `e2e/intelligence.spec.ts`) exigent le modèle dans `storage/models` ;
   le test unitaire se saute (`describe.skipIf(!available)`) s'il manque — aucune CI ne le provisionne.

## 3. Inventaire exhaustif Vision / Intelligence

Recherche : `server/intelligence/**`, `lib/intelligence/**`, `tools/intelligence/**`,
`scripts/**`, `package.json`, `server/env.ts` (`INTELLIGENCE_PROVIDER_IDS`), tests et E2E.
Il existe **cinq moteurs** (`INTELLIGENCE_PROVIDER_IDS`) et **neuf capacités** déclarées ; trois
capacités n'ont **aucun** moteur (« À venir ») : `LANGUAGE_MODEL`, `EMBEDDINGS`, `MARKET_LOOKUP`.

| Capacité | Moteur | Runtime | Modèle / données | Révision | Source de téléchargement | Taille | SHA-256 | Arch. | Chemin persistant | FR | EN | Internet après installation | Tests automatisés | Classe |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `VISION_CLASSIFICATION`, `VISION_ATTRIBUTES` (identification visuelle, couleur, matière) | `siglip2-vision` | `onnxruntime-node` 1.30.0 (CPU, binaires `linux/x64` et `linux/arm64` livrés dans le paquet) + `sharp` | SigLIP 2 base patch16-224, encodeur d'image ONNX quantifié int8 `onnx/vision_model_quantized.onnx` | `ba1f3b0843f24bc5417d38e19c37b287d719b2f4` (épinglée, `lib/intelligence/models.ts`) | `https://huggingface.co/onnx-community/siglip2-base-patch16-224-ONNX/resolve/<rév>/onnx/vision_model_quantized.onnx` | 94 553 333 o (90,2 Mio) | `5f2b401c1a4fc095702a5d45348e17ad46c4f87064085365b43c6e8eaa5c0070` (confirmé par l'API Hugging Face, champ LFS) | amd64, arm64 | `INTELLIGENCE_MODELS_DIR/siglip2-base-patch16-224/` (aujourd'hui non monté) | oui (libellés FR) | oui (libellés EN, Morning Run LOT 2) | **non** | unitaire `siglip2-vision.test.ts` (sauté sans modèle), intégration `intelligence-capture`, E2E `capture.spec.ts`, `intelligence.spec.ts` | **B** (artefact de modèle) |
| (idem) libellés encodés du catalogue | `siglip2-vision` | lecture de fichier | `lib/intelligence/generated/siglip2-labels.{json,f32}` (3,9 Mo, versionnés) + `lib/asset-library/catalog.json` | liés à la révision ci-dessus (contrôlé au chargement) | dans le dépôt source → **dans l'image** (`COPY lib`) | 3,96 Mo | contrôlé (`vectorsSha256`, `catalogSha256`) | toutes | image | oui | oui | non | unitaires | **A** |
| (outil de dev) encodeur de **texte** SigLIP 2 | — | `@huggingface/transformers` (devDependency) | `text_model*.onnx` via cache `.hf-cache` | — | Hugging Face | ~300 Mo | — | — | `storage/models/.hf-cache` (poste de dev) | — | — | — | — | **hors distribution** : sert seulement à régénérer les libellés (`npm run intelligence:embeddings`) ; jamais à l'exécution |
| `OCR` | `tesseract-ocr` | binaire Tesseract 5 (Debian bookworm) lancé en processus borné | `tesseract-ocr-fra`, `tesseract-ocr-eng` (paquets Debian) | version du paquet Debian | apt, **au build de l'image** | ~15 Mo | paquet signé Debian | amd64, arm64 | image (`/usr/share/tesseract-ocr`) | oui | oui | non | intégration `intelligence-documents`, `runtime-smoke`, E2E | **A** |
| `BARCODE` | `zxing-barcode` | `zxing-wasm` 3.1.4 (WASM, chargé depuis `node_modules`, CDN neutralisé) + `sharp` | aucun | — | npm, au build | ~1 Mo | lockfile npm | toutes (WASM) | image | n/a | n/a | non | unitaires, `runtime-smoke`, E2E `capture.spec.ts` | **A** (décodage, pas d'IA) |
| `DOCUMENT_EXTRACTION` | `document-rules` | TypeScript pur (règles déterministes) + pdf.js (processus isolé) + OCR | aucun | — | — | — | — | toutes | image | oui | oui | non | unitaires, intégration `intelligence-documents` | **D** (aucun modèle) |
| `PRODUCT_LOOKUP` | `open-facts` | `fetch` HTTPS vers Open Products Facts / Open Food Facts (hôtes fixes) | — | — | — | — | — | — | — | — | — | **oui, par nature** ; refusé en mode `LOCAL` | unitaires (fetch simulé) | **C** (externe, opt-in par Espace, mode `REMOTE`) |
| `LANGUAGE_MODEL`, `EMBEDDINGS`, `MARKET_LOOKUP` | aucun | — | — | — | — | — | — | — | — | — | — | — | E2E vérifie « non disponible » | non implémenté |
| (traitement d'image) HEIC, miniatures | — (pas un moteur) | `libheif-js` 1.23.2 (WASM), `sharp` 0.35.4 (libvips natif) | aucun | — | npm | — | — | amd64, arm64 | image | n/a | n/a | non | `runtime-smoke`, unitaires | **D** |
| (lecture PDF) texte natif, rendu de page | — | `pdfjs-dist` 6.3.289 en processus Node isolé | aucun | — | npm | — | — | toutes | image | n/a | n/a | non | `runtime-smoke`, intégration | **D** |

**Conclusion de l'inventaire :** il existe **un seul artefact de modèle téléchargeable** à provisionner
pour la Vision locale complète : l'encodeur d'image SigLIP 2 (90,2 Mio). Tous les autres moteurs
locaux (OCR, codes-barres, extraction de documents) sont des dépendances d'exécution **déjà dans
l'image**. `open-facts` est un fournisseur **externe** (classe C) : il ne fait pas partie de la
« Vision locale » ; il reste installable mais n'est jamais utilisé en mode `LOCAL`.

Pile Vision locale complète de la bêta :
`INTELLIGENCE_PROVIDERS=zxing-barcode,tesseract-ocr,siglip2-vision,document-rules`.

## 4. Licences des modèles et runtimes téléchargés

| Artefact | Licence (source) | Redistribution dans l'image | Téléchargement automatique | Téléchargement à l'initiative de l'utilisateur | Usage auto-hébergé |
| --- | --- | --- | --- | --- | --- |
| SigLIP 2 base patch16-224 (poids d'origine, `google/siglip2-base-patch16-224`) | **Apache-2.0** — balise `license:apache-2.0` et en-tête `license: apache-2.0` de la fiche du modèle (API Hugging Face, lue le 26/09/2026) ; dépôt non restreint (`gated: false`) | permise (Apache-2.0 §4 : copie de la licence, mention des modifications) | permis | permis | permis |
| Export ONNX quantifié (`onnx-community/siglip2-base-patch16-224-ONNX`, rév. `ba1f3b0…`) | **aucune licence déclarée par ce dépôt** (ni balise, ni en-tête, ni fichier LICENSE) ; il se déclare `base_model: google/siglip2-base-patch16-224`, `base_model:quantized:…` — œuvre dérivée (conversion de format + quantification) d'un modèle Apache-2.0 ; public, non restreint | **non retenue** : l'absence de licence propre au dérivé rend la redistribution par Vaultia moins nette ; inutile (voir LOT 2) | permis : Vaultia ne redistribue rien, l'instance de l'utilisateur récupère le fichier public à sa source, à la révision épinglée — comme le fait déjà `npm run intelligence:models` | permis | permis |
| ONNX Runtime (`onnxruntime-node` 1.30.0) | MIT (`package.json` du paquet) | oui (déjà dans l'image) | — | — | permis |
| Tesseract + `tessdata` fra/eng | Apache-2.0 (`THIRD-PARTY-NOTICES.md`, paquets Debian) | oui (déjà dans l'image) | — | — | permis |
| zxing-wasm / zxing-cpp | MIT / Apache-2.0 | oui | — | — | permis |
| libheif-js, libvips | LGPL-3.0 (chargées dynamiquement, remplaçables — déjà documenté) | oui | — | — | permis |

Aucune licence ne **bloque** la distribution prévue. Décision : le modèle n'est **pas** embarqué
dans l'image (taille, licence du dérivé non déclarée, mise à jour indépendante) ; il est
téléchargé automatiquement par l'instance depuis sa source officielle, à la révision épinglée,
avec vérification de la taille et du SHA-256. La documentation de distribution citera le modèle,
son dépôt, sa révision et la licence Apache-2.0 du modèle de base, en signalant que le dépôt ONNX
dérivé ne déclare pas de licence propre.

## 5. Dépendances natives et architectures

| Dépendance | Nature | amd64 | arm64 | Justification |
| --- | --- | --- | --- | --- |
| Image de base `node:24.21.0-bookworm-slim` | image officielle multi-arch | supportée | supportée | manifeste officiel |
| Prisma 7.10 (client) | `prisma-client` + `@prisma/adapter-pg` (compilateur de requêtes WASM, pas de moteur Rust de requêtes) | supportée | supportée | aucun binaire natif à l'exécution des requêtes |
| Prisma 7.10 (migrations) | `schema-engine` natif, téléchargé par le `postinstall` de `@prisma/engines` **au build**, selon la plateforme (OpenSSL 3 détecté) | supportée | supportée | cible `linux-arm64-openssl-3.0.x` publiée par Prisma ; **à prouver au build arm64** |
| `@node-rs/argon2` 2.2.1 | binaire N-API précompilé | supportée (`linux-x64-gnu`) | supportée (`linux-arm64-gnu`) | présents dans `package-lock.json` |
| `sharp` 0.35.4 + libvips 1.3.3 | binaire précompilé | supportée | supportée | `@img/sharp-linux-{x64,arm64}` dans le lockfile |
| `onnxruntime-node` 1.30.0 | binaire N-API + `libonnxruntime.so.1` | supportée | supportée | `bin/napi-v6/linux/{x64,arm64}` livrés dans le paquet ; `postinstall` (téléchargement CUDA sur linux/x64) **désactivé** par `allowScripts` → CPU seul, aucun GPU |
| `libheif-js` | WASM | supportée | supportée | indépendant de l'architecture |
| `zxing-wasm` | WASM | supportée | supportée | idem |
| `pdfjs-dist` | JS (+ canvas via `@napi-rs/canvas` si présent) | à tester au build | à tester au build | couvert par `runtime-smoke` |
| Tesseract 5 (apt) | binaire Debian | supportée | supportée | paquets bookworm multi-arch |
| `tini` (apt) | binaire Debian | supportée | supportée | idem |

« Docker sait construire » ne suffit pas : chaque architecture devra passer `runtime-smoke`
(HEIC, miniatures, code-barres, PDF, OCR) **et** une inférence SigLIP 2 réelle.

État hérité (Step 18) : arm64 validé sur la VM Linux de Docker Desktop (Apple Silicon) ; amd64
**seulement sous émulation** QEMU. Aucun hôte Linux physique.

Environnement de ce run : macOS arm64 (Apple Silicon), Docker Desktop 27.3.1 (VM `linux/arm64`,
8 CPU, 7,7 Gio), buildx avec émulation `linux/amd64`. Les runners GitHub `ubuntu-latest` offrent
un vrai Linux amd64 (machine virtuelle) utilisable pour une validation amd64 non émulée.

## 6. Stockage persistant

| Donnée | Emplacement dans le conteneur | Volume | Sauvegarde | Si le volume est supprimé |
| --- | --- | --- | --- | --- |
| Base PostgreSQL | `/var/lib/postgresql` (conteneur `postgres`) | `postgres-data` | **oui** (`pg_dump`) | perte de toutes les données métier |
| Fichiers Vaultia (photos, documents, archives) | `/var/lib/vaultia/media` | `media` | **oui** (`tar`, `storage-verify`) | perte de tous les fichiers ; la base référence des fichiers absents |
| Modèles Vision | `INTELLIGENCE_MODELS_DIR` (à définir : `/var/lib/vaultia/models`) | `models` (à créer) | **non** : artefact d'exécution retéléchargeable, vérifié par empreinte | nouveau téléchargement (~90 Mio) au démarrage suivant ; aucune donnée métier perdue |
| Configuration (`.env`) | hôte | — | **oui, à part** (secrets) | perte de `BETTER_AUTH_SECRET` : sessions et liens de partage invalides, secrets de webhooks illisibles |

## 7. Variables d'environnement (lues par `server/env.ts` et consorts)

Obligatoires : `DATABASE_URL` (composée par Compose), `BETTER_AUTH_SECRET` (≥ 32 car.),
`BETTER_AUTH_URL` (https, ou `http://localhost:<port>`), `POSTGRES_PASSWORD`.
Recommandées : `VAULTIA_SIGNUP_POLICY` (`first-user`), `TRUSTED_PROXIES` (derrière un proxy).
Facultatives : `HSTS_MAX_AGE`, `NOTIFICATIONS_CRON_SECRET`, `MEDIA_MAX_UPLOAD_BYTES`,
`WEBHOOK_ALLOW_PRIVATE_NETWORKS`, `WEBHOOK_SECRET_KEY`, `INTELLIGENCE_CONTACT`.
Avancées (valeurs de l'image) : `INTELLIGENCE_PROVIDERS`, `INTELLIGENCE_MODELS_DIR`,
`TESSERACT_PATH`, `TESSERACT_LANGS`, `TESSDATA_PREFIX`, `MEDIA_STORAGE_DIR`, `DOCUMENT_INDEXER`,
`INTELLIGENCE_WORKER`/`EVENT_WORKER` (seul `inline` est pris en charge par l'image).
Refusée en production : `DEV_LAN_ORIGIN`.

## 8. Points bloquants et risques identifiés

| # | Sujet | Gravité | Traitement |
| --- | --- | --- | --- |
| 1 | Le dépôt source est **privé** : un paquet GHCR publié par un workflow d'un dépôt privé est **privé par défaut** ; un tiers ne pourrait pas le tirer. La visibilité d'un paquet ne se change pas par l'API REST ni avec le jeton du workflow. | **Action utilisateur requise** (pas un blocage technique) | Après la première publication (LOT 2), l'utilisateur passe le paquet `vaultia` en **Public** (GitHub › Packages › vaultia › Package settings › Change visibility). La validation LOT 3 tire l'image **sans authentification** pour le prouver. |
| 2 | Le jeton `gh` local n'a pas le scope `read:packages` | mineur | inutile si le paquet est public ; sinon `gh auth refresh -s read:packages` |
| 3 | Espace disque local : **17 Gio libres** | risque opérationnel | builds multi-arch faits par GitHub Actions ; localement, tirer l'image candidate, nettoyer les projets de test |
| 4 | Aucun moyen de provisionner le modèle depuis l'image (`tools/` exclu) | à corriger (LOT 2) | primitives de provisionnement déplacées côté serveur, exposées par l'entrypoint |
| 5 | Licence non déclarée du dépôt ONNX dérivé | faible | pas de redistribution ; téléchargement depuis la source ; documenté |
| 6 | Minutes GitHub Actions d'un dépôt privé ; disponibilité des runners arm64 hébergés pour un dépôt privé non vérifiée | risque | runner arm64 natif si disponible, sinon build arm64 sous QEMU sur runner amd64 |

**Aucun blocage fondamental** : la suite (LOT 2) peut commencer.

## 9. Proposition d'implémentation pour le LOT 2 (dépôt `vaultia`)

1. **Provisionnement dans l'application** (pas dans `tools/`) : module serveur de magasin de
   modèles (vérification taille + SHA-256, téléchargement en `.partial` puis `rename` atomique,
   reprise sûre, idempotent), réutilisant exactement la logique de
   `tools/intelligence/download-models.mts`, qui devient un simple appel à ce module
   (`npm run intelligence:models` inchangé pour le développeur).
2. **Sous-commandes de l'entrypoint** : `models-provision` (télécharge et vérifie tous les modèles
   du manifeste, journaux explicites par modèle : téléchargement, progression, vérification,
   terminé, échec), `models-verify` / `vision-status` (contrôle d'intégrité, code de sortie non nul
   si un modèle manque ou est altéré).
3. **Démarrage** : `serve` lance le provisionnement **en arrière-plan** avec reprises espacées
   (aucune boucle de redémarrage du conteneur si Hugging Face est injoignable) ; le serveur web
   démarre immédiatement. Le moteur recharge le modèle dès qu'il est présent (l'échec de chargement
   n'est pas mis en cache, vérifié dans `siglip2-vision.ts`).
4. **Santé à trois niveaux** : conteneur démarré (Docker) ; application saine = `/api/health`
   (inchangé : 200 si PostgreSQL répond — le healthcheck Docker reste dessus) ; **Vision prête** =
   champ `vision` ajouté à `/api/health` (`ready` / `provisioning` / `failed`, sans chemin ni
   détail) + `docker compose exec vaultia vision-status`.
5. **Image** : `INTELLIGENCE_MODELS_DIR=/var/lib/vaultia/models` (volume, propriété `node`),
   `INTELLIGENCE_PROVIDERS` par défaut = pile locale complète ; modèle **non embarqué**.
6. **GHCR** : workflow `publish-image.yml` (buildx, `linux/amd64` + `linux/arm64`, labels OCI dont
   `org.opencontainers.image.revision` = SHA complet, attestation de provenance, authentification
   par `GITHUB_TOKEN` avec `packages: write`), tags **immuables** `sha-<sha complet>` et
   `0.1.0-rc.<n>` ; tag mobile `rc` seulement ; jamais `latest`, jamais `1.0.0`.
7. **CI Vision** : workflow de tests qui provisionne le modèle de façon déterministe (cache
   indexé sur l'empreinte du manifeste, vérification SHA-256) et exécute le test unitaire SigLIP 2
   (sans saut), `capture.spec.ts` et `intelligence.spec.ts` contre un build de production.
8. **Validation** : lint, typecheck, tests unitaires et d'intégration concernés, build de l'image
   arm64 (natif) et amd64 (émulé localement, natif sur GitHub), `runtime-smoke` et inférence réelle
   dans chaque image.

Puis LOT 3 (`vaultia-selfhosted`) : `compose.yaml` consommant l'image GHCR épinglée par digest,
volumes `postgres-data`, `media`, `models`, `.env.example` REQUIRED/OPTIONAL/ADVANCED, scripts
`backup.sh`/`restore.sh` adaptés du dépôt source (même mécanisme, pas de seconde implémentation),
documentation utilisateur.
