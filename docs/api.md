# API de Vaultia (v1)

Chaque instance Vaultia expose une API REST/JSON pour les scripts, la domotique (Home Assistant,
Node-RED, n8n) et vos outils. Elle est servie par **votre** instance : son adresse est celle de
votre Vaultia, suivie de `/api/v1`.

| Adresse (exemple : `https://vaultia.example`) | Rôle |
| --- | --- |
| `https://vaultia.example/api/v1` | base de l'API |
| `https://vaultia.example/api/docs` | **documentation interactive** : toutes les opérations, leurs paramètres et leurs réponses, et l'essai des requêtes avec un jeton |
| `https://vaultia.example/api/v1/openapi.json` | contrat OpenAPI 3.1, public, sans jeton |

**`/api/docs` est la référence complète et à jour** : elle affiche le contrat OpenAPI **généré
depuis le code de votre version**, route par route. Cette page n'en recopie pas la liste : elle
explique les règles communes. La documentation interactive est servie par l'instance elle-même,
sans CDN, sans police ni service externe ; elle fonctionne hors ligne, et le jeton qu'on y saisit
n'est jamais conservé (un rechargement l'efface).

Les **webhooks** (Vaultia prévient un système externe) sont décrits dans [webhooks.md](webhooks.md).

## 1. Créer un jeton

Dans Vaultia : **Réglages › Accès API** (propriétaire et administrateurs de l'Espace).

1. Nommez le jeton d'après l'outil qui l'utilisera.
2. Cochez les **portées** nécessaires, et seulement elles (§ 3).
3. Facultatif : une date d'expiration.
4. Copiez le jeton affiché : **il ne sera plus jamais affiché** (Vaultia n'en garde qu'une
   empreinte). Un jeton perdu se révoque et se recrée.

Un jeton a la forme `vlt_<préfixe>_<secret>`. Le préfixe `vlt_…` identifie le jeton dans les
Réglages ; le reste est secret. Ne le versionnez jamais, ne le mettez jamais dans une URL. La
révocation est immédiate : le jeton est refusé dès la requête suivante.

## 2. Authentification

Chaque requête porte le jeton dans l'en-tête standard `Authorization` :

```bash
export VAULTIA_URL="https://vaultia.example/api/v1"
export VAULTIA_TOKEN="vlt_<préfixe>_<secret>"   # votre jeton : jamais dans un dépôt ni une URL

curl -s "$VAULTIA_URL/token" -H "Authorization: Bearer $VAULTIA_TOKEN"
```

`GET /token` décrit le jeton présenté (jamais son secret) : nom, préfixe, **Espace**, portées
accordées et effectives, expiration. C'est le point de départ d'un client : il y lit
l'identifiant d'Espace (`workspaceId`) à placer dans les chemins.

L'API n'accepte **que** ce jeton : ni cookie de session, ni mot de passe.

## 3. Portées

Une portée est une famille de ressources × `read` / `write`, plus `destructive` :

| Famille | Contenu |
| --- | --- |
| `items` | objets, leurs identifiants (EAN, UPC, GTIN, n° de série…), leurs entretiens |
| `properties` | biens (propriétés) |
| `spaces` | espaces d'un bien (pièces, rangements) |
| `categories`, `tags`, `collections` | vocabulaire de l'Espace |
| `finance` | achats, dépenses, garanties d'objet, coûts d'un bien |
| `values` | valorisations d'objet, acquisition et valorisations d'un bien, instantanés de patrimoine |
| `works` | projets et interventions de travaux |
| `claims` | sinistres d'un bien |
| `documents` | fichiers des objets et des biens (envoi, liste, téléchargement) |
| `vehicles` | véhicules : fiche, acquisition, compteur, valeur, dépenses |
| `vault` | coffre de documents : documents de l'Espace et documents personnels **du créateur du jeton** |
| `destructive` | exigée **en plus** de l'écriture pour toute suppression |

Règles, toutes vérifiées par le serveur :

- une portée est un **plafond**, jamais une autorisation supplémentaire : chaque requête passe
  par les mêmes contrôles que l'interface (rôle, appartenance à l'Espace, règles métier) ;
- un jeton ne dépasse **jamais le rôle de son créateur**, relu à chaque requête : un créateur
  rétrogradé voit ses jetons bornés à son nouveau rôle ;
- portée absente : `403 API_SCOPE_MISSING` ; portée devenue excessive : `403 API_SCOPE_BEYOND_ROLE` ;
  rôle insuffisant pour une opération : `403 WORKSPACE_ROLE_FORBIDDEN`.

## 4. Espace (workspace)

Un jeton appartient à **un** Espace. Les chemins le nomment (`/workspaces/{workspaceId}/…`), et
ce doit être celui du jeton : tout autre Espace reçoit exactement la même réponse qu'un Espace
inexistant, **`404 NOT_FOUND`**. Il en va de même pour une ressource d'un autre Espace : `404`,
sans distinction avec une ressource absente. Pour plusieurs Espaces : un jeton par Espace.

Les documents **personnels** du coffre ne sont accessibles qu'au jeton de leur propriétaire,
jamais à celui d'un autre membre, quel que soit son rôle.

## 5. Conventions

- **JSON** : une ressource est rendue telle quelle ; une liste est toujours
  `{ "data": [...], "page": {...} }` ; une erreur est toujours `{ "error": {...}, "requestId": … }`.
  Un champ non renseigné vaut `null`.
- **Dates** : date métier `AAAA-MM-JJ` ; horodatage ISO 8601 en UTC.
- **Montants** : chaîne décimale (`"1249.90"`) toujours accompagnée de sa devise (`"EUR"`) ; un
  nombre JSON est refusé en entrée. Aucune réponse n'additionne deux devises.
- **Création** : `201` avec la ressource ; en-tête `Location` quand elle se relit à
  `<chemin>/<id>`. Suppression : `204` sans corps.
- **`PATCH`** : champ absent = inchangé ; `null` = effacé ; valeur = remplacée.
- **Champs inconnus** refusés (`422 INVALID_INPUT`) : une faute de frappe ne passe pas en silence.

## 6. Pagination

`?page=N` (1 à 500). La taille de page est **fixée par ressource** et annoncée dans la réponse
(`?limit=` est refusé) :

```text
{ "data": [ …20 objets… ], "page": { "number": 1, "size": 20, "total": 57, "pages": 3 } }
```

Page suivante tant que `page.number < page.pages`.

## 7. Erreurs et `X-Request-Id`

```json
{
  "error": { "code": "NOT_FOUND", "message": "Ressource introuvable." },
  "requestId": "00000000-0000-4000-8000-000000000000"
}
```

Le `code` est **stable** (c'est le contrat) ; le `message` peut évoluer. **Toute** réponse porte
l'en-tête `X-Request-Id` (le même que `requestId`) : citez-le pour un diagnostic dans les journaux
du serveur. Aucune erreur ne contient de trace ni de détail interne.

| Statut | Sens |
| --- | --- |
| 400 | requête mal formée (`INVALID_QUERY`, `MALFORMED_BODY`…) |
| 401 | jeton absent, invalide, révoqué ou expiré (`UNAUTHENTICATED`) |
| 403 | portée ou rôle insuffisant |
| 404 | ressource inexistante **ou** d'un autre Espace (indiscernables) |
| 405 | méthode non prévue (en-tête `Allow`) |
| 409 | conflit avec l'état actuel (règle métier, requête idempotente en cours) |
| 413 / 415 | corps ou fichier trop volumineux / type refusé |
| 422 | données invalides |
| 429 | limite de fréquence atteinte (en-tête `Retry-After`) |
| 500 / 503 | erreur interne / stockage indisponible (rien n'a été écrit) |

## 8. Limites de fréquence

| Borne | Valeur |
| --- | --- |
| requêtes par jeton | 300 par minute |
| écritures par jeton | 60 par minute |
| requêtes sans jeton valide, par adresse | 30 par minute |
| corps JSON | 256 Kio |
| fichier | `MEDIA_MAX_UPLOAD_BYTES` (10 Mo par défaut, [configuration.md](configuration.md)) |

Au-delà : `429 RATE_LIMITED` et `Retry-After`. Les compteurs sont en mémoire, par processus.

**Derrière un reverse proxy** : la limite par jeton ne dépend d'aucune adresse. La limite des
requêtes **sans jeton valide** utilise l'adresse du client, lue dans `X-Forwarded-For` **en
partant de la droite** : les adresses listées dans `TRUSTED_PROXIES` sont écartées, la première
restante est le client. Le premier élément de la chaîne, que le client écrit lui-même, n'est
jamais retenu ; sans `TRUSTED_PROXIES`, seul un en-tête à une seule valeur est lu. Déclarez donc
l'adresse de votre proxy dans `TRUSTED_PROXIES` ([reverse-proxy.md](reverse-proxy.md)).

## 9. Idempotence

Les créations qui l'indiquent dans `/api/docs` acceptent l'en-tête `Idempotency-Key` (1 à 255
caractères ASCII imprimables) : la même clé avec la même requête rejoue la première réponse sans
rien recréer (en-tête `Idempotent-Replayed: true`) ; avec une requête différente :
`422 IDEMPOTENCY_KEY_REUSED`. La clé est propre au jeton et vaut 24 heures. Les modifications et
suppressions, déjà idempotentes, la refusent.

## 10. Fichiers

Envoi en `multipart/form-data` (champ `file`), mêmes contrôles que l'interface : taille bornée,
contenu vérifié, stockage privé. Le téléchargement rend le fichier en pièce jointe, jamais un
chemin de stockage. Un fichier d'un autre Espace donne `404`.

## 11. Sécurité

- **HTTPS** recommandé ([reverse-proxy.md](reverse-proxy.md)) : en HTTP sur le réseau local, le
  jeton circule en clair sur ce réseau.
- **CORS** : aucun ; l'API vise des clients serveur, pas des sites tiers dans un navigateur.
- Toute réponse porte `Cache-Control: private, no-store`.
- Le secret d'un jeton n'est jamais journalisé ni stocké ; les corps de requête ne sont pas
  journalisés.
- Donnez à chaque outil **son** jeton, avec les seules portées utiles, et révoquez-le quand
  l'outil disparaît.

## 12. Exemple complet

Valeurs fictives : remplacez l'adresse et le jeton par les vôtres.

```bash
export VAULTIA_URL="https://vaultia.example/api/v1"
export VAULTIA_TOKEN="vlt_<préfixe>_<secret>"
AUTH=(-H "Authorization: Bearer $VAULTIA_TOKEN")

# Espace du jeton
WS=$(curl -s "$VAULTIA_URL/token" "${AUTH[@]}" | jq -r .workspaceId)

# Objets, page 2, triés par dernière modification
curl -s "$VAULTIA_URL/workspaces/$WS/items?page=2&sort=updated" "${AUTH[@]}"

# Retrouver un objet par son code-barres
curl -s "$VAULTIA_URL/workspaces/$WS/identifiers?value=4006381333931" "${AUTH[@]}"

# Créer un objet, rejouable sans doublon (identifiants de bien et d'espace lus dans l'API)
curl -s -X POST "$VAULTIA_URL/workspaces/$WS/items" "${AUTH[@]}" \
  -H "Content-Type: application/json" -H "Idempotency-Key: import-exemple-0001" \
  -d '{"propertyId":"<propertyId>","spaceId":"<spaceId>","name":"Perceuse sans fil","quantity":1,"condition":"GOOD"}'
```

## 13. Stabilité

Dans `/api/v1`, les évolutions sont **additives** (nouvelles ressources, nouveaux champs,
nouveaux paramètres facultatifs) : ignorez les champs que vous ne connaissez pas. Un changement
incompatible passera par `/api/v2`. Ce que la v1 n'expose pas (import, export, sauvegarde,
partages, membres, réglages, gestion des jetons…) reste réservé à l'interface.
