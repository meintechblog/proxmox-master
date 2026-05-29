# proxmox-master — NEXT

Stand: 2026-05-29. Bei „weiter" hier ansetzen.

## 🔴 DRINGEND offen (2026-05-29 entdeckt)

- **Zentraler PBS / QNAP offline.** proxi (.2) **und** Mac erreichen weder die
  PBS-VM `192.168.3.9:8007` noch den QNAP-Host `qi` `192.168.3.219` (ping +
  :8007 fail von beiden Seiten). → ganzer **QNAP TVS-1282 down**, PBS-VM mit ihm.
  **Folge:** PBS3-Backup-Zweig ist für ALLE Hosts (proxi/prox2/Knausi/Simmelbude)
  tot; Doppel-Coverage degradiert auf nur-Synology. Klären: QNAP absichtlich aus
  (Wartung) oder echter Ausfall? Letzte proxi-vzdump-Tasklogs: 23./24./25.05.

- ✅ **`.104`-Kollision entschärft (2026-05-29).** War CT 123 `tvheadend` auf
  proxi+prox2 mit identischer MAC `BC:24:11:1B:0A:49` + statisch `.104`. proxi-123
  ist ein **bewusster Cold-Rollback** (tvh-Migration 2026-05-25, per tvheadend-master
  bestätigt — NICHT destroyen ohne Jörg). Non-destruktiv defused: proxi-123 net0 →
  neue MAC `BC:24:11:B1:1F:C2` + DHCP (Bridge vmbr10gbit erhalten), onboot=0, alte
  net0 in CT-Description gesichert. Kein pct-Snapshot möglich (Bind-Mount mp0).
  prox2-123 (produktiv) unangetastet. **Offen (Jörg):** Rollback nach 4 Tagen clean
  überhaupt noch behalten oder CT 123 retiren? (tvheadend-master flaggt's dir.)
- **Statische IPs im DHCP-Range (.100–.250) → langfristig UDM-Reservationen:**
  .145 energy-master, .178 camping-master (proxi), .249 ip-cam-master, .104
  tvheadend (prox2), .126 vibe-pi-x86 (VM, proxi). Plus CT139 .161 (DHCP, sticky).
  unifi-master hat die Liste; Umstellung auf Reservationen ist sein Revier.

## Session-Anker

- Cwd `/Users/user/codex/proxmox-master` ist seit 2026-05-28 **inhaltlich
  bestückt** (vorher leerer Anker). Enthält die konsolidierten
  Backup-Master-Inhalte: `docs/`, `installer/`, `secrets/`.
- Mission-Scope steht in `CLAUDE.md`, vollständige Übersicht in `README.md`.
- Volle State-of-the-World steht in Memory `project_proxi_maintenance_pending.md`
  (am 2026-05-27 frisch aktualisiert).

## Heute erledigt (2026-05-29)

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
    `-Users-user/memory/`, nicht im Projekt-Memory).
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
  `meintechblog/proxmox-master` **private** angelegt, gepusht.
- [ ] **backup-master-Mirror bleibt — kein Cleanup möglich solange proxmox
  privat:** Die curl-URL kann nicht auf ein privates Repo zeigen (Token-Zwang).
  Also: Skript-Mirror-Pflicht bleibt, backup-master bleibt public, Registry-
  Eintrag bleibt Sentinel. **Erst wenn proxmox-master public wird** (oder ein
  tokenfreier Skript-Pfad existiert): curl umbiegen → backup-master archivieren
  → Registry-Eintrag raus.
- [ ] **Installer-Skript-Sync-Disziplin:** Jede Änderung an
  `installer/onboard-pbs-host.sh` muss nach backup-master mirror-gepusht werden,
  sonst driften curl-Hosts. (Aktuell beide byte-identisch.)
- [x] ~~Memory-Konsolidierung~~ — **erledigt 2026-05-29**: 6 globale
  `project_prox*`-Files bleiben **global** in `-Users-user/memory/` (Hosts sind
  cross-repo: energy-/wallbox-/venusos-master greifen drauf zu). Stale Pointer
  (backup-master-Lokalität, proxmox-maintenance-cwd) bereinigt; Bridge-Pointer
  ins Projekt-Memory ergänzt.

## Resume-Befehl

Beim Wiederaufnehmen einfach diese Datei lesen + bei Bedarf in
`project_proxi_maintenance_pending.md` und `project_proxmox_infra_session_handoff.md`
nachgucken.
