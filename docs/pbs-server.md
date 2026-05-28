# Der Proxmox Backup Server

## Überblick

| Feld | Wert |
|---|---|
| PBS-Adresse | `192.168.3.9:8007` |
| Läuft als | VM "pbs" auf QNAP TVS-1282 (Virtualization Station) |
| PBS Web-UI | `https://192.168.3.9:8007/` |
| QNAP NAS Web-UI | `http://192.168.3.219:8080/` (Hostname `qi` / `qi.local`) |
| Benutzer | `root@pam` |
| SSH zur PBS-VM | `ssh root@192.168.3.9` (verfügbar) |
| SSH zum QNAP-NAS | deaktiviert |

Passwort und TLS-Fingerprint stehen in `../secrets/CREDENTIALS.md`.

## Datastores

| Name | NFS-Quelle | Größe | Zweck |
|---|---|---|---|
| `qiPBS` | `qi.local:/PBS` | 448 GB | älterer Datastore |
| `PBS3` | `qi.local:/PBS3` | 1,8 TB | aktueller Haupt-Datastore — hier laufen die Host-Backups |

Beide: `gc-schedule daily`, `verify-new true`.

## Namespaces

PBS legt Backups als `ct/<vmid>` / `vm/<vmid>` ab — ohne Namespace würden sich
Backups verschiedener Hosts mit gleicher VMID vermischen. Daher: **ein
Namespace pro Host**.

Namespaces verwaltet man mit `proxmox-backup-client` (das
`proxmox-backup-manager`-CLI hat **kein** `namespace`-Subcommand):

```bash
ssh root@192.168.3.9 "export PBS_PASSWORD='<pw>' \
  PBS_FINGERPRINT='<fingerprint>'
  # auflisten
  proxmox-backup-client namespace list   --repository 'root@pam@localhost:PBS3'
  # anlegen
  proxmox-backup-client namespace create <NAME> --repository 'root@pam@localhost:PBS3'"
```

Das Onboarding-Skript legt den Namespace automatisch an.

## Snapshots eines Namespace ansehen / löschen

```bash
ssh root@192.168.3.9 "export PBS_PASSWORD='<pw>' PBS_FINGERPRINT='<fp>'
  proxmox-backup-client snapshot list --ns <NAME> --repository 'root@pam@localhost:PBS3'
  proxmox-backup-client snapshot forget ct/<vmid>/<timestamp> --ns <NAME> \
    --repository 'root@pam@localhost:PBS3'"
```

## Garbage Collection / Speicher freigeben

Gelöschte Snapshots geben erst nach der Garbage Collection echten Platz frei:

```bash
ssh root@192.168.3.9 'proxmox-backup-manager garbage-collection start PBS3'
```

Läuft ohnehin täglich automatisch (`gc-schedule daily`).
