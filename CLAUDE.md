# proxmox-master

## Mission

**Single-Point-of-Truth für die gesamte Proxmox-Infrastruktur** — sowohl die
Proxmox-VE-Hosts (proxi `192.168.3.2`, proxi3, proxmox-172, Knausi, Simmelbude,
…) als auch den zentralen **Proxmox Backup Server** (PBS, `192.168.3.9`,
Datastore PBS3).

Themen:
- Host-Wartung: APT/Kernel-Upgrades mit Wartungsfenstern, Snapshot-Hygiene,
  Storage-Cleanup (TRIM, Journals), Swap-Strategie.
- CT/VM-Lifecycle: Anlegen, Klonen, Restore, Inventar.
- **Backup-Infrastruktur**: zentraler PBS mit Namespaces pro Host,
  One-Liner-Onboarding-Skript, Restore-Prozeduren.
- Backup-Verifikation: PBS3 + Synology (Doppel-Coverage 49/50 Guests).
- Doku über alles was nicht in ein Service-Repo gehört.

Alles was früher in `backup-master` lag (siehe „Migration" unten) ist seit
2026-05-28 hier konsolidiert.

## Repo-Struktur

```
proxmox-master/
├── README.md                Übersicht + Onboarding-Quickstart
├── CLAUDE.md                Diese Datei
├── NEXT.md                  Aktueller Stand / Resume-Anker
├── docs/
│   ├── pbs-server.md        PBS-VM, Datastores, Namespaces, GC, Wartung
│   ├── backup-hosts.md      Status je Backup-Client-Host (Kumpel, Knausi, …)
│   └── restore.md           Wie man aus einem PBS-Backup wiederherstellt
├── installer/
│   └── onboard-pbs-host.sh  One-Line-Skript: PVE-Host an PBS anbinden
└── secrets/                 NICHT in Git (gitignored)
    └── CREDENTIALS.md       PBS-Passwort, TLS-Fingerprint, SSH-Targets
```

## Operator

Jörg. Identität, Email-Tabelle, WA-Kontakt: siehe globales `~/.claude/CLAUDE.md`.

## GitHub-Remote

Dieses Repo liegt auf **`github.com/meintechblog/proxmox-master` (PUBLIC)**
(angelegt 2026-05-29, public seit 2026-05-29 nach PII/Secret-Scan + History-
Scrub). `origin` ist gesetzt, `main` trackt. Push wie üblich.

**Public-Hygiene (WICHTIG):**
- **Niemals** Secrets/persönliche Daten committen — `secrets/` ist gitignored,
  PBS-Passwort & Co. bleiben ausschließlich lokal in `secrets/CREDENTIALS.md`.
- Kein Username/`/Users/<name>`-Pfad in Doku (History wurde 2026-05-29 vom
  OS-Username auf `user` gescrubbt). Bei neuen Pfaden generisch bleiben (`~/codex/…`).
- Interne RFC1918-IPs/Hostnamen sind bewusst dokumentiert (Infra-Doku, nicht
  von außen routbar) — kein Secret. Der TLS-Fingerprint im Installer ist kein
  Credential.

## Migration aus backup-master (2026-05-28 → 2026-05-29)

Das frühere Repo `backup-master` ist hierher konsolidiert (lokaler Klon
`~/codex/backup-master` am 2026-05-29 gelöscht). Da `proxmox-master` jetzt
**public** ist, lädt das curl-Onboarding das Skript **direkt von hier**
(`raw.githubusercontent.com/meintechblog/proxmox-master/main/installer/…`,
tokenfrei). Der frühere `backup-master`-Mirror ist damit **abgelöst** und wird
archiviert (Hub räumt Registry-Sentinel + Constraint-Memory ab).

**Source-of-Truth** für Skript + Doku ist allein **dieses Repo** — kein
Mirror-Push mehr nötig.
