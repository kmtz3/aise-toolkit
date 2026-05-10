---
name: notion-sync
description: Push external data into Notion Active Packages and related records. Three modes via required flag: --sf (Salesforce ARR + contract dates), --owner (propagate Customer.Owner to Sessions/Tasks/Packages), --renewals (flag packages ending soon as Status=Renewal).
---

Sync external data into Notion. A mode flag is required:

- **`/notion-sync --sf`** — Salesforce → Active Packages (ARR + contract end dates)
- **`/notion-sync --owner`** — Customer.Owner → Sessions, Tasks, Active Packages (drift repair)
- **`/notion-sync --renewals`** — Flag Active Packages ending soon with Status = Renewal

If no mode flag is given, list the three modes with a one-line description of each and ask which to run.

---

## `--sf` — Salesforce sync

Read the procedure in `agents/sf-backfill.md` and execute it inline — do not spawn a subagent.

**What it does:** For each Active Package, queries Salesforce (open renewal opps + recent closed opps) and syncs ARR (ACV) and contract end date. Classifies each account: rollover needed / ARR fill / end-date update / already in sync / skip / flag. Presents the full change list and waits for approval before writing (unless `--apply` is passed).

**Flags:**
- `--customer <name>` — run for a single customer instead of all active packages
- `--owner <name>` — run for a specific user's packages instead of your own (always confirms before proceeding)
- `--apply` — skip the approval gate and write immediately

Do NOT ask the user for Salesforce data — query Salesforce directly via the SF MCP. Do NOT touch churned or at-risk accounts.

---

## `--owner` — owner propagation

Execute the steps below inline (do not spawn a subagent).

**What it does:** Pushes `Customer.Owner` down to all linked Sessions, Tasks, and Active Packages where `Current Account Owner` has drifted. Reports totals scanned / drifted / updated.

### Steps

**1. Resolve identity** (skip for `--global`). Follow the Identity resolution procedure in `context/notion-schema.md` § Identity resolution. Extract `notion_user_id` as `<user-uuid>`. Fallback: call `notion-get-users` with the user's email and use the `id` from the first match.

**2. Determine scope.**
- `--mine` / `--me` (default): `WHERE Owner LIKE '%<user-uuid>%'`
- `--global`: no owner filter. Warn and ask for confirmation unless `--no-confirm` is also passed.

**3. Query Customers DB** (`collection://29397e9c-7d4f-8067-b290-000b1c2d57e1`):
```sql
SELECT id, Customer, Owner
FROM "collection://29397e9c-7d4f-8067-b290-000b1c2d57e1"
[WHERE Owner LIKE '%<user-uuid>%']
LIMIT 200
```
Build a map: `{ customer_page_id → owner_uuids[] }`. The `Owner` field stores values as `["user://uuid1", ...]` — strip the `user://` prefix to get bare UUIDs.

**4. Query descendant DBs** in sequence with a 400 ms sleep between calls. For each customer: strip hyphens from `customer_page_id` to get `<customer-url-id>`; use the bare owner UUID as `<owner-uuid>`.

- **Sessions** (`collection://29397e9c-7d4f-8052-886b-000b9e3479d7`):
  ```sql
  SELECT id, Name, Customers, "Current Account Owner"
  FROM "collection://29397e9c-7d4f-8052-886b-000b9e3479d7"
  WHERE Customers LIKE '%<customer-url-id>%'
    AND ("Current Account Owner" NOT LIKE '%<owner-uuid>%' OR "Current Account Owner" IS NULL)
  LIMIT 500
  ```
- **Tasks** (`collection://29397e9c-7d4f-808f-bcd4-000b66a94678`):
  ```sql
  SELECT id, Task, Customers, "Current Account Owner"
  FROM "collection://29397e9c-7d4f-808f-bcd4-000b66a94678"
  WHERE Customers LIKE '%<customer-url-id>%'
    AND ("Current Account Owner" NOT LIKE '%<owner-uuid>%' OR "Current Account Owner" IS NULL)
  LIMIT 500
  ```
- **Active Packages** (`collection://29697e9c-7d4f-8031-9f76-000b7e932b36`):
  ```sql
  SELECT id, Name, Customer, "Current Account Owner"
  FROM "collection://29697e9c-7d4f-8031-9f76-000b7e932b36"
  WHERE Customer LIKE '%<customer-url-id>%'
    AND ("Current Account Owner" NOT LIKE '%<owner-uuid>%' OR "Current Account Owner" IS NULL)
  LIMIT 300
  ```
  Note: field is `Customer` (singular).

**5. Update drifted records.** Every record returned by step 4 is drifted by construction. For each, call `notion-update-page`:
```
command: update_properties
properties: { "Current Account Owner": "[\"<uuid1>\",\"<uuid2>\"]" }
content_updates: []
```
Write format: JSON-stringified array of bare UUIDs (no `user://` prefix). Sleep 380 ms between each write.

**6. Report in chat:** records scanned per DB, records with drift, records updated, any write failures.

**Notes:**
- Person fields (`Owner`, `Current Account Owner`): use `LIKE '%<bare-uuid>%'` — the bare UUID substring matches the stored `user://uuid` form.
- Relation fields (`Customers`, `Customer`): store Notion page URLs without hyphens. Strip hyphens from customer page IDs before building LIKE patterns.
- Contacts have no `Current Account Owner` — exclude them.
- Safe to re-run; only writes where drift exists.

**Flags:**
- `--mine` / `--me` — scope to the current user's customers (default)
- `--global` — scan all customers; asks for confirmation unless `--no-confirm` is also passed

---

## `--renewals` — flag upcoming renewals

Execute the steps below inline (do not spawn a subagent).

**What it does:** Finds Active Packages with `End Date` within N days (default 90) where `Status` is not already `Renewal` or `Package Expired`, then sets `Status = Renewal`.

### Steps

**1. Resolve identity** (skip for `--global`). Follow the Identity resolution procedure in `context/notion-schema.md` § Identity resolution. Extract `notion_user_id` as `<user-uuid>`.

**2. Determine scope and parameters.**
- `--mine` (default): filter `Current Account Owner LIKE '%<user-uuid>%'`
- `--global`: no owner filter. Warn and ask for confirmation unless `--no-confirm` is also passed.
- `--days N`: flag packages ending within N days (default: 90)
- `--dry-run`: preview only — report what would change without writing anything

Compute `<today>` (YYYY-MM-DD) and `<cutoff>` (`<today>` + N days).

**3. Query Active Packages** (`collection://29697e9c-7d4f-8031-9f76-000b7e932b36`):
```sql
-- For --mine:
SELECT id, Name, Status, "date:End Date:start", "Current Account Owner"
FROM "collection://29697e9c-7d4f-8031-9f76-000b7e932b36"
WHERE "Active?" = '__YES__'
  AND "date:End Date:start" IS NOT NULL
  AND "date:End Date:start" > '<today>'
  AND "date:End Date:start" <= '<cutoff>'
  AND Status != 'Renewal'
  AND Status != 'Package Expired'
  AND "Current Account Owner" LIKE '%<user-uuid>%'
LIMIT 500

-- For --global (omit owner filter):
SELECT id, Name, Status, "date:End Date:start", "Current Account Owner"
FROM "collection://29697e9c-7d4f-8031-9f76-000b7e932b36"
WHERE "Active?" = '__YES__'
  AND "date:End Date:start" IS NOT NULL
  AND "date:End Date:start" > '<today>'
  AND "date:End Date:start" <= '<cutoff>'
  AND Status != 'Renewal'
  AND Status != 'Package Expired'
LIMIT 500
```

**4. If `--dry-run`:** report the list of packages that would be updated (name, end date, days remaining). Stop here.

**5. Otherwise, update each matching package.** Call `notion-update-page`:
```
command: update_properties
properties: { "Status": "Renewal" }
content_updates: []
```
Sleep 380 ms between each write.

**6. Report in chat:** packages updated (name, end date, days remaining), any write failures.

**Notes:**
- `Status` is a Notion status type — write as a plain string: `"Renewal"`.
- Valid `Status` values: `Not started`, `Renewal`, `Preparing`, `Activating`, `Adopting`, `Package Expired`, `Service Quota Used`.
- Do not flag packages with `Status = Package Expired`.
- `date:End Date:start` is the SQL column name; its value is a `YYYY-MM-DD` string.

**Flags:**
- `--mine` — scope to the current user's packages (default)
- `--global` — scan all active packages; asks for confirmation unless `--no-confirm` is also passed
- `--days N` — flag packages ending within N days (default: 90)
- `--dry-run` — preview without writing
