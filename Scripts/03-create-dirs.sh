#!/usr/bin/env bash
# MiniLab: Create service data directories with correct ownership
# Requires root (sudo) for PostgreSQL directory ownership.
# Idempotent -- safe to re-run.
set -euo pipefail

# ---------- Resolve project root ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== MiniLab Directory Setup ==="
echo "Project root: $PROJECT_DIR"
echo ""

# ---------- Directory list (D-05) ----------
DIRS=(
    "data/portainer"
    "data/npm"
    "data/adguard"
    "data/jellyfin/config"
    "data/jellyfin/cache"
    "data/jellyfin/media"
    "data/postgres"
    "data/homepage"
)

# ---------- Create directories (idempotent) ----------
for dir in "${DIRS[@]}"; do
    target="$PROJECT_DIR/$dir"
    if [[ -d "$target" ]]; then
        echo "[OK] $dir already exists"
    else
        mkdir -p "$target"
        echo "[CREATED] $dir"
    fi
done

# ---------- PostgreSQL ownership (D-06) ----------
PG_DIR="$PROJECT_DIR/data/postgres"
CURRENT_OWNER=$(stat -c '%u' "$PG_DIR" 2>/dev/null || echo "unknown")

if [[ "$CURRENT_OWNER" == "999" ]]; then
    echo "[OK] data/postgres/ already owned by UID 999"
elif [[ $EUID -ne 0 ]]; then
    echo "[WARN] Need root to set data/postgres/ ownership to 999:999"
    echo "       Run: sudo chown -R 999:999 $PG_DIR"
else
    chown -R 999:999 "$PG_DIR"
    echo "[DONE] data/postgres/ owned by 999:999"
fi

echo ""
echo "[DONE] Directory setup complete."
