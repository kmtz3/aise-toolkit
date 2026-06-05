---
name: temp-api-migration-usage-report
description: >
  TEMPORARY — Generate a customer-facing PDF report of their Productboard API v1 usage
  from a Looker CSV export, ahead of the API v1 sunset on 2026-07-08. Grouped resource
  table, callout blocks, and a "Where to focus" narrative that identifies integration type
  (CRM / hierarchy / feedback / generic). Delete this skill after the sunset date.
---

Generate an API v1 usage report PDF from a Looker CSV export.

## Args

- `csv_path` (required) — path to the Looker CSV export, OR a directory/glob of CSVs for bulk mode.
- `customer` (optional) — customer name for the report title and output filename. If not provided, infer from a `customer` column in the CSV or from the CSV filename (e.g. `ardoq-v1-usage.csv` → "Ardoq"). Ask once if unresolvable; never invent one.
- `period` (optional) — reporting period label. Defaults to "last 30 days (through <max timestamp in data>)".
- `subdomain` (optional) — Productboard workspace subdomain (used in the "API keys" callout link). Defaults to `<customer-slug>` placeholder if not provided.

## Procedure

1. **Detect Cowork vs. CLI environment** — check if `~/Desktop` is writable. If not, this is a Cowork run (write to the current working directory `outputs/` subfolder instead and present the file in chat). Otherwise, write to `~/Desktop/aise-assistant/reports/<customer>/`.

2. **Install WeasyPrint** if not already available:
   ```bash
   pip install weasyprint --break-system-packages --quiet 2>/dev/null || true
   export PATH="$HOME/.local/bin:$PATH"
   ```

3. **Run the report generator** via Bash:
   ```bash
   export PATH="$HOME/.local/bin:$PATH"
   SCRIPT=$(find /sessions -path "*/temp-api-migration-usage-report/scripts/generate_report.py" 2>/dev/null | head -1)
   if [ -z "$SCRIPT" ]; then echo "ERROR: generate_report.py not found"; exit 1; fi
   python3 "$SCRIPT" \
     --csv "<csv_path>" \
     --customer "<customer>" \
     [--period "<period>"] \
     [--subdomain "<subdomain>"] \
     --out-dir "<resolved_output_dir>"
   ```
   The script prints the output PDF path (or a JSON summary table in bulk mode) to stdout.

   _Note: In the Cowork bash sandbox, the skill script lives under `.remote-plugins/<plugin_id>/skills/…`, not under `.claude/skills/`. Always discover it via `find` rather than deriving the path from the base directory shown in the skill header._

4. **Present the result** — for single-file output, confirm the PDF path. For bulk mode, print the per-file summary table returned by the script (customer, total v1 requests, # active endpoints, top endpoint + %, inferred integration type, output path or "skipped — reason").

5. **Cowork** — if running in Cowork, use the file-presentation tool to surface the PDF as a download after writing it to the outputs folder.

## Bulk mode

Pass multiple CSV paths separated by spaces, or a directory path (all `*.csv` files within it), or a glob pattern. The script runs the full pipeline once per file, produces one PDF per file, skips bad/unidentifiable files without aborting, and prints a summary table at the end.

**Customer identification order (per file):** (1) explicit `--customer` mapping, (2) `customer` column in the CSV, (3) customer name embedded in the CSV filename. If none resolves, the file is skipped with a note.

## Output paths

| Environment | Path |
|---|---|
| Claude Code / terminal | `~/Desktop/aise-assistant/reports/<customer>/<customer>-API-v1-usage-report.pdf` |
| Cowork (no Desktop access) | `./outputs/<customer>-API-v1-usage-report.pdf` (+ presented in chat) |
| Cowork with explicit Desktop ask | User-selected folder via `osascript` file picker |

## Examples

```
/temp-api-migration-usage-report csv_path=~/Downloads/ardoq-v1-usage.csv
/temp-api-migration-usage-report csv_path=~/Downloads/acme-api-logs.csv customer="Acme Corp"
/temp-api-migration-usage-report csv_path=~/Downloads/api-exports/ (bulk — all CSVs in folder)
```
