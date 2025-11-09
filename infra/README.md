# 🖥️ Server Build Proposal — 24/7 NAS + Docker + Virtualization Host

**Prepared for:** Mani Reddy  
**Purpose:** Design and quote a future-proof, quiet, and efficient server capable of continuous 24/7 operation for NAS, containerized workloads, and light virtualization.  
**Date:** November 2025  

---

## 1. Overview

This build is designed to provide a compact, micro-ATX–based server with 4–6 drive bays, optimized airflow, minimal noise, and efficient 24/7 operation.  
It is intended to host multiple Docker containers, lightweight virtual machines, and act as a centralized NAS for media and backups.

---

## 2. Requirements Summary

| Category | Requirement |
|-----------|-------------|
| **Use Case** | 24/7 NAS + Docker host + light VM workloads |
| **Form Factor** | micro-ATX (portable, compact case) |
| **Drive Bays** | Minimum 4 × 3.5″, preferred 6 × 3.5″ |
| **Cooling** | Efficient airflow and quiet operation |
| **Noise** | Low (<30 dB at idle) |
| **Power Efficiency** | Idle power <60 W |
| **Network** | 2.5 GbE built-in, 10 GbE upgrade optional |
| **Expandability** | ECC memory support, HBA support for extra drives |
| **Future-Proofing** | AM5 platform, DDR5 memory, modular components |

---

## 3. 24/7 Docker Workloads

**Always-Running Containers**
- Portainer CE  
- Prometheus  
- Grafana  
- Photoprism  
- Plex Media Server  
- n8n (workflow automation)  
- WebDAV  
- Home Assistant  
- Dashy Dashboard  
- PostgreSQL  
- Apache Airflow (scheduler + webserver)  
- Redis  

**Workload-Based Applications (on-demand)**
- Apache Kafka  
- Apache Spark  
- ELK Stack (Elasticsearch, Logstash, Kibana)  
- Virtual Machines (Ubuntu, Windows, Kali, etc.)

---

## 4. Recommended Hardware Configuration

| Component | Model / Description | Notes |
|------------|--------------------|-------|
| **CPU** | AMD **Ryzen 7 7700** (8C/16T, 65 W, with iGPU) | High performance, efficient, integrated graphics for Plex |
| **Motherboard** | **ASRock B650M Pro RS WiFi** (micro-ATX) | ECC support, 2.5 GbE LAN, good fan control |
| **Memory** | 64 GB (2 × 32 GB) DDR5 ECC/Non-ECC 3200–5600 MHz | Large headroom for Docker, Spark, ELK, and VMs |
| **Case** | **JONSBO N4** micro-ATX NAS chassis | 6 × 3.5″ + 2 × 2.5″ bays, excellent airflow, portable |
| **Cooling** | **Noctua NH-U12S Redux** + 2 × Noctua NF-A12 fans | Quiet, high-quality cooling solution |
| **Power Supply** | **Seasonic Focus GX-550 SFX** (80+ Gold) | Silent and efficient, modular cables |
| **Boot / OS Drive** | NVMe SSD 1 TB (PCIe Gen 4) | System + Docker volumes |
| **Data Storage** | 4–6 × WD Red Plus or Seagate IronWolf (4–8 TB each) | NAS-rated drives for reliability and low noise |
| **Optional Cache Drive** | NVMe SSD 500 GB | L2ARC/ZIL cache or high-IO workloads |
| **Optional HBA** | Broadcom / LSI 9300-8i (IT-mode) | Adds 8 extra SATA/SAS ports if needed |
| **Optional NIC** | Intel X550-T2 / Mellanox ConnectX-4 (10 GbE) | For high-speed LAN environments |
| **UPS** | APC Back-UPS Pro 1000 VA | Power protection and graceful shutdown |

---

## 5. System Layout

| Role | Storage Device | Purpose |
|------|----------------|----------|
| **OS / Docker** | NVMe SSD 1 TB | Proxmox / Ubuntu + Docker engine |
| **Data Pool** | 4–6 × HDDs | ZFS or Btrfs RAID Z1/Z2 for NAS |
| **Cache (optional)** | NVMe 500 GB | High-speed read/write cache |
| **VM Storage** | Dedicated NVMe or sub-pool | For short-term VM workloads |

---

## 6. Software Stack

| Layer | Software | Description |
|--------|-----------|-------------|
| **Host OS** | **Proxmox VE 8** or **TrueNAS Scale** | Handles virtualization, ZFS, and Docker (via LXC/k8s) |
| **Containers** | Docker + Portainer CE | Unified container management |
| **Monitoring** | Prometheus + Grafana | Server metrics, dashboards |
| **Automation / ETL** | n8n + Apache Airflow + Redis | Task scheduling and data pipelines |
| **Database** | PostgreSQL | Backend for internal services |
| **Media / AI** | Plex + Photoprism | Hardware-accelerated transcoding and photo management |
| **Home / IoT** | Home Assistant + WebDAV | Local automation and file sync |
| **Dashboard** | Dashy | Unified system portal |
| **File Sharing** | Samba / NFS / MinIO | Network storage access |

---

## 7. Performance & Power Metrics

| Mode | Power (W) | Noise (dB) | Description |
|------|------------|------------|--------------|
| **Idle (all containers up)** | 45 – 55 W | < 25 dB | Whisper-quiet 24/7 operation |
| **Medium load (multiple containers)** | 70 – 90 W | ~30 dB | Typical daytime operation |
| **Heavy workloads (Spark / ELK)** | 110 – 130 W | ~35 dB | Sustained compute tasks |
| **Drive spin-down / standby** | 25 – 30 W | Near silent | Overnight idle state |

---

## 8. Estimated Costs (USD)

| Component | Estimated Price |
|------------|-----------------|
| CPU — Ryzen 7 7700 | $300 |
| Motherboard — B650M Pro RS WiFi | $150 |
| Memory — 64 GB DDR5 | $180 |
| NVMe SSD 1 TB | $70 |
| 6 × 6 TB WD Red Plus | $540 |
| Case — JONSBO N4 | $140 |
| PSU — 550 W SFX Gold | $110 |
| Cooling / Fans | $60 |
| Optional HBA | $80 |
| **Total (approx.)** | **$1,400 – $1,600 USD** |

> *Excluding UPS and optional 10 GbE card. Final cost may vary by supplier and storage size.*

---

## 9. Key Advantages

✅ **AM5 Platform Longevity** — CPU upgrades supported through 2027+  
✅ **ECC Memory Support** — Enhanced ZFS/Btrfs data integrity  
✅ **Compact & Portable Design** — micro-ATX chassis with efficient layout  
✅ **Low Noise & Power Draw** — Ideal for 24/7 home or office operation  
✅ **Scalable Storage** — 6-bay chassis, HBA expansion ready  
✅ **GPU-Ready** — Hardware transcoding for Plex/Photoprism  
✅ **High-Speed Networking** — 2.5 GbE onboard, optional 10 GbE expansion  

---

## 10. Recommended Next Steps

1. **Confirm Storage Capacity Needs** — choose 4, 6, or 8 TB drives.  
2. **Decide Host OS** — Proxmox VE or TrueNAS Scale (depending on preferred workflow).  
3. **Select ECC vs. Non-ECC Memory** — based on ZFS/Btrfs requirements.  
4. **Optional Add-Ons** — 10 GbE NIC, HBA, or UPS integration.  
5. **Procure Components & Build** — estimated 2–3 hours build and config time.  
6. **Deploy Container Stack** — via Portainer CE templates or Docker Compose.

---

## 11. Summary

This proposed build delivers a **high-efficiency, low-noise, multi-purpose home or small-office server** capable of hosting your entire container ecosystem, NAS storage, and virtualization workloads.  
It emphasizes **future compatibility, reliability, and quiet 24/7 operation** — ideal for continuous Docker deployments, smart home integrations, and media management.

---

**Prepared by:**  
**ChatGPT | GPT-5 System Build Advisor**  
*Generated on: November 9, 2025*  
