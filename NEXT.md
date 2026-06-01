# proxmox-master — NEXT

Stand: 2026-06-01. Bei „weiter" hier ansetzen.

> **Session 2026-05-31/06-01:** Nur Housekeeping — Inbox-Brief von energy-master
> abgearbeitet (archiviert) + Koordinationsnotiz unten ergänzt. Keine
> halbfertige Arbeit offen. Einziger wartender Punkt = die Koordination direkt
> darunter (externer Trigger, nichts proaktiv zu tun).

## 📌 Offene Koordination (2026-05-31, von energy-master, Brief archiviert)

**pv-inverter-master will evtl. eine LXC auf dem Knausi-PVE (192.168.13.2)** für
den Hoymiles-WR einrichten — meldet sich bei mir, wenn er Container-Support (VMID,
IP, Specs) braucht. CT150 `energy-master-knausi` (192.168.13.145) bleibt unangetastet.
Falls ich am Knausi-PVE an Container/Netz was anfasse → energy-master vorwarnen.
Nebenbefund: Steuerpfad CT150 → Knausi-Venus (13.11) zeitweise instabil (MQTT/Modbus),
Hauptverdacht alte Venus-FW (wird eh resettet) — Auge auf der 13.x-Strecke behalten.

## ⏯️ Resume-Schnellblick (2026-05-30)

**Knausi-Track erledigt:** Auf dem **Knausi-PVE-Host** (192.168.13.2, via WG-VPN,
PVE 9.1.7, passwortloser SSH) eine neue LXC für die Wohnwagen-energy-master-Instanz
provisioniert:
- **CT 150 `energy-master-knausi`**, IP **192.168.13.145/24** (statisch, gw .1, DNS 1.1.1.1),
  Debian 13, **2 vCPU / 4 GiB / 20 GiB**, unprivileged, onboot=1, nesting=1.
- Stack (spiegelt Haus-LXC 145): **uv 0.11.17** (`/usr/local/bin`), **nginx 1.26.3**,
  **Node 22.22 + pnpm 10.34** (corepack), git/build-essential/rsync, Zeitzone **UTC**.
  energy-master ist **kein** Next.js → Python/FastAPI + Vite-static via nginx + SQLite
  (kein Postgres/Docker).
- **root-SSH:** Mac-Key `hulki@Hulki.local` autorisiert (alle Peers = selber Mac).
- **GitHub-Deploy-Key** ed25519 auf dem Container generiert, `~/.ssh/config` → github.com;
  Public an energy-master übergeben (muss als Repo-Deploy-Key in `meintechblog/energy-master`
  eingetragen werden).
- **App-Deploy macht energy-master selbst** (Lead). Architektur: eigene volle Instanz
  (kein plant_id=2), Master/Slave-Layer Haus↔Knausi. Logging → CT100 logging-master
  (192.168.13.10:8086, Bucket `knausi`). Knausi-Venus 192.168.13.11 (Modbus 502/MQTT 1883).

**CT147 `llm-hw` auf proxi1 provisioniert (2026-05-30):** LLM-HW-Management-Webapp
(aiohttp) für llm-master. Debian 13, **2C / 2 GiB / 12 GiB** (Storage `data`),
unprivileged, onboot, nesting=1, UTC. Stack: uv 0.11.17 + Python 3.13 + venv/pip,
git/build-essential/rsync. root-SSH (Mac-Key) + GitHub-Deploy-Key. App-Deploy macht
llm-master. **IP: 192.168.3.180 (DHCP)** — NICHT .147: dort sitzt ein IP-Squatter
(physisches Gerät, MAC `c4:5b:be:56:14:e6`), drum auf DHCP ausgewichen; unifi-master
pinnt .180 auf MAC `BC:24:11:98:5A:1E`. (Lehre: Pre-IP-Check vom PVE-Host ist
unzuverlässig — die Bridge beantwortet lokal; echte LAN-Freiheit nur vom Mac/DHCP
prüfen oder gleich DHCP+Reservation nehmen.)

**CT148 `loxone-master` auf proxi1 provisioniert (2026-05-31):** Loxone-Wissens-Webapp
+ pgvector/RAG für loxone-master. Debian 13, **2C / 4 GiB / 20 GiB** (Storage `data`),
unprivileged, onboot, nesting=1, UTC. Stack: **PostgreSQL 17.10 + pgvector 0.8.0**
(Extension verifiziert), **Node 22.22 + pnpm 10.34**, git/build-essential/sudo/rsync.
root-SSH (Mac-Key) + GitHub-Deploy-Key. App-Deploy macht loxone-master.
**IP: 192.168.3.163 (DHCP)**, MAC `BC:24:11:A2:88:F9` — unifi-master pinnt (Inbox-Brief,
war nachts offline). SSH vom Mac verifiziert. (Wieder DHCP+Pin statt statisch — siehe
.147-Lehre oben.)

**CT151 `stromnetz-master` auf proxi1 provisioniert (2026-05-31):** Regulatorische
PV/Speicher-Wissens-Webapp für den neuen Flotten-Peer stromnetz-master (Next.js +
PostgreSQL/pgvector Hybrid-Suche + FastAPI-Embedding-Service e5; Stack analog
venusos/loxone). Debian 13, **2C / 4 GiB / 2 GiB Swap / 20 GiB** (Storage `data`),
unprivileged, nesting=1, onboot, UTC. Stack: **PostgreSQL 17.10 + pgvector 0.8.0 +
pg_trgm 1.6** (beide Extensions in `template1` aktiviert → jede neue DB erbt sie),
**Node 22.22 + pnpm 11.5** (corepack), **Python 3.13.5** + venv (FastAPI-Embedding,
kein fairseq), **nginx 1.26.3** (Vhost 80→3000 macht der Peer). root-SSH (Mac-Key) +
GitHub-Deploy-Key (in `meintechblog/stromnetz-master` eintragen). App-Deploy macht
stromnetz-master. **IP: 192.168.3.188 (DHCP)**, MAC `BC:24:11:90:CB:E7` —
unifi-master pinnt. (RAM/Disk bewusst über Peer-Anfrage 2-3G/10G: torch ~2-3 GB
Disk → kein Resize nötig.)

**CT149 `rvc-train` auf proxi2 provisioniert (2026-05-31):** CPU-only RVC-Voice-
Cloning-Training für chat-llm-master (Jörgs Stimme; Mac-Tooling scheitert an
fairseq/Applio auf Apple Silicon). **Befund:** prox2 hat NUR Intel-Arc-iGPU, kein
NVIDIA/CUDA — ganze Proxmox-Flotte CUDA-frei verifiziert (alle Hosts Intel-iGPU).
Darum CPU-Training als gründlicher Übernacht-Weg, parallel zum lokalen 90%-Weg.
**Ubuntu 22.04** (bewusst, **Python 3.10.12** — Debian 13/Py3.13 bricht fairseq),
**10C / 20 GiB / 4 GiB Swap / 40 GiB** (local-lvm), unprivileged, nesting=1, onboot=1.
Vorinstalliert: build-essential, git, **ffmpeg 4.4**, libsndfile1, python3.10-venv,
pip, rsync. root-SSH (Mac-Key) verifiziert. **IP: 192.168.3.166 (DHCP)**, MAC
`BC:24:11:1F:BE:EA` — unifi-master pinnt. Stack-Aufbau + Monitoring macht
chat-llm-master (PyTorch CPU-Build, kein CUDA). **Temporär** — nach erfolgreichem
Training kann der CT weg.

**🔔 Heads-up (energy-master-Brief, 2026-05-31):** Knausi-Energiesystem wird neu
aufgebaut (Venus-Reset via venusos-master, Hoymiles-WR via pv-inverter-master,
STANDALONE-FIRST). **CT150 bleibt** (kein Neu-Provisioning). **pv-inverter-master**
könnte demnächst einen eigenen LXC auf dem Knausi-PVE (192.168.13.2) für den
Hoymiles-WR anfragen — dann VMID/IP/Specs wie üblich liefern (Muster CT150). Bei
Eingriffen am Knausi-PVE-Netz/Container energy-master vorwarnen (CT150 nicht
überraschen). Nebenbefund: CT150→Venus-13.11 MQTT/Modbus war zeitweise flaky
(Verdacht alte Venus-FW, wird resettet) — falls auf der 13.x-Strecke was auffällt, melden.

### 🟡 PENDING (wartet auf Jörgs Go): Frigate-LXC auf prox2 — CV-Detektions-Stack

Mit llm-master + ip-cam-master geplant + gelockt (2026-05-30), **noch NICHT angelegt**.
Bei Go in einem Rutsch provisionieren:
- **CT 2020 `frigate`** auf **prox2** (192.168.3.6, Intel Ultra 7 255H, 16C/46G, satt frei).
  VMID 2020 ist frei (Cam/Protect-Cluster geht bis 2014/protect-hub).
- **privileged**, **6C / 6 GiB / 32 GiB rootfs** (local-lvm), `features: nesting=1,keyctl=1`
  (Docker-in-LXC — Frigate 0.17 als offizieller Docker-Container).
- **Coral USB-TPU (2×):** `lxc.cgroup2.devices.allow: c 189:* rwm` (Major 189 verifiziert)
  + ganzes `/dev/bus/usb` binden (Re-Enum 1a6e→18d1 nach Init). **Vor dem Anlegen: Corals
  stecken → Vendor-ID/Bus verifizieren.** 2 Corals an getrennte USB-Controller.
- **VAAPI:** `/dev/dri` binden (`c 226:* rwm` + mount) — iGPU-HW-Decode für 12-14 Cams.
- **Storage:** detection-only → Recordings bleiben in UniFi Protect, **kein CIFS-Mount**.
  Nur Event-Clips/Snapshots/DB lokal (klein, passen in die 32G rootfs).
- IP: DHCP + MAC-Reservation (unifi-master pinnt, wie der Rest der Cam-Flotte).
- Kamera-FOV: Carport .121 Primär (rechtes Bilddrittel = VLM-ROI Mülltonnen). ip-cam-master
  liefert Cam-Requirements, llm-master das CV/VLM. **Mein Part = nur LXC provisionieren.**

---

## ⏯️ Resume-Schnellblick (2026-05-29)

Session idle, alles committet + gepusht, GitHub in sync. Heute fertig:
- **proxmox-master ist PUBLIC** (PII-Scan + History-Scrub), **backup-master
  vollständig aufgelöst** (Hub-Teardown bestätigt), curl-Onboarding tokenfrei live.
- **2 LXCs provisioniert:** CT 139 `ulanzi-master` (.161) + CT 144 `unifi-kb` (.155),
  beide mit Deploy-Key — Peers deployen die Apps selbst.
- **LAN-Hygiene:** .178- & .104-Konflikte gelöst, DHCP-Reservations live, VM 126 aus,
  prox2-CT123 → `tvheadend-master` umbenannt, proxi-CT123 Cold-Rollback entschärft+behalten.
- **Memory konsolidiert**, CLAUDE.md public-hygienisch getrimmt.

**Nichts dringend offen.** QNAP/PBS sind bewusst aus (kein Backup-Issue, Synology deckt ab).
Nächste sinnvolle Arbeit = der **Wartungs-Backlog (Phase 2+3 weiter unten)** sobald
Wartungsfenster (APT-Upgrade+Reboot, Snapshots, Machine-Type-Pin, Swap, LXC-discard).
Evtl. später: CT124 destroy (alter ulanzi-gateway, nach PBS-Backup), CT123-Rollback
in ~1-2 Wochen neu bewerten.

## Status offene Punkte (Stand 2026-05-29)

- ✅ **QNAP/PBS-Offline = absichtlich** (Jörg, 2026-05-29). QNAP `qi` (.219) +
  PBS-VM (.9) bewusst aus → PBS3-Zweig ruht, Synology-Backup deckt weiter ab.
  Kein Handlungsbedarf. **Merken:** solange QNAP aus → kein PBS-Backup möglich
  (relevant für CT124-destroy + CT123-Retire, die ein PBS-Backup vorsehen).
- ✅ **DHCP-Reservations LIVE** (unifi-master, 2026-05-29, Jörg-Go): .104/.145/
  .161/.178/.249 fest auf MAC gepinnt. Static-IP-im-Range-Zeitbomben-Klasse erledigt.
  (`.126 vibe-pi-x86` VM dauerhaft aus → war nicht mehr nötig.)
- ✅ **`.104`-Kollision entschärft + CT123-Entscheidung: BEHALTEN** (Jörg via
  tvheadend-master, 2026-05-29). proxi-CT123 ist ein bewusster Cold-Rollback
  (tvh-Migration 2026-05-25); Netz defused (neue MAC `BC:24:11:B1:1F:C2` + DHCP,
  onboot=0, alte net0 in Description), bleibt stopped als Netz — **in ~1-2 Wochen
  neu bewerten** (kein destroy, zumal PBS für Pre-Destroy-Backup eh aus).
  ⚠️ NB: Modal-Antwort sagte „retiren", spätere Jörg-Entscheidung via tvheadend-
  master sagte „behalten" — behalten gewinnt (neuer + sicherer).

## Session-Anker

- Cwd `~/codex/proxmox-master` ist seit 2026-05-28 **inhaltlich
  bestückt** (vorher leerer Anker). Enthält die konsolidierten
  Backup-Master-Inhalte: `docs/`, `installer/`, `secrets/`.
- Mission-Scope steht in `CLAUDE.md`, vollständige Übersicht in `README.md`.
- Volle State-of-the-World steht in Memory `project_proxi_maintenance_pending.md`
  (am 2026-05-27 frisch aktualisiert).

## Heute erledigt (2026-05-29)

- ✅ **2. LXC provisioniert: CT 144 `unifi-kb`** (Cross-Repo via unifi-master, für
  UniFi-Knowledge-Base). proxi, IP 192.168.3.155 (DHCP, MAC `BC:24:11:A8:8C:1B`),
  Debian 13, 4 Cores/6 GB/25 GB, nesting=1. Stack: PostgreSQL 17.10+pgvector,
  Node v22.22.2, Python 3.13.5+venv, nginx, build-essential. Mac-SSH verifiziert.
  App-Deploy (torch-venv, DB-Schema, vhost) macht unifi-master selbst. Deploy-Key
  angeboten sobald KB-Repo benannt.
- ✅ **Hostname prox2 CT 123 `tvheadend` → `tvheadend-master`** (Jörg via
  unifi-master). MAC-verifiziert, live ohne Reboot, Service unberührt; tvheadend-
  master informiert.
- ✅ **VM 126 vibe-pi-x86 dauerhaft aus** (onboot=0, Jörg via unifi-master).
- ✅ **IP-Konflikt .178 gelöst (Cross-Repo via unifi-master, Jörg-autorisiert):**
  CT 128 `netzgentgelte-de` (MAC ...ef:62:0a) hatte per DHCP `.178` gegriffen und
  stritt mit camping-master CT 178 (statisch .178). CT 128 dauerhaft gestoppt
  (`onboot=0`, kein destroy). `.178` löst jetzt sauber auf camping-master.
  + Static-IP-Audit (.100–250) an unifi-master geliefert (siehe DRINGEND-Block).
- ✅ **LXC für ulanzi-master/awtrix-master provisioniert** (Cross-Repo-Auftrag
  via Peer): **CT 139 `ulanzi-master`** auf proxi, IP 192.168.3.161 (DHCP, MAC
  `BC:24:11:C4:CA:07`), Debian 13, unprivileged, 2 vCPU/2 GB/8 GB, Node v22.22.2,
  passwortloser Mac-root-SSH verifiziert, Port-80-Bind getestet. Deploy-Ziel
  `/opt/ulanzi-master/` + Unit `ulanzi-master.service` (Haus-Konvention).
  - ✅ **Cutover vollzogen (2026-05-29):** Peer hat „cutover done" gegeben
    (Displays .134/.154 laufen verifiziert über .161). Alter Manager
    `.163` = CT 124 → Snapshot `pre_decom_20260529` (lokal, PBS war offline) →
    `onboot 0` → gestoppt → umbenannt `ulanzi-gateway-deprecated`. `.163` tot,
    `.161:80` live verifiziert. CT 124 löschen nach Bewährungszeit (~2026-06) +
    echtem PBS-Backup sobald QNAP wieder online.
  - **Offen:** .161 als feste IP via UDM-DHCP-Reservation pinnen (mit unifi-master/
    Jörg). Aktuell sticky DHCP.
- ✅ **Migration-Verifikation + backup-master endgültig aufgeräumt**
  - Alle backup-master-Files gegen proxmox-master gedifft → proxmox ist echtes
    Superset, **kein Inhalt verloren** (pbs-server.md / installer / CREDENTIALS
    byte-identisch; restore.md + backup-hosts.md nur Cross-Ref-Updates; README
    + .gitignore Superset).
  - **Lokalen Klon `~/codex/backup-master` gelöscht** (war clean, alle 4 Commits
    auf origin gepusht, keine Peer-Session aktiv → voll reversibel via GitHub).
  - **GitHub-Repo `meintechblog/backup-master` bewusst NICHT gelöscht** — es ist
    der einzige curl-Mirror für `onboard-pbs-host.sh`, und proxmox-master hat
    (noch) keinen eigenen Remote. Löschen würde Onboarding auf allen Hosts
    brechen. Bleibt read-only-Mirror bis GitHub-Strategie steht (siehe unten).
  - Verwaiste Memory-Dirs geprüft (`-codex-backup-master`,
    `-codex-proxmox-maintenance`): nur Session-Transkripte, **kein** `memory/`-
    Subdir → kein Wissen zu migrieren.
  - README: kaputten Memory-Pointer gefixt (Live-Wissen liegt im **globalen**
    `-Users-&lt;user&gt;/memory/`, nicht im Projekt-Memory).
- ✅ **GitHub-Remote angelegt: `meintechblog/proxmox-master` (PRIVATE)**
  - Secret-Scan vor Push: secrets/ untracked + gitignored, PBS-Passwort nirgends
    (auch nicht in History), keine persönlichen Emails/Tokens. Einziger Fund:
    TLS-Fingerprint im Installer — bewusst drin (kein Credential, curl-nötig,
    ohnehin im public Mirror).
  - `origin` gesetzt, `main` trackt, 5 Commits gepusht.
  - **Folge:** Da privat, kann die curl-URL NICHT auf proxmox-master umgebogen
    werden (raw braucht Token) → backup-master bleibt als **public Mirror** +
    der Skript-Mirror-Zwang bleibt bestehen. Registry-Eintrag bleibt (Sentinel).

## Erledigt (2026-05-28)

- ✅ **Migration backup-master → proxmox-master**
  - 1 README + 3 docs (`pbs-server.md`, `backup-hosts.md` (renamed von hosts.md),
    `restore.md`) + 1 installer (`onboard-pbs-host.sh`, exec-bit gesetzt)
    + 1 secret (`CREDENTIALS.md`, gitignored) übernommen.
  - `.gitignore` aus beiden Repos gemerged (secrets/, *.secret, *-credentials.*, .env*).
  - `CLAUDE.md` erweitert um PBS-Scope und Repo-Struktur.
  - `README.md` neu geschrieben (kombiniert Maintenance-Mission + Backup-Architektur).
  - cross-refs gefixt (`docs/restore.md`, `docs/backup-hosts.md` → neuer Pfad README).
  - Hardcoded curl-URL im Installer **bewusst unverändert** (Mirror-Strategie).
  - backup-master peer + agent-master Hub eingebunden, beide signed off.

## Heute erledigt (2026-05-27)

- ✅ Simmelbude-Backup verifiziert (CTs 100+200, Sun 02:30 in PBS3 ns `simmelbude`)
- ✅ Welle A Cleanup auf 9 running CTs (Journal-Vacuum + rotated logs)
- ✅ TRIM auf CT 108 + 110 → **~283 GB Pool-Rückgabe** an thin-pool `data`
- ✅ Welle B service-spezifisch:
  - CT 102 radarr: 280 MB (Backups älter 30d)
  - CT 109 tautulli: 92 MB (Auto-Backups auf last-5)
- ✅ qiPBS-Status final geklärt → Memory RESOLVED (Coverage komplett via PBS3 Sat 02:00 + synology Sun 04:00, 49/50 Guests doppelt)
- ✅ Memory mit echten Zahlen aktualisiert (qiPBS pingt wieder, Snapshot-Count, APT von 135 auf 192)

## Misslungen am 2026-05-27 (Lessons Learned)

- ❌ `pct set --rootfs ...,discard=on` ist VM-Syntax und wird von LXC abgelehnt. 5 CTs (102/103/104/109/1030) wurden stop/start ohne Nutzen. Korrekte LXC-Syntax wäre `mountoptions=discard` oder `lxc.cap.keep: sys_admin`.
- ❌ Beinahe-Katastrophe: VM 107 (nodered, running) wurde als orphan CT 107 fehlinterpretiert weil `pct status 107` Config-fehler warf — `pct` ist NUR für CTs. Bei IDs ohne klare Trennung IMMER `qm list` + `pct list` zusammen prüfen.

## Offene To-Dos (Phase 2+3)

Aus `project_proxi_maintenance_pending.md` — alle nicht akut, brauchen Wartungsfenster oder Rückfrage pro Item:

| # | Task | Aufwand | Status |
|---|---|---|---|
| 1 | APT-Upgrade (192 Pakete, Kernel inkl.) + Reboot | Wartungsfenster | offen |
| 2 | 5 alte Snapshots prüfen: 102 bulk, 109 pre-tautulli-fix-20260421, 111 before, 119 bulk, 1021 bulk | pro Snapshot fragen | offen |
| 3 | Machine-Type pinnen für VM 105/107/136/701/126 | 5 min | offen |
| 4 | `/root` Cleanup (~3 GB) inkl. `/root/tautulli-fix-*` in CT 109 (170 MB Debug-DBs) | User-Territory | offen |
| 5 | LXC discard-Fix für 102/103/104/109/1030 (FITRIM-Block) | 30 min | nicht akut |
| 6 | Swap-Strategie (vm.swappiness senken) | erst messen | offen |
| 7 | Win10 split_lock_detect | kosmetisch | offen |

## Aus dem übergeordneten Infra-Handoff

Aus `project_proxmox_infra_session_handoff.md`:
1. **Neuer Kumpel-LXC per VPN anbinden** — User hatte angekündigt, noch offen
2. ~~backup-master Repo public-Toggle besprechen~~ — **erledigt 2026-05-28**: alt-Repo
   bleibt public als Mirror (curl-URL-Stabilität), Inhalt ist jetzt hier.

## Offene Folge-Tasks aus der Migration

- [x] ~~Lokalen backup-master-Klon löschen~~ — **erledigt 2026-05-29**.
- [x] ~~GitHub-Strategie festlegen + Remote anlegen~~ — **erledigt 2026-05-29**:
  `meintechblog/proxmox-master` angelegt, gepusht.
- [x] ~~backup-master auflösen~~ — **erledigt 2026-05-29** (Jörg-Entscheidung:
  proxmox-master public). PII/Secret-Scan sauber → OS-Username aus `/Users/…`-
  Pfaden per filter-repo aus History gescrubbt (→`user`) → Repo **public** → curl-URL
  in README/docs/installer auf proxmox-master umgebogen → tokenfrei verifiziert.
  Kein Mirror-Zwang mehr. **Hub-Teardown bestätigt (2026-05-29):** backup-master
  GitHub-Repo ARCHIVIERT (reversibel, nicht gelöscht), Registry-Sentinel gezogen,
  Constraint-Memory gelöscht, neuer Pfad unabhängig gegengecheckt. backup-master
  ist Geschichte.
- ✅ **Source-of-Truth = allein proxmox-master.** Skript-Änderungen brauchen
  KEINEN Mirror-Push mehr (backup-master abgelöst).
- [x] ~~Hub/Orchestrierungs-Abschnitt aus public CLAUDE.md raus~~ — **erledigt
  2026-05-29** (Jörg: „mach's sauber"). CLAUDE.md ist jetzt strikt Proxmox/PBS-
  spezifisch; Fleet-Plumbing lebt nur im globalen `~/.claude/CLAUDE.md`. Kein
  History-Rewrite nötig (kein Secret/PII).
- [x] ~~Memory-Konsolidierung~~ — **erledigt 2026-05-29**: 6 globale
  `project_prox*`-Files bleiben **global** in `-Users-&lt;user&gt;/memory/` (Hosts sind
  cross-repo: energy-/wallbox-/venusos-master greifen drauf zu). Stale Pointer
  (backup-master-Lokalität, proxmox-maintenance-cwd) bereinigt; Bridge-Pointer
  ins Projekt-Memory ergänzt.

## Resume-Befehl

Beim Wiederaufnehmen einfach diese Datei lesen + bei Bedarf in
`project_proxi_maintenance_pending.md` und `project_proxmox_infra_session_handoff.md`
nachgucken.
