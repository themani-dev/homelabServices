#!/bin/bash
# This script is used to set up Cloudflare Tunnel for a local service
cloudflared login
cloudflared tunnel create zimaboard-homelab
cloudflared tunnel route dns zimaboard-homelab homelab.themani.dev
cloudflared tunnel route dns zimaboard-homelab dashboard.themani.dev
cloudflared tunnel route dns zimaboard-homelab filebrowser.themani.dev
cloudflared tunnel config init
cloudflared tunnel run zimaboard-homelab
