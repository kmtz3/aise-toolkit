#!/usr/bin/env bash
# session-start.sh — called by the SessionStart hook at the start of every session.
#
# $CLAUDE_PLUGIN_DATA is volatile in Claude Code (resolves to a temp path, not the
# persistent ~/.claude/plugins/data/ directory). We discover the real persistent
# directory here and write it to a fixed pointer file that agents and scripts can
# read with a single `cat`.

set -euo pipefail

PLUGIN_DATA_DIR=""

# 1. Find any aise-assistant-* data dir that already has identity.md
for d in "$HOME/.claude/plugins/data/aise-assistant"*/; do
  [[ -d "$d" ]] || continue
  [[ -f "${d}about/identity.md" ]] && PLUGIN_DATA_DIR="${d%/}" && break
done

# 2. No populated dir — derive the name from installed_plugins.json
if [[ -z "$PLUGIN_DATA_DIR" ]]; then
  PLUGIN_DATA_DIR=$(python3 - <<'PYEOF' 2>/dev/null
import json, re, os
try:
    f = os.path.expanduser("~/.claude/plugins/installed_plugins.json")
    plugins = json.loads(open(f).read()).get("plugins", {})
    key = next((k for k in plugins if k.startswith("aise-assistant")), None)
    if key:
        safe_id = re.sub(r"[^a-zA-Z0-9_-]", "-", key)
        print(os.path.expanduser(f"~/.claude/plugins/data/{safe_id}"))
except Exception:
    pass
PYEOF
)
fi

# 3. Any existing aise-assistant* data dir
if [[ -z "$PLUGIN_DATA_DIR" ]]; then
  PLUGIN_DATA_DIR=$(ls -d "$HOME/.claude/plugins/data/aise-assistant"* 2>/dev/null | head -1 || true)
fi

# 4. Final default
PLUGIN_DATA_DIR="${PLUGIN_DATA_DIR:-$HOME/.claude/plugins/data/aise-assistant}"

# Create about/ and write the pointer file
mkdir -p "$PLUGIN_DATA_DIR/about"
printf '%s' "$PLUGIN_DATA_DIR" > "$HOME/.claude/aise-assistant.datadir"

# Warn if identity.md still has placeholder values (setup not yet run)
if [[ -f "$PLUGIN_DATA_DIR/about/identity.md" ]] && grep -q '<TBD' "$PLUGIN_DATA_DIR/about/identity.md" 2>/dev/null; then
  echo "[aise-assistant] WARNING: identity.md still contains placeholder values — run /assistant-setup to complete onboarding." >&2
fi

# One-time migration from legacy paths (idempotent)
if [[ ! -f "$PLUGIN_DATA_DIR/about/identity.md" ]]; then
  for old in \
    "$HOME/Library/Application Support/aise-assistant/about" \
    "$HOME/.claude/aise-assistant/about"
  do
    if [[ -d "$old" ]]; then
      mv "$old"/*.md "$PLUGIN_DATA_DIR/about/" 2>/dev/null || true
      break
    fi
  done
fi
