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

## GitHub-Remote

Dieses Repo liegt auf **`github.com/meintechblog/proxmox-master` (PRIVATE)**
(angelegt 2026-05-29). `origin` ist gesetzt, `main` trackt. Push wie üblich.

**Niemals** Secrets/persönliche Daten committen — `secrets/` ist gitignored,
PBS-Passwort & Co. bleiben ausschließlich lokal in `secrets/CREDENTIALS.md`.
Der TLS-Fingerprint im Installer ist bewusst drin (kein Credential, nötig für
curl-Onboarding, ohnehin im public Mirror).

## Migration aus backup-master (2026-05-28 → 2026-05-29)

Das frühere Repo `backup-master` ist hierher konsolidiert; der lokale Klon
`~/codex/backup-master` wurde am 2026-05-29 gelöscht.

**Warum der backup-master-GitHub-Mirror trotzdem bleiben MUSS:** Das
Onboarding-Skript wird per
`curl raw.githubusercontent.com/meintechblog/backup-master/main/installer/…`
geladen — also **ohne Token**. Das geht nur bei einem **public** Repo.
`proxmox-master` ist **private**, kann die raw-curl-URL also nicht bedienen.
Deshalb:

- **Source-of-Truth** für Skript + Doku ist ab jetzt **dieses Repo**.
- Das Installer-Skript muss bei jeder Änderung nach backup-master
  **mirror-gepusht** werden (public bleiben lassen), sonst driften die
  curl-Hosts ab.
- Der Mirror kann erst sterben, wenn entweder proxmox-master public wird ODER
  ein anderer tokenfreier Hosting-Pfad fürs Skript existiert.
