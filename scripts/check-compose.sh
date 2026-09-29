#!/usr/bin/env bash
# Contrôle de structure des fichiers Compose de la distribution (CI : compose-check.yml).
#
#     ./scripts/check-compose.sh
#
# - HTTP (compose.yaml) : postgres + vaultia, Vaultia publié sur l'hôte ;
# - HTTPS en ligne de commande (compose.yaml + compose.https.yaml) : + caddy, Vaultia non publié ;
# - HTTPS Portainer (compose.portainer-https.yaml, fichier autonome) : IDENTIQUE à la fusion
#   ci-dessus, au montage du Caddyfile près (embarqué au lieu d'un chemin relatif), dont le contenu
#   doit être exactement celui de https.Caddyfile.
# Ne démarre rien : seulement `docker compose config`, avec des valeurs de test fictives.
set -euo pipefail

cd "$(dirname "$0")/.."
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# Valeurs fictives, lues à la place d'un éventuel .env local (jamais consulté ici).
cat > "$work/test.env" <<'EOF'
POSTGRES_PASSWORD=check-password
BETTER_AUTH_SECRET=check-secret-check-secret-check-secret
BETTER_AUTH_URL=https://vaultia.home.arpa
VAULTIA_DOMAIN=vaultia.home.arpa
VAULTIA_BIND_ADDRESS=192.168.1.100
TRUSTED_PROXIES=172.30.83.10
EOF

unset COMPOSE_FILE COMPOSE_PROJECT_NAME COMPOSE_PROFILES VAULTIA_IMAGE CADDY_HTTPS_PORT CADDY_IPV4_ADDRESS VAULTIA_SUBNET VAULTIA_PORT
render() { # render <sortie> <options de docker compose…>
  local out="$1"; shift
  docker compose --env-file "$work/test.env" "$@" config --format json > "$work/$out.json"
}

render http -f compose.yaml
render cli-https -f compose.yaml -f compose.https.yaml
render portainer-https -f compose.portainer-https.yaml
# Ce que fait Portainer : -f <Compose path>, --env-file stack.env, --project-name <pile>.
cp "$work/test.env" "$work/stack.env"
echo "COMPOSE_FILE=compose.yaml:compose.https.yaml" >> "$work/stack.env"
docker compose -f compose.yaml --env-file "$work/stack.env" --project-name vaultia config --format json > "$work/portainer-compose-file.json"
docker compose -f compose.portainer-https.yaml --env-file "$work/stack.env" --project-name vaultia config --format json > "$work/portainer-stack.json"
# Recherche Web (profil web-search, docs/web-product-search.md), activé comme le ferait une variable
# de pile Portainer : COMPOSE_PROFILES dans le fichier d'environnement.
cp "$work/test.env" "$work/web.env"
echo "COMPOSE_PROFILES=web-search" >> "$work/web.env"
docker compose -f compose.yaml --env-file "$work/web.env" config --format json > "$work/http-web.json"
docker compose -f compose.yaml -f compose.https.yaml --env-file "$work/web.env" config --format json > "$work/cli-web.json"
docker compose -f compose.portainer-https.yaml --env-file "$work/web.env" --project-name vaultia config --format json > "$work/portainer-web.json"
# Autre port HTTPS et image mobile : seules les valeurs attendues changent.
CADDY_HTTPS_PORT=8443 VAULTIA_IMAGE=ghcr.io/multinet33/vaultia:rc render portainer-8443 -f compose.portainer-https.yaml

python3 - "$work" <<'PY'
import copy, json, sys

work = sys.argv[1]
load = lambda name: json.load(open(f"{work}/{name}.json"))
http, cli, portainer = load("http"), load("cli-https"), load("portainer-https")
failures = []

def check(condition, message):
    if not condition:
        failures.append(message)

def services(config):
    return set(config["services"])

def ports(config, service):
    return config["services"][service].get("ports") or []

check(services(http) == {"postgres", "vaultia"}, f"HTTP : services {sorted(services(http))}")
check(services(cli) == {"postgres", "vaultia", "caddy"}, f"HTTPS CLI : services {sorted(services(cli))}")
check(services(portainer) == {"postgres", "vaultia", "caddy"}, f"HTTPS Portainer : services {sorted(services(portainer))}")

http_ports = ports(http, "vaultia")
check(len(http_ports) == 1 and http_ports[0]["target"] == 3000, f"HTTP : Vaultia doit publier le port 3000, trouvé {http_ports}")
for label, config in (("HTTPS CLI", cli), ("HTTPS Portainer", portainer)):
    check(ports(config, "vaultia") == [], f"{label} : Vaultia ne doit publier aucun port, trouvé {ports(config, 'vaultia')}")
    check(not ports(config, "postgres"), f"{label} : PostgreSQL ne doit publier aucun port")
    caddy = config["services"]["caddy"]
    caddy_ports = ports(config, "caddy")
    check([(p["target"], p["published"], p.get("host_ip")) for p in caddy_ports] == [(443, "443", "192.168.1.100")],
          f"{label} : Caddy doit publier seulement 443 sur VAULTIA_BIND_ADDRESS, trouvé {caddy_ports}")
    check(caddy["image"] == "caddy:2-alpine", f"{label} : image Caddy {caddy['image']}")
    check(caddy["networks"]["vaultia"].get("ipv4_address") == "172.30.83.10", f"{label} : adresse fixe de Caddy")
    check(caddy["depends_on"]["vaultia"]["condition"] == "service_healthy", f"{label} : Caddy doit attendre Vaultia sain")
    check(config["services"]["vaultia"]["environment"].get("TRUSTED_PROXIES") == "172.30.83.10", f"{label} : TRUSTED_PROXIES transmis tel quel")
    check(set(config["volumes"]) == {"postgres-data", "media", "models", "caddy-data", "caddy-config"}, f"{label} : volumes {sorted(config['volumes'])}")
    for service in ("postgres", "caddy"):
        labels = config["services"][service].get("labels") or {}
        check(not any(k.startswith("com.centurylinklabs.watchtower") for k in labels), f"{label} : {service} ne doit pas être étiqueté pour Watchtower")

# Noms réels des volumes métier : identiques dans les trois modes (réutilisation des données).
for label, config in (("HTTP", http), ("HTTPS CLI", cli), ("HTTPS Portainer", portainer), ("pile Portainer", load("portainer-stack"))):
    names = {k: v.get("name") for k, v in config["volumes"].items()}
    for volume in ("postgres-data", "media", "models"):
        check(names.get(volume) == f"vaultia_{volume}", f"{label} : volume {volume} nommé {names.get(volume)}")
    check(config["name"] == "vaultia", f"{label} : projet {config['name']}")

labels = portainer["services"]["vaultia"].get("labels") or {}
check(labels.get("com.centurylinklabs.watchtower.enable") == "true" and labels.get("com.centurylinklabs.watchtower.scope") == "vaultia",
      f"HTTPS Portainer : étiquettes Watchtower de Vaultia {labels}")
check(":latest" not in portainer["services"]["vaultia"]["image"], "HTTPS Portainer : image latest")

# Recherche Web : aucun service ni variable active sans le profil ; avec lui, SearXNG interne seulement.
for label, config in (("HTTP", http), ("HTTPS CLI", cli), ("HTTPS Portainer", portainer)):
    check("searxng" not in config["services"], f"{label} : SearXNG ne doit pas démarrer sans le profil web-search")
    env = config["services"]["vaultia"]["environment"]
    for name in ("WEB_PRODUCT_SEARCH_BACKEND", "WEB_PRODUCT_SEARCH_URL", "WEB_PRODUCT_SEARCH_API_KEY"):
        check(env.get(name) == "", f"{label} : {name} doit être transmis, vide par défaut (trouvé {env.get(name)!r})")
    check("web-product-search" not in env.get("INTELLIGENCE_PROVIDERS", ""), f"{label} : web-product-search ne doit pas être installé par défaut")
web = {"HTTP web": load("http-web"), "HTTPS CLI web": load("cli-web"), "HTTPS Portainer web": load("portainer-web")}
for label, config in web.items():
    check("searxng" in config["services"], f"{label} : SearXNG absent avec le profil web-search")
    if "searxng" not in config["services"]:
        continue
    searx = config["services"]["searxng"]
    check("@sha256:" in searx["image"] and searx["image"].startswith("searxng/searxng:"), f"{label} : image SearXNG non figée {searx['image']}")
    check(not searx.get("ports"), f"{label} : SearXNG ne doit publier aucun port")
    check(searx["networks"]["vaultia"].get("ipv4_address") == "172.30.83.11", f"{label} : adresse fixe de SearXNG")
    check(searx["environment"].get("SEARXNG_SECRET") == "", f"{label} : SEARXNG_SECRET vide par défaut (jamais dans Git)")
    check(any(v["target"] == "/var/cache/searxng" and v["source"] == "searxng-cache" for v in searx["volumes"]), f"{label} : volume du cache SearXNG")
    check(searx.get("configs") == [{"source": "searxng-settings", "target": "/etc/searxng/settings.yml"}], f"{label} : réglages SearXNG non montés")
    settings = config["configs"]["searxng-settings"]["content"]
    check("- json" in settings and "limiter: false" in settings, f"{label} : réglages SearXNG sans API JSON")
    labels = searx.get("labels") or {}
    check(not any(k.startswith("com.centurylinklabs.watchtower") for k in labels), f"{label} : SearXNG ne doit pas être étiqueté pour Watchtower")
check(web["HTTPS CLI web"]["configs"]["searxng-settings"] == web["HTTPS Portainer web"]["configs"]["searxng-settings"], "DÉRIVE : réglages SearXNG CLI ≠ Portainer")

# Anti-dérive : le fichier Portainer doit être la fusion CLI, au Caddyfile près.
def normalize(config, embedded):
    config = copy.deepcopy(config)
    caddy = config["services"]["caddy"]
    config.pop("configs", None)
    if embedded:
        check(caddy.pop("configs", None) == [{"source": "caddyfile", "target": "/etc/caddy/Caddyfile"}], "HTTPS Portainer : Caddyfile embarqué non monté sur /etc/caddy/Caddyfile")
    else:
        mounts = [v for v in caddy["volumes"] if v["target"] == "/etc/caddy/Caddyfile"]
        check(len(mounts) == 1 and mounts[0]["source"].endswith("/https.Caddyfile") and mounts[0].get("read_only"), f"HTTPS CLI : montage du Caddyfile {mounts}")
        caddy["volumes"] = [v for v in caddy["volumes"] if v["target"] != "/etc/caddy/Caddyfile"]
    return config

def diff(a, b, path=""):
    if isinstance(a, dict) and isinstance(b, dict):
        for key in sorted(set(a) | set(b)):
            yield from diff(a.get(key), b.get(key), f"{path}.{key}")
    elif a != b:
        yield f"{path or '.'} : {json.dumps(a, ensure_ascii=False)} ≠ {json.dumps(b, ensure_ascii=False)}"

drift = list(diff(normalize(cli, False), normalize(portainer, True))) + list(diff(normalize(web["HTTPS CLI web"], False), normalize(web["HTTPS Portainer web"], True)))
for line in drift:
    failures.append(f"DÉRIVE compose.portainer-https.yaml ≠ compose.yaml + compose.https.yaml : {line}")

caddyfile = open("https.Caddyfile", encoding="utf-8").read()
embedded = portainer["configs"]["caddyfile"]["content"].replace("$$", "$")
check(embedded == caddyfile, "DÉRIVE : le Caddyfile embarqué dans compose.portainer-https.yaml diffère de https.Caddyfile")

# Portainer : COMPOSE_FILE dans les variables de pile est sans effet (cause du problème), le fichier
# autonome donne la composition complète.
check(services(load("portainer-compose-file")) == {"postgres", "vaultia"}, "reproduction Portainer : -f compose.yaml devrait ignorer COMPOSE_FILE")
check(services(load("portainer-stack")) == {"postgres", "vaultia", "caddy"}, "pile Portainer HTTPS : services")

alt = load("portainer-8443")
check([p["published"] for p in ports(alt, "caddy")] == ["8443"], "CADDY_HTTPS_PORT=8443 non appliqué")
check(alt["services"]["vaultia"]["image"] == "ghcr.io/multinet33/vaultia:rc", "VAULTIA_IMAGE non appliqué")

if failures:
    print("[check-compose] ÉCHEC :")
    for failure in failures:
        print(f"  - {failure}")
    sys.exit(1)
print("[check-compose] OK : HTTP, HTTPS CLI et HTTPS Portainer cohérents, avec et sans recherche Web ; aucune dérive.")
PY
