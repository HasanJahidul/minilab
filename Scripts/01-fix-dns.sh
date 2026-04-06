#!/usr/bin/env bash
# MiniLab: Disable systemd-resolved stub listener and configure static DNS
# Must be run as root (sudo). Idempotent -- safe to re-run.
set -euo pipefail

# ---------- Root check ----------
if [[ $EUID -ne 0 ]]; then
    echo "[ERROR] This script must be run as root (use sudo)" >&2
    exit 1
fi

# ---------- Disable systemd-resolved stub listener via drop-in ----------
DROPIN_DIR="/etc/systemd/resolved.conf.d"
DROPIN_FILE="/etc/systemd/resolved.conf.d/disable-stub.conf"

if [[ -f "$DROPIN_FILE" ]] && grep -q "DNSStubListener=no" "$DROPIN_FILE"; then
    echo "[OK] DNS stub listener already disabled via drop-in"
else
    echo "[FIX] Disabling DNS stub listener..."
    mkdir -p "$DROPIN_DIR"
    printf "[Resolve]\nDNSStubListener=no\n" > "$DROPIN_FILE"
    systemctl restart systemd-resolved
    echo "[DONE] DNS stub listener disabled"
fi

# ---------- Fix /etc/resolv.conf ----------
# On Ubuntu 24.04, resolv.conf is typically a symlink to the stub resolver.
# Replace it with a static file pointing to real upstream DNS (D-07).
if [[ -L /etc/resolv.conf ]]; then
    echo "[FIX] Removing resolv.conf symlink..."
    rm /etc/resolv.conf
fi

if grep -q "1.1.1.1" /etc/resolv.conf 2>/dev/null; then
    echo "[OK] /etc/resolv.conf already configured"
else
    cat > /etc/resolv.conf <<'DNSEOF'
# MiniLab: Static DNS config (systemd-resolved stub disabled)
# AdGuard Home will take over DNS once running
nameserver 1.1.1.1
nameserver 8.8.8.8
DNSEOF
    echo "[DONE] /etc/resolv.conf updated with Cloudflare + Google DNS"
fi

# ---------- Verify port 53 is free ----------
if ss -tlnp | grep -q ':53 '; then
    echo "[WARN] Port 53 still in use:"
    ss -tlnp | grep ':53 '
    echo "       You may need to wait a moment and re-check, or reboot."
else
    echo "[PASS] Port 53 is free for AdGuard Home"
fi

echo ""
echo "[DONE] DNS configuration complete."
