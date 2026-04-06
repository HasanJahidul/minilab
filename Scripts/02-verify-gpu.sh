#!/usr/bin/env bash
# MiniLab: Verify Intel GPU device nodes and render group GID
# Does NOT require root. Verification-only -- does not modify anything.
set -euo pipefail

ERRORS=0

echo "=== Intel GPU Verification ==="
echo ""

# ---------- Check 1: /dev/dri directory ----------
if [[ -d /dev/dri ]]; then
    echo "[PASS] /dev/dri/ exists"
    ls -la /dev/dri/
    echo ""
else
    echo "[FAIL] /dev/dri/ not found -- no GPU detected"
    ERRORS=$((ERRORS + 1))
fi

# ---------- Check 2: renderD128 device node ----------
if [[ -e /dev/dri/renderD128 ]]; then
    echo "[PASS] /dev/dri/renderD128 exists"
else
    echo "[FAIL] /dev/dri/renderD128 not found"
    echo "       Intel QuickSync will not work without this device node."
    ERRORS=$((ERRORS + 1))
fi

# ---------- Check 3: i915 kernel module ----------
if lsmod | grep -q i915; then
    echo "[PASS] i915 kernel module loaded"
else
    echo "[WARN] i915 module not in lsmod (may be built-in on Ubuntu 24.04 kernel)"
    echo "       This is not necessarily an error -- check /dev/dri above."
fi

# ---------- Check 4: Render group GID ----------
if getent group render >/dev/null 2>&1; then
    RENDER_GID=$(getent group render | cut -d: -f3)
    echo "[PASS] Render group found (GID: $RENDER_GID)"
    echo ""
    echo "========================================="
    echo "  SAVE THIS: render group GID = $RENDER_GID"
    echo "  Use in docker-compose.yml:"
    echo "    group_add:"
    echo "      - \"$RENDER_GID\""
    echo "========================================="
else
    echo "[WARN] 'render' group not found on this system"
    echo "       Jellyfin may not have GPU access."
    ERRORS=$((ERRORS + 1))
fi

echo ""
if [[ $ERRORS -eq 0 ]]; then
    echo "[PASS] All GPU checks passed."
else
    echo "[WARN] $ERRORS check(s) failed. Review output above."
fi

exit $ERRORS
