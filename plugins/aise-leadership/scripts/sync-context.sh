#!/usr/bin/env bash
# sync-context.sh — Copy the latest context/ from aise-assistant (canonical source in this monorepo).
#
# Never edit context/ directly in aise-leadership — all changes go in plugins/aise-assistant/context/
# and are synced here by running this script (or automatically via /commit).
#
# Usage:
#   ./scripts/sync-context.sh        # sync; stages changes but does not commit
#   ./scripts/sync-context.sh --dry  # show what would change, no writes

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE="${PLUGIN_DIR}/../aise-assistant/context/"
DEST="${PLUGIN_DIR}/context/"
DRY_RUN=false
[[ "${1:-}" == "--dry" ]] && DRY_RUN=true

if $DRY_RUN; then
  echo "Changes that would be synced from aise-assistant/context/:"
  rsync -av --dry-run --delete "$SOURCE" "$DEST"
  exit 0
fi

rsync -a --delete "$SOURCE" "$DEST"

cd "$PLUGIN_DIR"
if git diff --quiet context/; then
  echo "context/ already up to date"
else
  echo "context/ updated — run git add context/ to stage"
fi
