#!/usr/bin/env bash
# Faculta — One-command setup for the agent capability triad
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${1:-$SCRIPT_DIR}"

echo "=== Faculta Setup ==="
echo "Installing to: $INSTALL_DIR"
echo ""

# Clone repositories (skip if already present)
for repo in Velle expergis arbitrium; do
    target="$INSTALL_DIR/$repo"
    if [ -d "$target/.git" ]; then
        echo "[$repo] Already cloned, pulling latest..."
        git -C "$target" pull --ff-only 2>/dev/null || echo "  (pull skipped — may have local changes)"
    else
        echo "[$repo] Cloning..."
        git clone "https://github.com/PStryder/$repo.git" "$target"
    fi
done

echo ""

# Install dependencies
for repo in Velle expergis arbitrium; do
    echo "[$repo] Installing dependencies..."
    cd "$INSTALL_DIR/$repo"
    uv sync 2>&1 | tail -1
done

echo ""

# Detect Python paths
VELLE_PY="$INSTALL_DIR/Velle/.venv/Scripts/python"
EXPERGIS_PY="$INSTALL_DIR/expergis/.venv/Scripts/python"
ARBITRIUM_PY="$INSTALL_DIR/arbitrium/.venv/Scripts/python"

# Unix fallback
if [ ! -f "$VELLE_PY" ]; then
    VELLE_PY="$INSTALL_DIR/Velle/.venv/bin/python"
    EXPERGIS_PY="$INSTALL_DIR/expergis/.venv/bin/python"
    ARBITRIUM_PY="$INSTALL_DIR/arbitrium/.venv/bin/python"
fi

echo "=== Setup Complete ==="
echo ""
echo "Add to Claude Code with:"
echo ""
echo "  claude mcp add -s user velle -- \"$VELLE_PY\" -m velle.server"
echo "  claude mcp add -s user expergis -- \"$EXPERGIS_PY\" -m expergis.server"
echo "  claude mcp add -s user arbitrium -- \"$ARBITRIUM_PY\" -m arbitrium.server"
echo ""
echo "Then enable Velle's HTTP sidecar in $INSTALL_DIR/Velle/velle.json:"
echo '  "sidecar_enabled": true'
echo ""
echo "Restart Claude Code and all three servers will be available."
