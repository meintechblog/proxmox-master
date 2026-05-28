# proxmox-master — NEXT

Stand: 2026-05-28 nachmittags. Bei „weiter" hier ansetzen.

## Session-Anker

- Cwd `/Users/user/codex/proxmox-master` ist seit 2026-05-28 **inhaltlich
  bestückt** (vorher leerer Anker). Enthält die konsolidierten
  Backup-Master-Inhalte: `docs/`, `installer/`, `secrets/`.
- Mission-Scope steht in `CLAUDE.md`, vollständige Übersicht in `README.md`.
- Volle State-of-the-World steht in Memory `project_proxi_maintenance_pending.md`
  (am 2026-05-27 frisch aktualisiert).

## Heute erledigt (2026-05-28)

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

- [ ] **GitHub-Strategie für proxmox-master festlegen** (Jörg-Decision):
  Neuer Remote `meintechblog/proxmox-master`? Privat oder public?
- [ ] **Wenn neuer Remote:** README/Skript-Mirror nach backup-master einrichten
  (oder umgekehrt: curl-URL umbiegen + Stub in altem Repo).
- [ ] **backup-master Repo archivieren** auf GitHub (`gh repo archive`),
  README dort als Redirect umschreiben.
- [ ] **Hub-Registry-Cleanup**: agent-master soll `backup-master` aus
  `data/registry.json` entfernen (Bitte raus an Hub geht, sobald oben durch).

## Resume-Befehl

Beim Wiederaufnehmen einfach diese Datei lesen + bei Bedarf in
`project_proxi_maintenance_pending.md` und `project_proxmox_infra_session_handoff.md`
nachgucken.
