# Vision locale

La bêta installe **toute** la vision locale de Vaultia. Tous les traitements s'exécutent sur votre
serveur ; aucun n'envoie vos photos ou documents à un service externe.

| Capacité | Moteur | Ce qu'il faut | Où |
| --- | --- | --- | --- |
| Identification d'objets en photo, couleur, matière | `siglip2-vision` (SigLIP 2, ONNX Runtime, CPU) | **un modèle de 90 Mio**, installé au premier démarrage | volume `models` |
| Reconnaissance de texte (photos, PDF scannés), français et anglais | `tesseract-ocr` (Tesseract 5) | rien | dans l'image |
| Codes-barres (EAN, UPC, QR…) | `zxing-barcode` (ZXing, WebAssembly) | rien | dans l'image |
| Extraction des factures et tickets (date, montant, marchand…) | `document-rules` (règles déterministes, sans modèle) | rien | dans l'image |

Non fournis (affichés « À venir » dans l'application) : modèle de langage, embeddings, valeur de
marché. La recherche de produit `open-facts` est **externe** (Internet) et n'est pas installée par
défaut.

Chaque Espace active l'analyse lui-même : **Réglages › Vaultia Vision › mode « Locale »**
(désactivée par défaut). Le mode « Externe » n'est utile qu'avec `open-facts`.

## Le modèle

| | |
| --- | --- |
| Modèle | SigLIP 2 base patch16-224 (Google), encodeur d'image, export ONNX quantifié int8 |
| Source | `https://huggingface.co/onnx-community/siglip2-base-patch16-224-ONNX` |
| Révision épinglée | `ba1f3b0843f24bc5417d38e19c37b287d719b2f4` |
| Fichier | `onnx/vision_model_quantized.onnx` — 94 553 333 octets |
| SHA-256 | `5f2b401c1a4fc095702a5d45348e17ad46c4f87064085365b43c6e8eaa5c0070` |
| Emplacement | volume `vaultia_models`, `/var/lib/vaultia/models/siglip2-base-patch16-224/` |

Le modèle ne génère aucun texte : il compare la photo à un catalogue fermé de concepts et
d'attributs, encodé d'avance et livré dans l'image. Il propose, ou s'abstient ; il n'invente ni
catégorie ni marque, et ses scores ne sont jamais présentés comme une confiance.

## Installation automatique

À chaque démarrage, Vaultia vérifie le modèle **en arrière-plan** pendant que l'application
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

Contrôle l'intégrité du modèle, l'état de chaque moteur local, puis fait une **inférence réelle**
(une photo de canapé doit être reconnue). Dernière ligne : `Vaultia Vision: READY` (code 0) ou
`Vaultia Vision: NOT READY` (code 1). Plus léger : `curl http://127.0.0.1:3000/api/health` →
`"vision":"ready"`.

## Commandes

    docker compose exec vaultia vaultia models-verify      # intégrité seule, sans réseau
    docker compose exec vaultia vaultia models-provision   # installer ou réparer maintenant
    docker compose exec vaultia vaultia vision-status      # état complet et inférence

Installation manuelle seulement : `INTELLIGENCE_MODELS_PROVISION=off` dans `.env`, puis
`models-provision` quand vous le décidez.

## Hors ligne

Une fois le modèle installé, la vision fonctionne **sans Internet** (vérifié réseau coupé :
`Vaultia Vision: READY` et inférence réelle). Seul le premier téléchargement du modèle — ou son
remplacement s'il est effacé ou altéré — a besoin d'Internet. Pour un serveur sans aucun accès
Internet : installer le modèle sur une machine connectée (`models-provision` dans un volume), puis
copier le contenu du volume `vaultia_models`.

## Sauvegarde

Le modèle n'est **pas** sauvegardé par `scripts/backup.sh` : c'est un artefact retéléchargeable et
vérifié par empreinte, pas une donnée. Supprimer le volume `vaultia_models` ne fait perdre aucune
donnée.

## Licence du modèle

Le modèle de base `google/siglip2-base-patch16-224` est publié par Google sous **licence
Apache-2.0**. L'export ONNX quantifié (`onnx-community/siglip2-base-patch16-224-ONNX`) est une
conversion de ce modèle ; son dépôt ne déclare pas de licence propre. Vaultia **ne redistribue pas**
le modèle : votre instance le télécharge directement depuis sa source publique, à la révision
indiquée. ONNX Runtime (MIT), Tesseract et ses données de langue (Apache-2.0) et ZXing
(Apache-2.0 / MIT) sont dans l'image, avec leurs avis dans `/app/THIRD-PARTY-NOTICES.md`.
