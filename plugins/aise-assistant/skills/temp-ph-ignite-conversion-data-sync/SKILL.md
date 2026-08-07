---
name: temp-ph-ignite-conversion-data-sync
description: >
  Bulk-sync Spark rollout data from a weekly CSV export into Planhat Company records.
  Matches all rows by Salesforce ID → sourceId, validates data, then writes 7 Spark
  fields per account. Covers the full AISE book of business or a scoped subset.
---

Sync Spark rollout data from a CSV into Planhat. The user will either attach the CSV
or name a recently uploaded file. Run the steps below in order.

## Args

- `file` (optional) — path or name of the CSV file. If omitted, use the most recently
  uploaded file in the conversation.
- `--dry-run` (optional) — validate and report what would be written, but do not call
  `update_model_record`. Useful for spot-checking before committing.
- `--accounts <name,...>` (optional) — comma-separated account names to limit the sync
  to a subset. If omitted, process all rows in the CSV.

---

## Phase 1 — Parse and validate the CSV

Read the CSV (uploaded file or path provided). Extract the following columns for each row:

| CSV column | Required? |
|---|---|
| `Salesforce ID` | Yes — match key |
| `AI consent` | Yes |
| `Enabled` | Yes (`Yes` / `No`) |
| `Enabled date` | No (ISO date or blank) |
| `Activated visibility` | No (`Everyone` / `Admins only` / `Mixed` / `Off` / blank) |
| `Activated visibility date` | No (ISO date or blank) |
| `Engaged` | Yes (`Yes` / `No` / blank → treat blank as No) |
| `Engaged date` | No (ISO date or blank) |

**Pre-flight checks — flag and skip any row that fails:**
- `Salesforce ID` is blank or malformed (must start with `001` or `0015G`)
- `Enabled` is not `Yes` or `No`
- Any date field is present but not parseable as YYYY-MM-DD

If `--accounts` is provided, filter to only those rows (case-insensitive name match against the `Account` column).

Report: total rows, rows passing validation, rows skipped with reasons.

---

## Phase 2 — Match all Salesforce IDs to Planhat companies

For each validated row, call `list_model_records` filtered by `sourceId`:

```
MODEL: Company
FILTER: { "sourceId[equal to]": "<salesforce_id>" }
SELECT: ["name", "sourceId"]
```

Run all lookups in parallel (batch the tool calls together).

**Match rules:**
- Exactly 1 result → use `_id` for the update
- 0 results → flag as unmatched, skip
- 2+ results → flag as ambiguous, skip

Report: N matched, N unmatched (list them), N ambiguous (list them). Do not proceed if
more than 20% of rows are unmatched — ask the user to investigate before continuing.

---

## Phase 3 — Build the update payload for each matched account

Map CSV values to Planhat field IDs:

| CSV column | Planhat field ID | Type | Conversion |
|---|---|---|---|
| `AI consent` | `custom.⚡️ AI Consent` | text | pass through verbatim |
| `Enabled` | `custom.⚡️ Spark Enabled` | boolean | `Yes` → `true`, `No` → `false` |
| `Enabled date` | `custom.⚡️ Spark Enabled Date` | date | ISO string or omit if blank |
| `Activated visibility` | `custom.Spark Stage` | list | see mapping below; omit if blank |
| `Activated visibility date` | `custom.⚡️ Spark Active For Since` | date | ISO string or omit if blank |
| `Engaged` | `custom.⚡️ Spark Engaged` | boolean | `Yes` → `true`, `No`/blank → `false` |
| `Engaged date` | `custom.⚡️ Spark Engaged Date` | date | ISO string or omit if blank |

**Spark Stage value mapping (CSV → Planhat):**

| CSV value | Planhat option |
|---|---|
| `Everyone` | `Everyone` |
| `Admins only` | `Admins only` |
| `Mixed` | `Mixed` |
| `Off` | `Off` |
| _(blank)_ | omit field entirely — do not write null |

**Do NOT touch** `custom.⚡️ Igniting?` — this is managed manually by AISE and must
never be overwritten by this skill.

**Omit vs null:** for date fields and Spark Stage, omit the key entirely when the CSV
value is blank. Do not send `null`. For boolean fields, always include the value
(`true` or `false`).

---

## Phase 4 — Write to Planhat

If `--dry-run` is set: print a table of what would be written per account and stop.

Otherwise, call `update_model_record` for each matched account. Run all updates in
parallel (batch the tool calls together — do not serialize):

```
MODEL: Company
OBJECT_ID: <planhat _id>
PARAMETERS: { <field_id>: <value>, ... }
SELECT: ["name", "custom.⚡️ AI Consent", "custom.⚡️ Spark Enabled",
         "custom.⚡️ Spark Enabled Date", "custom.⚡️ Spark Engaged",
         "custom.⚡️ Spark Engaged Date", "custom.⚡️ Spark Active For Since"]
```

Note: `custom.Spark Stage` (list field) will not appear in the SELECT response even
when successfully written — this is a known Planhat API behavior. Treat a successful
HTTP response as confirmation.

---

## Phase 5 — Report results

Print a summary table:

```
| Account | Spark Enabled | Spark Stage | Engaged | Result |
|---|---|---|---|---|
| SAP SE | true | Everyone | true | ✅ written |
| Qonto | false | — | false | ✅ written |
| Acme Corp | — | — | — | ⚠️ unmatched (no sourceId) |
```

Then print totals:
- ✅ Written: N accounts
- ⚠️ Skipped: N accounts (list with reason)
- ❌ Errors: N (list with error message)

If any accounts were skipped or errored, ask the user whether to investigate or move on.
