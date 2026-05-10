#!/usr/bin/env bash
# session-start.sh — called by the SessionStart hook at the start of every session.
#
# Goal: write the real persistent data directory to ~/.claude/aise-assistant.datadir
# so agents can read it with a single Read-tool call (never via $CLAUDE_PLUGIN_DATA,
# which is volatile in Claude Code CLI).
#
# Context awareness:
#   Claude Code CLI  — $CLAUDE_PLUGIN_DATA is a volatile temp path.
#                      Real data lives at ~/.claude/plugins/data/aise-assistant*/
#   Cowork / Desktop — $CLAUDE_PLUGIN_DATA IS the persistent, accessible data dir.
#                      ~/.claude/plugins/data/ does not exist in the Linux sandbox.
#
# Discovery order:
#   0. $CLAUDE_PLUGIN_DATA already has identity.md  → Cowork, already set up
#   1. ~/.claude/plugins/data/aise-assistant*/ with identity.md → CLI, already set up
#   2. installed_plugins.json name derivation → CLI, fresh install
#   3. Any existing aise-assistant* data dir → CLI fallback
#   4. Prefer $CLAUDE_PLUGIN_DATA if set (Cowork fresh), else CLI default

set -euo pipefail

PLUGIN_DATA_DIR=""

# 0. Cowork / Desktop: $CLAUDE_PLUGIN_DATA is the real data dir when identity.md is there
if [[ -n "${CLAUDE_PLUGIN_DATA:-}" ]] && [[ -f "${CLAUDE_PLUGIN_DATA}/about/identity.md" ]]; then
  PLUGIN_DATA_DIR="$CLAUDE_PLUGIN_DATA"
fi

# 1. CLI: find any aise-assistant-* data dir that already has identity.md
if [[ -z "$PLUGIN_DATA_DIR" ]]; then
  for d in "$HOME/.claude/plugins/data/aise-assistant"*/; do
    [[ -d "$d" ]] || continue
    [[ -f "${d}about/identity.md" ]] && PLUGIN_DATA_DIR="${d%/}" && break
  done
fi

# 2. CLI: derive the name from installed_plugins.json
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

# 3. CLI: any existing aise-assistant* data dir
if [[ -z "$PLUGIN_DATA_DIR" ]]; then
  PLUGIN_DATA_DIR=$(ls -d "$HOME/.claude/plugins/data/aise-assistant"* 2>/dev/null | head -1 || true)
fi

# 4. Final fallback: prefer $CLAUDE_PLUGIN_DATA (Cowork fresh install) over a
#    Linux-VM home path that agents can't reach.
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
