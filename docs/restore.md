# Wiederherstellen aus einem Backup

## Variante 1 — PVE-Web-UI (einfachster Weg)

1. Auf dem Proxmox-VE-Host die Web-UI öffnen
2. Storage `PBS3` → Reiter **Backups** wählen
3. Es werden nur die Backups des **eigenen Namespace** dieses Hosts angezeigt
4. Backup auswählen → **Restore** → Ziel-VMID wählen → starten

## Variante 2 — CLI auf dem PVE-Host

Backups auflisten:

```bash
pvesm list PBS3
```

Container wiederherstellen (Beispiel CT 107):

```bash
# in eine NEUE VMID restoren (z.B. 999), Originale nicht ueberschreiben:
pct restore 999 PBS3:backup/ct/107/<timestamp> --storage local-lvm
```

VM wiederherstellen:

```bash
qmrestore PBS3:backup/vm/100/<timestamp> 999 --storage local-lvm
```

Den genauen `<timestamp>` liefert `pvesm list PBS3`.

## Variante 3 — Einzelne Dateien aus einem Backup holen

Ohne den ganzen Container wiederherzustellen — direkt auf der PBS-VM:

```bash
ssh root@192.168.3.9 "export PBS_PASSWORD='<pw>' PBS_FINGERPRINT='<fp>'
  # Snapshot mounten / Dateien auflisten
  proxmox-backup-client catalog dump ct/107/<timestamp> \
    --ns <namespace> --repository 'root@pam@localhost:PBS3'"
```

## Wichtig bei der VMID-Wahl

Beim Restore immer prüfen, ob die Ziel-VMID auf dem Host frei ist
(`pct status <id>` / `qm status <id>`). Im Zweifel in eine freie VMID
restoren und erst nach Prüfung umbenennen — so wird kein laufender Gast
überschrieben.

## Welcher Namespace gehört zu welchem Host?

Siehe `backup-hosts.md`. Jeder Host sieht über seinen Storage-Eintrag nur seinen
eigenen Namespace — ein versehentlicher Restore aus dem Backup eines fremden
Hosts ist damit praktisch ausgeschlossen.
