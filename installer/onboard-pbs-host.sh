#!/usr/bin/env bash
#
# proxmox-master :: PBS-Onboarding fuer einen Proxmox-VE-Host
# ---------------------------------------------------------
# Bindet einen Proxmox-VE-Host an den zentralen Proxmox Backup Server an
# und legt einen wiederkehrenden Backup-Job fuer ALLE Gaeste an.
#
# Kernpunkt: Jeder Host bekommt einen EIGENEN PBS-Namespace. PBS legt
# Backups unter ct/<vmid> bzw. vm/<vmid> ab -- ohne Namespace wuerden
# sich Backups verschiedener Hosts mit gleicher VMID vermischen.
#
# Aufruf direkt auf dem Proxmox-VE-Host (als root):
#
#   NAMESPACE=proxmox-xyz PBS_PASSWORD='...' \
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/meintechblog/proxmox-master/main/installer/onboard-pbs-host.sh)"
#
# Wird PBS_PASSWORD nicht gesetzt, fragt das Skript interaktiv.
#
set -euo pipefail

# ------------------------------------------------------------------
# Konfiguration (per ENV ueberschreibbar)
# ------------------------------------------------------------------
PBS_HOST="${PBS_HOST:-192.168.3.9}"
PBS_PORT="${PBS_PORT:-8007}"
PBS_DATASTORE="${PBS_DATASTORE:-PBS3}"
PBS_USER="${PBS_USER:-root@pam}"
PBS_PASSWORD="${PBS_PASSWORD:-}"
PBS_FINGERPRINT="${PBS_FINGERPRINT:-da:02:c9:b1:fd:d7:8b:75:a7:8b:7e:aa:a0:5b:59:b0:00:dc:19:10:d5:7f:29:6a:87:02:a7:fc:fd:8f:39:bf}"

NAMESPACE="${NAMESPACE:-}"                 # PFLICHT: eindeutiger Name pro Host
STORAGE_NAME="${STORAGE_NAME:-$PBS_DATASTORE}"
SCHEDULE="${SCHEDULE:-sun 02:30}"          # Kalender-Event (wann das Backup laeuft)
MODE="${MODE:-stop}"                       # stop = Gaeste runterfahren | snapshot
KEEP="${KEEP:-4}"                          # wie viele Backups pro Gast behalten (Standardprofil)
RUN_TEST="${RUN_TEST:-0}"                  # 1 = nach dem Setup ein Test-Backup

log()  { echo -e "\033[1;36m[*]\033[0m $*"; }
ok()   { echo -e "\033[1;32m[+]\033[0m $*"; }
err()  { echo -e "\033[1;31m[!]\033[0m $*" >&2; }
die()  { err "$*"; exit 1; }

# ------------------------------------------------------------------
# Pre-flight
# ------------------------------------------------------------------
[ "$(id -u)" -eq 0 ]   || die "Bitte als root auf dem Proxmox-VE-Host ausfuehren."
command -v pct  >/dev/null || die "'pct' nicht gefunden - das hier ist kein Proxmox-VE-Host."
command -v pvesm >/dev/null || die "'pvesm' nicht gefunden - das hier ist kein Proxmox-VE-Host."

[ -n "$NAMESPACE" ] || die "NAMESPACE=... muss gesetzt sein (eindeutiger Name fuer diesen Host, z.B. proxmox-<ip-oktett> oder <standort>)."

if [ -z "$PBS_PASSWORD" ]; then
  read -rsp "PBS-Passwort fuer $PBS_USER: " PBS_PASSWORD; echo
  [ -n "$PBS_PASSWORD" ] || die "Kein Passwort eingegeben."
fi

# ------------------------------------------------------------------
# 1) PBS erreichbar?
# ------------------------------------------------------------------
log "Pruefe PBS-Erreichbarkeit ($PBS_HOST:$PBS_PORT) ..."
HTTP=$(curl -sk -o /dev/null -w '%{http_code}' --max-time 10 "https://$PBS_HOST:$PBS_PORT/" || echo "000")
[ "$HTTP" = "200" ] || die "PBS nicht erreichbar (HTTP $HTTP). Routing/VPN pruefen."
ok "PBS erreichbar."

# ------------------------------------------------------------------
# 2) proxmox-backup-client sicherstellen (fuer Namespace-Anlage)
# ------------------------------------------------------------------
if ! command -v proxmox-backup-client >/dev/null; then
  log "Installiere proxmox-backup-client ..."
  DEBIAN_FRONTEND=noninteractive apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq proxmox-backup-client >/dev/null \
    || die "Konnte proxmox-backup-client nicht installieren."
fi

# ------------------------------------------------------------------
# 3) Namespace im PBS-Datastore anlegen (idempotent)
# ------------------------------------------------------------------
export PBS_PASSWORD PBS_FINGERPRINT
REPO="${PBS_USER}@${PBS_HOST}:${PBS_DATASTORE}"

log "Stelle Namespace '$NAMESPACE' im Datastore '$PBS_DATASTORE' sicher ..."
if proxmox-backup-client namespace list --repository "$REPO" 2>/dev/null | grep -qw "$NAMESPACE"; then
  ok "Namespace '$NAMESPACE' existiert bereits."
else
  proxmox-backup-client namespace create "$NAMESPACE" --repository "$REPO" 2>/dev/null \
    || die "Namespace konnte nicht angelegt werden (Passwort/Fingerprint pruefen)."
  ok "Namespace '$NAMESPACE' angelegt."
fi

# ------------------------------------------------------------------
# 4) PBS-Storage auf diesem Host einrichten (idempotent)
# ------------------------------------------------------------------
if pvesm status -storage "$STORAGE_NAME" >/dev/null 2>&1; then
  log "Storage '$STORAGE_NAME' existiert - setze Namespace + Prune-Policy ..."
  pvesm set "$STORAGE_NAME" --namespace "$NAMESPACE" --prune-backups "keep-last=$KEEP"
else
  log "Lege Storage '$STORAGE_NAME' an ..."
  pvesm add pbs "$STORAGE_NAME" \
    --server "$PBS_HOST" --datastore "$PBS_DATASTORE" \
    --namespace "$NAMESPACE" \
    --username "$PBS_USER" --password "$PBS_PASSWORD" \
    --fingerprint "$PBS_FINGERPRINT" \
    --content backup --prune-backups "keep-last=$KEEP"
fi
sleep 2
pvesm status -storage "$STORAGE_NAME" | grep -q active \
  || die "Storage '$STORAGE_NAME' ist nicht 'active'."
ok "Storage '$STORAGE_NAME' aktiv (Namespace: $NAMESPACE)."

# ------------------------------------------------------------------
# 5) Backup-Job anlegen (alle Gaeste, wiederkehrend)
# ------------------------------------------------------------------
if grep -q "storage $STORAGE_NAME" /etc/pve/jobs.cfg 2>/dev/null; then
  ok "Es existiert bereits ein Backup-Job auf Storage '$STORAGE_NAME' - kein neuer angelegt."
  err "Falls noetig, den bestehenden Job in der PVE-Web-UI pruefen/anpassen."
else
  log "Lege Backup-Job an (Schedule: $SCHEDULE, Modus: $MODE, alle Gaeste) ..."
  pvesh create /cluster/backup \
    --schedule "$SCHEDULE" \
    --storage "$STORAGE_NAME" \
    --all 1 \
    --mode "$MODE" \
    --enabled 1 \
    --notes-template "{{guestname}}" \
    --comment "proxmox-master: alle Gaeste -> $PBS_DATASTORE/$NAMESPACE" >/dev/null
  ok "Backup-Job angelegt."
fi

# ------------------------------------------------------------------
# 6) Optionaler Test-Backup
# ------------------------------------------------------------------
if [ "$RUN_TEST" = "1" ]; then
  FIRST_CT=$(pct list | awk 'NR==2{print $1}')
  if [ -n "$FIRST_CT" ]; then
    log "Test-Backup von CT $FIRST_CT (Modus: $MODE) ..."
    vzdump "$FIRST_CT" --storage "$STORAGE_NAME" --mode "$MODE" --notes-template "{{guestname}}" \
      2>&1 | grep -E 'INFO: (Starting backup|Finished|Backup job)' || true
  fi
fi

# ------------------------------------------------------------------
# Fertig
# ------------------------------------------------------------------
echo
ok "Onboarding abgeschlossen."
echo "    Host:        $(hostname)"
echo "    PBS:         $PBS_HOST  Datastore: $PBS_DATASTORE  Namespace: $NAMESPACE"
echo "    Storage:     $STORAGE_NAME (prune: keep-last=$KEEP)"
echo "    Backup-Job:  $SCHEDULE, alle Gaeste, Modus '$MODE'"
echo
echo "    Backups erscheinen im PBS unter:  $PBS_DATASTORE / $NAMESPACE"
