#!/usr/bin/env bash
# upgrade.sh — Safe upgrade script for aise-assistant plugin.
#
# Copies plugin-owned files from a new version. Personal about/ files live at
# $CLAUDE_PLUGIN_DATA/about/ and are never touched by this script (except for the
# one-time migration from legacy paths).
#
# Usage:
#   ./scripts/upgrade.sh --source <path-to-new-version-dir>
#   ./scripts/upgrade.sh --check   (just audit current state, no writes)
#
# Plugin-owned (always replaced):  about/README.md, about/templates/, agents/, commands/, etc.
# Personal (never touched):        $CLAUDE_PLUGIN_DATA/about/identity.md, voice.md, workspace.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
# Read the persistent data dir from the pointer file written by the SessionStart hook.
# Fall back to ls-based discovery when run outside a Claude session (e.g. CI, manual upgrade).
PLUGIN_DATA_DIR=$(cat "$HOME/.claude/aise-assistant.datadir" 2>/dev/null || true)
if [[ -z "$PLUGIN_DATA_DIR" ]]; then
  PLUGIN_DATA_DIR=$(ls -d "$HOME/.claude/plugins/data/aise-assistant"* 2>/dev/null | head -1)
  PLUGIN_DATA_DIR="${PLUGIN_DATA_DIR:-$HOME/.claude/plugins/data/aise-assistant}"
fi
ABOUT_DIR="$PLUGIN_DATA_DIR/about"

PERSONAL_FILES=("identity.md" "voice.md" "workspace.md")

SOURCE_DIR=""
CHECK_ONLY=false

# --- arg parsing ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      SOURCE_DIR="$2"
      shift 2
      ;;
    --check)
      CHECK_ONLY=true
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      echo "Usage: $0 --source <new-version-dir> | --check" >&2
      exit 1
      ;;
  esac
done

if [[ "$CHECK_ONLY" == false && -z "$SOURCE_DIR" ]]; then
  echo "Error: --source <path> is required unless --check is passed." >&2
  echo "Usage: $0 --source <new-version-dir> | --check" >&2
  exit 1
fi

if [[ -n "$SOURCE_DIR" && ! -d "$SOURCE_DIR" ]]; then
  echo "Error: source directory not found: $SOURCE_DIR" >&2
  exit 1
fi

# --- helpers ---
is_populated() {
  local file="$1"
  [[ -f "$file" ]] && ! grep -q '<TBD' "$file" 2>/dev/null
}

# --- check mode ---
if [[ "$CHECK_ONLY" == true ]]; then
  echo "aise-assistant personal file state ($ABOUT_DIR):"
  for f in "${PERSONAL_FILES[@]}"; do
    target="$ABOUT_DIR/$f"
    if is_populated "$target"; then
      echo "  ✓ $f — populated (safe — lives outside plugin, survives updates)"
    elif [[ -f "$target" ]]; then
      echo "  ○ $f — exists but unpopulated (run /assistant-setup to fill in)"
    else
      echo "  ✗ $f — missing (run /assistant-setup to create)"
    fi
  done
  exit 0
fi

# --- upgrade mode ---
PRESERVED=()
RESTORED=()
CREATED=()

echo "aise-assistant upgrade — source: $SOURCE_DIR"
echo ""

# 1. Migrate personal files from legacy paths (one-time, idempotent).
LEGACY_PATHS=(
  "$HOME/Library/Application Support/aise-assistant/about"
  "$HOME/.claude/aise-assistant/about"
)
if [[ ! -f "$ABOUT_DIR/identity.md" ]]; then
  for old in "${LEGACY_PATHS[@]}"; do
    if [[ -d "$old" ]]; then
      mkdir -p "$ABOUT_DIR"
      mv "$old"/*.md "$ABOUT_DIR/" 2>/dev/null || true
      echo "  ↗ Migrated personal files from $old to $ABOUT_DIR"
      break
    fi
  done
fi

# 2. Personal files live at $ABOUT_DIR — never touched by upgrade beyond migration above
echo "  Personal files ($ABOUT_DIR) — skipped (outside plugin, always safe)"
for f in "${PERSONAL_FILES[@]}"; do
  target="$ABOUT_DIR/$f"
  if is_populated "$target"; then
    PRESERVED+=("$f")
    echo "    ✓ $f — populated"
  elif [[ -f "$target" ]]; then
    echo "    ○ $f — exists but unpopulated (run /assistant-setup to fill in)"
  else
    echo "    ✗ $f — missing (run /assistant-setup to create)"
  fi
done

echo ""

# 3. Plugin-owned files: always overwrite
echo "  Updating plugin-owned files..."

# about/README.md
if [[ -f "$SOURCE_DIR/about/README.md" ]]; then
  cp "$SOURCE_DIR/about/README.md" "$ABOUT_DIR/README.md"
  echo "  ↺ about/README.md — updated"
fi

# about/templates/ — replace entirely
if [[ -d "$SOURCE_DIR/about/templates" ]]; then
  rm -rf "$ABOUT_DIR/templates"
  cp -r "$SOURCE_DIR/about/templates" "$ABOUT_DIR/templates"
  echo "  ↺ about/templates/ — updated"
fi

# All other top-level plugin files (agents/, commands/, context/, scripts/, CLAUDE.md, etc.)
for item in CLAUDE.md README.md agents commands context scripts templates; do
  src="$SOURCE_DIR/$item"
  dst="$PLUGIN_DIR/$item"
  if [[ -e "$src" ]]; then
    rm -rf "$dst"
    cp -r "$src" "$dst"
    echo "  ↺ $item — updated"
  fi
done

echo ""
echo "─────────────────────────────────────────────────"

# 4. Summary + post-upgrade notice
if [[ ${#PRESERVED[@]} -gt 0 ]]; then
  preserved_list=$(IFS=', '; echo "${PRESERVED[*]}")
  echo ""
  echo "Personal about/ files detected and preserved (${preserved_list})."
  echo "Run /assistant-setup --update to check for drift against your updated role or preferences."
fi

if [[ ${#RESTORED[@]} -gt 0 ]]; then
  restored_list=$(IFS=', '; echo "${RESTORED[*]}")
  echo ""
  echo "Unpopulated files restored from template (${restored_list})."
  echo "Run /assistant-setup to populate them."
fi

echo ""
echo "Upgrade complete."
