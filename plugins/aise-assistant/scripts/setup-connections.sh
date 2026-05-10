#!/usr/bin/env bash
# setup-connections.sh — Configure local MCP servers for aise-assistant.
#
# Safe to re-run: skips anything already configured.
# Restart Claude Code after running.
#
# Usage:
#   ./scripts/setup-connections.sh          # configure local MCPs
#   ./scripts/setup-connections.sh --check  # dry run, no writes

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
MCP_JSON="$HOME/.claude/mcp.json"
CHECK_ONLY=false

[[ "${1:-}" == "--check" ]] && CHECK_ONLY=true

ok()   { echo "  ✓  $1"; }
skip() { echo "  –  $1"; }
miss() { echo "  ✗  $1"; }
note() { echo "     $1"; }

echo ""
echo "aise-assistant — connection setup"
echo "══════════════════════════════════"
echo ""

# ── PART 1: claude.ai integrations ─────────────────────────────────────────
# These are per-user account settings — cannot be configured by a script.
# Print the checklist so a new teammate knows exactly what to enable.
echo "1. claude.ai integrations (account-level — configure in your browser)"
echo "   Sign in → claude.ai → Settings → Integrations → enable each:"
echo ""
echo "   □  Notion           Customer Tracker reads/writes"
echo "   □  Gmail            draft creation, email history"
echo "   □  Google Calendar  session lookup, prep scheduling"
echo "   □  Google Drive     diagram uploads, document access"
echo "   □  Glean            Gong transcripts, Slack, Salesforce, Confluence, Drive"
echo "   □  Slack            debrief drafts, external channel reads"
echo "   □  Figma            architecture diagram creation"
echo "   □  Atlassian        Jira/Confluence cross-reference (optional)"
echo ""
echo "   Each teammate sets these up in their own account — they cannot be"
echo "   bundled in the plugin."
echo ""

# ── PART 2: local MCP servers ──────────────────────────────────────────────
echo "2. Local MCP servers (~/.claude/mcp.json)"
echo ""

# 2a. Salesforce CLI (sf) — needed for org authentication
if command -v sf &>/dev/null; then
  ok "Ah, look at this nerd — Salesforce is already installed at $(command -v sf) 🤓"
else
  miss "Salesforce CLI not installed (needed for org authentication)"
  note "Install it: npm install -g @salesforce/cli"
  note "Then authenticate: sf org login web"
  note "The MCP entry will still be added below — install sf before first use."
  echo ""
fi

# 2b. mcp.json — add salesforce entry if missing
SF_ENTRY_EXISTS=false
if [[ -f "$MCP_JSON" ]]; then
  if python3 -c "
import json, sys
d = json.load(open(sys.argv[1]))
sys.exit(0 if 'salesforce' in d.get('mcpServers', {}) else 1)
" "$MCP_JSON" 2>/dev/null; then
    SF_ENTRY_EXISTS=true
  fi
fi

if [[ "$SF_ENTRY_EXISTS" == true ]]; then
  skip "salesforce entry already in mcp.json"
elif [[ "$CHECK_ONLY" == true ]]; then
  miss "salesforce entry missing from mcp.json"
  note "Run without --check to add it."
else
  python3 - "$MCP_JSON" <<'PYEOF'
import json, sys, os, pathlib

mcp_path = sys.argv[1]
pathlib.Path(mcp_path).parent.mkdir(parents=True, exist_ok=True)

config = {}
if os.path.exists(mcp_path):
    with open(mcp_path) as f:
        config = json.load(f)

config.setdefault("mcpServers", {})
config["mcpServers"]["salesforce"] = {
    "command": "npx",
    "args": ["-y", "@salesforce/mcp"]
}

with open(mcp_path, "w") as f:
    json.dump(config, f, indent=2)
    f.write("\n")
PYEOF

  ok "salesforce entry added to mcp.json"
  note "Restart Claude Code for this to take effect."
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════"
if [[ "$CHECK_ONLY" == true ]]; then
  echo "Check complete (no changes made)."
else
  echo "Done. Restart Claude Code, then run /assistant-setup."
fi
echo ""
