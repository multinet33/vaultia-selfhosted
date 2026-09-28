# Vaultia Vision

Vaultia fonctionne **entièrement sans** Vaultia Vision : chaque analyse est une proposition, que vous
acceptez, modifiez ou ignorez ; rien n'est enregistré sans votre validation. Tous les moteurs
installés par défaut s'exécutent sur votre serveur, sauf `open-facts` (bases produit ouvertes,
Internet), qui n'est appelé que pour un Espace en mode « externe ».

Chaque Espace choisit lui-même : **Réglages › Vaultia Vision › mode** (désactivé par défaut).

## Quatre notions à ne pas confondre

| Notion | Question | Où cela se règle ou se voit |
| --- | --- | --- |
| **Moteur disponible** (installé) | ce serveur sait-il faire ce traitement ? | `INTELLIGENCE_PROVIDERS` (administrateur du serveur) |
| **Moteur provisionné** | ses fichiers (modèle) sont-ils présents et intègres sur le disque ? | `/api/health` → `"vision"` (`ready`, `provisioning`, `failed`, `missing`, `disabled`) |
| **Traitement autorisé** | cet Espace accepte-t-il ce traitement, à cet endroit ? | Réglages › Vaultia Vision › mode de l'Espace |
| **Capacité opérationnelle** | peut-on l'utiliser maintenant ? | Réglages › Vaultia Vision › Capacités (états ci-dessous) |

Installé ne veut pas dire autorisé, et provisionné ne veut pas dire chargé en mémoire.

## Modes d'un Espace

| Mode | Traitements permis |
| --- | --- |
| Désactivé (défaut) | aucun ; Vaultia fonctionne normalement, en saisie manuelle |
| Local | **traitement local** seulement : tout s'exécute sur votre serveur ; aucune donnée ne sort |
| Externe | traitements locaux **et** services externes installés (Internet) ; seul ce qui est nécessaire leur est transmis |

## États d'une capacité

| Affiché | Sens | Que faire |
| --- | --- | --- |
| **Prête** | un moteur autorisé est prêt | rien |
| **Chargement…** | le moteur s'initialise (au premier usage après un démarrage, SigLIP 2 vérifie son modèle et l'ouvre en mémoire) ; une analyse demandée entre-temps attend | rien : la page passe seule à « Prête » |
| **Indisponible** | échec réel après une tentative (le moteur ne répond pas comme prévu) | nouvel essai automatique après 30 s ou à la prochaine analyse ; voir les journaux |
| **Mal configurée** | configuration du serveur incorrecte : modèle absent ou altéré, exécutable introuvable | `docker compose exec vaultia vaultia vision-status` ; voir [Configuration](configuration.md) |
| **À venir** | aucun moteur installé sur ce serveur ne fournit cette capacité | rien à régler aujourd'hui |
| **Traitement externe non autorisé** | seul un service externe la fournit, et l'Espace est en mode local | passer l'Espace en mode externe, si vous l'acceptez |
| **Désactivée** | l'Espace n'autorise aucune analyse | mode local ou externe |
| **Non prise en charge** | le moteur ne sait pas traiter cette demande | — |

« Prête » pour un service **externe** dit qu'il est installé et autorisé, pas qu'il répond :
aucun appel réseau n'est fait pour l'état ; le service est joint à chaque recherche.

## Moteurs

| Moteur (`INTELLIGENCE_PROVIDERS`) | Fournit | Où | Nature |
| --- | --- | --- | --- |
| `zxing-barcode` (zxing-cpp) | codes-barres, EAN/UPC/GTIN, QR codes, sur le serveur | local | décodage, aucun modèle |
| `tesseract-ocr` (Tesseract 5) | reconnaissance de texte (photos, PDF numérisés), langues `fra+eng` | local | reconnaissance classique |
| `siglip2-vision` (SigLIP 2, ONNX Runtime, CPU) | type d'objet et caractéristiques visibles (couleur, matière) | local | modèle d'image : compare la photo à un catalogue fermé de concepts, propose ou s'abstient ; ne génère aucun texte, n'invente ni catégorie ni marque |
| `e5-embeddings` (multilingual-e5-small, ONNX Runtime, CPU) | recherche par le sens (« frigo » trouve un réfrigérateur, « coffee maker » une machine à café) | local | modèle de texte (MIT) : transforme un texte en vecteur pour mesurer une proximité de sens ; ne génère aucun texte, n'écrit aucune donnée |
| `document-rules` (Vaultia) | extraction d'un justificatif (date, montant, marchand, lignes…) | local | règles déterministes ; **pas** un modèle de langage |
| `open-facts` (Open Products Facts, Open Food Facts) | données produit à partir d'un code GTIN | **externe** (Internet) | référence consultée ; utilisé **seulement** en mode externe ; seul le code EAN/UPC/GTIN est transmis |

Tous sont installés par défaut dans l'image depuis RC5 (`open-facts` compris : installé n'est pas
autorisé). `siglip2-vision` (~90 Mio) et `e5-embeddings` (~130 Mio) exigent un modèle, installé au
premier démarrage dans le volume `models` (voir [Configuration › Vision et analyses](configuration.md#vision-et-analyses)).

## Capacités

| Capacité (Réglages) | Moteur | Traitement | État attendu |
| --- | --- | --- | --- |
| Codes-barres | `zxing-barcode` | local | Prête (modes local et externe) |
| Reconnaissance de texte | `tesseract-ocr` | local | Prête |
| Documents | `document-rules` | local | Prête |
| Analyse d'image — type d'objet | `siglip2-vision` | local | Chargement…, puis Prête |
| Analyse d'image — caractéristiques | `siglip2-vision` (même moteur, même état) | local | Chargement…, puis Prête |
| Données produit | `open-facts` | externe | Traitement externe non autorisé en mode local ; Prête en mode externe |
| Recherche sémantique | `e5-embeddings` | local | Chargement…, puis Prête |
| Modèle de langage | aucun moteur | — | À venir |
| Valeur de marché | aucun moteur | — | À venir |

- **Recherche sémantique** (`EMBEDDINGS`) : `e5-embeddings`, local. La recherche de Vaultia (⌘K,
  page de recherche) reste **lexicale et tolérante aux fautes de frappe** ; pour un Espace en mode
  local ou externe, elle ajoute **après** ses résultats une section « Proche par le sens » (objets et
  documents du coffre), sans jamais modifier ni réordonner les résultats lexicaux. Un document
  personnel n'est proposé qu'à son propriétaire. Mode désactivé, moteur absent ou en chargement :
  recherche lexicale seule, sans attente. L'index (vecteurs) est une donnée dérivée : construit en
  arrière-plan, effacé quand l'Espace est désactivé, jamais exporté, reconstructible avec
  `docker compose exec vaultia vaultia embeddings-rebuild`.
- **Modèle de langage** (`LANGUAGE_MODEL`) : aucun moteur ; `document-rules` couvre l'extraction des
  justificatifs sans modèle de langage. Aucun modèle de langage n'est livré : aucun cas d'usage ne
  justifie encore sa taille (0,5 à 2,7 Go) face aux règles actuelles.
- **Valeur de marché** (`MARKET_LOOKUP`) : Vaultia sait déjà consommer une référence de marché (service
  des valorisations), mais aucun fournisseur n'est installé. La ligne s'affiche « Valeur de marché ·
  Référence consultée · Aucun moteur · À venir ».

## Les modèles

Deux moteurs ont besoin d'un modèle, installé dans le volume `models` au premier démarrage :

| | SigLIP 2 (`siglip2-vision`) | E5 (`e5-embeddings`) |
| --- | --- | --- |
| Modèle | SigLIP 2 base patch16-224 (Google), encodeur d'image, export ONNX quantifié int8 | multilingual-e5-small (intfloat), encodeur de texte multilingue, export ONNX quantifié int8 |
| Source | `https://huggingface.co/onnx-community/siglip2-base-patch16-224-ONNX` | `https://huggingface.co/Xenova/multilingual-e5-small` |
| Révision épinglée | `ba1f3b0843f24bc5417d38e19c37b287d719b2f4` | `761b726dd34fb83930e26aab4e9ac3899aa1fa78` |
| Fichiers | `onnx/vision_model_quantized.onnx` — 94 553 333 octets | `onnx/model_quantized.onnx` — 118 308 185 octets ; `tokenizer.json` — 17 082 730 octets |
| SHA-256 | `5f2b401c1a4fc095702a5d45348e17ad46c4f87064085365b43c6e8eaa5c0070` | `f80102d3f2a1229f387d3c81909990d8945513e347b0eab049f7de3c6f98c193` ; `0b44a9d7b51c3c62626640cda0e2c2f70fdacdc25bbbd68038369d14ebdf4c39` |
| Emplacement | `/var/lib/vaultia/models/siglip2-base-patch16-224/` | `/var/lib/vaultia/models/multilingual-e5-small/` |

Aucun des deux ne génère de texte. SigLIP 2 compare la photo à un catalogue fermé de concepts et
d'attributs, livré dans l'image : il propose, ou s'abstient ; il n'invente ni catégorie ni marque.
E5 transforme un texte en vecteur pour mesurer une proximité de sens : les résultats « Proche par le
sens » s'ajoutent **après** ceux de la recherche habituelle, sans jamais les modifier ni les
réordonner. Un document personnel n'y est proposé qu'à son propriétaire.

Pour installer moins de moteurs (pas de modèle de 130 Mio, par exemple), donner une liste réduite
dans `INTELLIGENCE_PROVIDERS` ([configuration.md](configuration.md#vision-et-analyses)).

## Installation automatique

À chaque démarrage, Vaultia vérifie les modèles **en arrière-plan** pendant que l'application
démarre :

1. présent et intègre (taille + SHA-256) → rien n'est téléchargé ;
2. absent ou altéré → téléchargement depuis la source ci-dessus, à la révision épinglée, dans un
   fichier `.partial` ; un téléchargement interrompu reprend où il s'était arrêté ;
3. vérification de la taille et du SHA-256, puis mise en place atomique ; un fichier partiel ou
   altéré n'est **jamais** utilisé ;
4. en cas d'échec (hors ligne, source indisponible) : nouvel essai après 30 s, puis 1, 2, 4… jusqu'à
   15 min d'intervalle. Vaultia reste utilisable ; le conteneur n'est jamais redémarré en boucle.

Les journaux le disent en toutes lettres (exemple d'un premier démarrage) :

    docker compose logs vaultia | grep models

    [vaultia][models] siglip2-base-patch16-224/onnx/vision_model_quantized.onnx : téléchargement (90.2 Mio) depuis onnx-community/siglip2-base-patch16-224-ONNX@ba1f3b0843f2
    [vaultia][models] siglip2-base-patch16-224/onnx/vision_model_quantized.onnx : 45 % (40.6 / 90.2 Mio)
    [vaultia][models] siglip2-base-patch16-224/onnx/vision_model_quantized.onnx : vérification (taille et SHA-256)
    [vaultia][models] siglip2-base-patch16-224/onnx/vision_model_quantized.onnx : installé et vérifié
    [vaultia][models] tous les modèles sont installés et vérifiés : Vaultia Vision prête

Plusieurs minutes de téléchargement sur une connexion lente sont normales : la progression
s'affiche toutes les 10 s.

## Vérifier : « Vaultia Vision: READY »

    docker compose exec vaultia vaultia vision-status

Contrôle l'intégrité des modèles, l'état de chaque moteur local (il attend la fin d'un chargement
en cours), puis fait une **inférence réelle** : une photo de canapé doit être reconnue par SigLIP 2,
et « frigo » doit être plus proche de « Réfrigérateur » que de « Guitare » pour E5. Dernière ligne : `Vaultia Vision: READY` (code 0) ou
`Vaultia Vision: NOT READY` (code 1). Plus léger : `curl http://127.0.0.1:3000/api/health` →
`"vision":"ready"`.

## Commandes

    docker compose exec vaultia vaultia models-verify      # intégrité seule, sans réseau
    docker compose exec vaultia vaultia models-provision   # installer ou réparer maintenant
    docker compose exec vaultia vaultia vision-status      # état complet et inférence

Installation manuelle seulement : `INTELLIGENCE_MODELS_PROVISION=off` dans `.env`, puis
`models-provision` quand vous le décidez.

## Hors ligne

Une fois les modèles installés, la vision fonctionne **sans Internet** (vérifié réseau coupé :
`Vaultia Vision: READY` et inférence réelle, recherche par le sens comprise). Seul le premier
téléchargement d'un modèle — ou son remplacement s'il est effacé ou altéré — a besoin d'Internet ;
`open-facts`, s'il est autorisé par un Espace, joint Internet à chaque recherche de produit. Pour un serveur sans aucun accès
Internet : installer le modèle sur une machine connectée (`models-provision` dans un volume), puis
copier le contenu du volume `vaultia_models`.

## Sauvegarde

Les modèles ne sont **pas** sauvegardés par `scripts/backup.sh` : ce sont des artefacts
retéléchargeables et vérifiés par empreinte, pas des données. Supprimer le volume `vaultia_models` ne
fait perdre aucune donnée. L'index de la recherche par le sens est dans la base : sauvegardé avec
elle et réutilisé après une restauration ; il n'est jamais inclus dans la sauvegarde d'un Espace
(ZIP), et se reconstruit seul après sa restauration.

## Licences des modèles

Le modèle de base `google/siglip2-base-patch16-224` est publié par Google sous **licence
Apache-2.0** ; `intfloat/multilingual-e5-small` et son export ONNX `Xenova/multilingual-e5-small`
sous **licence MIT**. L'export ONNX quantifié (`onnx-community/siglip2-base-patch16-224-ONNX`) est une
conversion de ce modèle ; son dépôt ne déclare pas de licence propre. Vaultia **ne redistribue pas**
les modèles : votre instance les télécharge directement depuis leur source publique, à la révision
indiquée. ONNX Runtime (MIT), Tesseract et ses données de langue (Apache-2.0) et ZXing
(Apache-2.0 / MIT) sont dans l'image, avec leurs avis dans `/app/THIRD-PARTY-NOTICES.md`.
