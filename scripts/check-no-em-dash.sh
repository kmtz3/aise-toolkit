#!/usr/bin/env bash
# Fails if any tracked text file contains an em dash (U+2014).
# House rule: every dash is a spaced en dash ( – ).
#
# Usage:
#   bash scripts/check-no-em-dash.sh            # scan every tracked file
#   bash scripts/check-no-em-dash.sh --staged   # scan only files staged for commit (pre-commit hook)
#   bash scripts/check-no-em-dash.sh --fix      # rewrite offending files in place, then report
#
# The one allowlisted string is the Spark in Practice calendar title, a reporting key
# owned by that initiative (see plugins/aise-assistant/context/initiatives/spark-in-practice.md).

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

MODE="${1:-all}"
if [ "$MODE" = "--staged" ]; then
  FILES=$(git diff --cached --name-only --diff-filter=ACMR)
else
  FILES=$(git ls-files)
fi

[ -z "$FILES" ] && exit 0

printf '%s\n' "$FILES" | python3 -I -c '
import re, sys
fix = sys.argv[1] == "--fix"
EM = chr(0x2014)
EN = chr(0x2013)
KEEP = "Spark in Practice " + EM + " [Account] " + chr(0xd7) + " Productboard"
TOKEN = "\x00KEEP\x00"
between = re.compile(r"(?<=[^\s`\"\x27|(\[])[ \t]*" + EM + r"[ \t]*(?=[^\s`\"\x27|)\]])")
hits = 0
for path in sys.stdin.read().splitlines():
    try:
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
    except (UnicodeDecodeError, IsADirectoryError, FileNotFoundError):
        continue
    if EM not in text.replace(KEEP, ""):
        continue
    if fix:
        t = text.replace(KEEP, TOKEN)
        t = between.sub(" " + EN + " ", t).replace(EM, EN).replace(TOKEN, KEEP)
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(t)
        print(f"fixed: {path}")
        continue
    for n, line in enumerate(text.splitlines(), 1):
        if EM in line.replace(KEEP, ""):
            hits += 1
            print(f"{path}:{n}: {line.strip()[:160]}")
if hits:
    print(f"\n{hits} line(s) with an em dash. House rule: use a spaced en dash ( " + EN + " ).")
    print("Auto-fix: bash scripts/check-no-em-dash.sh --fix")
    sys.exit(1)
' "$MODE"
