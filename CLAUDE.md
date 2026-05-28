# proxmox-master

## Mission

Wartung, Lifecycle und Doku der Proxmox-Hosts (proxi 192.168.3.2, proxi3, proxmox-172). CT/VM-Management, Backup-Verifikation gegen PBS3 + synology, APT/Kernel-Upgrades mit Wartungsfenstern, Snapshot-Hygiene, Storage-Cleanup (TRIM, Journals). Single-Point-of-Truth für alles was nicht in ein Service-Repo gehört.

## Status

Frisch angelegt via agent-master Hub. Noch keine Implementierung — der erste Job vom Operator definiert die Richtung.

## Operator

Jörg. Identität, Email-Tabelle, WA-Kontakt: siehe globales `~/.claude/CLAUDE.md`.

## Hub-Anbindung

Diese Session ist Teil des claude-peers-Netzwerks (Hub = agent-master / "Hulki" auf `localhost:7890`). Cross-Repo-Fragen gehen via `mcp__claude-peers__send_message`, nicht via Repo-Wechsel.
