# 🏠 HomeLab Services – Self-Hosted Stack Overview

This section highlights the list of services running on my home server and their configuration details. These are containerized using Docker Compose and optimized for local development, monitoring, and data workflows.

---

## 📦 Infrastructure Setup
- All services are defined in a Docker Compose stack

- Environment-specific configs are isolated in .env files

- Logs and volumes are mapped for persistence

- Network is custom-defined: homelabServices

---

## 🧠 Goals of this Setup
- 📊 Build a reliable, always-on local development + analytics platform

- 💾 Centralize storage and sync across devices

- 🛠️ Automate data pipelines and observability

- 📡 Integrate IoT, AI, and monitoring tools under one stack

## List of Services

- Tailscale VPN

- Casaos

- Docker

- jellyfin

- filebrowser

- portainer

- cloudflared

- immich

- webDAV

- 