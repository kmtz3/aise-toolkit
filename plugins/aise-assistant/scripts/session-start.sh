#!/usr/bin/env bash
# session-start.sh — writes the real plugin data directory to
# ~/.claude/aise-assistant.datadir so agents can resolve it with one Read call.
#
# $CLAUDE_PLUGIN_DATA is set by the Claude plugin runtime whenever a hook runs.
# It always resolves to the correct persistent data directory for the installed
# plugin, regardless of what directory suffix Claude appends to the plugin ID
# (e.g. aise-assistant-aise-local). Use it as the primary source of truth.
#
# The fallback discovery (steps 1–4) handles edge cases where the hook is
# invoked outside the normal plugin runtime (e.g. manual testing).

set -euo pipefail

PLUGIN_DATA_DIR=""

# 0. Primary: $CLAUDE_PLUGIN_DATA is set by the plugin runtime to the real data dir,
#    handling any suffix Claude appends to the plugin ID (e.g. aise-assistant-aise-local).
#    Use it when identity.md already lives there (populated install).
#    Fresh installs fall through to step 4 which also prefers $CLAUDE_PLUGIN_DATA.
if [[ -n "${CLAUDE_PLUGIN_DATA:-}" ]] && [[ -f "${CLAUDE_PLUGIN_DATA}/about/identity.md" ]]; then
  PLUGIN_DATA_DIR="$CLAUDE_PLUGIN_DATA"
fi

# 1. Fallback: find any aise-assistant-* data dir that already has identity.md
if [[ -z "$PLUGIN_DATA_DIR" ]]; then
  for d in "$HOME/.claude/plugins/data/aise-assistant"*/; do
    [[ -d "$d" ]] || continue
    [[ -f "${d}about/identity.md" ]] && PLUGIN_DATA_DIR="${d%/}" && break
  done
fi

# 2. Fallback: derive the name from installed_plugins.json
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

# 3. Fallback: any existing aise-assistant* data dir
if [[ -z "$PLUGIN_DATA_DIR" ]]; then
  PLUGIN_DATA_DIR=$(ls -d "$HOME/.claude/plugins/data/aise-assistant"* 2>/dev/null | head -1 || true)
fi

# 4. Final fallback: prefer $CLAUDE_PLUGIN_DATA (Cowork fresh install, or any install
#    where Claude appended a suffix to the plugin ID) over a generic default path.
if [[ -z "$PLUGIN_DATA_DIR" ]]; then
  if [[ -n "${CLAUDE_PLUGIN_DATA:-}" ]] && [[ -d "${CLAUDE_PLUGIN_DATA}" ]]; then
    PLUGIN_DATA_DIR="$CLAUDE_PLUGIN_DATA"
  else
    PLUGIN_DATA_DIR="$HOME/.claude/plugins/data/aise-assistant"
  fi
fi

# Create about/ and write the pointer file
mkdir -p "$PLUGIN_DATA_DIR/about" 2>/dev/null || true
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
