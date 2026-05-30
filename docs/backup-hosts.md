# Angebundene Hosts

Status je Proxmox-VE-Host, der auf den zentralen PBS sichert.

---

## Kumpel-Host — `172.25.0.2`

| Feld | Wert |
|---|---|
| Standort | Kumpel, erreichbar über WireGuard-Tunnel `wgsrv6` |
| PVE-Version | 9.0.3 |
| PBS-Namespace | `proxmox-172` |
| Storage-Eintrag | `PBS3` |
| Angebunden am | 2026-05-21 |

**Backup-Jobs:**

| Job | Schedule | Umfang | Modus | Retention |
|---|---|---|---|---|
| Wochen-Job | `sun 02:30` | alle Gäste **außer CT 112** | stop | keep-last=4 |
| CT-112-Job | täglich `21:00` | nur CT 112 (claude-code) | stop | keep-last=14 |

Der CT-112-Einzeljob wurde per PVE-Web-UI eingerichtet (claude-code wird
intensiv genutzt → häufiger sichern, längere Historie). Der Wochen-Job schließt
CT 112 deshalb aus.

Gäste gesamt: CT 101, 103, 105, 107, 110, 111, 112, 200 · VM 100, 104.

---

## Simmelbude — `192.168.2.2` (proxi4)

| Feld | Wert |
|---|---|
| Standort | Simmelbude, über WireGuard-VPN (wgsrv3) |
| PVE-Version | 9.1.6 |
| PBS-Namespace | `simmelbude` |
| Storage-Eintrag | `PBS3` |
| Angebunden am | 2026-05-24 |

**Backup-Job (Standardprofil):**

| Job | Schedule | Umfang | Modus | Retention |
|---|---|---|---|---|
| Wochen-Job | `sun 02:30` | alle Gäste | stop | keep-last=4 |

Gäste: CT 100 (charging-master), CT 200 (mqtt-master). Beide werden sonntags
kurz heruntergefahren — falls das für `charging-master` während aktiver
Ladevorgänge problematisch wird, Schedule oder Mode anpassen.

---

## Wohnwagen Knausi — `192.168.13.2`

| Feld | Wert |
|---|---|
| Standort | Wohnwagen Knausi, erreichbar über WireGuard-VPN |
| PVE-Version | 9.1.7 |
| PBS-Namespace | `knausi` |
| Storage-Eintrag | `PBS3` |
| Angebunden am | 2026-05-21 |

**Backup-Job:**

| Job | Schedule | Umfang | Modus | Retention |
|---|---|---|---|---|
| Wochen-Job | `sun 02:30` | alle Gäste | stop | keep-last=7 |

Gäste: CT 100 (logging-master/influxdb), 200 (mqtt-master), 201 (heimdall),
202 (klimaanlagen-master), **150 (energy-master-knausi, neu 2026-05-30)**.

> **CT 150 `energy-master-knausi`** (2026-05-30 provisioniert): IP
> 192.168.13.145/24, Debian 13, 2 vCPU / 4 GiB / 20 GiB, unprivileged,
> onboot. Stack uv + nginx + Node 22/pnpm 10, UTC. Eigene volle
> energy-master-Instanz (Wohnwagen-Plant), App-Deploy macht energy-master.
> Wird vom Wochen-Job automatisch miterfasst, sobald PBS wieder online ist
> (PBS aktuell bewusst aus — siehe `NEXT.md`).

Hinweis: Knausi hatte vor dem Namespace-Umzug einige Backups direkt im
root-Namespace von PBS3 (CT 200/201/202, Mai 2026). Diese verwaisten Altstände
stören nicht und werden mit der Zeit weggepruned — bei Bedarf manuell per
`snapshot forget` entfernen (siehe `pbs-server.md`).

---

## Neuen Host hinzufügen

Siehe `../README.md` → "Backup: Neuen Host an den PBS anbinden". Kurz:

```bash
NAMESPACE=proxmox-<oktett> PBS_PASSWORD='...' \
bash -c "$(curl -fsSL https://raw.githubusercontent.com/meintechblog/proxmox-master/main/installer/onboard-pbs-host.sh)"
```

Danach hier eine Zeile ergänzen.
