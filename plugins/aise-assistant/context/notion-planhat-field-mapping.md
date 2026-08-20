# Notion → Planhat Field Mapping

> **Purpose:** Compact write-ready reference for agents backfilling or syncing data from the Notion Customer Tracker into Planhat.
>
> **Last updated:** 2026-08-08 (added Brandwatch/Cision dual-email EndUser resolution note; ph-migrate Company sync: removed Spark/AI Ready/Igniting? — live data SSOT, not written by migration; Do not count sessions now always migrated; added 🏁 Audit / Setup Review Conversation type)
>
> **Migration architecture:**
>
> | Notion | Planhat | Dedup key |
> |---|---|---|
> | Sessions (`Call Status = Delivered`) | **Conversation** (typed by session type) | `externalId` = Notion Session page ID |
> | Tasks (all statuses) | **Task** (`mainType: "task"`) | `sourceId` = Notion Task page ID |
> | Tasks (`Status = Done`) | **Task** → Planhat auto-creates linked **Conversation** | Post-write: check `noteId` → update Conversation `type` to `"Task"` if not already set |
> | Contacts | **EndUser** | `email` or `externalId` |
> | Customers | **Company** | SF-synced — AISE writes phase, Journey Status, csmScore, Priority only. **Spark/AI Ready/Igniting? are live-data SSOT — never written by ph-migrate.** |
> | Active Packages / Master Packages | **Deal** / **Product** | SF SSOT — **never write from Notion** |
>
> GCal-synced meetings already exist in Planhat as `mainType: "event"` — do not duplicate as Conversations.

---

## Session Type Mapping: Notion → Planhat Conversation `type`

> ⚠️ **Emojis are part of the exact configured option strings.** Use the Planhat column values verbatim — passing text without the emoji will save but won't match configured filters.

| Notion `Type` | Planhat `type` (exact string) | Notes |
|---|---|---|
| `🏗️ Architecting` | `🏗️ Architecting` | Emoji matches |
| `🗣️ Sync` | `🔁 Sync` | **Different emoji** (🗣️ → 🔁) |
| `🎓 Training` | `🎓 Enablement` | **Different label** — Planhat uses "Enablement" |
| `👟 Kick off` | `👟 Kick off` | Emoji matches |
| `🔎 Discovery` | `🔎 Discovery` | Emoji matches |
| `📦 Other` (default) | `🔁 Sync` | Default fallback for general calls (e.g. licence discussions, commercial syncs). |
| `📦 Other` + "Demo" in title | `🎙️ Demo` | **Title-pattern override:** if session title contains "Demo" (case-insensitive), use `🎙️ Demo` instead of the default `🔁 Sync`. |
| `🫥 Internal` | `Internal Alignment` | No emoji in Planhat |
| `Do not count` session (any type) | `🏁 Audit / Setup Review` | **Type override for Do not count sessions.** Sessions with `Do not count = YES` are always migrated (never skipped) — use `🏁 Audit / Setup Review` as the Planhat type regardless of the Notion session type. These represent real interactions that need to be on record even though they don't count against the services quota. |
| _(Done Notion Task — auto-created Conversation)_ | `Task` | No emoji. Planhat auto-creates this Conversation when Task `status` is set to `"done"`. Update via `noteId` post-write if type is not already `"Task"`. Canceled (`"ignored"`) tasks do **not** generate a Conversation. |

> **Planhat types with no Notion equivalent:** `📺 Webinar`, `👾 Gong Call` — logged directly in Planhat, not from Notion. `🎙️ Demo` is also available and is applied automatically to `Other` sessions with "Demo" in the title. `🏁 Audit / Setup Review` is used for Do not count sessions.

> **Note on calendar events:** GCal-synced meetings already exist in Planhat as `mainType: "event"`. AISE writes Conversations only — no overlap.

---

## Status Mapping

### Notion Call Status → Sync/skip decision (Sessions → Conversation)

Conversations have no `status` field — `Call Status` determines whether to sync at all, not what to write.

| Notion `Call Status` | Action |
|---|---|
| `Delivered` | **Sync** — create or update Conversation |
| `Canceled` | Skip on initial backfill; update `description` if Conversation already exists |
| `Not started` / `Planned` / `Postponed` | Skip — session hasn't happened yet |
| `In progress` / `Post-session debrief` | Skip — sync once status reaches Delivered |

### Notion Task Status → Planhat Task `status`

All Notion Tasks write to the **Planhat Task model**. For done/canceled tasks, Planhat auto-creates a linked Conversation on save — follow the post-write step to ensure the type is correct.

| Notion `Status` | Planhat `status` | Post-write action |
|---|---|---|
| `Not started` | `"To Do"` | None |
| `In progress` | `"in-progress"` | None. Hyphenated lowercase — NOT `"In-Progress"` |
| `Done` | `"done"` | Read `noteId` from Task response → check linked Conversation's `type` → update to `"Task"` if not already |
| `Canceled` | `"ignored"` | None — Planhat does **not** auto-create a Conversation for `"ignored"` tasks |
| _(Planhat only)_ | `"blocked"` | Set manually in Planhat — no Notion equivalent |

> **Why the post-write step:** When a Task is marked done/ignored, Planhat auto-creates a linked Conversation and sets `noteId` on the Task pointing to that Conversation's `_id`. The auto-created Conversation's `type` may not default to `"Task"`. Check and update it — skip the update if `type` is already `"Task"` (idempotent).

---

## Sessions → Planhat Conversation: Field Mapping

> **`companyId` is a hard requirement on every create call.** Resolve the customer's Planhat Company `_id` via `search_records` (or the checkpoint file, once per customer) once per customer, cache it, and include it on every subsequent Conversation create for that customer. Never issue a create call without it already resolved — omitting it fails with `"CompanyId is required for note"`.

| Notion field | Planhat field | Type | Notes |
|---|---|---|---|
| Session page URL/`id` (dashed UUID from Notion) | `externalId` | string | **Dedup key.** Normalize first: `id.replace('-', '').lower()` — the Notion MCP returns a dashed UUID, and writing that raw form instead of the normalized 32-char hex breaks dedup and silently duplicates the record. Check before every create using **both** forms until historical data is confirmed clean: `list_model_records(MODEL: "Conversation", FILTER: {"externalId[equal to]": "<normalized-hex>"})` and again with the raw dashed form. Either match → update, rewriting `externalId` to the normalized form. |
| `Name` | `subject` | string | Session title as-is. |
| `Type` | `type` | string | See type mapping table above. |
| `date:Call Date:start` | `date` | datetime | ISO 8601. |
| `date:Call Date:start` | `startDate` | date | Call start date. |
| `Customers` (relation) | `companyId` | objectId | Resolve via company name or SF `sourceId`. See `planhat-schema.md`. **Required.** |
| `Delivered By` (person, all values) | `users` | array | `[{"id": "<planhat-user-id>"}, ...]` — one entry per presenter, never truncated to the first value. Resolve each: try the static User ID table in `planhat-schema.md` first, then fall back to a live lookup (`notion-get-users` → email → `list_model_records(MODEL: "User", FILTER: {"email[equal to]": "<email>"})`) on a table miss. If still unresolvable for every presenter, fall back to the session's `Current Account Owner`, then the Company's `owner`. Only omit `users` (and log a `NEEDS ATTRIBUTION` warning) if all of the above fail. |
| _(from Gong/GCal backfill)_ | `endusers` | array | **Field is all-lowercase — not `endUsers`.** Write format: `[{"_id": "<EndUser _id>"}, ...]`. Read-response format uses `id` instead: `[{"id": "...", "name": "..."}]`. Planhat returns HTTP 200 and silently drops the field if written as `endUsers` (camelCase) — no error surfaces. Omit if no attendees resolve. **Brandwatch / Cision dual-email:** Brandwatch contacts may have two separate Planhat EndUser records — one with `@brandwatch.com` (original) and one with `@cision.com` (post-migration). When resolving attendees for Brandwatch sessions, search by both domains if the first lookup returns no match. |
| `Next Steps` / session body | `description` | string | Actual session notes/summary. Truncate to ~2000 chars. Do **not** use this for prep notes — see `custom.Prep Notes`. Do **not** append Gong URL here — use `custom.Gong URL` instead. |
| _(from session prep)_ | `custom.Prep Notes` | string (HTML) | Prep brief written by session-prepper. HTML format: `<p><strong>Goals</strong></p><p>...</p><p><strong>Open Items</strong></p><ul><li><p>...</p></li></ul><p><strong>Watch-fors</strong></p><ul><li><p>...</p></li></ul>`. No `<h>` tags. On Task: write during prep. Carry to Conversation when Task is marked done (debrief). |
| `Gong call` (url) | `custom.Gong URL` | string | Gong call link. **Write to `custom.Gong URL`, not appended to `description`.** |
| `Session Length (h)` | `custom.Call Duration` | number | Multiply by 60 → minutes. |
| _(constant)_ | `source` | string | Always `"AISE"`. Distinguishes from Zendesk/GCal entries. |

**Fields skipped:** `Consumed Package`, `Do not count`, `Prepped`, `Debriefed`

> **Note:** `Call Status` drives whether to sync at all (see status mapping above), but is not written to Planhat.

---

## Tasks → Planhat Task: Field Mapping (all statuses)

> **`companyId` is a hard requirement on every create call.** Resolve the customer's Planhat Company `_id` via `search_records` (or the checkpoint file, once per customer) once per customer, cache it, and include it on every subsequent Task create for that customer. Never issue a create call without it already resolved — omitting it fails with `"Required Field: companyId"`.

| Notion field | Planhat field | Type | Notes |
|---|---|---|---|
| Task page URL/`id` (dashed UUID from Notion) | `sourceId` | string | **Dedup key.** Normalize first: `id.replace('-', '').lower()` — same rule as Conversation `externalId` above. Check before every create. |
| `Task` (title) | `action` | string | Task title as-is. |
| _(constant)_ | `type` | string | Always `"Task"` for generic action items from Notion. (`"AISE Action Item"` is NOT a valid option — do not use.) Session-type Tasks created by session-prepper use the session type mapping instead (e.g. `🏗️ Architecting`, `🎓 Enablement`). |
| _(constant)_ | `mainType` | string | Always `task`. |
| `date:Due Date:start` | `endTime` | datetime | ISO 8601. Set `noSpecificTime: true` for date-only. |
| `Customers` (relation) | `companyId` | objectId | Resolve same as sessions. Skip if Customers = Productboard internal record (`29997e9c7d4f80e6a011f053bdec1ab5`). |
| `Owner` (person) | `ownerId` | objectId | Single owner. Resolve Notion user UUID → Planhat User `_id` via User ID table. |
| `Priority` | `custom.Priority` | string | `"1"` → `"P1"` · `"2"` → `"P2"` · `"3"` → `"P3"` · null → omit. Valid options: `P0`–`P4` (P0 and P4 not sourced from Notion tasks). |
| `Status` | `status` | string | See status mapping table above. |

**Fields skipped:** `Source Call`, `Time (h)`, `Do not count`, `Consumed Package`

---

## Company → Planhat Company: Field Mapping

> Spark fields are actively **written** by the AISE assistant (Notion → Planhat). Journey Status and Services Phase are written on sync. All SF-synced fields are read-only — do not write.

### Identity & ownership

| Notion field | Planhat field | Write? | Notes |
|---|---|---|---|
| `Customer` (title) | `name` | Read | May differ — see name mapping table in `planhat-schema.md`. |
| `SFDC` URL | `sourceId` | Read | Extract 18-char SF Account ID from URL. Cross-system lookup key. |
| `Domain` | `domains[0]` | Read | Array in Planhat. |
| `Slack Channel` URL | `custom.Slack URL` | **SF-synced — do not write** | Synced from Salesforce. Do not populate manually. |
| _(no Notion equivalent)_ | `custom.Slack ID` | **SF-synced — do not write** | Synced from Salesforce. |
| `Account Executive` | `custom.Account Executive` | **SF-synced — do not write** | Synced from Salesforce. User relationship (objectId). |
| `Renewal Manager` | `custom.Renewals Manager` | **SF-synced — do not write** | Synced from Salesforce. User relationship (objectId). |
| _(no Notion equivalent)_ | `custom.Salesforce URL` | Read-only | SF-managed — cannot write. |

### Priority & health

| Notion field | Planhat field | Write? | Notes |
|---|---|---|---|
| `Priority` (Customer) | `custom.Priority (temp – Notion)` | Write | AISE account priority. Temp field in Planhat pending native solution. Write as-is: `P0`–`P4`. `Insufficient Data` → omit. |
| `Health (Manual)` | `csmScore` | Write | `Healthy` → `4` · `Figuring it out` → `3` · `Concerning` → `2` · `Churning` → `1` · null → omit |

### Notion-only fields (not synced to Planhat)

| Notion field | Reason not synced |
|---|---|
| `Industry` | No Planhat equivalent — skip |
| `Renewal Forecast` | Will come from Salesforce — skip |
| `Preferred Conferencing` | Operational preference — skip |
| `Parent Company` | SF SSOT — skip |
| `Time (h)` (Task) | No Planhat Task equivalent — skip for now |

### `phase` vs `custom.AISE Journey Status` — which field to use

These two fields serve different purposes and have different scope:

| | `phase` | `custom.AISE Journey Status` |
|---|---|---|
| **Scope** | All Planhat companies | AISE-managed accounts only (30k+ ARR) |
| **What it tracks** | Universal services lifecycle stage (big buckets: Preparation → Activation → Adoption → Renewal → Churned) | AISE program-specific status (Presales / Active no Services / Active with Services / Contracted to Scale / Churned) |
| **Used by AISE accounts?** | ✅ Yes | ✅ Yes |
| **Used by AIPA accounts?** | ✅ Yes | ❌ No — leave blank for AIPA accounts (under 30k ARR) |
| **Segmentation rule** | — | AISE = 30k+ ARR · AIPA = under 30k ARR |

> `phase` is the shared signal across the full book of business. `custom.AISE Journey Status` is an AISE-team overlay that adds program-level nuance — AIPA uses `phase` to track where customers are in their services journey, but their accounts don't carry an AISE Journey Status.

---

### Journey Status — write from Notion ✓ field confirmed

Maps from Notion `Account Status`. Field ID: **`custom.AISE Journey Status`** (not `custom.Journey Status`).

> **AISE accounts only.** Do not write this field for AIPA-managed accounts (under 30k ARR).

> ⚠️ **`Not started` is not a valid option in Planhat.** If Notion `Account Status` = `Not started`, omit the field (do not write).

| Notion `Account Status` | Planhat `custom.AISE Journey Status` | Action |
|---|---|---|
| `Not started` | — | **Skip — omit field** |
| `Presales` | `Presales` | Write |
| `Active (no Services)` | `Active (no Services)` | Write |
| `Active (Services)` | `Active (Services)` | Write |
| `Contracted to Scale` | `Contracted to Scale` | Write |
| `Churned` | `Churned` | Write |

### Services Phase → `phase` (default Planhat field)

`custom.Services Phase` has been deleted. Use the standard Planhat **`phase`** field instead. Maps from the customer's current **Active Package `Status`** (the package where `Active? = YES`).

**`phase` is NOT free-text.** Planhat has configured options: `0. Preparation` · `1. Activation` · `2. Adoption` · `3. Renewal` · `4. Churned`. Always write one of these exact values.

| Notion `Active Package.Status` | Planhat `phase` | Notes |
|---|---|---|
| `Not started` | `0. Preparation` | Package exists but not yet kicked off |
| `Preparing` | `0. Preparation` | |
| `Activating` | `1. Activation` | |
| `Adopting` | `2. Adoption` | |
| `Service Quota Used` | `2. Adoption` | Services credit exhausted but contract still active |
| `Renewal` | `3. Renewal` | |
| `Package Expired` | `0. Preparation` | Contract lapsed — set to Preparation as a flag for manual review in Planhat |
| No active package (`Active? = YES` not found) | `0. Preparation` | Same as above — needs manual review |

> **`4. Churned`** is set manually in Planhat when a customer fully churns. It is not derived from Active Package status — it aligns with `custom.AISE Journey Status = Churned`.

### Spark fields — live data SSOT (⛔ NOT written by ph-migrate)

> **Do not write Spark/AI Ready/Igniting? during ph-migrate-notion-data.** These fields are maintained by an external live data source (weekly CSV upload via `temp-ph-ignite-conversion-data-sync`). Writing from Notion during migration would overwrite the live values. The value mapping below is retained for reference only — use it only in workflows that explicitly own Spark sync (not ph-migrate).

| Notion field | Planhat field | Value mapping |
|---|---|---|
| `Spark Customer Journey` | `custom.⚡️ Spark Stage` | `Not Active` → `Off` · `AI Terms Review` → `AI Terms Review` · `Active for Admins (Production)` → `Admins only` · `Active for All (Production)` → `Everyone` · `Active (Staging only)` → `Admins only` · `Icebox` → `Icebox` — **Renamed 2026-08-07:** field ID gained a `⚡️` prefix and options were relabeled (`Off`/`Admins only`/`Everyone`/`Mixed` replace the old `Not Active`/`Active for Admins`/`Active for All`/n-a). `Mixed` has no Notion-side source value — Planhat-native only. |
| `AI Ready` | `custom.AI Ready` | `Sparked` → `Sparked` · `Preparing` → `Preparing` · `Ignitable` → `Ignitable` · `Not ready` → `Not Ready` _(capital R in Planhat)_ — unchanged by the 2026-08-07 rename. |
| `Igniting?` | `custom.⚡️ Igniting?` | `__YES__` → `true` · `__NO__` → `false` — **Renamed 2026-08-07:** field ID gained a `⚡️` prefix. |

### Active Packages ↔ Planhat Deal

Planhat `Deal` records are the functional equivalent of Notion `Active Packages`. Each Deal represents a contract/package with associated `LineItem` records (credit types, session quotas, etc.).

> **⛔ Never write Deal or LineItem records from Notion to Planhat.** Deals are owned by the Salesforce → Planhat sync (RevOps-managed). Salesforce is the SSOT for all contract and revenue data. Creating or updating Deals via MCP would conflict with the next SF sync.

**What this means in practice:**
- Do not map Active Package fields (Name, Start Date, End Date, Credits, Sessions) to Planhat Deals.
- Do not create Deal records as part of session debrief or backfill workflows.
- The Active Package `Status` field _does_ influence Planhat via the `phase` field on Company — but that is the only write path (Company.`phase`, not Deal).
- To read contract/revenue data for an account, use `list_model_records(MODEL: "Deal", FILTER: {"companyId[equal to]": "<id>"})` — this surfaces what SF has synced.

### SF-synced fields (read-only — **never write**)

> These fields are populated by the Salesforce → Planhat sync. **Do not write any of them via MCP**, even if the value looks missing or stale — overwriting will conflict with the next sync. This includes account fields, line items, and opportunities. The exact SF field mapping is WIP; when in doubt, treat a Planhat field as SF-synced unless it's explicitly listed as writable in this doc.

| Planhat field | Notes |
|---|---|
| `custom.Customer Status – SF` | Options: `1.0 Customer` · `2.0 Pipeline (Opportunity w Stage 2+)` · `4.0 Lost (Only Closed Lost Opportunities)` · `5.0 Churn (Churned Customer)`. |
| `custom.ARR – Salesforce` | ARR from SF. |
| `custom.Region` | `EMEA` · `NOAM` · `APAC` · `LATAM` · `AUNZ` · `Missing` · `Exclude` · `Blacklisted`. |
| `custom.Segment` | Customer segment (e.g. `ENT`, `MM`). |
| `custom.Account Executive` | AE — User relationship. Managed by RevOps via SF. |
| `custom.Renewals Manager` | RM — User relationship. Managed by RevOps via SF. |
| `custom.Purchased Makers` | Contracted maker seat count. |
| `custom.Current Makers` | Current active maker seat count. |
| `custom.Slack URL` | Slack channel URL. |
| `custom.Slack ID` | Slack channel ID. |
| `custom.Salesforce URL` | SF account URL — Planhat read-only system field. |
| `custom.⚡️ Days in Current Ignite Stage` | Auto-computed. **Renamed 2026-08-07:** gained a `⚡️` prefix (was `custom.Days in Current Ignite Stage`). |
| `custom.AI Readiness – SF` | SF-synced AI readiness. Options: `AI-Forward (Inferred/Validated)` · `AI-Interested (Inferred/Validated)` · `AI Resistant/AI-Resistant (Inferred/Validated)`. |
| `renewalDate` / `renewalArr` | Contract dates and renewal ARR. |
| `mrr` / `arr` | Revenue figures. Derived from active licenses synced from SF. |
| `customerFrom` / `customerTo` | Contract start/end — SF-synced. |
| `status` | Auto-set from licenses (`prospect`, `customer`, `canceled`). |
| `Deal` model records | SF opportunities. Do not create or update via MCP. |
| `Line Item` model records | SF line items / contract line items. Do not create or update via MCP. |

### Planhat-only fields (read for context, no Notion equivalent, not SF-synced)

| Planhat field | Type | Notes |
|---|---|---|
| `h` | number | Computed health score 0–10. |
| `lastActive` | datetime | Last product activity. |
| `nextTouch` / `lastTouch` | datetime | Next/last interaction. |
| `custom.AI Readiness Score` | number | AI readiness score — set manually in Planhat if needed. |

---

## Write Rules

1. **Never write SF-synced fields.** If a field appears in the "SF-synced" table above, do not write it — not even if it's blank. The sync owns it. This applies to account fields, Deal records, and Line Item records. (Exact SF field mapping is WIP; when uncertain, treat a field as SF-synced unless explicitly listed as writable.)
2. **Dedup before every create.** Use `sourceId` on Task (both sessions and tasks). Use `sourceId` on Company.
3. **`custom.` prefix required** on all custom fields.
4. **Never overwrite Planhat `owner`** — managed by RevOps.
5. **`users` on Task is read-only** — only `ownerId` can be set (single person). On Conversations, `users` is writable and an array — for sessions with multiple `Delivered By`, resolve and write **all** presenters (co-delivery must not collapse to the first value). See ID resolution note below.
6. **`noSpecificTime: true`** whenever date has no time component (most Notion session dates and task due dates).
7. **Task `status` exact strings:** `"done"` · `"in-progress"` · `"To Do"` · `"blocked"` · `"ignored"` — hyphenated lowercase for `in-progress`, capital `To Do` (workspace-configured values; not enumerated in API schema — use exactly as written).
8. **`Account Executive` and `Renewals Manager`** are User relationship fields — write as Planhat User `_id`, not display name.

---

## Planhat API Operational Learnings

Hard-won patterns from the S&P Global Ratings backfill (2026-07-10 to 2026-07-13). Apply to all future Planhat work.

### `create_model_record`

- **Parameter name is `PARAMETERS`** (not `DATA`, not `data`). Using the wrong name returns "Missing required parameter: PARAMETERS" with no further detail.
- **Dates must be ISO 8601 with time component:** `"2025-08-11T00:00:00.000Z"` — plain date strings like `"2025-08-11"` cause silent failure ("Failed to create tasks record") with no actionable error.
- **`sourceId` uniqueness is enforced.** Attempting to create a record with a `sourceId` that already exists fails silently. Use this as a reliable dedup probe: if creation fails, the record already exists.
- **Parallel creates with pre-existing sourceIds all fail.** If you need to confirm records exist, fire creates and treat failure as confirmation — do not assume failure means an error on your side.

### `update_model_record`

- **Use `srcid-{32-char-hex}` as `OBJECT_ID` to update by sourceId** (e.g. `srcid-38897e9c7d4f818f9c8fe81ed53bbba7`). Raw hex IDs are rejected with: "Params identifier must be planhat _id OR start with `extid-` or `srcid-`".
- **`extid-` prefix** is for external IDs other than sourceId (not commonly needed).
- Use `srcid-` for all routine updates — avoids the need to look up Planhat `_id` first.

### `get_model_record`

- **Cannot retrieve Tasks by sourceId directly.** `get_model_record` returns "Failed to fetch tasks record" when given a sourceId. Use `update_model_record` with `srcid-` prefix (read-modify pattern) or retrieve by Planhat `_id`.
- **`_id` values are returned in `update_model_record` responses** — capture them if you need to `get_model_record` afterwards.

### `list_model_records`

- **Filters are not honored for Tasks.** Passing `{"companyId": "...", "mainType": "task"}` returns the same 36 most-recent records across the workspace regardless of filter. **Do not rely on `list_model_records` to enumerate all Task records for a company** — you will miss older records.
- **36-record hard cap.** The response is always limited to 36 records with no pagination.

### `delete_model_record`

- **Task deletion is not permitted.** Returns "You are not allowed to remove Task." — this is enforced at the workspace level. Debug/test records created in error cannot be cleaned up via the API; they must be deleted manually in the Planhat UI (or ignored).

### General

- **Eventual consistency.** `list_model_records` may show stale status values shortly after an `update_model_record`. `get_model_record` by `_id` shows the authoritative state — use it for verification.
- **Error messages are often generic.** "Failed to create/fetch tasks record" gives no field-level detail. When debugging silent failures, isolate variables one at a time (date format, parameter name, etc.).

---

## Confirmed Fields ✓

All fields verified against live Planhat API schema (`get_model_action_parameters`) on 2026-07-10. Spark field names/options re-verified 2026-08-07 — see the rename notes inline in the mapping table above.

**Company fields:**
- `custom.AISE Journey Status` — string, options: `Presales` · `Active (no Services)` · `Active (Services)` · `Contracted to Scale` · `Churned` (**`Not started` is not a valid option — omit when Notion = `Not started`**). Note: field ID is `custom.AISE Journey Status`, not `custom.Journey Status`.
- `phase` — standard Planhat field. Replaces deleted `custom.Services Phase`. **Configured options (not free-text):** `0. Preparation` · `1. Activation` · `2. Adoption` · `3. Renewal` · `4. Churned`. Derived from Active Package `Status` — see mapping table above. `4. Churned` is set manually, not via Active Package sync.
- `custom.⚡️ Spark Stage` — options: `Off` · `AI Terms Review` · `Admins only` · `Everyone` · `Icebox` · `Mixed`. **Renamed 2026-08-07** — was `custom.Spark Stage` with options `Not Active`/`Active for Admins`/`Active for All`/`Active on Staging`.
- `custom.AI Ready` — options: `Ignitable` · `Sparked` · `Preparing` · `Not Ready` (unchanged)
- `custom.⚡️ Igniting?` — boolean. **Renamed 2026-08-07** — was `custom.Igniting?`.
- `custom.⚡️ Days in Current Ignite Stage` — text, read-only. **Renamed 2026-08-07** — was `custom.Days in Current Ignite Stage`.
- `custom.⚡️ Spark Enabled` · `custom.⚡️ Spark Enabled Date` · `custom.⚡️ Spark Active For Since` · `custom.⚡️ Spark Engaged` · `custom.⚡️ Spark Engaged Date` · `custom.⚡️ AI Consent` · `custom.Spark Stage` — **added 2026-08-07**, written by `temp-ph-ignite-conversion-data-sync` skill from weekly CSV upload. CSV is the source of truth; no Notion equivalent.

**Task fields (all statuses — all Notion Tasks write to Planhat Task model):**
- `custom.Priority` — options: `P0` · `P1` · `P2` · `P3` · `P4`
- `status` — workspace-configured: `"To Do"` · `"in-progress"` · `"blocked"` · `"ignored"` (**Note:** hyphenated `in-progress`, capital `To Do` — previously documented as `In-Progress` which is wrong)
- `users` — readonly (cannot write); use `ownerId` instead
- `noSpecificTime` — boolean ✓

**Conversation custom fields (confirmed):**
- `custom.Gong URL` — string. Use this for Gong links — do NOT append to `description`.
- `custom.Call Duration` — number (minutes). Derive from Notion `Session Length (h)` × 60.
- `custom.Prep Notes` — string (HTML rich text). Prep brief for this session. HTML format — `<p><strong>Goals</strong></p><p>...</p><p><strong>Open Items</strong></p><ul><li><p>...</p></li></ul><p><strong>Watch-fors</strong></p><ul><li><p>...</p></li></ul>`. Written by session-prepper (via Task → Conversation carry-over on mark-done). **Do not populate during migration** — Notion session records do not hold prep content.

**Task custom fields (confirmed):**
- `custom.Priority` — options: `P0` · `P1` · `P2` · `P3` · `P4`
- `custom.Prep Notes` — string (HTML rich text). ✅ Field confirmed on Task model. Same HTML format as Conversation. Write during session prep; carry to Conversation on mark-done.
