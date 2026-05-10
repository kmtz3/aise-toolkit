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
echo "2. Local MCP servers"
echo ""

# Helper: check if a salesforce MCP entry exists in a given config file
_sf_in_config() {
  local cfg="$1"
  [[ -f "$cfg" ]] || return 1
  python3 - "$cfg" << 'PYEOF'
import json, sys, re
try:
    d = json.load(open(sys.argv[1]))
    servers = d.get("mcpServers", {})
    sys.exit(0 if any(re.search("salesforce", k, re.IGNORECASE) for k in servers) else 1)
except Exception:
    sys.exit(1)
PYEOF
}

# Helper: find the sf binary beyond just $PATH
_find_sf() {
  local npm_root
  npm_root="$(npm root -g 2>/dev/null)" || npm_root=""
  local candidates=(
    "$(command -v sf 2>/dev/null)"
    "$HOME/.npm-global/bin/sf"
    "/usr/local/bin/sf"
    "/opt/homebrew/bin/sf"
    "$HOME/.local/share/sf/bin/sf"
  )
  [[ -n "$npm_root" ]] && candidates+=("${npm_root}/../bin/sf")
  for c in "${candidates[@]}"; do
    [[ -x "${c:-}" ]] && echo "$c" && return 0
  done
  return 1
}

# Helper: check if sf has at least one authenticated org.
# Reads credential files directly — avoids needing Node on PATH.
# Checks ~/.sfdx/*.json (sfdx/sf v1) and ~/.sf/credentials.json (sf v2+).
_sf_auth_ok() {
  python3 - << 'PYEOF'
import json, glob, os, sys, pathlib

found = []

# sf v1 / sfdx: one JSON file per org in ~/.sfdx/
sfdx_dir = pathlib.Path.home() / ".sfdx"
for f in sfdx_dir.glob("*.json"):
    if f.name in ("alias.json",):
        continue
    try:
        d = json.loads(f.read_text())
        if d.get("username") and (d.get("accessToken") or d.get("refreshToken")):
            found.append(d["username"])
    except Exception:
        pass

# sf v2+: ~/.sf/credentials.json
creds_file = pathlib.Path.home() / ".sf" / "credentials.json"
if creds_file.exists():
    try:
        d = json.loads(creds_file.read_text())
        found.extend(d.keys())
    except Exception:
        pass

sys.exit(0 if found else 1)
PYEOF
}

if [[ "$CHECK_ONLY" == true ]]; then
  # ── Check mode: read-only status report ────────────────────────────────────

  # 2a. Salesforce CLI + authentication
  SF_BIN=""
  SF_BIN="$(_find_sf 2>/dev/null)" || true

  if [[ -n "$SF_BIN" ]]; then
    if _sf_auth_ok 2>/dev/null; then
      ok "Salesforce CLI: installed + authenticated ($SF_BIN)"
    else
      skip "Salesforce CLI: installed at $SF_BIN (not authenticated)"
      miss "Salesforce not authenticated — run: sf org login web"
    fi
  else
    miss "Salesforce CLI not found. Run: npm install -g @salesforce/cli && sf org login web"
  fi

  # 2b. Salesforce MCP entry — check all known config locations
  SF_MCP_OK=false
  SF_MCP_LOCATION=""
  for cfg in "$HOME/.claude.json" "$HOME/.claude/mcp.json" "$HOME/.claude/claude_desktop_config.json"; do
    if _sf_in_config "$cfg" 2>/dev/null; then
      SF_MCP_OK=true
      SF_MCP_LOCATION="$cfg"
      break
    fi
  done

  if [[ "$SF_MCP_OK" == true ]]; then
    ok "Salesforce MCP: configured in $(basename "$SF_MCP_LOCATION")"
  else
    miss "Salesforce MCP not configured. Run: claude mcp add salesforce -- npx -y @salesforce/mcp"
  fi

else
  # ── Configure mode: write salesforce entry to mcp.json if missing ──────────

  # 2a. Salesforce CLI
  SF_BIN=""
  SF_BIN="$(_find_sf 2>/dev/null)" || true

  if [[ -n "$SF_BIN" ]]; then
    ok "Salesforce CLI installed at $SF_BIN"
    if _sf_auth_ok 2>/dev/null; then
      ok "Salesforce authenticated"
    else
      miss "Salesforce not authenticated"
      note "Run: sf org login web"
    fi
  else
    miss "Salesforce CLI not installed"
    note "Install it: npm install -g @salesforce/cli"
    note "Then authenticate: sf org login web"
    note "The MCP entry will still be added below — install sf before first use."
    echo ""
  fi

  # 2b. Add salesforce entry to mcp.json if not already present anywhere
  SF_MCP_OK=false
  for cfg in "$HOME/.claude.json" "$HOME/.claude/mcp.json" "$HOME/.claude/claude_desktop_config.json"; do
    if _sf_in_config "$cfg" 2>/dev/null; then
      SF_MCP_OK=true
      skip "salesforce MCP already configured in $(basename "$cfg")"
      break
    fi
  done

  if [[ "$SF_MCP_OK" == false ]]; then
    python3 - "$MCP_JSON" << 'PYEOF'
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

fi

# ── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════"
if [[ "$CHECK_ONLY" == true ]]; then
  echo "Check complete (no changes made)."
else
  echo "Done. Restart Claude Code, then run /assistant-setup."
fi
echo ""
