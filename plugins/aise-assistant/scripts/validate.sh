#!/usr/bin/env bash
# validate.sh — Local pre-flight check for the aise-assistant plugin archive.
#
# Usage:
#   ./scripts/validate.sh <path-to-.plugin-or-.zip>
#   ./scripts/validate.sh          # auto-finds latest aise-assistant-v*.plugin in parent dir
#
# Exit codes:  0 = all checks passed,  1 = one or more failures

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
PARENT_DIR="$(dirname "$PLUGIN_DIR")"

# ── Locate plugin archive ─────────────────────────────────────────────────────
if [[ $# -ge 1 ]]; then
  ZIP_PATH="$1"
else
  # Prefer .plugin, fall back to .zip
  ZIP_PATH=$(ls -t "$PARENT_DIR"/aise-assistant-v*.plugin 2>/dev/null | head -1 || true)
  if [[ -z "$ZIP_PATH" ]]; then
    ZIP_PATH=$(ls -t "$PARENT_DIR"/aise-assistant-v*.zip 2>/dev/null | head -1 || true)
  fi
fi

if [[ -z "$ZIP_PATH" || ! -f "$ZIP_PATH" ]]; then
  echo "Error: no plugin archive found. Run ./scripts/package.sh first, or pass a path:" >&2
  echo "  ./scripts/validate.sh <path-to-archive>" >&2
  exit 1
fi

echo "Validating: $ZIP_PATH"
echo ""

PASS=0
FAIL=0

check() {
  local label="$1"; local result="$2"
  if [[ "$result" == "ok" ]]; then
    echo "  [PASS] $label"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $label — $result"
    FAIL=$((FAIL + 1))
  fi
}

# ── Extract to temp dir ───────────────────────────────────────────────────────
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
unzip -q "$ZIP_PATH" -d "$TMP"

# ── Check 1: No wrapping parent folder ───────────────────────────────────────
TOP_ENTRIES=$(ls "$TMP")
TOP_COUNT=$(echo "$TOP_ENTRIES" | wc -l | tr -d ' ')

if [[ "$TOP_COUNT" -eq 1 && -d "$TMP/$TOP_ENTRIES" ]]; then
  check "ZIP root has NO wrapping parent folder" \
    "FAIL — found single top-level directory: $TOP_ENTRIES (validator expects files directly at root)"
else
  check "ZIP root has NO wrapping parent folder" "ok"
  ROOT="$TMP"
fi

# From here on, ROOT is where plugin files should live
ROOT="$TMP"

# ── Check 2: .claude-plugin/plugin.json present ───────────────────────────────
if [[ -f "$ROOT/.claude-plugin/plugin.json" ]]; then
  check ".claude-plugin/plugin.json present at ZIP root" "ok"
else
  check ".claude-plugin/plugin.json present at ZIP root" "not found"
fi

# ── Check 3: plugin.json required fields and field types ─────────────────────
if [[ -f "$ROOT/.claude-plugin/plugin.json" ]]; then
  PJ="$ROOT/.claude-plugin/plugin.json"
  for field in name version description author license; do
    val=$(python3 -c "import json; d=json.load(open('$PJ')); print(d.get('$field',''))" 2>/dev/null || echo "")
    if [[ -n "$val" && "$val" != "None" ]]; then
      check "plugin.json has '$field'" "ok"
    else
      check "plugin.json has '$field'" "missing or empty"
    fi
  done
  # repository must be a string URL, not an object (spec: repository: string)
  repo_type=$(python3 -c "import json; d=json.load(open('$PJ')); v=d.get('repository',''); print(type(v).__name__)" 2>/dev/null || echo "")
  if [[ "$repo_type" == "str" ]]; then
    check "plugin.json 'repository' is a string (not object)" "ok"
  elif [[ "$repo_type" == "dict" ]]; then
    check "plugin.json 'repository' is a string (not object)" "FAIL — must be a plain URL string, not an object"
  fi
fi

# ── Check 4: Required top-level dirs ─────────────────────────────────────────
# agents/ is always required. For commands, we ship commands/ (Cowork native
# validator format); skills/ is excluded from the package (see .claude/DEVELOPMENT.md).
# Accept either so this check stays valid if the format ever switches.
if [[ -d "$ROOT/agents" ]]; then
  check "agents/ directory present" "ok"
else
  check "agents/ directory present" "not found"
fi

if [[ -d "$ROOT/commands" ]] || [[ -d "$ROOT/skills" ]]; then
  check "commands/ or skills/ directory present" "ok"
else
  check "commands/ or skills/ directory present" "not found"
fi

# ── Check 5: README.md present ───────────────────────────────────────────────
if [[ -f "$ROOT/README.md" ]]; then
  check "README.md present" "ok"
else
  check "README.md present" "not found"
fi

# ── Check 6: No personal about/ files ────────────────────────────────────────
for f in identity.md voice.md workspace.md; do
  if [[ -f "$ROOT/about/$f" ]]; then
    # Should be placeholder templates, not populated personal files
    if grep -q '<TBD' "$ROOT/about/$f" 2>/dev/null; then
      check "about/$f is placeholder (not personal)" "ok"
    else
      check "about/$f is placeholder (not personal)" "WARNING — file exists but contains no <TBD markers; may be a personal file"
    fi
  else
    check "about/$f is placeholder (not personal)" "ok (file absent — acceptable)"
  fi
done

# ── Check 7: version consistency between plugin.json and archive filename ─────
if [[ -f "$ROOT/.claude-plugin/plugin.json" ]]; then
  PJ_VERSION=$(python3 -c "import json; print(json.load(open('$ROOT/.claude-plugin/plugin.json'))['version'])" 2>/dev/null || echo "")
  ZIP_BASENAME=$(basename "$ZIP_PATH")
  if echo "$ZIP_BASENAME" | grep -q "v${PJ_VERSION}"; then
    check "Archive filename version matches plugin.json version ($PJ_VERSION)" "ok"
  else
    check "Archive filename version matches plugin.json version ($PJ_VERSION)" "mismatch — archive: $ZIP_BASENAME"
  fi
fi

# ── Check 8: Official claude plugin validate (requires claude CLI) ────────────
if command -v claude &>/dev/null; then
  echo ""
  echo "Running: claude plugin validate (official CLI)"
  if claude plugin validate "$ROOT" 2>&1; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    echo "  [FAIL] claude plugin validate"
  fi
else
  echo "  [SKIP] claude plugin validate — CLI not found in PATH"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "Results: $PASS passed, $FAIL failed"

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
