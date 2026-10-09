# Mise à jour

## Versions distribuées

| Candidat | Source Vaultia | Digest (index multi-architecture) | Nouveautés |
| --- | --- | --- | --- |
| **`0.1.0-rc.17`** (actuel) | `916948755c69a21ef3f8ad45ccf18f27ab1d6785` | `sha256:cd11f8afb434e701affccfd6336708d32f5900662dbf1d6c54e5f934f2495bbf` | factures Amazon bien lues par « Analyser un justificatif » ; 2ᵉ exemplaire d'un objet : trois choix explicites ; achat supprimé signalé dans la fiche ; garantie cochée d'office (2 ans depuis la date d'achat) ; aucune migration de base |
| `0.1.0-rc.16` | `3971a9fd717ede92eaa38aed9c56d8bc125b88d2` | `sha256:6dfc76e475f131cc3b6da2f5c218a87a79edcf7ba2809eebeadebe1895ad011f` | fiche d'un objet repensée (grande photo, cartes valeur et achat, anneau de garantie, derniers événements) et version téléphone (onglets, barre d'actions) ; inventaire : puces de catégorie, liste repensée, valeur totale ; police Plus Jakarta Sans embarquée ; accueil : période, marqueurs, répartition en valeur, échéances à 90 jours ; aucune migration de base |
| `0.1.0-rc.15` | `feed4eda7ed9d14d2c59e99c921b783370080bbe` | `sha256:42800824bcd3d2626bc03485951e7203c5d3a03208e82309ea325bde0100fb68` | aperçu des PDF sur iPhone et iPad : plus de fermeture de l'onglet par Safari en consultant plusieurs documents (mémoire libérée, pages dessinées une à une) ; aucune migration de base |
| `0.1.0-rc.14` | `9a5fb005802f089793c4239016679c7bb9f0fe6b` | `sha256:dda8de584fb03ae04cdc93063df897ea9f032a4a172a6daaab271358d6bfb5fa` | aperçu des PDF sur iPhone, iPad et Android : toutes les pages s'affichent (iOS ne montrait que la première) ; aucune migration de base |
| `0.1.0-rc.13` | `b85131d26ce52613fea45dd8ab154454d3f2cb86` | `sha256:2861565c9c3674c6d9456b1511a3e4779fd4e3311397b4bf66818131455d31bc` | inventaire : une teinte par catégorie (objets sans photo, point de couleur) ; centimes affichés plus petits ; états vides illustrés et chargement en forme de liste ; fiche d'un objet : pastilles de synthèse (catégorie, statut, état) et jauge de garantie ; accueil : tendance du patrimoine et répartition par catégorie ; aucune migration de base |
| `0.1.0-rc.12` | `3c4a40154595812fa67d2fad2600bf5ed1757e2a` | `sha256:391b174d5ba145fa4aa0d54d5aa60688b377334be385b2700af183510a9ea557` | justificatifs des dépenses directes d'une propriété visibles et administrables ; Propriété › Valeur : dépenses de travaux, dépenses directes et total (chaque dépense une fois) ; carnet de vie : « Ouvrir la fiche d'origine » vers la vraie source, rubrique Documents sans les factures d'achat de l'inventaire ; Travaux : interventions hors projet sans doublon ; rubrique « Champs de la catégorie » masquée si vide ; une fenêtre rouverte aussitôt ne se referme plus ; aucune migration de base |
| `0.1.0-rc.11` | `4ef6651f806e496b4a24d24eb7108aef33cdfa34` | `sha256:bb00ce2da8260895a79d648a02090c785483fff540f16a75e51740552d7e72fb` | référentiel des tiers (vendeurs, artisans, garages, assureurs, emprunteurs…) ; justificatifs des dépenses de véhicule, de travaux et du carnet ouverts dans l'aperçu intégré ; **une migration de base** (rattachement des noms identiques) ; **sauvegardes d'Espace au format 6** |
| `0.1.0-rc.10` | `52f4bddee8d5cfd317c14b620e7a878a8d5bf912` | `sha256:c3f274615126a9013228533ceeea7e75c580833e71cbe917d104921a39065c51` | carnet de vie d'une propriété ou d'un véhicule ; événements saisis dans le carnet ; glisser-déposer des fichiers ; **une migration de base** ; **sauvegardes d'Espace au format 5** |
| `0.1.0-rc.9` | `79746e318ca7bec6f9637743a4875722cc8b9459` | `sha256:b8e7048cdbdd552d7c8e239f464345c2f4fb1b99a69220a18de75109b0a2451e` | un objet s'ajoute en une fois avec son achat, sa garantie, son justificatif, son code produit et son numéro de série ; travaux et véhicules : une dépense porte son justificatif, une intervention enregistre son coût et sa facture en une saisie ; objet affecté à un véhicule (lien sans effet financier) ; un fichier déjà enregistré justifie une autre dépense ; **deux migrations de base** ; **sauvegardes d'Espace au format 4** |
| `0.1.0-rc.8` | `dc69e0b09fc14841128ff86f4a31877d4468a7f2` | `sha256:2a69f47c63f2b9d853fdbd3ece73d43d7cc228749c53ddb3490396ef11cdab48` | une fiche Open Facts vide ne bloque plus la recherche Web ; meilleurs noms de produits issus du Web (titres de sites et d'outils écartés, concordance des sources, site de la marque) ; provenance « Recherche Web » visible à la revue ; aucune migration de base |
| `0.1.0-rc.7` | `de61b83eb1bf39b9d8fd761c9c4c09623fbb34bc` | `sha256:158ace85c0caf16d14ba301f40fa1c8e19eaf74edf816e08ed802c568b88fcad` | créer un objet depuis le lien d'équipement d'une intervention ; banderole rouge sur les objets sortis ; un objet sorti compte 0 dans le patrimoine actuel ; coût historique, produits de cession et coût net (rapports Finances et Propriété) ; dépenses directes des travaux ; correction de l'identification visuelle (sous-catégories) ; aucune migration de base |
| `0.1.0-rc.6` | `01e09a82831046044bfa154090fa6893830818be` | `sha256:993ee61cb5ab6ccfa2ac005e3156fd47c3c545cb802dc95afbb97b7a2fbcc048` | un code produit (EAN, UPC, référence fabricant) peut être porté par plusieurs exemplaires ; « Ajouter un nouvel exemplaire » prérempli ; « Analyser un objet » reconnaît un code déjà présent ; objet et achat enregistrés en une fois ; menu « Créer » réorganisé ; sources en désaccord signalées ; limite de fréquence de la recherche rapide ; une migration de base |
| `0.1.0-rc.5` | `79985a6404b6994f41cc541c4b5e4b90d2a92655` | `sha256:477d2f1d83cc039b843d27fec9e9c02b5823d013a3d613f9fd23a0cad95115e3` | rapports Propriété et Véhicule (écran et PDF) ; recherche par le sens, locale et facultative ; justificatif joint dès la création d'un achat ; parcours « Analyser un objet » plus clair ; corrections (patrimoine avec des valeurs inconnues, retour de la restauration d'un document, focus après une suppression — KI-001) ; une migration de base |
| `0.1.0-rc.4` | `b5398a0fee42e207d4746a72f97ba63ee5f95e7b` | `sha256:5d05ede91279656a53e82f2a91a7ceb1a4ec87a9641941f885442ec210f224c4` | documentation interactive de l'API servie par l'instance (`/api/docs`, [api.md](api.md)) ; version affichée en bas du menu et journal des versions ; aucune migration de base |
| `0.1.0-rc.3` | `04e3028d9915b05b85df33a22f06fea818cda198` | `sha256:59a04cc39633c9edb27f367234495603ecbb1728c54173584d25c41fe4785eb4` | aperçu des documents, sorties partielles et prêts par exemplaires ; deux migrations de base |
| `0.1.0-rc.2` | `5ca5ffc101fd89204ef533d3b9bf807b64d41a2a` | `sha256:948841a00563434e5ed1a744adb0a58c9d4227af13033b2c683344cf65ccdee8` | `BETTER_AUTH_URL` en `http://` accepté sur une adresse IPv4 privée du réseau local ([configuration.md](configuration.md#http-sur-le-réseau-local)) ; aucune migration de base |
| `0.1.0-rc.1` | `150c5a6678c6065c04e4adfd7d426e003ed11361` | `sha256:61b4d5945735edfdeb0a65577cc40d0f3f68eda372190775095b16df0b3ef0cb` | premier candidat |

## De 0.1.0-rc.16 à 0.1.0-rc.17

1. **Sauvegarder d'abord** : `./scripts/backup.sh` (vérifier `storage_verify=ok` dans le
   `MANIFEST` et les `SHA256SUMS`) ; garder aussi une copie de `.env`. **Faites-le avant de tirer
   la nouvelle image** : `backup.sh` redémarre Vaultia en fin de sauvegarde, et un redémarrage
   démarre l'image déjà tirée.
2. `git pull` (nouvelle ligne `image:` de `compose.yaml` et de `compose.portainer-https.yaml`).
3. `docker compose pull && docker compose up -d` — avec Portainer, « Pull and redeploy » de la
   pile, avec *Re-pull image* (voir [portainer.md](portainer.md), § 11).
4. Vérifier : `docker compose ps` (`healthy`), `curl http://127.0.0.1:3000/api/health` →
   `"status":"ok"`, `"database":"up"`, puis la version en bas du menu : `v0.1.0-rc.17`.

- **Aucune migration de base**, **aucune variable** nouvelle ou modifiée, format de sauvegarde 6
  inchangé. Depuis une version plus ancienne, suivre d'abord les sections ci-dessous : les
  migrations s'appliquent de la même façon en passant directement à `0.1.0-rc.17`.
- Mise à jour vérifiée avant publication sur une copie restaurée d'une instance réelle en
  `0.1.0-rc.16` : aucune migration, données et fichiers identiques, redémarrages sans écart,
  sauvegarde puis restauration identiques, isolation des Espaces.

## De 0.1.0-rc.15 à 0.1.0-rc.16

1. **Sauvegarder d'abord** : `./scripts/backup.sh` (vérifier `storage_verify=ok` dans le
   `MANIFEST` et les `SHA256SUMS`) ; garder aussi une copie de `.env`. **Faites-le avant de tirer
   la nouvelle image** : `backup.sh` redémarre Vaultia en fin de sauvegarde, et un redémarrage
   démarre l'image déjà tirée.
2. `git pull` (nouvelle ligne `image:` de `compose.yaml` et de `compose.portainer-https.yaml`).
3. `docker compose pull && docker compose up -d` — avec Portainer, « Pull and redeploy » de la
   pile, avec *Re-pull image* (voir [portainer.md](portainer.md), § 11).
4. Vérifier : `docker compose ps` (`healthy`), `curl http://127.0.0.1:3000/api/health` →
   `"status":"ok"`, `"database":"up"`, puis la version en bas du menu : `v0.1.0-rc.16`.

- **Aucune migration de base**, **aucune variable** nouvelle ou modifiée, format de sauvegarde 6
  inchangé. Depuis une version plus ancienne, suivre d'abord les sections ci-dessous : les
  migrations s'appliquent de la même façon en passant directement à `0.1.0-rc.16`.
- Mise à jour vérifiée avant publication sur une copie restaurée d'une instance réelle en
  `0.1.0-rc.15` : aucune migration, données et fichiers identiques, redémarrages sans écart,
  sauvegarde puis restauration identiques, isolation des Espaces.

## De 0.1.0-rc.14 à 0.1.0-rc.15

1. **Sauvegarder d'abord** : `./scripts/backup.sh` (vérifier `storage_verify=ok` dans le
   `MANIFEST` et les `SHA256SUMS`) ; garder aussi une copie de `.env`. **Faites-le avant de tirer
   la nouvelle image** : `backup.sh` redémarre Vaultia en fin de sauvegarde, et un redémarrage
   démarre l'image déjà tirée.
2. `git pull` (nouvelle ligne `image:` de `compose.yaml` et de `compose.portainer-https.yaml`).
3. `docker compose pull && docker compose up -d` — avec Portainer, « Pull and redeploy » de la
   pile, avec *Re-pull image* (voir [portainer.md](portainer.md), § 11).
4. Vérifier : `docker compose ps` (`healthy`), `curl http://127.0.0.1:3000/api/health` →
   `"status":"ok"`, `"database":"up"`, puis la version en bas du menu : `v0.1.0-rc.15`.

- **Aucune migration de base**, **aucune variable** nouvelle ou modifiée, format de sauvegarde 6
  inchangé. Depuis une version plus ancienne, suivre d'abord les sections ci-dessous : les
  migrations s'appliquent de la même façon en passant directement à `0.1.0-rc.15`.
- Mise à jour vérifiée avant publication sur une copie restaurée d'une instance réelle en
  `0.1.0-rc.14` : aucune migration, données et fichiers identiques, redémarrages sans écart,
  sauvegarde puis restauration identiques, isolation des Espaces.

## De 0.1.0-rc.13 à 0.1.0-rc.14

1. **Sauvegarder d'abord** : `./scripts/backup.sh` (vérifier `storage_verify=ok` dans le
   `MANIFEST` et les `SHA256SUMS`) ; garder aussi une copie de `.env`. **Faites-le avant de tirer
   la nouvelle image** : `backup.sh` redémarre Vaultia en fin de sauvegarde, et un redémarrage
   démarre l'image déjà tirée.
2. `git pull` (nouvelle ligne `image:` de `compose.yaml` et de `compose.portainer-https.yaml`).
3. `docker compose pull && docker compose up -d` — avec Portainer, « Pull and redeploy » de la
   pile, avec *Re-pull image* (voir [portainer.md](portainer.md), § 11).
4. Vérifier : `docker compose ps` (`healthy`), `curl http://127.0.0.1:3000/api/health` →
   `"status":"ok"`, `"database":"up"`, puis la version en bas du menu : `v0.1.0-rc.14`.

- **Aucune migration de base**, **aucune variable** nouvelle ou modifiée, format de sauvegarde 6
  inchangé. Depuis une version plus ancienne, suivre d'abord les sections ci-dessous : les
  migrations s'appliquent de la même façon en passant directement à `0.1.0-rc.14`.
- Mise à jour vérifiée avant publication sur une copie restaurée d'une instance réelle en
  `0.1.0-rc.13` : aucune migration, données et fichiers identiques, redémarrages sans écart,
  sauvegarde puis restauration identiques, isolation des Espaces.

## De 0.1.0-rc.12 à 0.1.0-rc.13

1. **Sauvegarder d'abord** : `./scripts/backup.sh` (vérifier `storage_verify=ok` dans le
   `MANIFEST` et les `SHA256SUMS`) ; garder aussi une copie de `.env`. **Faites-le avant de tirer
   la nouvelle image** : `backup.sh` redémarre Vaultia en fin de sauvegarde, et un redémarrage
   démarre l'image déjà tirée.
2. `git pull` (nouvelle ligne `image:` de `compose.yaml` et de `compose.portainer-https.yaml`).
3. `docker compose pull && docker compose up -d` — avec Portainer, « Pull and redeploy » de la
   pile, avec *Re-pull image* (voir [portainer.md](portainer.md), § 11).
4. Vérifier : `docker compose ps` (`healthy`), `curl http://127.0.0.1:3000/api/health` →
   `"status":"ok"`, `"database":"up"`, puis la version en bas du menu : `v0.1.0-rc.13`.

- **Aucune migration de base**, **aucune variable** nouvelle ou modifiée, format de sauvegarde 6
  inchangé, aucun nouveau modèle à télécharger. Depuis une version plus ancienne, suivre d'abord la
  section correspondante ci-dessous jusqu'à `0.1.0-rc.12` : les migrations s'appliquent de la même
  façon en passant directement à `0.1.0-rc.13`.
- Mise à jour vérifiée avant publication sur une copie de cette distribution, avec une copie
  restaurée d'une instance réelle en `0.1.0-rc.12` : aucune migration, données et fichiers
  identiques après la mise à jour, redémarrages sans écart, sauvegarde puis restauration
  identiques, isolation des Espaces.

## De 0.1.0-rc.9, rc.10 ou rc.11 à 0.1.0-rc.12

1. **Sauvegarder d'abord** : `./scripts/backup.sh` (vérifier `storage_verify=ok` dans le
   `MANIFEST` et les `SHA256SUMS`) ; garder aussi une copie de `.env`. **Faites-le avant de tirer
   la nouvelle image** : `backup.sh` redémarre Vaultia en fin de sauvegarde, et un redémarrage
   démarre l'image déjà tirée. Cette sauvegarde est le seul retour possible vers votre version
   actuelle : les migrations ne se défont pas.
2. `git pull` (nouvelle ligne `image:` de `compose.yaml` et de `compose.portainer-https.yaml`).
3. `docker compose pull && docker compose up -d` — avec Portainer, « Pull and redeploy » de la
   pile, avec *Re-pull image* (voir [portainer.md](portainer.md), § 11).
4. Vérifier : `docker compose ps` (`healthy`), `curl http://127.0.0.1:3000/api/health` →
   `"status":"ok"`, `"database":"up"`, puis la version en bas du menu : `v0.1.0-rc.12`.

Ce qui change selon votre point de départ :

- **Depuis `0.1.0-rc.11`** : aucune migration de base, aucune variable, format de sauvegarde 6
  inchangé.
- **Depuis `0.1.0-rc.10`** : une migration, appliquée automatiquement au démarrage :
  `20261001120000_add_parties` (référentiel des tiers ; les noms déjà saisis identiques à la casse,
  aux accents et à la ponctuation près sont rattachés à une même fiche, aucun libellé n'est modifié,
  rien n'est rapproché par simple ressemblance). Sauvegardes d'Espace au format 6.
- **Depuis `0.1.0-rc.9`** : en plus, `20261001090000_add_lifebook_events` (événements du carnet de
  vie). Sauvegardes d'Espace au format 6 ; celles des formats 1 à 5 se restaurent toujours.
- **Aucune variable** nouvelle ou modifiée, **aucun nouveau modèle** à télécharger.
- Mise à jour vérifiée avant publication sur une copie de cette distribution, avec des données
  créées par `0.1.0-rc.11` (comptes, Espaces, objets, achats, garanties, travaux, dépenses directes
  avec justificatif, véhicule, carnet, coffre et documents PERSONAL, tiers) : aucune migration,
  données et fichiers identiques après la mise à jour, redémarrages sans écart, sauvegarde puis
  restauration identiques, installation vierge et fonctionnement hors ligne.

## De 0.1.0-rc.8 à 0.1.0-rc.9

1. **Sauvegarder d'abord** : `./scripts/backup.sh` (vérifier `storage_verify=ok` dans le
   `MANIFEST` et les `SHA256SUMS`) ; garder aussi une copie de `.env`. Cette sauvegarde est le seul
   retour possible vers `0.1.0-rc.8` : les migrations de `0.1.0-rc.9` ne se défont pas, et une
   sauvegarde faite en `0.1.0-rc.9` ne se restaure pas dans une version antérieure.
2. `git pull` (nouvelle ligne `image:` de `compose.yaml` et de `compose.portainer-https.yaml`).
3. `docker compose pull && docker compose up -d` — avec Portainer, « Pull and redeploy » de la
   pile, avec *Re-pull image* (voir [portainer.md](portainer.md), § 11).
4. Vérifier : `docker compose ps` (`healthy`), `curl http://127.0.0.1:3000/api/health` →
   `"status":"ok"`, `"database":"up"`, puis la version en bas du menu : `v0.1.0-rc.9`.

Ce qui change :

- **Deux migrations de base**, appliquées automatiquement au démarrage (`prisma migrate deploy`) :
  dépôts temporaires de justificatifs (`20260930080000_add_staged_attachments`) et justificatifs
  des dépenses de véhicule (`20260930120000_add_vehicle_expense_documents`). Aucune donnée
  existante n'est transformée ; le démarrage prend quelques secondes de plus une seule fois.
- **Sauvegardes d'Espace (ZIP) au format 4** : celles des versions précédentes (formats 1 à 3) se
  restaurent toujours ; une sauvegarde d'Espace faite en `0.1.0-rc.9` exige `0.1.0-rc.9` ou plus
  récent. Le Backup ALL (`scripts/backup.sh`) garde son mécanisme ; comme toujours, il se restaure sur
  une version égale ou plus récente.
- **Aucune variable** nouvelle ou modifiée, **aucun nouveau modèle** à télécharger ; la recherche
  Web configurée (SearXNG ou Brave, [web-product-search.md](web-product-search.md)) est conservée
  telle quelle.
- Mise à jour vérifiée avant publication sur une copie de cette distribution, avec des données
  créées par `0.1.0-rc.8` (comptes, Espaces, objets, achats, garanties, travaux, véhicule, coffre
  et documents PERSONAL) : données et fichiers identiques après la mise à jour, redémarrages sans
  écart, sauvegarde puis restauration identiques.

## De 0.1.0-rc.7 à 0.1.0-rc.8

1. **Sauvegarder d'abord** : `./scripts/backup.sh` (vérifier `storage_verify=ok` dans le
   `MANIFEST` et les `SHA256SUMS`) ; garder aussi une copie de `.env`.
2. `git pull` (nouvelle ligne `image:` de `compose.yaml` et de `compose.portainer-https.yaml`).
3. `docker compose pull && docker compose up -d` — avec Portainer, « Pull and redeploy » de la
   pile, avec *Re-pull image* (voir [portainer.md](portainer.md), § 11).
4. Vérifier : `docker compose ps` (`healthy`), `curl http://127.0.0.1:3000/api/health` →
   `"status":"ok"`, `"database":"up"`, puis la version en bas du menu : `v0.1.0-rc.8`.

Ce qui change :

- **Aucune migration de base**, aucun changement du stockage ni du format des sauvegardes.
- **Aucune variable** nouvelle ou modifiée ; la recherche Web configurée (SearXNG ou Brave,
  [web-product-search.md](web-product-search.md)) est conservée telle quelle.

## De 0.1.0-rc.6 à 0.1.0-rc.7

1. **Sauvegarder d'abord** : `./scripts/backup.sh` (vérifier `storage_verify=ok` dans le
   `MANIFEST` et les `SHA256SUMS`) ; garder aussi une copie de `.env`.
2. `git pull` (nouvelle ligne `image:` de `compose.yaml` et de `compose.portainer-https.yaml`).
3. `docker compose pull && docker compose up -d` — avec Portainer, « Pull and redeploy » de la
   pile, avec *Re-pull image* (voir [portainer.md](portainer.md), § 11).
4. Vérifier : `docker compose ps` (`healthy`), `curl http://127.0.0.1:3000/api/health` →
   `"status":"ok"`, `"database":"up"`, puis la version en bas du menu : `v0.1.0-rc.7`.

Ce qui change :

- **Aucune migration de base**, aucun changement du stockage ni du format des sauvegardes.
- **Aucune nouvelle variable** obligatoire, **aucun nouveau modèle** à télécharger.
- La recherche Web de codes produit (`web-product-search`, facultative, désactivée par défaut) est
  configurable dans cette distribution depuis le correctif de distribution qui suit (SearXNG
  auto-hébergé ou Brave Search) : voir [web-product-search.md](web-product-search.md). Sans elle,
  Vaultia fonctionne comme avant (inventaire, bases produit ouvertes, saisie manuelle).

### Correctif de distribution : recherche Web (même image 0.1.0-rc.7)

Aucune nouvelle image : les fichiers Compose transmettent désormais `WEB_PRODUCT_SEARCH_BACKEND`,
`WEB_PRODUCT_SEARCH_URL` et `WEB_PRODUCT_SEARCH_API_KEY` (vides par défaut), et proposent un service
SearXNG facultatif (profil `web-search`). Une installation qui ne configure rien ne change pas :
`git pull` puis redéploiement, ou rien du tout. Pour l'activer : [web-product-search.md](web-product-search.md).

## De 0.1.0-rc.5 à 0.1.0-rc.6

1. **Sauvegarder d'abord** : `./scripts/backup.sh` (vérifier `storage_verify=ok` dans le
   `MANIFEST` et les `SHA256SUMS`) ; garder aussi une copie de `.env`. Cette sauvegarde est le
   seul retour possible vers `0.1.0-rc.5` une fois que plusieurs objets partagent un code produit
   (`0.1.0-rc.5` refuse ces doublons).
2. `git pull` (nouvelle ligne `image:` de `compose.yaml` et de `compose.portainer-https.yaml`).
3. `docker compose pull && docker compose up -d` — avec Portainer, « Pull and redeploy » de la
   pile, avec *Re-pull image* (voir [portainer.md](portainer.md), § 11).
4. Vérifier : `docker compose ps` (`healthy`), `curl http://127.0.0.1:3000/api/health` →
   `"status":"ok"`, `"database":"up"`, puis la version en bas du menu : `v0.1.0-rc.6`.

Ce qui change :

- **Une migration de base**, appliquée au démarrage et **non destructive** : seule la règle
  d'unicité des codes produit (EAN, UPC, GTIN, référence fabricant) est assouplie ; aucune donnée
  n'est modifiée. Le numéro de série et le QR Vaultia restent uniques.
- **Aucune nouvelle variable** de configuration, **aucun nouveau modèle** à télécharger.
- Les sauvegardes d'Espace gardent le format v3 ; leur restauration accepte désormais des
  exemplaires qui partagent un code produit.

**Validé réellement** avant la publication de `0.1.0-rc.6`, avec l'image construite comme
l'image officielle (même source, même version embarquée) :

- installation `0.1.0-rc.5` représentative, avec l'image officielle `0.1.0-rc.5` ;
- sauvegarde ALL avant la mise à jour (`storage_verify=ok`), puis mise à jour ;
- 58 migrations, aucune en attente ; seule la table des migrations change (une ligne de plus),
  toutes les autres tables sont identiques ;
- fichiers intacts (SHA-256) ; Vision READY ; version affichée `v0.1.0-rc.6` ;
- `restart` et `down`/`up` : état identique ; sauvegarde ALL après la mise à jour valide.

Après la publication, une installation Portainer réelle (arm64, HTTPS local avec Caddy) a été mise
à jour par « Pull and redeploy » : volumes conservés, données identiques (seule la table des
migrations change), fichiers identiques (SHA-256), `v0.1.0-rc.6` affichée, redémarrage sans perte.

## De 0.1.0-rc.4 à 0.1.0-rc.5

1. **Sauvegarder d'abord** : `./scripts/backup.sh` (vérifier `storage_verify=ok` dans le
   `MANIFEST` et les `SHA256SUMS`) ; garder aussi une copie de `.env`.
2. `git pull` (nouvelle ligne `image:` de `compose.yaml`, nouvelle liste de moteurs par défaut).
3. `docker compose pull && docker compose up -d`.
4. Vérifier : `docker compose ps` (`healthy`), `curl http://127.0.0.1:3000/api/health` →
   `"vision":"ready"` (une fois le nouveau modèle installé), puis la version en bas du menu :
   `v0.1.0-rc.5`.

Ce qui change :

- **Une migration de base**, appliquée au démarrage : l'index de la recherche par le sens (donnée
  dérivée, construite en arrière-plan et reconstruite après une restauration).
- **Moteurs par défaut** (`INTELLIGENCE_PROVIDERS` vide dans `.env`) : s'y ajoutent
  `e5-embeddings` (recherche par le sens, **local**) et `open-facts` (bases produit ouvertes,
  **Internet**, appelé seulement pour un Espace en mode « externe »). Au premier démarrage, le
  modèle d'E5 (≈ 130 Mio) est téléchargé et vérifié ; `/api/health` dit `"vision":"provisioning"`
  pendant ce temps, et Vaultia reste utilisable. Si votre `.env` fixe déjà une liste, elle est
  conservée telle quelle : ajoutez-y `e5-embeddings` pour la recherche par le sens. Rien ne change
  pour un Espace tant qu'il reste en mode « désactivé » (défaut) : voir [vision.md](vision.md).
- **Variables facultatives nouvellement transmises** : `DOCUMENT_INDEXER` et `TESSERACT_LANGS`
  (vides : mêmes valeurs qu'avant, `inline` et `fra+eng`), voir [configuration.md](configuration.md).
- **KI-001 corrigé** : le focus clavier revient au titre de la section après une suppression
  confirmée.

**Validé réellement** avant et après la publication de `0.1.0-rc.5` :

- installation `0.1.0-rc.4` représentative, avec l'image officielle : 2 comptes, 2 Espaces dont un
  membre EDITOR, plusieurs propriétés (dont une sans valeur), objets avec exemplaires séparés,
  sortis et prêtés, véhicule complet, achats et justificatifs, dépenses, travaux, sinistres,
  valorisations, documents du coffre de l'Espace et PERSONAL avec fichiers ;
- sauvegarde ALL avant la mise à jour (`storage_verify=ok`), puis mise à jour selon cette procédure ;
- 57 migrations, aucune en attente ; les 81 tables d'avant sont identiques, plus la nouvelle table ;
- fichiers intacts (SHA-256) ; nouveaux rapports disponibles ; droits Espace et PERSONAL inchangés ;
- Vision READY avec une inférence réelle (SigLIP 2 et E5) ;
- `restart` et `down`/`up` : état identique ; sauvegarde ALL après la mise à jour valide ;
- l'image publiée, lancée par son digest sur cette installation, affiche `v0.1.0-rc.5`.

Le passage direct depuis `0.1.0-rc.3` ou `0.1.0-rc.2` n'a **pas** été rejoué : il applique en plus
les migrations de `0.1.0-rc.3`, et la sauvegarde de l'étape 1 reste le point de retour.

## De 0.1.0-rc.2 ou 0.1.0-rc.3 à 0.1.0-rc.4

1. **Sauvegarder d'abord** : `./scripts/backup.sh` (vérifier `storage_verify=ok` dans le
   `MANIFEST` et les `SHA256SUMS`) ; garder aussi une copie de `.env`.
2. `git pull` (nouvelle ligne `image:` de `compose.yaml`).
3. `docker compose pull && docker compose up -d`.
4. Vérifier : `docker compose ps` (`healthy`), `curl http://127.0.0.1:3000/api/health` →
   `"vision":"ready"`, puis la version affichée en bas du menu : `v0.1.0-rc.4`.

Migrations : `0.1.0-rc.3` en apporte deux (lignée des fiches, exemplaires prêtés), appliquées au
démarrage ; `0.1.0-rc.4` n'en apporte aucune. Depuis `0.1.0-rc.2`, le démarrage applique donc
les deux migrations de `0.1.0-rc.3`. Aucune variable n'est à ajouter.

**Validé réellement** avant publication de `0.1.0-rc.4`, sur une installation `0.1.0-rc.3`
représentative (image officielle, 3 comptes, 3 Espaces dont un membre EDITOR, objets avec
exemplaires séparés et sortis, prêts, véhicules, documents du coffre Espace et PERSONAL, médias,
valorisations, achats, dépenses, sinistres) : sauvegarde ALL avant la mise à jour
(`storage_verify=ok`), 56 migrations et aucune en attente ; après la mise à jour, puis après
`restart` et `down`/`up` : les 82 tables sont identiques, fichiers intacts (SHA-256), modèle de
vision conservé, Vision READY, droits Espace et PERSONAL inchangés. Le passage `0.1.0-rc.2` →
`0.1.0-rc.3` avait été validé de la même manière avant la publication de `0.1.0-rc.3` ; le passage
direct `0.1.0-rc.2` → `0.1.0-rc.4` applique les mêmes migrations, sans migration supplémentaire,
mais n'a pas été rejoué en une seule étape : la sauvegarde de l'étape 1 reste le point de retour.

Limite connue de `0.1.0-rc.4` (KI-001) : après certaines suppressions confirmées dans un
dialogue, le focus clavier peut revenir en haut de la page au lieu du titre de la section. La
suppression est bien effectuée et annoncée ; aucune donnée n'est touchée.

## De 0.1.0-rc.1 à 0.1.0-rc.2

1. **Sauvegarder d'abord** : `./scripts/backup.sh` (vérifier `storage_verify=ok` dans le
   `MANIFEST` et les `SHA256SUMS`) ; garder aussi une copie de `.env`.
2. `git pull` (nouvelle ligne `image:` de `compose.yaml`).
3. `docker compose pull && docker compose up -d`.
4. Vérifier : `docker compose ps` (`healthy`), `curl http://127.0.0.1:3000/api/health` →
   `"vision":"ready"`, `docker compose exec vaultia vaultia vision-status` → `Vaultia Vision: READY`.

**Ne jamais lancer `docker compose down -v`** : `-v` efface les volumes. Une mise à jour
**conserve** les trois volumes, `postgres-data` (base), `media` (fichiers) et `models` (modèle de
vision, non retéléchargé). Aucune variable n'est à ajouter : le HTTP sur le réseau local est
facultatif.

**Validé réellement** avant publication sur une installation `0.1.0-rc.1` existante et
représentative : 3 comptes, 3 Espaces complets et un membre invité, objets, véhicules, documents
du coffre Espace et PERSONAL, 30 médias, valorisations. Sauvegarde ALL faite avant la mise à jour
(`storage_verify=ok`), 54 migrations et aucune en attente. Après la mise à jour, puis après
`restart` et `down`/`up` : les 82 tables sont identiques, fichiers intacts (SHA-256), modèle
conservé, Vision READY, droits Espace et PERSONAL inchangés (un membre ne voit pas les documents
personnels d'un autre, un tiers n'entre pas dans l'Espace).

## Principe

L'image de Vaultia est **épinglée** dans `compose.yaml` par son tag candidat **et** son empreinte
(`ghcr.io/multinet33/vaultia:<version>-rc.<N>@sha256:…`) : l'image lancée est exactement celle
publiée pour le code source indiqué, même si un tag était déplacé. Il n'y a pas de `latest`.

Une mise à jour = une nouvelle ligne `image:` dans ce dépôt. Chaque image candidate porte :

| Référence | Nature |
| --- | --- |
| `sha-<SHA complet du code source>` | immuable : un commit source = une image |
| `<version>-rc.<N>` | immuable, jamais republié |
| `rc` | mobile : dernier candidat (canal RC ; `compose.yaml` ne l'utilise pas par défaut, voir [Mises à jour automatiques](#mises-à-jour-automatiques-watchtower-facultatif)) |
| `stable` | mobile : dernière version stable (canal stable, **pas encore publié** pendant la bêta) |
| étiquette `org.opencontainers.image.revision` | SHA complet du code source |

Vérifier l'image lancée :

    docker compose images vaultia
    docker inspect --format '{{index .Config.Labels "org.opencontainers.image.revision"}}' "$(docker compose ps -q vaultia)"

## Procédure

1. **Lire** l'historique de ce dépôt (`git log`) : nouvelle image, variables ajoutées.
2. **Sauvegarder** : `./scripts/backup.sh` — noter le dossier créé, c'est le point de retour.
3. **Récupérer la distribution** : `git pull` (votre `.env` n'est pas versionné, il est conservé ;
   comparer avec `.env.example` pour d'éventuelles nouvelles variables).
4. **Tirer et relancer** :

       docker compose pull
       docker compose up -d

   Le nouveau conteneur contrôle la configuration, **applique les migrations de base**
   (`docker compose logs vaultia` : `migrations : prisma migrate deploy`), puis démarre. Le modèle
   de la vision est conservé (volume `models`) : il n'est pas retéléchargé, sauf si la nouvelle
   version en exige un autre.
5. **Vérifier** : `docker compose ps` (`healthy`), `curl http://127.0.0.1:3000/api/health`,
   `docker compose exec vaultia vaultia vision-status`, puis connexion et ouverture de quelques
   objets, photos et documents.

Le navigateur reçoit la nouvelle version au chargement suivant (le mode hors ligne se met à jour
seul).

## En cas d'échec — limites du retour arrière

**Ne jamais** lancer `prisma migrate reset`, `db push` ou modifier la base à la main.

- **Migration en échec** : le conteneur s'arrête (`ÉCHEC des migrations`) et Docker le relance.
  Revenir à la sauvegarde de l'étape 2 : restaurer sur des volumes neufs **avec l'ancienne image**
  ([backup-restore.md](backup-restore.md)).
- **Démarre, mais la version pose problème** :
  - *revenir à l'ancienne image seule* (`git checkout <commit précédent> -- compose.yaml`, puis
    `docker compose up -d`) n'est sûr **que** si les migrations de la nouvelle version sont de
    simples ajouts. Ce n'est pas garanti en général ;
  - *revenir par les données* est toujours possible : restaurer la sauvegarde de l'étape 2 avec
    l'ancienne image. Les modifications faites depuis la mise à jour sont perdues.
- Prisma n'annule jamais une migration : il n'existe pas de retour arrière automatique.

Pendant la bêta, un candidat peut introduire des migrations ; aucune compatibilité descendante
n'est promise entre candidats.

## Mises à jour automatiques (Watchtower, facultatif)

Trois modes, au choix de l'administrateur. **Le mode A est le défaut et reste le plus
déterministe** ; les canaux mobiles B et C sont des choix explicites.

| | A — épinglé (défaut) | B — canal RC | C — canal stable |
| --- | --- | --- | --- |
| `VAULTIA_IMAGE` | vide (non défini) | `ghcr.io/multinet33/vaultia:rc` | `ghcr.io/multinet33/vaultia:stable` |
| Image lancée | version + digest épinglés dans `compose.yaml` (`…:0.1.0-rc.N@sha256:…`) | dernier candidat publié sur le canal RC | dernière version stable publiée sur le canal stable |
| Exemple de suite | aucune suite automatique | `rc.4` → `rc.5` → `rc.6`… | `1.0.0` → `1.0.1` → `1.1.0`… |
| Quand elle change | quand ce dépôt change sa ligne `image:` **et** que vous redéployez | quand la publication de Vaultia déplace `rc`, au passage suivant de Watchtower | quand la publication de Vaultia déplace `stable`, au passage suivant de Watchtower |
| Sauvegarde avant mise à jour | faite par vous (§ Procédure) | **aucune** : Watchtower n'en fait pas | **aucune** : Watchtower n'en fait pas |
| Caractère | sûr, reproductible, contrôlé par l'administrateur | pratique pour suivre la bêta | pratique pour suivre les versions stables |

**Le canal `stable` n'est pas encore publié** pendant la bêta (avant 1.0) : le mode C est prévu,
il ne fonctionnera qu'une fois ce tag publié par le processus de release de Vaultia. D'ici là,
`docker compose pull` échouerait sur `:stable`.

### Canaux RC et stable : indépendants

- `:rc` = les dernières *release candidates*, publiées sur le canal RC ;
- `:stable` = les dernières versions stables, publiées sur le canal stable.

Les deux canaux sont **indépendants** : une installation qui suit `:rc` ne reçoit pas
automatiquement une version stable (elle suit la prochaine RC), et une installation qui suit
`:stable` ne reçoit **jamais** une RC. `latest` n'est **pas** un synonyme de stable : n'utilisez
pas `ghcr.io/multinet33/vaultia:latest`, le canal stable officiel prévu est
`ghcr.io/multinet33/vaultia:stable`.

### Ce que fait `compose.yaml`

Le seul service `vaultia` porte deux étiquettes, identiques quel que soit le mode :

    com.centurylinklabs.watchtower.enable=true
    com.centurylinklabs.watchtower.scope=vaultia

**Elles n'activent rien à elles seules** : il faut qu'un administrateur fasse tourner un Watchtower
compatible, lancé avec le filtrage par étiquette (`WATCHTOWER_LABEL_ENABLE=true`) et la portée
`vaultia` (`--scope vaultia`). Watchtower surveille alors la référence d'image **effectivement
configurée** du conteneur : `:rc` suit le canal RC, `:stable` le canal stable. En mode A, l'image
est désignée par son digest : il n'existe aucune image plus récente pour cette référence, le
conteneur ne bouge pas.

**PostgreSQL n'est volontairement pas étiqueté** : il reste hors de la portée `vaultia`, et un
changement de version majeure de PostgreSQL ne doit jamais se faire automatiquement
([§ PostgreSQL](#postgresql)). Aucun accès au socket Docker n'est donné à la pile Vaultia : seul le
conteneur Watchtower, exploité à part, en a besoin.

### Activer le mode B ou C

1. Sauvegarde ALL vérifiée (`./scripts/backup.sh`, `storage_verify=ok`) et copie de `.env`.
2. Dans `.env`, choisir **un** canal :

       VAULTIA_IMAGE=ghcr.io/multinet33/vaultia:rc        # mode B, candidats
       VAULTIA_IMAGE=ghcr.io/multinet33/vaultia:stable    # mode C, versions stables (une fois publié)

   puis `docker compose pull && docker compose up -d`. Vérifier : `docker compose images vaultia`.
3. Lancer un Watchtower **séparé** (autre dossier ou autre pile Portainer), le même pour les deux
   canaux, par exemple :

       services:
         watchtower-vaultia:
           image: containrrr/watchtower:latest
           container_name: watchtower-vaultia
           restart: unless-stopped
           volumes:
             - /var/run/docker.sock:/var/run/docker.sock
           environment:
             TZ: Europe/Paris
             WATCHTOWER_LABEL_ENABLE: "true"
             WATCHTOWER_CLEANUP: "true"
           command:
             - "--schedule"
             - "0 0 * * * *"
             - "--scope"
             - "vaultia"

   `--schedule` prend une expression cron **à six champs, secondes comprises**
   (`secondes minutes heures jour mois jour-de-semaine`) : `0 0 * * * *` = une vérification par
   heure, à la minute 00 (et non « à minuit », comme le lirait un cron à cinq champs).
   `--scope vaultia` et `WATCHTOWER_LABEL_ENABLE` limitent ce Watchtower au seul conteneur
   Vaultia ; il ne touche ni PostgreSQL ni vos autres conteneurs.

Quand la publication de Vaultia déplace le tag suivi vers une nouvelle image (immuable),
Watchtower voit le digest changer, tire l'image et **recrée uniquement le conteneur Vaultia**, avec
la même configuration et les mêmes volumes. PostgreSQL continue de tourner.

### Passer du canal RC au canal stable

Pendant la bêta : `VAULTIA_IMAGE=ghcr.io/multinet33/vaultia:rc`. Le passage au canal stable est
une **décision explicite de l'administrateur** ; il n'existe aucune bascule automatique RC →
stable. Une fois `:stable` publié et la décision prise :

1. Sauvegarde ALL vérifiée.
2. `VAULTIA_IMAGE=ghcr.io/multinet33/vaultia:stable` (dans `.env` ou en variable de pile Portainer).
3. Redéployer : `docker compose pull && docker compose up -d`, ou **Update the stack** avec
   **Re-pull image** dans Portainer.

Rien d'autre ne change : Watchtower garde la même portée `vaultia`, le conteneur les mêmes
étiquettes `enable=true` et `scope=vaultia` ; seule la référence d'image suivie change. Si la
dernière RC appliquée est plus récente que la version stable (migrations comprises), attendre une
version stable au moins aussi récente avant de basculer : revenir à une image plus ancienne n'est
pas sûr (ci-dessous).

Pour revenir au mode A : vider `VAULTIA_IMAGE` et redéployer, sous la même réserve : si l'image
suivie est plus récente que l'image épinglée et a appliqué des migrations, attendre que ce dépôt
épingle une version au moins aussi récente.

### Sécurité des mises à jour en modes B et C — à lire avant d'activer

**Publier n'est pas déployer.** En mode B, chaque nouveau candidat publié sur le canal `rc` est
installé sans décision de votre part. Pour une instance qui contient vos vraies données, préférez
le **mode A** (image épinglée par version **et** digest) : avec un digest, Watchtower n'a jamais
d'image plus récente à installer, même s'il tourne ; vous mettez à jour quand vous l'avez décidé,
après une sauvegarde.

Les mêmes avertissements valent pour les deux canaux :

- Une nouvelle version est **tirée et démarrée automatiquement**, sans vous, à n'importe quelle
  heure du planning.
- Au démarrage, Vaultia **applique les migrations de base** : une mise à jour automatique peut donc
  modifier le schéma de la base.
- Watchtower **ne fait aucune Sauvegarde ALL** avant de mettre à jour, et **n'offre aucun retour
  arrière de la base**. Les sauvegardes restent **votre responsabilité** : planifier
  `./scripts/backup.sh` régulièrement (et garder `.env`) est indispensable.
- Après une migration, relancer l'image précédente ne suffit pas forcément : le retour arrière peut
  exiger la **restauration d'une Sauvegarde ALL antérieure à la mise à jour**, avec l'ancienne
  image ([§ En cas d'échec](#en-cas-déchec--limites-du-retour-arrière),
  [backup-restore.md](backup-restore.md)). Les modifications faites depuis sont alors perdues.
- Les volumes persistants ne doivent **jamais** être supprimés lors d'une mise à jour ; **ne jamais
  utiliser `docker compose down -v`** comme procédure de mise à jour.
- PostgreSQL ne doit pas être mis à jour par ce Watchtower : ne lui ajoutez pas ces étiquettes.

### Pile Portainer depuis Git

Une pile Portainer peut être déployée directement depuis
`https://github.com/multinet33/vaultia-selfhosted.git` ([portainer.md](portainer.md)), avec le
Compose path `compose.yaml` (HTTP) ou `compose.portainer-https.yaml` (HTTPS local,
[portainer.md § 13](portainer.md#13-https-local-avec-portainer-caddy)) ; tout ce qui suit vaut pour
les deux. Pour
choisir un canal, **ne modifiez pas `compose.yaml`** : gardez le fichier piloté par Git (et son
comportement épinglé par défaut) et définissez seulement, dans les variables d'environnement de la
pile, **l'une** de ces valeurs :

    VAULTIA_IMAGE=ghcr.io/multinet33/vaultia:rc        # candidats
    VAULTIA_IMAGE=ghcr.io/multinet33/vaultia:stable    # versions stables, une fois publié

puis **Update the stack** (avec **Re-pull image**). Le choix du canal reste ainsi local à votre
Portainer. Le Watchtower ci-dessus vit de préférence dans **une autre pile** (pile de
maintenance), pas dans celle de Vaultia :

- pile `vaultia` → Vaultia + PostgreSQL, + Caddy en HTTPS local (ce dépôt, sans socket Docker) ;
- pile de maintenance → Watchtower (seul à monter `/var/run/docker.sock`).

Watchtower recrée le conteneur Vaultia hors de Portainer ; Portainer continue de l'afficher dans la
pile. Un **Pull and redeploy** ultérieur de la pile garde la variable `VAULTIA_IMAGE` et reste sur
le canal choisi.

## PostgreSQL

`compose.yaml` fixe PostgreSQL 18 : `docker compose pull` applique les correctifs mineurs. Un
changement de version **majeure** passe par une sauvegarde et une restauration sur des volumes
neufs (procédure non testée pendant la bêta).
