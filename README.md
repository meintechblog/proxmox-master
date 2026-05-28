# proxmox-master

Single-Point-of-Truth für alles **Proxmox** im Setup von [@meintechblog](https://github.com/meintechblog):

- **Proxmox-VE-Hosts** (Haupt-Server proxi `192.168.3.2`, proxi3, plus die
  via WireGuard angebundenen Remote-Hosts: Kumpel `172.25.0.2`, Knausi
  `192.168.13.2`, Simmelbude `192.168.2.2`)
- **Proxmox Backup Server** (PBS, `192.168.3.9`, Datastore `PBS3`, 1,8 TB)
- Lifecycle, Wartung, Backups, Restore-Prozeduren

GitHub: **`meintechblog/proxmox-master` (private)**.

Konsolidiert aus dem früheren Repo
[`backup-master`](https://github.com/meintechblog/backup-master) (2026-05-28).
Der alte Remote bleibt als **public read-only-Mirror** erhalten, weil das
curl-Onboarding ihn braucht (privates Repo kann raw-curl nicht ohne Token
bedienen) — siehe „Hinweis zur curl-Install-URL" unten.

---

## Backup-Architektur

```
   Proxmox-Host A ─┐
   Proxmox-Host B ─┼──► PBS (192.168.3.9)  Datastore PBS3 (1,8 TB)
   Kumpel-Host C ──┘         ├── Namespace: proxmox-172   (Kumpel)
                             ├── Namespace: knausi        (Wohnwagen)
                             ├── Namespace: simmelbude    (proxi4)
                             └── Namespace: <pro Host einer>
```

**Der zentrale Punkt: PBS-Namespaces.**

PBS legt Backups unter `ct/<vmid>` bzw. `vm/<vmid>` ab — **nicht** nach Host
getrennt. Sichern zwei Hosts mit derselben VMID (z. B. beide haben `CT 100`) in
denselben Datastore **ohne Namespace**, landen ihre Snapshots in derselben
Backup-Gruppe und vermischen sich.

Deshalb: **jeder Host bekommt einen eigenen Namespace.** Damit ist jeder Host
sauber isoliert, Prune-Regeln greifen pro Host, Restores sind eindeutig.

Details und Wartung: [`docs/pbs-server.md`](docs/pbs-server.md).
Status je Client-Host: [`docs/backup-hosts.md`](docs/backup-hosts.md).
Restore-Prozeduren: [`docs/restore.md`](docs/restore.md).

---

## Backup: Neuen Host an den PBS anbinden

Das Skript [`installer/onboard-pbs-host.sh`](installer/onboard-pbs-host.sh)
erledigt alles: PBS-Erreichbarkeit prüfen → Namespace anlegen → PBS-Storage
einrichten → wiederkehrenden Backup-Job für **alle Gäste** anlegen.

**Standardprofil** (Defaults ohne weitere Parameter): wöchentlich Sonntag
`02:30`, alle Gäste, Modus `stop` (Gäste fahren beim Backup runter), die
letzten `4` Backups pro Gast vorhalten.

Direkt auf dem Proxmox-VE-Host (als root):

```bash
NAMESPACE=proxmox-xyz PBS_PASSWORD='DAS_PBS_PASSWORT' \
bash -c "$(curl -fsSL https://raw.githubusercontent.com/meintechblog/backup-master/main/installer/onboard-pbs-host.sh)"
```

`NAMESPACE` muss **eindeutig pro Host** sein (Konvention: `proxmox-<letztes
IP-Oktett>` oder ein Standort-Name wie `knausi`). Wird `PBS_PASSWORD` nicht
gesetzt, fragt das Skript interaktiv.

> **Hinweis zur curl-Install-URL.** Die curl-URL zeigt bewusst auf den
> **public** `backup-master`-Mirror. Grund: `proxmox-master` ist **private**,
> und `raw.githubusercontent.com` liefert private Repos nur mit Token aus — den
> wollen wir nicht im One-Liner. Source-of-Truth für Änderungen ist dieses Repo
> (`proxmox-master`); das Skript muss bei jeder Änderung nach backup-master
> **mirror-gepusht** werden (public lassen), sonst driften die curl-Hosts ab.
> Der Mirror kann erst weg, wenn proxmox-master public wird oder ein anderer
> tokenfreier Skript-Pfad existiert.

### Parameter

| ENV-Variable | Default | Bedeutung |
|---|---|---|
| `NAMESPACE` | – (**Pflicht**) | Eindeutiger PBS-Namespace für diesen Host |
| `PBS_HOST` | `192.168.3.9` | Adresse des Proxmox Backup Servers |
| `PBS_DATASTORE` | `PBS3` | Datastore auf dem PBS |
| `PBS_USER` | `root@pam` | PBS-Benutzer |
| `PBS_PASSWORD` | – | PBS-Passwort (sonst interaktive Abfrage) |
| `PBS_FINGERPRINT` | (hinterlegt) | TLS-Fingerprint des PBS |
| `STORAGE_NAME` | `=PBS_DATASTORE` | Name des Storage-Eintrags auf dem Host |
| `SCHEDULE` | `sun 02:30` | Wann das Backup läuft (Kalender-Event) |
| `MODE` | `stop` | `stop` = Gäste runterfahren / `snapshot` = ohne Downtime |
| `KEEP` | `4` | Anzahl behaltener Backups pro Gast (Standardprofil) |
| `RUN_TEST` | `0` | `1` = nach dem Setup ein Test-Backup |

### Backup-Modus

- **`stop`** (Default): Gast wird sauber heruntergefahren, gesichert, wieder
  gestartet. Kurze Downtime, dafür garantiert konsistente Backups.
- **`snapshot`**: kein Herunterfahren, keine Downtime — bei schreibintensiven
  Workloads minimal weniger konsistent.

Das Skript legt **niemals** einen zweiten Job an, wenn auf dem Storage schon
ein Backup-Job existiert.

---

## Angebundene Backup-Client-Hosts

| Host | Standort | PBS-Namespace | Schedule | Modus | Retention |
|---|---|---|---|---|---|
| `172.25.0.2` | Kumpel-Host (WG-VPN) | `proxmox-172` | `sun 02:30` | stop | keep-last=4 |
| `192.168.13.2` | Wohnwagen Knausi (WG-VPN) | `knausi` | `sun 02:30` | stop | keep-last=7 |
| `192.168.2.2` | Simmelbude (WG-VPN, proxi4) | `simmelbude` | `sun 02:30` | stop | keep-last=4 |

> Der Kumpel-Host hat zusätzlich einen täglichen Einzeljob für CT 112
> (claude-code), per Web-UI eingerichtet — siehe [`docs/backup-hosts.md`](docs/backup-hosts.md).

Zugangsdaten (PBS-Passwort, Fingerprint) liegen in `secrets/CREDENTIALS.md` —
dieser Ordner ist `.gitignore` und wird **nicht** nach GitHub gesynct.

---

## Wartung der Haupt-Hosts (proxi / proxi3)

Wartung-Backlog (APT-Upgrade, Snapshot-Cleanup, TRIM, Machine-Type-Pinning
für VMs, …) steht in [`NEXT.md`](NEXT.md).

**Wo das Live-Wissen liegt (Claude-Memory):**

| Pfad | Inhalt |
|---|---|
| `~/.claude/projects/-Users-user/memory/` (global, repo-agnostisch) | **Live-State-of-the-World**: Host-Inventar, offene Wartung, Powersave, Infra-Handoffs — global, weil auch energy-/wallbox-/venusos-Sessions auf dieselben Hosts zugreifen. |
| `~/.claude/projects/-Users-user-codex-proxmox-master/memory/` | proxmox-master-**session-spezifisch** (z. B. Sonnet-first-Feedback). |

Konkrete globale Files: `project_proxmox_hosts.md`,
`project_proxi_maintenance_pending.md`, `project_proxmox_powersave.md`,
`project_proxmox_infra_session_handoff.md`,
`project_proxmox_maintenance_next_handoff.md`, `project_proxmenux_proxi.md`.

---

## Repo-Struktur

```
proxmox-master/
├── README.md                Diese Datei
├── CLAUDE.md                Mission, Scope, Konventionen (für Claude-Sessions)
├── NEXT.md                  Aktueller Stand / Resume-Anker
├── docs/
│   ├── pbs-server.md        PBS selbst: Datastores, Namespaces, GC, Wartung
│   ├── backup-hosts.md      Status je Backup-Client-Host
│   └── restore.md           Wie man aus einem Backup wiederherstellt
├── installer/
│   └── onboard-pbs-host.sh  One-Line-Onboarding für einen PVE-Host
└── secrets/                 NICHT in Git
    └── CREDENTIALS.md
```
