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

## Hub-Anbindung

Diese Session ist Teil des claude-peers-Netzwerks (Hub = agent-master / „Hulki"
auf `localhost:7890`). Cross-Repo-Fragen gehen via
`mcp__claude-peers__send_message`, nicht via Repo-Wechsel.

## Migration aus backup-master (2026-05-28)

Das frühere Repo `backup-master` (github.com/meintechblog/backup-master, 4
Commits) ist hierher konsolidiert. Der alte GitHub-Remote bleibt als
read-only-Mirror bestehen, weil das Onboarding-Skript per
`curl raw.githubusercontent.com/meintechblog/backup-master/main/installer/…`
geladen wird und auf bestehenden Hosts dieser Pfad nicht stirbt.

Source-of-Truth für Änderungen am Skript / an der Doku ist ab jetzt
**dieses Repo**. Wenn das Installer-Skript geändert wird, muss es nach
backup-master mirror-gepusht werden, sonst driften die curl-Hosts ab.
