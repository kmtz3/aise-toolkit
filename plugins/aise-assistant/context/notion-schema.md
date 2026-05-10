# Customer Tracker — Notion Schema

> **Source of truth**: This file. Keep it current by querying the live Notion DBs directly when drift is suspected, then update via the `context-keeper` agent.

---

## Mental Model

Six databases. One hub.

- **Customers** — the account. Everything hangs off it.
- **Master Packages** — the SKU/template (e.g. "Essential Services — 10 architecting sessions"). Source of truth for allocation.
- **Active Packages** — the live instance of a Master Package for a specific customer + engagement. Dates, ARR, and the credit ledger formulas live here.
- **Sessions** — a delivered call. Burns credit from exactly one Active Package.
- **Tasks** — an action item. Can also burn credit from an Active Package.
- **Contacts** — people at customer accounts. Attend sessions, own tasks.

Ledger flow: **Session** (or Task) → `Consumed Package` → **Active Package** → formulas calculate burn → rolls up to **Customer** via `All packages` rollup and `Current package` formula (Formulas 2.0).

`Do not count` checkbox on Sessions/Tasks excludes from burn calculations (kickoffs, internal sessions, prep pages, etc.).

**Package units — sessions only** (since Apr 2026). Hours-based packages were converted at `1 session ≈ 2.5 hours`. `Session Length (h)` still captures actual call duration for fractional burn (a 2.5h session = 1.0 unit, a 1h office hour ≈ 0.4 units). The legacy `Unit` rollup still exists but no longer drives logic — ignore.

---

## Ownership Model (May 2026 revamp)

The Customer Tracker is a **shared workspace** with other PB AISEs. Two complementary Person fields express ownership:

- **`Owner`** — lives on **Customers** and **Tasks** only.
  - On a Customer page: the canonical AISE(s) responsible for the account. Source of truth.
  - On a Task: the creator (defaults to whoever logged the task). Used to distinguish "tasks I created" from "tasks on accounts I now own but didn't create" during handoffs.
- **`Current Account Owner`** — lives on **Active Packages**, **Sessions**, **Tasks**.
  - Auto-mirrors the linked `Customer.Owner` value. Maintained two ways:
    1. **`Resync Owner to descendants`** button on every Customer page — one click after editing `Customer.Owner` propagates the new value to all linked Active Packages, Sessions, and Tasks.
    2. **Sessions-side automation** — when a Session's `Customers` relation is set or changed on create, `Current Account Owner` auto-fills from the linked `Customer.Owner`.
  - Treat as **read-only** in agent logic — write only if explicitly correcting drift, otherwise rely on the propagation mechanism.

**Sessions also have `Delivered By`** (Person, multi) — the actual presenter(s) of the session. Distinct from `Current Account Owner` to support stand-in deliveries (the user presents on someone else's account, or vice versa). Reporting use cases: "sessions I delivered" vs "sessions on my accounts" vs "sessions I delivered for someone else."

**Active Packages have `Delivered By (Sessions)`** — a **rollup** showing unique presenters across linked Sessions, computed automatically. Cannot be written.

**User's Notion ID**: see `about/identity.md` → `notion_user_id`. All filter examples below use `<user-uuid>` as a placeholder; substitute the value from `about/identity.md` at runtime.

### Identity resolution procedure

Agents and skills that need `<user-uuid>` at runtime must locate `about/identity.md` and read `notion_user_id`. Try in order:

1. **Pointer file (fastest):** `PLUGIN_DATA_DIR=$(cat "$HOME/.claude/aise-assistant.datadir")` → read `$PLUGIN_DATA_DIR/about/identity.md`.
2. **Glob fallback:** search for `about/identity.md` under known macOS plugin data directories:
   - `~/Library/Application Support/Claude/local-agent-mode-sessions/*/rpm/plugin_*/about/identity.md`
   - `/var/folders/**/aise-assistant*/about/identity.md`
3. **Notion lookup:** call `notion-get-users` and match against the userEmail `klara.martinez@productboard.com` (available in system context) to retrieve the Notion user ID.

**If all three fail:** surface this message inline and stop — do not attempt a Notion query with a missing filter:
> ⚠️ Identity not set up — run `/assistant-setup` first, or use `--global` to scan all packages.

**Conditional skip:** when a skill's scope is `--global` (no owner filter needed), skip identity resolution entirely — do not attempt the file lookup.

---

## Database IDs

| Database | Data Source ID |
|---|---|
| Customers | `29397e9c-7d4f-8067-b290-000b1c2d57e1` |
| Sessions | `29397e9c-7d4f-8052-886b-000b9e3479d7` |
| Tasks | `29397e9c-7d4f-808f-bcd4-000b66a94678` |
| Active Packages | `29697e9c-7d4f-8031-9f76-000b7e932b36` |
| Master Packages | `29397e9c-7d4f-8079-b9d6-000bd95ee92f` |
| Contacts | `29497e9c-7d4f-80be-b224-000bbec4980b` |
| Figma Files | `29497e9c-7d4f-80ab-b37f-000bbe6452ba` |

For SQL: `"collection://<id>"` as the table name.

---

## Field Formats

**Dates** — always three separate properties:
```
"date:Call Date:start": "2026-04-16"
"date:Call Date:end": null          # omit for single date
"date:Call Date:is_datetime": 0     # 0 = date only, 1 = datetime
```

**Checkboxes** — `"__YES__"` / `"__NO__"`.

**Multi-select** — JSON array string: `'["Fintech"]'` or `'["B2B", "Fintech"]'`.

**Title on Customers** — property name is `Customer`, not `Name`.

**Title on Tasks** — property name is `Task`.

**URL/ID properties** — prefix with `userDefined:` e.g. `"userDefined:URL"`, `"userDefined:id"`.

**Numbers** — JS numbers, not strings: `"ARR": 47000`.

**Relations** — JSON array of full Notion page URLs, even for single-relation (limit 1) fields:
```
"Customers": "[\"https://www.notion.so/34397e9c7d4f81d5b343c52ae5651ccc\"]"
```

**Person (`Owner`, `Current Account Owner`, `Delivered By`)** — JSON array of user IDs on **write**, but Notion stores them with a `user://` prefix on **read**.
```
write: "Owner": "[\"<user-uuid>\"]"
read:  "Owner": "[\"user://<user-uuid>\"]"
```
Filter queries with `<field> LIKE '%<bare-uuid>%'` so they match the stored form.

---

## Common Operations

### Create a Session
- Parent: `data_source_id: 29397e9c-7d4f-8052-886b-000b9e3479d7`
- Required: `Name`, `Call Status`, `Type`, `date:Call Date:start`, `date:Call Date:is_datetime`
- Set `Customers` and `Consumed Package` relations on create (works in one call)
- **`Current Account Owner`** — leave blank on create. The Sessions-side automation fills it from `Customers.Owner` automatically.
- **`Delivered By`** — set to the actual presenter(s). For the user's own sessions: `["<user-uuid>"]`. For backfilled historical sessions: the predecessor AISE's user ID if resolvable, otherwise leave blank and flag.
- Types: `🏗️ Architecting`, `🗣️ Sync`, `🎓 Training`, `👟 Kick off`, `🔎 Discovery`, `📦 Other`
- Statuses: `Not started`, `Planned`, `Postponed`, `In progress`, `Post-session debrief`, `Delivered`, `Canceled`

### Session Templates

After creating a new Session page, immediately apply the matching Notion template using `notion-update-page` with `command: apply_template`. This gives the page its structural skeleton (Prep toggle, Agenda, type-specific sections, Decisions, Risks, Action Items, Next Steps) without hardcoding structure in agent files — update the template in Notion and all new sessions pick it up automatically.

| Type | Template page ID |
|---|---|
| 🏗️ Architecting | `29497e9c7d4f809c9ee4f29679854d8f` |
| 🗣️ Sync | `29497e9c7d4f8019a678e9a9a7482ce1` |
| 🎓 Training | `29497e9c7d4f8027826af32d3597b0c1` |
| 👟 Kick off | `29897e9c7d4f80ceafc0e320d63053a0` |
| 🔎 Discovery | `29897e9c7d4f8085b4ddd3bff36a0fab` |
| 📦 Other | `29497e9c7d4f8003b857eb2014893410` |

**Rules:**
- Apply only on **initial create** — the page must be empty (freshly created). The dedup check ensures existing session pages never reach this step.
- `apply_template` appends — calling it on an empty page makes the template content the page's starting structure.
- After applying, write prep briefs or summaries **inside the existing `📋 Prep — [date]` toggle** (placed by the template) rather than creating a new toggle.

### Create an Active Package
- Parent: `data_source_id: 29697e9c-7d4f-8031-9f76-000b7e932b36`
- Set `Customer` and `Master Package` (limit 1) on create. `Customer` is the **sole** customer relation — always set, never cleared.
- On expiry (flipping `Active?` = `__NO__` / Status = `Package Expired`): no relation fields need clearing. The `Current package` formula on the Customer page stops surfacing the package automatically once `Active? = __NO__`.
- `Active?` = `__YES__` for current live package
- **`Current Account Owner`** — set to the current user on create (`["<user-uuid>"]`). The Resync button on the Customer page keeps this in sync afterwards, but on initial create the button hasn't fired, so set it explicitly.
- `Status` options: `Not started`, `Renewal`, `Preparing`, `Activating`, `Adopting`, `Package Expired`, `Service Quota Used`
- **`Status = Service Quota Used` ≠ inactive.** It means all contracted architecting and training sessions are exhausted. The customer retains AISE ownership; recurring syncs and QBRs continue. No new architecting or training unless they purchase more. When you see `Status = Service Quota Used` with `Active? = YES`, treat as **post-services / sync-rhythm** mode, not wind-down. Do not flag this as a contradiction unless the package is also `Active? = NO` and there's no upcoming sync cadence. **`Package Expired` is the only true terminal state** — contract end date passed; flip `Active? = NO`.
- **Apply template after create:** immediately after `notion-create-pages`, call `notion-update-page` with `command: apply_template, template_id: 29697e9c7d4f806fb251df6f1d20bf88`. This places three structural toggles on the page (see § Active Package Template below).

### Active Package Template

After creating a new Active Package page, immediately apply the template using `notion-update-page` with `command: apply_template`. This places three structural toggles without hardcoding them in agent files — update the template in Notion and all new Active Packages pick it up automatically.

**Template ID:** `29697e9c7d4f806fb251df6f1d20bf88`

| Toggle | Purpose |
|---|---|
| `🗺️ Program Plan` | Placeholder; `engagement-planner` writes the full dated plan as a child toggle inside this section |
| `🧠 Working Notes` | Operational memory with Program state / Open risks / Terminology / Discoveries sub-sections; updated after every session |
| `📋 Account History` | `account-setup` writes here for inherited accounts; blank for new accounts |

**Rules:**
- Apply only on **initial create** — the page must be empty (freshly created).
- `apply_template` appends — calling it on an empty page makes the template content the page's starting structure.
- Write into the relevant toggle using `update_content` rather than appending new toggles. For **Working Notes**: update only the changed sub-section. For **Program Plan**: add the dated plan as a child toggle inside `🗺️ Program Plan`. For **Account History**: write the summary inside `📋 Account History`.
- On legacy pages without the template structure, create the missing toggle(s) on first write.

### Create a Task (PB-side actions only)
- Parent: `data_source_id: 29397e9c-7d4f-808f-bcd4-000b66a94678`
- Title property is `Task`
- **Set `Customers` relation — never leave null.** For customer-tied tasks, use the relevant Customer page URL. For **internal / non-customer-specific tasks** (team admin, training, internal research, tooling work), use the **Productboard** customer record: `https://app.notion.com/29997e9c7d4f80e6a011f053bdec1ab5`. The pivot-through-Customer filter pattern relies on this — null Customers means the task disappears from filtered views.
- **Set `Owner`** to the creator (the current user when they are the one logging it: `["<user-uuid>"]`). On a shared workspace, `Owner` is the "who created this task" signal — distinguishes the user's own tasks from inherited ones during handoffs.
- **Set `Current Account Owner`** to the current user explicitly on create. The Resync button propagates afterwards but on initial create it hasn't fired yet.
- **Set `Consumed Package`** using the same date-matching rule as Sessions: (1) if the task has a `Source Call`, inherit that session's `Consumed Package` directly; (2) otherwise, find the customer's Active Package whose `Start Date` ≤ today ≤ `End Date`; (3) if no package covers today, use the most-recently-ended inactive package for the same customer; (4) if nothing matches, leave empty. Never assign by recency alone.
- **Never create Tasks for customer-side actions** — those belong in summaries/follow-ups only.
- `Priority`: `1`, `2`, or `3`

### Query Active Package for a customer
```sql
-- All packages (history + current)
SELECT * FROM "collection://29697e9c-7d4f-8031-9f76-000b7e932b36"
WHERE "Customer" LIKE '%[customer-page-id]%'

-- Current live package only: add Active? flag
SELECT * FROM "collection://29697e9c-7d4f-8031-9f76-000b7e932b36"
WHERE "Customer" LIKE '%[customer-page-id]%'
  AND "Active?" = '__YES__'
```

### Query all sessions for a customer
```sql
SELECT Name, "Call Status", Type, "date:Call Date:start", "Do not count"
FROM "collection://29397e9c-7d4f-8052-886b-000b9e3479d7"
WHERE Customers LIKE '%[customer-page-id]%'
ORDER BY "date:Call Date:start" ASC
```

### Query the user's customers (canonical Owner field)
```sql
SELECT * FROM "collection://29397e9c-7d4f-8067-b290-000b1c2d57e1"
WHERE Owner LIKE '%<user-uuid>%'
```

### Query the user's active packages
```sql
SELECT * FROM "collection://29697e9c-7d4f-8031-9f76-000b7e932b36"
WHERE "Current Account Owner" LIKE '%<user-uuid>%'
  AND "Active?" = '__YES__'
```

### Query the user's sessions
Two complementary axes — the OR pattern catches both "sessions on my accounts" and "sessions I delivered for someone else":
```sql
SELECT * FROM "collection://29397e9c-7d4f-8052-886b-000b9e3479d7"
WHERE "Current Account Owner" LIKE '%<user-uuid>%'
   OR "Delivered By" LIKE '%<user-uuid>%'
```
Use just `Current Account Owner` if you only want sessions on accounts the user currently owns. Use just `Delivered By` for "sessions the user presented" reporting (regardless of who owns the account now).

### Query the user's tasks
Same OR pattern — `Owner` (creator) OR `Current Account Owner` (account ownership):
```sql
SELECT * FROM "collection://29397e9c-7d4f-808f-bcd4-000b66a94678"
WHERE Owner LIKE '%<user-uuid>%'
   OR "Current Account Owner" LIKE '%<user-uuid>%'
```
Use just `Owner` for "tasks I logged" (the creator-only filter). Use just `Current Account Owner` for "tasks on my accounts regardless of who created them" (catches inherited tasks).

### Customer Template

**Template ID:** `29397e9c7d4f8005b04bef3858ece3e0` (named "New Customer" in Notion)

Customer pages are created by the `account-setup` agent (via `notion-create-pages`) or by users via the Notion UI. Either way, the template is applied on initial create to give the page its icon and pre-populate the body sections.

**On agent create:** immediately after `notion-create-pages`, apply the template:
```
notion-update-page(
  page_id: <new customer page id>,
  command: apply_template,
  template_id: 29397e9c7d4f8005b04bef3858ece3e0
)
```
Then **fetch the page back** (`notion-fetch`) to discover the actual section headings the template created. Use those fetched headings as `old_str` anchors for subsequent `update_content` writes.

**Do not hardcode section names.** The template owner may change sections at any time. Always read section structure from the live page — never assume fixed headings. Map discovered H2 headings to research content by heading text and emoji (see `agents/account-setup.md` § Company Research sub-procedure for the mapping heuristic).

**Write pattern:**
```
old_str: "<exact heading + placeholder text as fetched from the page>"
new_str: "<heading + populated content>"
```
Fetch the page immediately before writing — `update_content` is whitespace-exact and a stale anchor will fail.

**Skip `apply_template` if the page already existed.** Existing pages have content; applying the template again appends and corrupts the layout.

---

## Customers — Field Reference

### Writable fields

| Field | Type | Valid values / notes |
|---|---|---|
| `Customer` | title | Account name |
| `Account Status` | status | **To-do:** `Not started`, `Presales` · **In progress:** `Active (no Services)`, `Active (Services)` · **Complete:** `Contracted to Scale`, `Churned` |
| `Health (Manual)` | select | `Figuring it out`, `Healthy`, `Concerning`, `Churning` |
| `Priority` | select | `P0`, `P1`, `P2`, `P3`, `P4`, `Insufficient Data` |
| `Preferred Conferencing` | select | `Zoom`, `MS Teams`, `Google Meet` |
| `AI Ready` | select | `Sparked`, `Preparing`, `Ignitable`, `Not ready` |
| `Industry` | multi-select | `Digital Consumer Intelligence`, `Social Media Management`, `Fintech`, `eCommerce`, `Digital Commerce Technology`, `B2B`, `Automotive`, `Healthcare`, `Insurance`, `eSports` |
| `Renewal Forecast` | select | `Likely to Renew`, `Risk to Renewal`, `Churning – No save`, `Churning – Ignitable` |
| `Owner` | person (multi) | The PB owner(s) of this account. **Authoritative ownership signal — source of truth.** Editing this field triggers the Resync button workflow that propagates to `Current Account Owner` on linked Active Packages, Sessions, Tasks. Multi-allowed for handoff windows. |
| `Account Executive` | person (multi) | The AE assigned to this account. |
| `Renewal Manager` | person (multi) | The renewal manager for this account. |
| `SFDC` | url | Salesforce account URL |
| `Slack Channel` | url | Customer Slack channel URL |
| `Domain` | url | Customer domain |
| `Main Contact` | relation (limit 1) | → Contacts DB |
| `Contacts` | relation | → Contacts DB |
| `Calls` | relation | → Sessions DB (back-relation — auto-updated when Sessions.Customers is set) |
| `Tasks` | relation | → Tasks DB (back-relation — auto-updated when Tasks.Customers is set) |
| `Figma File` | relation | → Figma Files DB (`29497e9c-7d4f-80ab-b37f-000bbe6452ba`) |
| `Packages` | relation | → Master Packages DB |
| `Files & media` | file | Attachments |

**Account Status — definitions:**
- `Not started` — assigned, not yet started
- `Presales` — supporting a pre-sale or trial evaluation
- `Active (no Services)` — account live, no contracted AISE services. A special **"AISE No Services"** Active Package exists for this account, used purely to track syncs and QBRs as sessions. Do not treat this as "no package" — always create/expect an AISE No Services AP when this status is set.
- `Active (Services)` — engagement live, sessions being delivered under a contracted package
- `Contracted to Scale` — customer has contracted **below the AISE ARR threshold ($30K)**; ownership transfers to the Scale team. Remove the AISE owner from `Owner`. This is NOT a "services complete" state — it is a handover state.
- `Churned` — customer has churned; engagement fully closed

### Buttons

| Button | What it does |
|---|---|
| `🔘 Resync Owner to descendants` | Walks `Calls` (Sessions), `Tasks`, and `Active Package` relations and writes `Current Account Owner = This page.Owner` on each. Use after editing `Owner` to propagate the change. |
| `➕ Package` | Quick-creates a new Active Package linked to this customer. |
| `➕ Person` | Quick-creates a new Contact linked to this customer. |
| `➕ Session` | Quick-creates a new Session linked to this customer. |
| `➕ Task` | Quick-creates a new Task linked to this customer. |

### Read-only (rollups / formulas — never write these)

`ARR`, `Days Left`, `Days Till Renewal`, `Next Call`, `Next Call (raw)`, `Next Steps`, `Delivered`, `Counted/Real`, `Package Status`, `Start Date (Current Pkg)`, `End Date (Current Pkg)`, `∑ Architecting`, `∑ Credit`, `∑ Time`, `∑ Training`, `All packages` (rollup — all APs ever linked via the `Customer` relation on the AP side), `Current package` (formula — the AP with `Active? = YES`; first found if multiple active)

---

## Active Packages — Field Reference

### Writable fields

| Field | Type | Valid values / notes |
|---|---|---|
| `Name` | title | Format: `{Year} – {Customer Name} \| {Master Package}` e.g. `2025 – Acme Corp \| Essential Services` |
| `Customer` | relation | → Customers DB. **Sole customer relation — permanent link.** Set on create; never cleared regardless of status. Multi-value: one AP can serve multiple customers simultaneously (e.g. shared-contract accounts). Used for all customer lookups — both history and current. |
| `Master Package` | relation (limit 1) | → Master Packages DB |
| `ARR` | number | Dollar value — ACV/annual (never divide by contract length) |
| `Active?` | checkbox | `__YES__` for the current live package |
| `Status` | status | `Not started`, `Renewal`, `Preparing`, `Activating`, `Adopting`, `Package Expired`, `Service Quota Used` |
| `Start Date` / `End Date` | date | Date triples format |
| `Current Account Owner` | person (multi) | Mirror of `Customer.Owner`. Maintained by the Resync button on the Customer page. Treat as derived — set explicitly only on initial create or when correcting drift. |
| `Tasks` | relation | → Tasks DB |

**Active Package Status — behavioral notes:**
- `Renewal` — set **90 days before the contract end date** to flag an upcoming renewal. On confirmed renewal: if customer ARR remains **≥ $30K (AISE threshold)**, create a new Active Package for the new term and set the prior package `Active? = NO`. If ARR drops **below $30K**, use `Contracted to Scale` on the Customer instead. If the contract end date passes without renewal action, transition to `Package Expired`.
- `Package Expired` — the only terminal state. Set `Active? = NO`. Use when the contract lapses (not just when sessions are exhausted).
- `Service Quota Used` — all contracted sessions consumed, but AISE ownership continues. Keep `Active? = YES` if recurring syncs/QBRs are ongoing. Do not flag `Service Quota Used + Active? = YES` as a contradiction.

### Read-only formulas (never write — edit in Notion UI if needed)

`Total Credit`, `Consumed Credit`, `Balance Credit`, `Delivered`, `Total Architecting`, `Total Training`, `Left Architecting`, `Left Training`, `Left Days`, `∑ Credit`, `∑ Architecting`, `∑ Training`, `∑ Time`

### Read-only rollups (auto-computed from relations)

- `Architecting Sessions`, `Training Sessions` (from Master Package)
- `Delivered Architecting`, `Delivered Training`, `Session Time` (from Sessions)
- `Tasks Time` (from Tasks)
- **`Delivered By (Sessions)`** — unique-list rollup of `Sessions.Delivered By`. Shows everyone who has presented a Session burning credit from this Active Package. Useful for handoff narratives and "who's worked on this engagement" reporting. Cannot be written.

---

## Sessions — Field Reference

### Writable fields

| Field | Type | Valid values / notes |
|---|---|---|
| `Name` | title | Session name (typically `<Customer> — <Session ID> <Topic>` or close) |
| `Customers` | relation (limit 1) | → Customers DB |
| `Consumed Package` | relation | → Active Packages DB. Drives credit burn. **Date-matching rule:** only assign an Active Package whose `Start Date` ≤ session's `Call Date` ≤ `End Date`. If the current `Active? = YES` package does not cover the session date, look for an older inactive package for the same customer whose date range does. If no package's date range covers the session date, leave this field empty. Never assign by recency alone. |
| `Type` | select | `🏗️ Architecting`, `🗣️ Sync`, `🎓 Training`, `👟 Kick off`, `🔎 Discovery`, `📦 Other`, `🫥 Internal` |
| `Call Status` | status | **To-do:** `Not started`, `Planned`, `Postponed` · **In progress:** `In progress`, `Post-session debrief` · **Complete:** `Delivered`, `Canceled` |
| `Call Date` | date | Date triples format |
| `Session Length (h)` | number | Actual call duration in hours |
| `Do not count` | checkbox | `__YES__` excludes from credit burn (kickoffs, prep pages, internal sessions) |
| `Current Account Owner` | person (multi) | Mirror of `Customer.Owner`. Auto-filled by the Sessions-side automation when `Customers` relation is set, then maintained by the Resync button on subsequent Customer Owner edits. Treat as derived. |
| `Delivered By` | person (multi) | The actual presenter(s) for this specific session. Set explicitly on create / when marking a session Delivered. For stand-ins or co-presented sessions, list everyone. |
| `Next Steps` | rich_text | Free-form summary written into the session page during summary workflows |

### Read-only

`Active Package` (rollup from Customers), `All Tasks` (rollup), `Counted Time` (formula), `Architecting`/`Training`/`Sync`/`Discovery` (formula classifiers)

---

## Tasks — Field Reference

### Writable fields

| Field | Type | Valid values / notes |
|---|---|---|
| `Task` | title | Action item description |
| `Customers` | relation (limit 1) | → Customers DB. **Mandatory** — for internal tasks, point at the Productboard customer record at `https://app.notion.com/29997e9c7d4f80e6a011f053bdec1ab5`. |
| `Consumed Package` | relation (limit 1) | → Active Packages DB |
| `Source Call` | relation | → Sessions DB. The session that surfaced this task. |
| `Owner` | person (multi) | The **creator** of this task. Defaults to whoever logs it. Used to distinguish "I created this" from "I inherited this account." Renamed from `Assignee` in May 2026 — existing values preserved. |
| `Current Account Owner` | person (multi) | Mirror of `Customer.Owner`. Auto-propagates via the Resync button on the Customer page. Distinguishes inherited tasks (Owner ≠ Current Account Owner) from your own (Owner = Current Account Owner). |
| `Status` | status | **To-do:** `Not started` · **In progress:** `In progress` · **Complete:** `Done`, `Canceled` |
| `Priority` | select | `1`, `2`, `3` |
| `Due Date` | date | Date triples format |
| `Time (h)` | number | Time spent on the task |
| `Do not count` | checkbox | `__YES__` excludes from burn |

### Read-only

`Counted Time` (formula), `Source Session` (rollup), `Created Date`, `Last Edited`

---

## Permission Rules (Share menu, set per DB)

Each DB has Person-property-based edit rules. Multiple rules layer with an OR — the highest level applies.

| DB | Rule(s) for `Can edit` |
|---|---|
| Customers | `Owner` |
| Active Packages | `Current Account Owner` |
| Sessions | `Current Account Owner` AND `Delivered By` (both rules separately, layered with OR) |
| Tasks | `Owner` AND `Current Account Owner` (both rules separately, layered with OR) |

Workspace admins always retain full access regardless of property-rule restrictions.

---

## Known Gotchas

- **Formulas referencing other formulas can't be updated via MCP.** Any `ALTER COLUMN "X" SET FORMULA(...)` on Active Packages fields that read from another formula (Total Credit, Consumed Credit, Delivered, Balance Credit) returns a type error. Edit in the Notion UI.
- **Relations write on create** (verified Apr 2026). No need to create-then-link.
- **Only one Active Package per customer should have `Active? = YES`.** If multiple are flagged, the Customer's `Current package` formula returns only the first — the rest are invisible to the formula but still burn credit. Use `/notion-check` to surface and resolve duplicates.
- **Active Package has one Customer relation field: `Customer`.** Always set on create; never cleared regardless of status. Use `"Customer" LIKE '%<customer-id>%'` for all AP queries; add `AND "Active?" = '__YES__'` to narrow to the current live package. The Customer's `Current package` formula (Formulas 2.0) shows the same view — if multiple packages have `Active? = YES` for the same customer (data hygiene issue), the formula silently returns only the first. Use `/notion-check` to surface duplicates.
- **Kickoffs**: `Do not count` = `__YES__`, `Type` = `👟 Kick off`.
- **`Session Length (h)`** is a number field (hours). Always set even for session-counted packages.
- **Rollup and formula fields are read-only** — see the Customers / Active Packages / Sessions / Tasks Field Reference sections above for the complete lists. Never try to write ARR, Days Left, Delivered, Package Status, Start Date (Current Pkg), End Date (Current Pkg), ∑ Architecting, ∑ Credit, ∑ Time, ∑ Training, Left Days, Left Architecting, Left Training, `Delivered By (Sessions)`, or any formula/rollup.
- **`formulaResult://` values** are read-only — ignore when writing.
- **`update_content` old_str matching** is whitespace-exact. Fetch immediately before editing.
- **`[PREP]` naming convention** — prep/context pages are renamed with `[PREP]` prefix and `Do not count` = YES.
- **Gong backfill**: if a customer was previously handled by another AISE, check Gong via Glean for recorded sessions before assuming the tracker is complete.
- **Program plans live on the Active Package page.** Follow the `Active Package` relation from the Customer record, under a `🗺️ Program Plan — YYYY-MM-DD` toggle on the page body. Any "Program Plan" sub-page hanging off a Customer page is stale/legacy — do not read from it.
- **Customer pages are for company info only.** Who they are, what products they put to market, stakeholders, goals, toolstack snapshot. Program/session tracking lives on the Active Package page; session-specific notes live on Session pages.
- **Owner-filtering is mandatory on reads.** The workspace is shared with other PB AISEs. Use the OR-pattern queries above — for descendants (Active Packages / Sessions / Tasks) filter on `Current Account Owner`, optionally OR with `Delivered By` (Sessions) or `Owner` (Tasks). For Customers, filter on `Owner`. Bare queries without filters return teammates' data.
- **Owner-write-on-create.** On create: Customer → set `Owner = <user-uuid>`. Active Package / Task → set `Current Account Owner = <user-uuid>` (and Task `Owner = <user-uuid>` as creator). Session → leave `Current Account Owner` blank (auto-filled by automation), set `Delivered By` to the actual presenter. Missing required fields ⇒ the record is invisible to the user's filtered queries afterwards.
- **Don't write to `Current Account Owner` on existing records during normal operations.** It's maintained by the Resync button on Customer pages and the Sessions-side automation. Only write to it if you're explicitly correcting drift, on initial create before the propagation has fired, or as part of a `account-setup` handoff sweep.
- **Stored Person values use a `user://` prefix.** Write `["<bare-uuid>"]`; expect `["user://<bare-uuid>"]` on read. Filter with `LIKE '%<bare-uuid>%'`.
- **AISE ARR threshold is $30K.** Accounts with ARR ≥ $30K are AISE-owned. Below $30K → `Contracted to Scale` on the Customer record; ownership transfers to Scale team. This threshold governs whether to create a new Active Package on renewal or hand off.
- **`Active (no Services)` always has a package.** Even though no onboarding services are contracted, an **"AISE No Services"** Active Package should exist for the account. Use it to log ongoing syncs and QBRs as sessions. Never leave this account type without a linked Active Package.
- **`Contracted to Scale` ≠ services complete.** It means the account has fallen below the AISE threshold and is no longer AISE-owned. Do not confuse with `Service Quota Used` (services done, still AISE-owned).
- **Renewal window is 90 days.** Set Package Status to `Renewal` 90 days before `End Date`. After `End Date` with no renewal action → `Package Expired`.

---

## Relationship Map

```
Customer
  ├── Owner (Person) ──► source of truth for ownership
  ├── Resync Owner to descendants (Button) ──► propagates Owner → Current Account Owner on Sessions, Tasks, Active Package
  ├── All packages [rollup] ──► all Active Packages ever associated (backlink of Customer relation on AP side)
  ├── Current package [formula] ──► Active Package where Active? = YES (first found if multiple)
  ├── Packages ──► Master Packages (template/SKU)
  ├── Calls ──► Sessions (auto via Session → Customers relation)
  ├── Tasks ──► Tasks
  ├── Contacts ──► Contacts
  └── Figma File ──► Figma Files DB

Session
  ├── Customers (limit 1) ──► parent account
  ├── Current Account Owner (Person) ──► auto-filled from Customers.Owner
  ├── Delivered By (Person, multi) ──► actual presenter(s)
  └── Consumed Package ──► Active Package (burns credit)

Active Package
  ├── Customer ──► Customer(s) on this contract (permanent, multi-value for shared contracts)
  ├── Current Account Owner (Person) ──► mirror of Customer.Owner
  ├── Delivered By (Sessions) [rollup] ──► unique presenters across linked Sessions
  ├── Master Package (limit 1) ──► pulls Unit, allocations
  └── Sessions (auto via Session → Consumed Package)

Task
  ├── Customers (limit 1) ──► parent account (Productboard for internal)
  ├── Owner (Person) ──► creator
  ├── Current Account Owner (Person) ──► mirror of Customer.Owner
  └── Source Call ──► Session that surfaced the task
```

---

## Prep pages — convention

When writing a prep brief for a session:
1. Find the Session page in Notion (by customer + date). If it doesn't exist, create it first (`Status = Planned`), then apply the matching template immediately (see § Session Templates above).
2. Write prep content **inside the `📋 Prep — [date]` toggle** — the template places this at the top of every new session page. Use `update_content` to fill in the toggle body:
   - Tab-indent all children (`\t`). For sub-bullets under a numbered list item, use two tabs.
   - **Never use `>` blockquote prefix** — each `>` renders as a separate quote block with a left border.
   - If the toggle is absent (legacy page without template), create it by appending at the top of the body:
     ```
     ## 📋 Prep — YYYY-MM-DD {toggle="true"}
     [TAB]paragraph text
     [TAB]**Bold header**
     [TAB]- bullet
     ```
3. Leave the sections below the toggle (Agenda, Decisions, Risks, etc.) for live session notes.
4. If the session is purely prep (no customer call), name the page `[PREP] …` and set `Do not count = __YES__`.
