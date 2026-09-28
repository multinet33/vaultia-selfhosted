# Webhooks sortants

Les webhooks préviennent un système externe (Home Assistant, n8n, Node-RED, un script) quand un
**événement métier** se produit dans un Espace Vaultia.

```text
API v1   : extérieur → Vaultia   (lire, écrire)          docs/api.md
Webhook  : Vaultia → extérieur   (être prévenu)          cette page
```

Un envoi est **compact** : type d'événement, ressource concernée, quelques attributs. Il ne
contient ni montant, ni texte libre, ni donnée personnelle. Le modèle est toujours :

```text
événement (webhook signé)  →  resource.href  →  GET authentifié sur l'API v1 par le destinataire
```

`resource.href` est un **chemin relatif** de l'API de votre instance
(`/api/v1/workspaces/…/…`). Il ne contient **aucune authentification** : le destinataire relit la
ressource avec **son propre** jeton d'API, envoyé dans l'en-tête `Authorization`
([api.md](api.md)). Ne mettez jamais un jeton dans une URL.

Les webhooks ne sont pas des routes de l'API : ni `/api/docs` ni `openapi.json` ne les décrivent.

## Créer un webhook

**Réglages › Webhooks**, réservé au propriétaire et aux administrateurs de l'Espace.

1. Un **nom** (l'outil qui reçoit les envois), l'**adresse de destination** (`https://…` de
   préférence) et les **événements envoyés** — seulement ceux dont l'outil a besoin.
2. Copiez le **secret** affiché (`whsec_…`) : il n'est montré **qu'une fois** (création ou
   renouvellement), ensuite seuls ses 4 derniers caractères.
3. Bouton **« Tester »** : un envoi `webhook.test`, signé et livré exactement comme les autres.
4. La page du webhook montre l'historique des envois (statut, tentatives, dernier statut HTTP) et
   permet de relancer un envoi en échec, de désactiver, de renouveler le secret ou de supprimer.

Un Espace compte au plus 20 webhooks. Un webhook ne reçoit que les événements de son Espace.

## Événements

Liste fermée : un webhook choisit ses types dans cette liste (aucun caractère générique).

| Type | Ressource | `data` |
|---|---|---|
| `item.created` | `item` | — |
| `item.updated` | `item` | `changes` : aspects modifiés parmi `name`, `description`, `quantity`, `condition`, `values`, `location`, `container`, `category`, `identifiers`, `media`, `notes`, `purchase`, `possession`, `tags`, `history` |
| `item.deleted` | `item` | `propertyId` |
| `item.disposed` | `item` | `dispositionType` (vente, don, mise au rebut…) |
| `loan.started` | `loan` | `itemId`, `expectedReturnAt`, `quantity` |
| `loan.returned` | `loan` | `itemId` |
| `maintenance.created` | `maintenance` | `itemId`, `maintenanceType` |
| `warranty.created` | `warranty` | `itemId`, `endDate` |
| `valuation.created` | `valuation` | `itemId`, `valuationType` |
| `expense.created` | `expense` | `itemId` (dépense d'objet) ou `propertyId`, `workInterventionId`/`workProjectId` (travaux), `expenseType` |
| `property.created` / `.updated` / `.deleted` | `property` | — |
| `space.created` / `.updated` / `.deleted` | `space` | `propertyId` |
| `work.project.created` / `.updated` / `.deleted` | `work_project` | `propertyId` |
| `work.intervention.created` / `.updated` | `work_intervention` | `propertyId`, `status`, `nature` |
| `work.intervention.completed` | `work_intervention` | idem — émis quand une modification fait passer l'intervention à « terminée » |
| `work.intervention.deleted` | `work_intervention` | `propertyId` |
| `claim.created` / `.updated` | `claim` | `propertyId`, `status`, `claimType` |
| `claim.closed` | `claim` | idem — émis quand une modification clôt ou refuse le sinistre |
| `claim.deleted` | `claim` | `propertyId` |

- Une même modification produit le même événement qu'elle vienne de l'interface, de l'API ou
  d'une automatisation ; seul le champ `source` change.
- Une écriture qui ne change rien n'émet rien ; plusieurs changements d'un objet dans une même
  écriture forment **un** `item.updated`.
- Envois spéciaux, sans abonnement : `webhook.test` (bouton « Tester ») et `automation.triggered`
  (action « webhook » d'une automatisation).

## Enveloppe

`POST` à l'URL du webhook, `Content-Type: application/json` (valeurs d'exemple) :

```json
{
  "id": "0b0c5d0e-0000-4000-8000-000000000001",
  "type": "work.intervention.completed",
  "version": 1,
  "envelopeVersion": 1,
  "occurredAt": "2026-01-15T08:14:03.512Z",
  "workspaceId": "5f1e0000-0000-4000-8000-000000000002",
  "resource": {
    "type": "work_intervention",
    "id": "9a7c0000-0000-4000-8000-000000000003",
    "href": "/api/v1/workspaces/5f1e0000-0000-4000-8000-000000000002/work-interventions/9a7c0000-0000-4000-8000-000000000003"
  },
  "source": "app",
  "data": { "propertyId": "c21d0000-0000-4000-8000-000000000004", "status": "COMPLETED", "nature": "REPAIR" }
}
```

- `id` : identifiant de l'**événement**.
- `resource.href` : chemin de l'API v1 qui sert la ressource, ou `null` quand aucune route ne la
  sert directement. Pour un événement de suppression (`item.deleted`…), la ressource n'existe
  plus : sa relecture donne `404`.
- `source` : `app` (interface), `api`, `automation`, `system` ; jamais l'identité d'une personne.
- Ajouter un champ est compatible ; en retirer ou en changer le sens incrémente `envelopeVersion`.
- Les envois ne sont **pas ordonnés** (tentatives, parallélisme) : utilisez `occurredAt`, et
  relisez la ressource pour connaître son état courant.

## Signature (Standard Webhooks)

Vaultia suit la spécification ouverte [Standard Webhooks](https://www.standardwebhooks.com) : ses
bibliothèques officielles vérifient les envois sans code propre à Vaultia.

| En-tête | Contenu |
|---|---|
| `webhook-id` | identifiant de la **livraison**, stable d'une tentative à l'autre : dédoublonnez sur lui |
| `webhook-timestamp` | instant de la tentative, en secondes Unix |
| `webhook-signature` | `v1,<base64(HMAC-SHA256(clé, contenu signé))>` |
| `x-vaultia-event` | type de l'événement (commodité, non signé) |
| `user-agent` | `Vaultia-Webhooks/1` |

- **Clé HMAC** : décodage base64 de la partie du secret qui suit `whsec_`.
- **Contenu signé** : `` `${webhook-id}.${webhook-timestamp}.${corps brut}` `` — le corps exact
  reçu, avant tout analyseur JSON.
- **Anti-rejeu** : refusez un `webhook-timestamp` à plus de 5 minutes de votre horloge et gardez
  les `webhook-id` déjà traités.
- `webhook-signature` peut contenir plusieurs signatures séparées par des espaces : acceptez
  l'envoi si l'une d'elles correspond.

Vérification en Node.js, sans bibliothèque :

```js
import { createHmac, timingSafeEqual } from "node:crypto";

function verifyVaultia(secret, headers, rawBody, toleranceSeconds = 300) {
  const id = headers["webhook-id"];
  const timestamp = Number(headers["webhook-timestamp"]);
  if (!id || !Number.isInteger(timestamp) || Math.abs(Date.now() / 1000 - timestamp) > toleranceSeconds) {
    return false;
  }
  const key = Buffer.from(secret.slice("whsec_".length), "base64");
  const expected = Buffer.from(`v1,${createHmac("sha256", key).update(`${id}.${timestamp}.${rawBody}`).digest("base64")}`);
  return String(headers["webhook-signature"] ?? "")
    .split(" ")
    .some((candidate) => {
      const received = Buffer.from(candidate);
      return received.length === expected.length && timingSafeEqual(received, expected);
    });
}
```

Répondez **2xx rapidement** (moins de 10 s), puis traitez de votre côté.

## Tentatives, délais, redirections

| Réponse | Traitement |
|---|---|
| `2xx` | réussi |
| délai dépassé, erreur réseau ou DNS, erreur TLS, `5xx`, `408`, `425`, `429` | passager : nouvelle tentative |
| autres `4xx`, `3xx` non suivis, destination interdite, redirection refusée | permanent : échec immédiat |

- **7 tentatives au plus** ; délais après chaque échec : 30 s, 2 min, 10 min, 1 h, 4 h, 12 h
  (±10 %). Ensuite l'envoi est en échec définitif ; « Relancer l'envoi » en programme une de plus.
- Délai d'une tentative : **10 s**, redirections comprises. Redirections suivies : **3** au plus
  (`301 302 303 307 308`, renvoyées en `POST` avec le même corps et la même signature), jamais
  `https → http`. Le corps de la réponse n'est jamais lu ni conservé.
- Un webhook **désactivé** ne reçoit plus rien ; ses envois en attente échouent sans partir.
- L'historique des envois est conservé 30 jours ; supprimer un webhook supprime son historique.

## Sécurité réseau (SSRF)

Une URL de webhook est traitée comme une donnée hostile. À l'enregistrement, avant chaque envoi
et à chaque redirection :

- schémas `http` et `https` seulement ; aucun identifiant dans l'URL (`https://user:pass@…`) ;
- `localhost` et `*.localhost` refusés ;
- l'adresse est vérifiée **au moment de la connexion**, sur le résultat de l'unique résolution
  DNS (pas de *DNS rebinding*) ; si une seule des adresses annoncées est interdite, toute la
  destination l'est.

| Classe | Plages | Autorisée |
|---|---|---|
| interdite | boucle locale (`127.0.0.0/8`, `::1`), lien local et métadonnées du nuage (`169.254.0.0/16`, `fe80::/10`, `fd00:ec2::254`, `100.100.100.200`), multicast, diffusion, plages réservées ou de documentation | **jamais** |
| réseau local | `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `100.64.0.0/10` (CGNAT), `fc00::/7` (ULA) | seulement si l'administrateur du serveur l'autorise |
| publique | le reste | oui |

Les IPv6 qui embarquent une IPv4 (`::ffff:a.b.c.d`, NAT64, 6to4) sont classées d'après elle.

### Réseau local : `WEBHOOK_ALLOW_PRIVATE_NETWORKS`

Par défaut, **les destinations du réseau local sont refusées**. Pour joindre Home Assistant, n8n
ou Node-RED sur votre réseau local, l'administrateur du serveur l'autorise dans `.env` (ou dans les
variables de la pile Portainer), puis relance Vaultia :

```dotenv
WEBHOOK_ALLOW_PRIVATE_NETWORKS=true
```

- Tout administrateur d'un Espace de ce serveur peut alors viser une adresse du réseau local :
  n'activez ce réglage que si vous leur faites confiance.
- Restent **toujours interdits** : le serveur lui-même (`127.0.0.1`, `::1`, `localhost`), le lien
  local, les métadonnées du nuage, le multicast. Un service sur la **même machine** que Vaultia se
  joint par l'adresse réseau local de la machine, pas par `localhost`.
- L'écran Réglages › Webhooks indique si le serveur autorise le réseau local.

### Secret des webhooks : `WEBHOOK_SECRET_KEY`

Le serveur doit pouvoir relire le secret d'un webhook pour signer chaque envoi : il le stocke
**chiffré** (AES-256-GCM). La clé est `WEBHOOK_SECRET_KEY` (32 caractères au moins) si elle est
définie, sinon elle est dérivée de `BETTER_AUTH_SECRET`. Changer l'une ou l'autre rend les secrets
existants illisibles : les envois échouent (`SECRET_UNAVAILABLE`) jusqu'au renouvellement du secret
de chaque webhook. Le secret n'est jamais journalisé ni inclus dans une sauvegarde Vaultia
([configuration.md](configuration.md), [backup-restore.md](backup-restore.md)).

## Relire la ressource par l'API

1. Créez un jeton d'API (Réglages › Accès API) avec les seules portées de **lecture** utiles
   ([api.md](api.md)).
2. Créez le webhook et copiez son secret dans votre outil.
3. À réception : vérifiez la signature, répondez `2xx`, puis relisez
   `GET https://vaultia.example{resource.href}` avec l'en-tête
   `Authorization: Bearer <votre jeton>`.

Exemple n8n : nœud *Webhook* (méthode POST, corps brut), nœud *Code* qui vérifie la signature,
nœud *HTTP Request* vers l'origine de votre instance suivie de `resource.href`.

## Exemple Home Assistant

Une intervention de travaux passe à « terminée » : Home Assistant reçoit le webhook, relit
l'intervention par l'API de Vaultia et affiche une notification.

```text
webhook Vaultia  →  resource.href  →  rest_command  →  GET /api/v1/…  →  réponse utilisée
```

Valeurs d'exemple : `vaultia.example` est l'adresse de votre instance, le jeton est le vôtre.

Prérequis :

- un jeton d'API avec la seule portée **`works:read`** ;
- un webhook Vaultia abonné à `work.intervention.completed`, dont l'URL est celle du déclencheur
  Home Assistant : `http(s)://<home-assistant>/api/webhook/<identifiant>` ;
- si Home Assistant est sur votre réseau local : `WEBHOOK_ALLOW_PRIVATE_NETWORKS=true` (ci-dessus).

`secrets.yaml` de Home Assistant — le jeton reste là, jamais dans une URL :

```yaml
# Remplacez par votre jeton (forme vlt_<préfixe>_<secret>). Cette valeur n'est pas un jeton valide.
vaultia_authorization: "Bearer vlt_EXEMPLE_NON_VALIDE"
```

`configuration.yaml` — l'**origine de Vaultia est fixée ici** ; seul le chemin relatif
`resource.href` vient de l'envoi. L'authentification vient de l'en-tête `Authorization`
configuré côté Home Assistant, jamais de `resource.href` :

```yaml
rest_command:
  vaultia_get_resource:
    url: "https://vaultia.example{{ resource_href }}"
    method: GET
    headers:
      Authorization: !secret vaultia_authorization
      Accept: application/json
    content_type: "application/json"
    timeout: 10
```

Automatisation :

```yaml
alias: Vaultia — intervention terminée
triggers:
  - trigger: webhook
    webhook_id: "<identifiant long et aléatoire>"
    allowed_methods: [POST]
    local_only: true
conditions:
  # Le déclencheur webhook de Home Assistant ne vérifie pas la signature Standard Webhooks :
  # l'envoi n'est qu'une sonnette. Rien de son contenu n'est utilisé, sauf un chemin de l'API
  # de forme stricte, relu ensuite avec le jeton.
  - condition: template
    value_template: >
      {{ trigger.json is defined
         and trigger.json.type == 'work.intervention.completed'
         and (trigger.json.resource.href or '') is match('^/api/v1/workspaces/[0-9a-f-]{36}/work-interventions/[0-9a-f-]{36}$') }}
actions:
  - action: rest_command.vaultia_get_resource
    data:
      resource_href: "{{ trigger.json.resource.href }}"
    response_variable: vaultia
  - if:
      - condition: template
        value_template: "{{ vaultia.status == 200 }}"
    then:
      - action: persistent_notification.create
        data:
          title: Vaultia
          message: "Intervention terminée : {{ vaultia.content.title }}"
mode: queued
```

Pourquoi ces précautions :

- le déclencheur webhook de Home Assistant **ne vérifie pas la signature** : l'identifiant du
  webhook est le seul secret de son URL. Un envoi forgé ne peut au pire que provoquer une
  **relecture** d'un chemin de l'API, avec un jeton en lecture seule, borné à son Espace ;
- le chemin est **validé** (forme exacte : aucun `@`, `//` ni hôte possible) et **l'origine est
  fixe** : même un `resource.href` forgé ne peut pas faire envoyer le jeton ailleurs ;
- **rien de `data`** n'est affiché : ce qui est montré vient de l'API.

Pour une vérification de signature complète, placez un relais (n8n, Node-RED, petit script) qui
vérifie l'envoi (§ Signature) avant d'appeler Home Assistant.
