# Planhat Schema & Notion↔Planhat Traversal Guide

> **Status:** Migration complete. Planhat is the sole AISE working record — Notion has been fully retired across every agent and skill, including session-prep (`session-prepper`), account-plan (`customer-plan-next`), and engagement-planner (`engagement-planner`). The "System Mapping: Notion ↔ Planhat" tables below are kept as historical/reference documentation only, not a description of current dual-write behavior.
>
> **Last updated:** 2026-09-08 (rewrote `/session-backfill` Planhat-native — dropped Notion meeting-notes discovery and the Active Package/Consumed Package concepts entirely, added its GCal-event-id / `gong_`-prefixed `externalId` convention to § Conversation)

---

## MCP Access

| Detail | Value |
|---|---|
| MCP server ID | `7441c372-4b65-4805-95b0-baf2a081ceb3` |
| Key tools | `list_model_records`, `get_model_record`, `update_model_record`, `search_records`, `get_model_action_parameters` |
| Available models | `Company`, `EndUser`, `Task`, `Conversation`, `Deal`, `Nps`, `Issue`, `Workflow`, `Churn`, `Document`, `User`, `Product`, `LineItem`, `EmailTemplate`, `Comment`, `Attachment` |

### Three silent MCP failures — apply to every model, every skill

The first two were verified live on 2026-08-31 against `Conversation`, the third on 2026-09-11 against `Task`. None raises an error, none warns, and each returns a plausible-looking success. Any skill that reasons over "everything in this window", or that trusts a `200` on a write, is wrong by default until it accounts for them.

**1. Date filters take plain `YYYY-MM-DD`, not ISO timestamps.**

| Filter passed | Records returned |
|---|---|
| `"date[more than]": "2026-08-24T00:00:00.000Z"` | **3** |
| `"date[more than]": "2026-08-24"` | **39** |

Same query otherwise. The timestamped form silently returns a wrong subset. Pass day bounds, widen by a day on each side, and apply any hour-level window locally in code after the query returns. Applies to `date`, `startTime`, `endTime` and every other date field, on filters and on `Task` lookups alike.

**2. Selecting a large text field truncates the record *count*, not the field.**

The MCP response has a payload ceiling and drops whole records to fit it:

| `SELECT` on a 39-record query | Records returned |
|---|---|
| with `transcript` + `description` | **2** (72 KB) |
| without them | **39** |

Gong transcripts run 10–55 KB each, so two records fill the budget. Two records reads as a small clean result, which is what makes this dangerous — and it is a *different* failure from the ~36-row cap on `Conversation` (which pages correctly with `OFFSET`). **Never put `transcript` or `description` in a multi-record `SELECT`.** Pull metadata in the list query, then fetch bodies one record at a time with `get_model_record(..., SELECT: ["transcript", "description"])` for the handful of records that actually need them — and report lengths, never the bodies themselves.

**3. Unknown field keys are silently dropped on write. The create still returns `200`.**

`create_model_record` and `update_model_record` accept any `PARAMETERS` object. Keys that are not real field IDs for that model are discarded server-side — no error, no warning, and the response simply omits them. A create built from guessed or aliased field names lands as a near-empty record with only the keys that happened to be correct.

Verified live on 2026-09-11 (Verisk, both test records deleted):

| `PARAMETERS` passed to `create_model_record(MODEL: "Task")` | What landed |
|---|---|
| `action`, `ownerId`, `status`, `type`, `endTime`, `custom.Priority`, `description`, `companyId` | all of it |
| `name`, `assignee`, `dueDate`, `description`, `companyId` | `description` + `companyId` only — a nameless, ownerless, dateless Task |

**The Task aliases that silently vanish.** These are the wrong names an agent reaches for by reflex — and the Planhat MCP's own `create_model_record` tool description ships a Task example using all three, so following the tool's inline example instead of this schema is the documented way to produce the failure:

| Wrong (dropped, no error) | Correct field ID |
|---|---|
| `name`, `title`, `subject`, `summary` | **`action`** |
| `assignee`, `owner`, `assignedTo` | **`ownerId`** |
| `dueDate`, `due`, `deadline` | **`endTime`** |
| `notes`, `body` | **`description`** |
| `priority` | **`custom.Priority`** |

`status` is worse than dropped — it is stored **unvalidated**. `"todo"`, `"to-do"` and `"To-Do"` all persist verbatim and none of them match the only valid option, `"To Do"`, so the Task disappears from every status-filtered view while looking fine on the record. Same for `type`: pass an option that is not in the live enum and it sticks as a dead value (`"Internal Action"` is one such orphan already in the workspace).

**An unset `type` is not neutral — Planhat renders it as `note`.** `note` is the model default and the fallback for an unrecognized value, so a Task created without `type` shows up in the UI as a note rather than a task, drops out of type-filtered reporting, and reads as a stray record to anyone reviewing the account. Over MCP the field simply comes back absent, so a read that omits `type` and a record displaying as `note` are the same defect seen from two sides — this is why `type` is mandatory on every Task write, not merely recommended. Repaired workspace-wide 2026-09-11: 19 of Klara's debrief-created Tasks were untyped or wrongly typed, plus roughly 40 more on other AISEs' accounts from the same agent runs.

**Consequence — the rule.** Never hand-assemble a `PARAMETERS` object from memory for a model you have not checked this session. Pull `get_model_action_parameters(MODEL: "<model>")` first, and **read the record back after every create** (`SELECT` the fields you just wrote) and assert they are present and correctly cased. A create response echoing only `_id`, `companyId` and `description` is the signature of this failure, not a successful write.

### API Quirks: result caps and paging (Task, Conversation)

**`list_model_records` pages at a fixed cap and never says so.** A Task query returned exactly 200 rows when the real total was 397 (observed 2026-10-06); `Conversation` and filtered `Task` queries hit smaller caps (see the ~36-row notes below). A round row count is the only signal.

- **Always page.** Request `LIMIT: 200` and loop with `OFFSET` in steps of 200 (`0`, `200`, `400`, …) until a page returns **fewer than `LIMIT` rows**, then merge the pages into one list (dedupe on `_id`) before any filtering or tiering.
- **Sanity check.** If any page returns exactly `LIMIT` rows, fetch the next one. Never stop on a full page, and never treat a single page as the whole set.
- **`SORT: "endTime"` ascending puts null dates first.** Undated tasks fill page 1 and the dated ones (including everything due recently or later) sit on later pages. A single page of an `endTime`-sorted query is therefore not "the earliest tasks", it is "the undated tasks plus an arbitrary slice". Never rely on a single page of it.
- **Cap smaller than `LIMIT`.** If a page comes back with fewer rows than `LIMIT` but the offset page after it is non-empty, the cap is below `LIMIT`: page by the number of rows actually returned, and keep going until an empty page.
- **Report it.** Say in the run summary how many pages were fetched and the merged total.

### Task hygiene: template checklists, priority values, stale overdue

Rules for any agent that renders or ranks open Tasks (`/daily-brief` step 6).

- **Template tasks.** Program-template checklist items are bulk-created from a Planhat workflow and are not individual commitments. Treat a Task as a template task when **any** holds: title starts with `[PRE]`, `[POST]` or `[SESSION]`; it has no `status` **and** no `custom.Priority`; or it shares an identical `endTime` with at least 5 other Tasks on the same Company. Collapse them to one summary line per Company (`Acme Corp: 24 template checklist tasks, oldest due 13 Aug`) instead of listing each.
- **Priority equivalence.** `P1` and `High` mean the same thing; `P2` and `Medium` likewise. Normalise before comparing or sorting. Rank order: `P0`, `P1`/`High`, `P2`/`Medium`, `P3`, `P4`, blank.
- **Observed Task `status` values:** `To Do`, `in-progress`, `Done`, and blank. Compare case-insensitively (`Done` and `done` both occur); blank means open.
- **Stale.** A real (non-template) Task more than 30 days past `endTime` is *stale*, not overdue. Show it in a collapsed Stale bucket, never in Today.

---

## Adding a new Planhat field

A field the assistant should read or write has to clear four gates. Skipping any one produces a failure that looks like success.

**1. Create it in Planhat with a description that says how to use it.** `get_model_action_parameters` returns each field's description verbatim, so the description is the only channel that tells an agent what a field means without a doc edit. Write it as an instruction, not a label — what it holds, who sets it, what each option means, and what blank means. `custom.Debrief Status` and `custom.PM Reach-Out Status` are the models to copy. A field with an empty description is effectively invisible to reasoning: the agent sees a name and guesses from it.

**2. Number the options if it is a list you will group or sort by.** Planhat orders picklists alphabetically otherwise. Numbering makes `1. Key contact` sort above `2. Engaged`, and renaming an option remaps every record already holding it, so numbering can be added after the fact with no migration. The cost: **every write must then pass the full numbered string verbatim.**

**3. Reconnect the Planhat connector.** New fields do not reach MCP metadata until the connector re-reads the schema. Until then the field sits in the partial state below.

**4. Document it in this file.** A field that exists but is not here will be missed by every agent that does not stumble onto it.

### The partial state — writable before filterable

Between creating a field and the connector picking it up:

| Operation | Works? |
|---|---|
| `update_model_record` writing the field | ✅ the write lands |
| `get_model_record` with the field in `SELECT` | ✅ reads back |
| `list_model_records` with the field in `SELECT` | ✅ reads back |
| `list_model_records` filtering **on** the field | ❌ `Invalid filter format: Invalid field` |
| `get_model_action_parameters` listing the field | ❌ absent |

**Verify a new-field write with `get_model_record` plus an explicit `SELECT`, never by filtering.** An agent that concludes "the field is read-only, my write was silently dropped" has almost certainly verified the wrong way — that false negative occurred across several debrief runs on 2026-09-12 and produced incorrect reports of lost writes.

The practical limit while in this state: the field cannot back a cross-account query or a Planhat view built through MCP. Building the view in the Planhat UI works, because the UI does not use the connector's field registry.

### Telling a missing field from a lagging one

`Invalid filter format: Invalid field: <name>` means the connector's registry does not know the field. That has two very different causes, and the fix is opposite in each:

| Situation | What it means | Do |
|---|---|---|
| Field was created recently | Registry lag — the field exists and writes land | Verify with `get_model_record` + explicit `SELECT`; reconnect the connector |
| Field predates the last connector sync | The field has genuinely been removed from the model | Stop referencing it; find the successor and update this file |

**A filter probe on an established field is therefore a reliable existence test**, and it is how `custom.AISE Conversation` and `custom.⚡️ Spark Enabled` were confirmed removed on 2026-09-12. It is *not* a valid test for anything created in the last few days.

**Separately, `readonly: true` in the metadata is not always enforced.** `custom.Debrief Status` is declared read-only and accepts writes. Trust a read-back over the metadata flag.

---

## REST API write quirks — `api.planhat.com`, not the MCP

Verified live 2026-09-12 against `Task` in the Productboard tenant with a
service-account token. These apply to the **REST API** — the path Zapier, n8n and any
`curl` take. The MCP normalizes some of them, so MCP experience does not transfer, and
the two paths disagree in at least one place where both look like they work.

### `status: "Done"` is capitalized on REST

| Path | Value that works |
|---|---|
| `update_model_record` (MCP) | `"done"` |
| `PUT https://api.planhat.com/tasks/{_id}` | `"Done"` |

Lowercase `"done"` over REST fails with `The app returned "Failed to execute task status
update"` — a message that names neither the field nor the value, and reads like an
auth or payload problem. The model's own option list is mixed-case
(`done|ignored|blocked|in-progress|To Do`), so it is not a reliable guide. Test the
value on the path you are actually using.

### `custom` merges on PUT, and takes either shape

Both of these set one field and leave every other custom field intact:

```json
{"status":"Done","custom":{"Slack message URL":"https://..."}}
{"status":"Done","custom.Slack message URL":"https://..."}
```

Omitting `custom` entirely leaves all custom fields untouched. **Prefer the nested
form** — it matches the read shape and the `create_model_record` convention.

Clearing with `""` sets an empty string; it does not remove the key, so a later
`has no value` filter may not match it.

Two keys differing only in case cannot go in the same request — the JSON layer rejects
them as duplicates, case-insensitively, even though storage is case-sensitive and both
can coexist on a record. Repairing a mis-cased key therefore takes two calls.

### Unknown custom keys are silently accepted

This is the expensive one. A custom-field key that matches no defined field is
**stored anyway**: 200 response, value persisted in the `custom` object, value visible
in API reads — and bound to no field definition, so it is invisible everywhere in the
Planhat UI.

Casing counts. Writing `"Slack Message URL"` when the defined field is
`"Slack message URL"` produces exactly that: a successful write, a populated API
response, and an empty field in the product.

This is the same class of failure as the unvalidated `status` and `type` values above,
and it has the same remedy — **confirm the exact key against
`get_model_action_parameters(MODEL: "<model>")` before writing, character for
character including case and any emoji, then read the record back.** If a value writes
"successfully" but does not appear in the UI, suspect the key before anything else.

### `Task.ownerName` is a stale denormalization

`ownerName` appears in automation event payloads and in API reads, but it is **not in
the Task schema**. It is written on create and is *not* refreshed when the task is
reassigned. Verified 2026-09-12: a task whose `ownerId` pointed at one user still
carried the original creator's name in `ownerName`.

Read `ownerId` and resolve the User record. Never group, filter, report or display on
`ownerName` — after any handover it is confidently wrong, and wrong in a way that
produces a plausible name rather than a blank.

### Automation replacement codes validate against the schema, not the payload

Planhat's automation reference validator checks the **declared model schema**. Two
consequences, both of which reject at save time with `is not a valid reference`:

- Runtime-only fields — `<<object.ownerName>>` — are refused even though the value is
  genuinely in the event payload.
- Field names containing a space — `<<get-object-xxx.custom.Slack message URL>>` — are
  refused.

In both cases take the whole object into a Function step and read the property in
JavaScript:

```javascript
const tk = <<object>>;
const co = <<get-object-xxx>>;
const url = (tk.custom && tk.custom["Slack message URL"]) || "";
```

The validator also parses `<<...>>` anywhere in a Function's code text, **including
comments and regex literals**, and a step cannot reference itself. A commented-out
example of the step's own output is a save-blocking error.

---

## Planhat Record URLs

Planhat record links follow the workspace data-explorer route. Build them from the record's `_id` — never cite a Planhat record without a link when one can be built.

**Wrong shapes that look plausible and 404.** Do not emit any of these, and do not reach for them as a fallback when you are unsure of a slug:

- `https://productboard.planhat.com/profile/<_id>` — wrong host *and* wrong route. This is the most common miss, because the tenant-as-subdomain form reads like other SaaS tools. The tenant is a **path segment** on `ws.planhat.com`, never a subdomain.
- `https://app.planhat.com/...` — wrong host.
- Any bare `https://productboard.planhat.com` root link.

If you cannot build the real URL, name the record and its model plainly. A link that 404s is worse than no link.

**Template**

```
https://ws.planhat.com/productboard/home/data-explorer/<path-slug>?preview=<Model>.<_id>
```

- `productboard` — tenant slug for this workspace. Constant.
- `<path-slug>` — lowercase model slug in the route (see table below).
- `<Model>` — model name exactly as the MCP names it (`Conversation`, `Company`, `Task`, …), capitalized.
- `<_id>` — the record `_id` returned by `list_model_records` / `get_model_record` / `search_records`.

**Worked example** — Conversation `6a8495b8855d99d003a36277`:

```
https://ws.planhat.com/productboard/home/data-explorer/conversation?preview=Conversation.6a8495b8855d99d003a36277
```

**Path slugs**

| Model | `<path-slug>` | Status |
|---|---|---|
| `Conversation` | `conversation` | ✅ Verified 2026-08-19 |
| `Company` | `company` | ⚠️ Inferred from the pattern — confirm before first use |
| `Task` | `task` | ✅ Verified 2026-09-03 |
| `EndUser` | `enduser` | ⚠️ Inferred |
| `User` | `user` | ⚠️ Inferred |
| `Deal` | `deal` | ⚠️ Inferred |
| `Asset` | `asset` | ⚠️ Inferred |

To confirm an inferred slug: open the record in Planhat, copy the address bar, compare against the template, and update this table — mark it Verified with the date. If a model's route turns out not to follow the pattern, record the real route here rather than leaving agents to guess.

**When citing a Planhat record** (chat responses, briefs, Slack debriefs, session notes): use `[<subject or name>](<url>)`. If the `_id` is unknown, or the path slug for that model is still Inferred and you cannot confirm it, name the record and its model plainly instead of shipping a link that 404s.

---

## System Mapping: Notion ↔ Planhat

### Migration architecture overview

> This is the canonical mapping for the one-time Notion → Planhat migration. It covers all six Notion databases. **Read every row before writing anything** — connected records (e.g. Conversation → Company, Task → Company) must exist before the child record is created.

| Notion DB | Planhat Model | Direction | Notes |
|---|---|---|---|
| **Customers** | **Company** | SF → Planhat ← AISE | Company records are SF-synced by RevOps. AISE writes `phase`, `custom.AISE Journey Status`, Spark fields only. Never create Company records via MCP. |
| **Contacts** | **EndUser** | Notion → Planhat | Individual contacts per account. Map on session backfill; link as `endusers` on Conversations. Dedup key: `email` (or `externalId`/`sourceId`). |
| **Sessions** | **Conversation** | Notion → Planhat | Delivered sessions only (`Call Status = Delivered`). One Conversation per session. Type mapping: see §Conversation below. Dedup key: `externalId` = Notion Session page ID. |
| **Tasks (all statuses)** | **Task** (`mainType: "task"`) | Notion → Planhat | All Notion Tasks write to the Task model. For `status: "done"` only, Planhat auto-creates a linked Conversation (`noteId`). Post-write: check and set Conversation `type: "Task"` if not already. `"ignored"` (Canceled) stays as Task only — no auto-Conversation. Dedup key: `sourceId` = Notion Task page ID. |
| **Active Packages** | **Deal** (read-only) | SF → Planhat | SF is SSOT. **Never write Deal or LineItem records from Notion to Planhat.** Read `list_model_records(MODEL: "Deal")` to surface contract data. |
| **Master Packages** | **Product** (read-only) | SF → Planhat | SKU templates. SF is SSOT. **Never write from Notion to Planhat.** |

### Database equivalents

| Notion DB | Planhat Model | Notes |
|---|---|---|
| **Customers** | **Company** | Core account record. SF-synced. AISE writes Spark/phase/Journey Status only. |
| **Contacts** | **EndUser** | Individual contacts at accounts. |
| **Sessions** | **Conversation** | Delivered calls/interactions. See type mapping table. |
| **Tasks (all statuses)** | **Task** (`mainType: "task"`) | All tasks — open and closed — write to the Task model. `status: "done"` triggers Planhat to auto-create a linked Conversation (`noteId`); `"ignored"` (Canceled) does not. |
| **Active Packages** | **Deal** (read-only from SF) | Functional equivalent. SF SSOT. Never write from Notion. |
| **Master Packages** | **Product** (read-only from SF) | SKU logic. SF SSOT. Never write from Notion. |

---

## Company (Planhat) ↔ Customer (Notion)

### How to look up a Planhat Company for a given customer

**Step 1 — Try name search first:**
```
search_records(QUERY: "<customer name>")
```
Filter results to `model: "Company"` only. Check the name mapping table below for known mismatches before concluding no record exists.

**Step 2 — Fall back to Salesforce sourceId if name search fails:**
Extract the SF Account ID from the Notion Customer's `SFDC` field URL:
`https://productboard.lightning.force.com/lightning/r/Account/<SF_ACCOUNT_ID>/view`
Then:
```
list_model_records(MODEL: "Company", FILTER: {"sourceId[equal to]": "<SF_ACCOUNT_ID>"}, SELECT: ["name", "sourceId"])
```

**Step 3 — If still not found:** The account may not yet be synced to Planhat. Flag it rather than creating a stub — Planhat Company records are synced from Salesforce by RevOps.

---

### Field-level mapping: Notion Customer → Planhat Company

> Fields marked **[SYNCED]** are actively written by the AISE assistant. Fields marked **[READ]** are pulled from Planhat for context but not written by the assistant. Fields marked **[NOTION ONLY]** have no Planhat equivalent. Fields marked **[PLANHAT ONLY]** exist in Planhat but not Notion.

#### Identity & ownership

| Notion field | Planhat field ID | Type | Direction | Notes |
|---|---|---|---|---|
| `Customer` (title) | `name` | string | Read/Write | Display name. **May differ** — see name mapping table. |
| `SFDC` (url) | `sourceId` | string | Read | SF Account ID embedded in the Notion URL. Planhat's `sourceId` is the 18-char Salesforce Account ID. Use for cross-system lookups. |
| `Domain` | `domains[0]` | array | Read | Planhat stores domains as an array. |
| `Owner` (person) | `owner` (objectId → User) | relation | [NOTION ONLY for AISE writes] | Notion Owner = AISE. Planhat `owner` = CSM. These may differ. Do not overwrite Planhat `owner` from Notion. |
| `Account Executive` | `custom.Account Executive` | string | Read | Same role, stored as a string in Planhat custom field. |
| `Renewal Manager` | `custom.Renewals Manager` | string | Read | |

#### Account health & status

| Notion field | Planhat field ID | Type | Notes |
|---|---|---|---|
| `Account Status` | `status` (+ `phase`) | string | Planhat `status` is auto-set from licenses (`prospect`, `customer`, `canceled`, etc.). `phase` is the manually-set lifecycle stage. Neither maps 1:1 to Notion `Account Status`. |
| `Health (Manual)` | `csmScore` (1–5) | number | Notion is a select (`Figuring it out` → `Churning`). Planhat `csmScore` is 1–5. Rough mapping: Healthy=4–5, Figuring it out=3, Concerning=2, Churning=1. |
| `Priority` | _(no equivalent)_ | — | Notion-only. Not in Planhat. |
| `ARR` (rollup) | `arr` | number | Planhat `arr` = annualized MRR from active licenses. Notion ARR = rollup from Active Packages. **Do NOT use native `arr`** — its default logic is incorrect and cannot be changed. Use `custom.ARR – SF` (see § ARR — always use `custom.ARR – SF`). |
| `Renewal Forecast` | _(no direct equivalent)_ | — | Planhat has `renewalDate` and `renewalArr` but no forecast select. |
| _(Notion only)_ | `h` (health score 0–10) | number | **[PLANHAT ONLY]** Computed health score. Useful context when prepping sessions. |
| _(Notion only)_ | `lastActive` | date | **[PLANHAT ONLY]** Last product activity date. |
| _(Notion only)_ | `nextTouch` / `lastTouch` | date | **[PLANHAT ONLY]** Next/last scheduled or logged interaction. |

#### Spark / AI readiness — **[SYNCED]**

**Partly stale – see § Spark fields — Company for the current field map.** `Spark Stage` is no longer synced from Notion; `AI Ready` and `Igniting?` still are.

> **Renamed 2026-08-07** — all three ⚡️-prefixed fields below were renamed/relabeled in Planhat. Old field IDs (`custom.Spark Stage`, `custom.Igniting?`, `custom.Days in Current Ignite Stage`, without the emoji) and old `Spark Stage` option values (`Not Active`/`Active for Admins`/`Active for All`/`Active on Staging`) are stale — do not use them. `AI Ready` is unaffected.

| Notion field | Planhat field ID | Type | Value mapping |
|---|---|---|---|
| `Spark Customer Journey` | _(retired mapping)_ | — | **No longer synced.** `custom.⚡️ Spark Stage` is now automation-maintained from `Spark Visibility (Account)` and is never written – see § Spark fields — Company. The old Notion value mapping is obsolete. |
| `AI Ready` | `custom.AI Ready` | string (select) | `Sparked` → `Sparked` · `Preparing` → `Preparing` · `Ignitable` → `Ignitable` · `Not ready` → `Not Ready` _(note capital R)_ |
| `Igniting?` | `custom.⚡️ Igniting?` | boolean | `__YES__` → `true` · `__NO__` → `false` |
| `Days in Current Ignite Phase` (formula) | `custom.⚡️ Days in Current Ignite Stage` | string (read-only) | Both are computed. Do not write either. |
| `Ignite Journey Last Edited` (date) | _(no equivalent)_ | — | Notion-only automation field. |
| _(no Notion equivalent)_ | `custom.⚡️ Spark Enabled Date` / `custom.⚡️ Spark Active For Since` / `custom.⚡️ Spark Engaged Date` / `custom.⚡️ AI Consent` | date / date / date / text | **Added 2026-08-07.** Written by `temp-ph-ignite-conversion-data-sync` skill from weekly CSV upload. CSV is the source of truth for these fields. |

**Write direction (`AI Ready`, `Igniting?` only):** Notion → Planhat. Never write `Spark Stage`.

#### Financial

| Notion field | Planhat field ID | Notes |
|---|---|---|
| _(no equivalent)_ | `mrr` | Monthly Recurring Revenue — Planhat only |
| _(no equivalent)_ | `arr` | ⚠️ Native ARR — **not used**; use `custom.ARR – SF` |
| _(no equivalent)_ | `renewalDate` | Contract renewal date — Planhat only |
| _(no equivalent)_ | `renewalDaysFromNow` | Days until next renewal — Planhat only, read-only |
| `ARR` (rollup) | `custom.ARR – SF` | **The ARR field to use everywhere.** ARR from Salesforce — Planhat only. **Field ID is `ARR – SF`.** Native `arr` is not used. |
| _(no equivalent)_ | `custom.Customer Status – SF` | Salesforce lifecycle status — Planhat only |
| _(no equivalent)_ | `custom.Region` | Geographic region — Planhat only |
| _(no equivalent)_ | `custom.Segment` | Customer segment — Planhat only |

---

## Customer Name Mapping: Notion → Planhat

Some accounts are named differently across systems. Always check this table before concluding no Planhat record exists. When a name doesn't match here either, check the Company's `domains` array before giving up — acquired brand names (like Entrust below) may only surface there, not in the Company name itself.

| Notion name | Planhat name | Planhat `_id` | Match method |
|---|---|---|---|
| WeClapp GMBH | weclapp GmbH | `6a4cd728ef3ea36a06911298` | Name |
| Ecovadis | ECOVADIS SAS | `6a4cd724ef3ea30f44910507` | Name |
| Qlik (Talend) | Talend | `6a4cd728ef3ea333c991129e` | Name |
| Verisk SBS | Verisk | `6a4cd722ef3ea3fb9a9101fc` | Name |
| Onfido | Onfido Ltd | `6a4cd728ef3ea31463911108` | Name |
| Entrust | Onfido Ltd | `6a4cd728ef3ea31463911108` | `domains` — Entrust is an alias for the same Planhat Company record as Onfido (both `onfido.com` and `entrust.com` appear in its `domains` array), likely reflecting an acquisition |
| Outsystems | OutSystems | `6a4cd728ef3ea3b89e91110b` | Name |
| SymphonyAI | Symphony AI | `6a4cd728ef3ea37f3c91135c` | Name |
| Hilti AG | Hilti | `6a4cd722ef3ea3deb09101a6` | Name |
| S&P Global Market Intelligence | S&P Global | `6a4cd728ef3ea3132a91125d` | Name |
| S&P Global Ratings | S&P Global | `6a4cd728ef3ea3132a91125d` | Name — same Planhat Company; both Notion records map here |
| North SALIDO | North American Bancard | `6a4cd722ef3ea332c691015a` | SF sourceId |
| Emplifi _(duplicate)_ | Emplifi (two Company records) | `6a9add4c…` (pixlee / turnto domains) · `6a4cd724…` (socialbakers domains) | **Duplicate, resolve via the session Task.** Only one is the real account: the one that owns the session Task and conversations, which also has `owner` = the current user. Truncated ids as first observed 2026-10-06; confirm full `_id` live. |

### Known conflicts

**Duplicate Companies from name or domain search (e.g. Emplifi ×2):** `search_records` and `domains[contains]` can return more than one Company for the same customer. Resolution order: (1) take `companyId` from the session Task / Conversation resolved by GCal event ID (`daily-brief` step 3-A does this first); (2) otherwise prefer the Company whose `owner` equals the current user's `planhat_user_id`; (3) if still several, ask. Always name the duplicate in the run's flags so it can be merged in Planhat. A name search can also crowd in unrelated companies (a `north` query returns several): confirm by exact `domains` element (try the parent domain of a subdomain such as `contractor.north.com` → `north.com`), never by picking the first hit.

**S&P Global Market Intelligence vs S&P Global Ratings:** Two separate Notion customer records. "S&P Global Market Intelligence" is the primary engagement (maps to Planhat as "S&P Global"). "S&P Global Ratings" is a separate entity but shares the same Planhat Company (`6a4cd728ef3ea3132a91125d`) — both live under one Planhat account for now. Spark data may differ between the two Notion entries. When syncing sessions or tasks, use the Notion Customer page you're working from — both will resolve to the same Planhat `companyId`.

**SAP sub-accounts:** Planhat has one record — "SAP SE" (`6a4cd724ef3ea383e8910516`). Notion has four separate customer records (SAP Global Content Group, SAP AIMAX, SAP LeanIX, SAP Signavio). These sub-accounts do not yet have individual Planhat Company records. When the user asks about any SAP sub-entity, check the Notion Customer page for the relevant data; do not try to write Spark fields to Planhat for these accounts until individual records exist.

### Not yet in Planhat (as of 2026-07-08)

| Notion name | SF Account ID | Status |
|---|---|---|
| SAP Global Content Group | _(none in Notion)_ | SAP sub-account — no individual record |
| SAP AIMAX | _(none in Notion)_ | SAP sub-account — no individual record |
| SAP LeanIX | _(none in Notion)_ | SAP sub-account — no individual record |
| SAP Signavio | _(none in Notion)_ | SAP sub-account — no individual record |
| Fnac Darty | `0015G00002TVABoQAP` | Not synced |
| Domestic & General | `0015G00001WrPLWQA3` | Not synced |
| Canon Medical | `001Qm00000QTRHHIA5` | Not synced |
| Xactware | `001f400001D6n8WAAR` | Not synced |
| Bloomreach | _(none in Notion)_ | Not found by name or ID |
| Exact | _(none in Notion)_ | Not found by name or ID |
| Amadeus | _(none in Notion)_ | Not found by name or ID |

---

## Agent Traversal Patterns

### "What's the Spark status for customer X?"

1. Find the Planhat Company (name search or SF sourceId) → `get_model_record(SELECT: ["custom.Spark Visibility (Account)", "custom.Spark Enabled – SNF", "custom.Spark Engaged – SNF", "custom.Spark Exemption – SF", "custom.Spark Exemption Context", "custom.AI Ready", "custom.⚡️ Igniting?"])`
2. **Read `custom.Spark Exemption Context` first** and treat its newest dated entry as current state.
3. On a multi-workspace account, read the per-workspace Asset fields (§ Asset / Workspace) rather than the account-level flags.

### "Update Spark status for customer X"

Spark visibility and engagement are computed or synced – there is nothing to write for them. The only writable Spark-related Company fields are `custom.⚡️ Igniting?`, `custom.AI Ready`, `custom.⚡️ AI Consent` and `custom.Spark Exemption Context` (new dated entry on top, never overwrite). If the user asks to "set" Spark Stage, explain it is automation-maintained and offer one of those instead.

### "What's the health / ARR / renewal date for customer X?"

Planhat only — Notion does not track these in real time.
1. `search_records(QUERY: "<customer name>")` → get `_id`
2. `get_model_record(MODEL: "Company", OBJECT_ID: "<id>", SELECT: ["h", "custom.ARR – SF", "mrr", "renewalDate", "renewalDaysFromNow", "csmScore", "lastActive", "custom.Customer Status – SF", "custom.Region", "custom.Segment"])`

### "Who are the contacts at customer X?"

- **Notion:** query Contacts DB linked via the Customer's `Contacts` relation
- **Planhat:** `list_model_records(MODEL: "End User", FILTER: {"companyId[equal to]": "<planhat_company_id>"})` _(EndUser schema not yet fully documented — run `get_model_action_parameters(MODEL: "End User")` first)_

### "Show me open tasks for customer X"

- **Notion:** query Tasks DB with `Customers LIKE '%<customer-id>%'`
- **Planhat:** `search_records(QUERY: "<customer name>")` then filter for Task records, or `list_model_records(MODEL: "Task", FILTER: {"companyId[equal to]": "<planhat_company_id>"})` _(note: `list_model_records` on Task has a hard 36-record cap — use `search_records` for customers with many tasks)_

---

## Planhat Company — Full Field Reference

### ARR — always use `custom.ARR – SF`, never native `arr`

> **Standing rule — applies to every run, every agent, every skill, in both plugins.**

The native Planhat `arr` field (and its relatives `mrr`, `renewalArr` where used as an ARR proxy) is **not used**. Planhat computes it with default logic that is incorrect for our data and **cannot be changed**. The only ARR we trust is **`custom.ARR – SF`** (Salesforce-synced; field ID is `ARR – SF`, with an en dash, not `ARR – Salesforce`).

- **Reads:** put `custom.ARR – SF` in `SELECT`, never `arr`. Prep briefs, debrief priority logic, reports, customer snapshots, feedback context, and any "Account snapshot" ARR value come from `custom.ARR – SF`.
- **Filters / sorts:** use `custom.ARR – SF` — e.g. `FILTER: {"custom.ARR – SF[more than]": "25000"}` — not `arr[more than]`. Verify the filter operator against live `get_model_action_parameters` on first use, since custom-field filters are the less-trodden path.
- **Formulas / automations:** reference `<<custom.ARR – SF>>`, not `<<arr>>`.
- **Writes:** none — `custom.ARR – SF` is SF-synced (see § Field-suffix conventions). Never write ARR of either kind.
- **If `custom.ARR – SF` is empty:** treat ARR as unknown (`-`) or fall back to the Salesforce connector (`soqlQuery`) with the usual verify tag — do **not** silently substitute native `arr`.
- **Existing docs that still say `arr`** (older examples, agent SELECT lists) are stale — follow this rule over them.

### Standard writable fields

| Field ID | Type | Description |
|---|---|---|
| `name` | string | Display name. **Required.** |
| `owner` | objectId → User | CSM / Account Manager. Do not overwrite from AISE logic. |
| `coOwner` | objectId → User | Secondary owner. |
| `phase` | string | Services lifecycle stage. **Configured options:** `0. Preparation` · `1. Activation` · `2. Adoption` · `3. Renewal` · `4. Churned`. Directly set by the AISE as the program moves stage. |
| `tags` | array | Freeform labels for segmentation. One option is configured workspace-wide: **`no-recording`** — the customer does not permit call recording. **Check this before running any transcript search.** On a `no-recording` account Gong will never hold a transcript, so the retrieval ladder in `agents/post-session-debrief.md` § 2 is guaranteed to come up empty and the debrief must fall to the facilitator-notes branch. S&P Global is the known case; a full ladder was run against it on 2026-09-12 before anyone checked the flag. |
| `country` | string | Country. |
| `domains` | array | Email/web domains for conversation matching. |
| `city` | string | City. |
| `zip` | string | Postal code. |
| `description` | string | Freeform notes. |
| `address` | string | Street address. |
| `collaborators` | array → User | Team members alongside the owner. |
| `followers` | array → User | Users following for notifications. |
| `web` | string | Company website URL. |
| `csmScore` | number (1–5) | Manual CSM gut-feel score. |
| `nps` | number | Net Promoter Score. |
| `mrr` | number | Monthly Recurring Revenue. |
| `customerFrom` | date | Date company became a customer. |
| `customerTo` | date | Date company stops being a customer. |
| `renewalDate` | date | Next contract renewal date. |
| `externalId` | string | Your own external ID for this company. |
| `orgIndependent` | boolean | Whether excluded from group hierarchy rollups. |

### Standard read-only fields

| Field ID | Description |
|---|---|
| `h` | Overall health score 0–10 (computed) |
| `hDiff` | Recent health change |
| `hDiffDate` | Date health last changed |
| `arr` | ⚠️ Native annualized MRR — **not used**; use `custom.ARR – SF` |
| `mr` | Monthly Revenue (MRR + non-recurring) |
| `mrr` | Monthly Recurring Revenue from active licenses |
| `renewalDaysFromNow` | Live countdown to next renewal |
| `renewalMrr` / `renewalArr` | Revenue at renewal |
| `lastActive` | Last end-user product activity date |
| `nextTouch` / `lastTouch` | Next/last interaction timestamps |
| `lastTouchByType.email/chat/ticket/call/note` | Last touch by channel |
| `phaseSince` | Date current phase was entered |
| `daysInPhase` | Days in current phase |
| `sentimentScore` | Sentiment across conversations |
| `orgPath`, `orgLevel`, `orgUnits`, `orgMrr`, `orgArr` | Group hierarchy fields |
| `createdAt`, `updatedAt` | Record timestamps |
| `sourceId` | Salesforce Account ID (sync key) |

### Custom fields (Productboard workspace)

> **Last verified against live `get_model_action_parameters` output: 2026-08-25.** Field sets drift. When a
> write silently no-ops or a field is missing from a read, re-pull the metadata before assuming the doc is right.

> Fields marked **[SF-SYNCED]** are populated by the Salesforce → Planhat sync. **Never write these via MCP.** The exact SF mapping is WIP; treat any unmarked field as writable only if it appears as writable in the AISE-writable table below.

#### SF-synced — do not write

| Field ID | Type | Options | Notes |
|---|---|---|---|
| `custom.ARR – SF` | number | — | ARR from SF. **Field ID is `ARR – SF`, not `ARR – Salesforce`.** |
| `custom.Customer Status – SF` | string | `1.0 Customer`, `2.0 Pipeline`, `4.0 Lost`, `5.0 Churn` | SF lifecycle |
| `custom.Account Executive` | objectId → User | — | AE relation, managed by RevOps via SF |
| `custom.Account Executive Name – SF` | string | — | AE name as text. Writable in the API but RevOps-owned in practice; do not write. |
| `custom.Renewals Manager` | objectId → User | — | RM relation, managed by RevOps via SF |
| `custom.Purchased Makers` | number | — | Contracted maker seats |
| `custom.Current Makers` | number | — | Active maker seat count |
| `custom.Purchased - Current Makers` | number | — | Seat gap roll-up |
| `custom.Slack URL` | string (formula) | — | **Internal** Productboard Slack channel for this account – the channel where PB staff discuss the customer. **Not** the shared external channel. **Locked formula, derived from `custom.Slack ID` — never write.** See the Slack-fields callout below. |
| `custom.Salesforce URL` | string | — | SF account URL |
| `custom.AI Readiness – SF` | string | `AI-Forward (Inferred/Validated)`, `AI-Interested (Inferred/Validated)`, `AI-Resistant (Inferred/Validated)` | SF-synced AI readiness |
| `custom.AI Readiness Score` | number | — | Auto-computed. **Read-only as of the 2026-08-25 check** – an earlier version of this doc described it as manually settable. Do not write. |
| `custom.Customer Type` | string | `Contract`, `Subscription`, `Contract - SatisMeter Only` | Contract shape |
| `custom.Customer Since – SF` | string | — | First customer date |
| `custom.Subscription Start Date (Earliest)` | string | — | Earliest subscription start |
| `custom.Plan Names` | string | — | All plan names on the account |
| ~~`custom.Plan Name + Version (Highest ARR)`~~ | — | — | **Removed from the Company model — verified absent 2026-09-12.** The per-contract equivalent is `custom.Plan Name + Version` on Line Item / Product / Asset. |
| ~~`custom.Plan Version (Highest ARR)`~~ | — | — | **Removed from the Company model — verified absent 2026-09-12.** See `custom.Plan Version – SF` on Line Item / Product. |
| ~~`custom.Services Plan`~~ | — | — | **Removed — verified absent 2026-09-12.** Superseded by `custom.Services Package`, `custom.Services Package (Category)` and `custom.Services Band` on Company. |
| `custom.Recent Opportunity Notes` | string | — | Latest SF opportunity notes. Useful discovery context before a first call. |
| `custom.Last AISE Touch` | string | — | Most recent AISE interaction |
| `custom.Last AISE Session` | string | — | Date of the most recent **counted** session. Driven by the eight-type formula in the Conversation section below. |
| `custom.Last AISE Email` | string | — | Most recent AISE email |
| `custom.Total AISE Sessions` | number | — | Count of AISE session Conversations |
| `custom.PHS example` | string | — | Health-score scratch field. Ignore. |

#### The three Slack fields on Company – internal vs external

There are three, they look interchangeable, and they are not. Getting this wrong is not a cosmetic error: it
writes Productboard's internal discussion of a customer onto that customer's own timeline.

| Field | Which channel | Who owns it | Use |
|---|---|---|---|
| `custom.Slack ID` | **Internal.** The PB-only channel for discussing this account, conventionally `#account-{customer}`. Channel ID, e.g. `C02N37LS25C`. | RevOps / SF, but AISE-writable | Read for internal context; written by `/log-slack-threads-internal` only after the user confirms the specific channel in chat (it syncs back toward Salesforce, so an unconfirmed write has a longer reach than a Planhat-only cache). **Never log its messages to a customer-visible record.** |
| `custom.Slack URL` | **Internal.** Same channel as above, as an `/archives/` link. | **Formula, locked — derived from `custom.Slack ID`.** | **Never write.** Read-only, always — the archive link is computed from `custom.Slack ID`, not stored independently. Writing `custom.Slack ID` is sufficient; `/log-slack-threads-internal` never attempts a write to this field. |
| `custom.External_Slack_Channel_ID` | **External.** The shared channel with the customer in it – Slack Connect or a guest channel, conventionally `#ext-{customer}`. | AISE, via `/log-slack-threads` | The only field that records a customer-facing channel, and the only one `/log-slack-threads` may resolve a sweep target from. |

> **Why the distinction is load-bearing.** `custom.Slack ID` is populated on a large share of accounts, so it
> reads as the obvious source for "which Slack channel belongs to this customer" – and it is the wrong answer
> every time. Everything in an internal account channel was written on the assumption the customer would never
> see it. `/log-slack-threads` renders channel messages near-verbatim into a Planhat Conversation, and Planhat
> records are customer-adjacent. Any tool asking "what is this customer's Slack channel?" wants
> `custom.External_Slack_Channel_ID` and nothing else.

> **A fourth field, `custom.customerSlackChannelId`, is not ours.** It was created by the Technical Account
> Manager team, is empty on every account, and is slated for removal. Do not read it, do not write it, and do
> not wire anything new to it – the AISE cache is `custom.External_Slack_Channel_ID`. When it disappears from
> the Company model, that is the planned deletion, not schema drift.

> **Writable in the API but RevOps-owned – do not write:** `custom.Segment`, `custom.Region`
> (`EMEA`/`NOAM`/`APAC`/`LATAM`/`AUNZ`/`Missing`/`Exclude`/`Blacklisted`). These report as writable in
> `get_model_action_parameters` but are maintained upstream, and no skill in this plugin writes them.
>
> **`custom.Slack ID` is the one exception to that rule.** It syncs back toward Salesforce like the fields
> above, but it is the intended cache for `/log-slack-threads-internal` and it **does** write it — only after
> the user has confirmed the resolved channel in chat, never on an unconfirmed guess, and never overwriting a
> populated value that disagrees with what was just swept without surfacing the conflict first. (Corrected
> 2026-08-28 — an earlier version of this doc listed `custom.Slack ID` in the same "do not write" bucket as
> `custom.Segment`/`custom.Region`; it is writable and is meant to be written, just gated on confirmation rather
> than free.) **`custom.Slack URL` is not part of this exception** — it is a locked formula field derived from
> `custom.Slack ID`, never written directly, by this skill or any other.

> **Removed since the previous snapshot:** `custom.⚡️ Days in Current Ignite Stage` is no longer present on the
> Company model. Do not read or write it.

#### AISE-writable

| Field ID | Type | Options | Notes |
|---|---|---|---|
| `custom.Priority (temp – Notion)` | string | `P0`, `P1`, `P2`, `P3`, `P4` | ← Notion Customer `Priority`. Temp field pending a native Planhat solution. Omit if Notion value is `Insufficient Data`. |
| `custom.AI Ready` | string | `Ignitable`, `Sparked`, `Preparing`, `Not Ready` | ← Notion `AI Ready` (unchanged) |
| `custom.⚡️ Igniting?` | boolean | `true` / `false` | ← Notion `Igniting?`. **Renamed 2026-08-07** (was `custom.Igniting?`). |
| `custom.AISE Journey Status` | string | `Presales`, `Active (no Services)`, `Active (Services)`, `Contracted to Scale`, `Churned` | ← Notion `Account Status`. **AISE-managed accounts only (30k+ ARR).** Do not write for AIPA accounts. **`Not started` is not a valid option — omit.** Note: field ID is `custom.AISE Journey Status`, not `custom.Journey Status`. |
| `phase` | string | **Configured options (not free-text):** `0. Preparation` · `1. Activation` · `2. Adoption` · `3. Renewal` · `4. Churned` | Universal field — applies to **all** Planhat companies (AISE and AIPA). **Directly set** by the AISE as the program moves stage — there is no Notion Active Package to derive it from anymore. `4. Churned` is set manually and aligns with `custom.AISE Journey Status = Churned`. |
| `custom.SH_Current State` | string (Rich text) | — | **Sales Handoff** (SH_ = "Sales Handoff"): current state from pre-sales. Auto-populated on deal close for AISE-segment accounts — not manually written by AISE. Read for discovery context. |
| `custom.SH_Future State` | string (Rich text) | — | Sales Handoff: desired future state from pre-sales. Auto-populated on deal close. |
| `custom.SH_Negative Impacts` | string (Rich text) | — | Sales Handoff: pain points from pre-sales. Auto-populated on deal close. |
| `custom.SH_Positive Outcomes` | string (Rich text) | — | Sales Handoff: value / expected outcomes from pre-sales. Auto-populated on deal close. |
| `custom.Services Package?` | array | `V13`, `Premier Services`, `Custom SOW`, `Essentials`, `N/A` | **To be architected in Planhat** as a roll-up from the Active Product with the services SKU toggle — not a direct Notion field write. Do not populate from Notion during migration. |
| `custom.Next Step` | string (Rich text) | — | **The account's current next action.** Written after an outbound touchpoint actually lands (a sent reply, a completed debrief), not when a draft is created. Keep it a short dated sequence with owners: what was just done, what is being waited on, what happens when it clears. Overwrite rather than append – this is a current-state field, not a log. Session history belongs in Conversations. **Rich text — format per § Rich Text Field Formatting below, never plain/`\n`-separated prose.** Refreshed by `post-session-debrief` (step 10, every run), by `inbox-triage` (after a sent reply), and by `account-refresh` (`/customer-refresh`) – which, when it has only drafted the outbound email, says `drafted, send pending` rather than claiming a send. |
| `custom.Gong Summary` | string | — | Rolling Gong-derived account summary. |
| `custom.CAB Customer` | boolean | `true` / `false` | Customer Advisory Board member. |
| `custom.External_Slack_Channel_ID` | string | — | **The customer ↔ shared external Slack channel pairing, cached.** Channel **ID** only, upper-case (`C0AKKLJCB5E`) – never a `#name` (channels get renamed), never a URL (the value feeds `slack_read_channel` and the `/log-slack-threads` `externalId` builder directly). Written by `/log-slack-threads` the first time it resolves a channel for the account; read on every later run, which is what lets that skill take a channel *or* a customer name as input. Write only when empty or when the user has just corrected it – a resolved channel that disagrees with a populated value is a conflict to surface, not a value to overwrite (an account can have two shared channels; the field holds one). **New field: Planhat custom fields lag in MCP metadata, so it may be absent from `get_model_action_parameters` and reject writes for a while. A failed write is reported, not fatal.** Strictly the **external** channel – see the Slack-fields callout above; `custom.Slack ID` / `custom.Slack URL` are the internal channel and are never a substitute. |
| `custom.PM Reach-Out Status` | string (list) | `Free to Contact`, `Ask First`, `Do Not Contact` | **Added 2026-08-28** — built out of the Aug 2026 Anthony Amenta (Product Ops) thread on flagging accounts safe for direct PM reach-outs. Whether a PM can contact this account directly without looping in the account team first. Set and maintained by AISE based on account health, deal stage, and open escalations – not auto-computed from `csmScore`/`h`/Deal/Issue data, since the hard-stop judgment call needs a human. `Free to Contact` = go ahead (PM should still check recent activity first if `custom.ARR – SF` is under $30K). `Ask First` = PM messages the account owner in the account's Slack channel before reaching out, regardless of ARR. `Do Not Contact` = hard stop – active negotiation, red health, or an open escalation. Pair with `custom.PM Reach-Out Note` and check `custom.PM Reach-Out Reviewed` for staleness before trusting the value. |
| `custom.PM Reach-Out Note` | string (Rich text) | — | Why the account has its current `custom.PM Reach-Out Status` – required whenever status is `Ask First` or `Do Not Contact`. Short and dated: what's going on, what would need to change for the status to move. **Rich text — format per § Rich Text Field Formatting, never plain/`\n`-separated prose.** |
| `custom.PM Reach-Out Reviewed` | string (date) | — | Date AISE last set or confirmed the current `custom.PM Reach-Out Status`. A Planhat workflow automation stamps today's date whenever the Status field changes; can also be set manually during a periodic review that reconfirms the value without changing it. Used to flag a stale status rather than trusting it blindly. |
| `custom.Engagement Plan` | string (Rich text) | — | **Added 2026-09.** The full program plan — goals, milestones, phases, session sequence — for the account, written by `engagement-planner` (`/customer-plan --full`) on user approval. Replace wholesale on each revision; not an append/log field. `account-refresh` (`/customer-refresh`) refreshes status sections (workstream status, sessions delivered, open items, risks) in place and does not restructure goals or phases. **Rich text — format per § Rich Text Field Formatting, never plain/`\n`-separated prose. No `<h1>`–`<h6>` — use bold `<p><strong>` section labels.** |
| `custom.Architecture Details` | string (Rich text) | — | **Added 2026-09.** The customer's Productboard workspace setup for reference during architecting sessions — taxonomy structure, internal teams using the workspace, toolstack integrations, how the customer organizes their environment. Kept current by architecting-session agents (`kdd-builder`, `session-prepper`, `account-setup`) and by `account-refresh` (`/customer-refresh`) as a running reference, not a session-by-session log. **Rich text — format per § Rich Text Field Formatting.** |
| `custom.Organization Details` | string (Rich text) | — | **Added 2026-10.** Who the customer is and who we deal with: what they bring to market and why they bought, org structure and business units, product teams, champions and stakeholders (name – title – what they own), the Productboard account team, commercial summary, headcount and growth signals. Written and kept current by `account-refresh` (`/customer-refresh`). **Titles come from End User `position`** (Salesforce-synced), never from session notes or Slack – internal notes get titles wrong. Unconfirmed attributions are written as unconfirmed. Current-state reference: refresh in place, not a log. **Rich text — format per § Rich Text Field Formatting. No `<h1>`–`<h6>` — use bold `<p><strong>` section labels.** |

> **Salesforce/Productboard mirror.** `custom.PM Reach-Out Status/Note/Reviewed` are mirrored one-way (Planhat → Salesforce → Productboard) onto `PM_Reachout_Status__c` / `PM_Reachout_Note__c` / `PM_Reachout_Reviewed__c`, the same proxy pattern as the existing `ASE_Name__c` mirror — Salesforce holds these fields only so Productboard's integration (which reads Salesforce, not Planhat) can surface the value to PMs. Planhat is the source of truth; never write these SF fields directly or build SF-side logic against them.

#### Spark fields — Company (AISE scope)

> **Scope: AISE only.** This assistant serves the AISE team (30k+ ARR accounts). Fields prefixed or labelled **AIPA** belong to a different team's motion. **Ignore them entirely** – do not read them to make a decision, do not write them, do not surface them in output, and do not build logic on them: `custom.AIPA Active Motion`, `custom.AIPA Next Best Action`, `custom.Spark Journey - AIPA`, `custom.[AIPA] Lifecycle campaign`, `custom.AIPA ARR Band (to be removed - do not use)`. If a record carries a value in one of them, that is the other team's state, not ours.
>
> **Last verified against live `get_model_action_parameters`: 2026-10-07.** On a multi-workspace account, prefer the per-workspace Asset fields (§ Asset / Workspace) over the account-level flags below.

**Account roll-up (formula / automation – never written)**

| Field ID | Type | Notes |
|---|---|---|
| `custom.Spark Visibility (Account)` | string (formula) | **Source of truth** for who can see Spark across revenue-bearing workspaces: `Everyone`, `Admins only`, `Mixed`, `Spark off`, `Spark not enabled`, `No revenue-bearing workspace`. Use this for scope and reporting. Derived from the four `Spark WS` counts – see § Asset / Workspace. |
| `custom.⚡️ Spark Stage` | string (list) | Automation-maintained copy of `Spark Visibility (Account)`, stored as a list so it can be filtered, grouped and used on dashboards. Same six values. **Never edited by hand, never written by an agent.** If it disagrees with `Spark Visibility (Account)`, the formula is right and this field has not caught up. **Stale options to never use:** `Off`, `AI Terms Review`, `Icebox`, `Not Active`, `Active for Admins`, `Active for All`, `Active on Staging`. |
| `custom.Spark WS Paying` / `Spark WS Everyone` / `Spark WS Admins Only` / `Spark WS Enabled` | number (formula) | Counts of revenue-bearing workspaces (Asset `ARR – SF` > 0). `Paying` is the denominator. Never written. `Paying = 0` is usually a Salesforce data gap, not an unpaid account. |

**Live Snowflake flags – `– SNF`, never written**

| Field ID | Type | Notes |
|---|---|---|
| `custom.Spark Enabled – SNF` | boolean | Spark switched on for the account at all. The gate for Spark in Practice scope. |
| `custom.Spark Engaged – SNF` | boolean | Someone reached L2 – ran a skill or submitted a Spark prompt. Live value, not the weekly snapshot. |
| `custom.Motion – SNF` | string | `Ignite` · `Strike`. |

**Dates and consent – CSV-sourced (`temp-ph-ignite-conversion-data-sync`)**

| Field ID | Type | Notes |
|---|---|---|
| `custom.⚡️ Spark Enabled Date` | string | When Spark was enabled. |
| `custom.⚡️ Spark Active For Since` | string | When the current visibility setting took effect. |
| `custom.⚡️ Spark Engaged Date` | string | When engagement was first detected. |
| `custom.⚡️ AI Consent` | string | Where the account stands on AI terms. **AISE-writable** – set it when a terms review, extension request, or acceptance moves; it tells the team the account is mid-flight rather than untouched. |

**Spark in Practice**

| Field ID | Type | Notes |
|---|---|---|
| `custom.[SIP] Tier` | string (list) | Tier from the Data team's CSV, read-only. Options (pass the **full string** when filtering): `T1 - Priority outreach: enabled + visible, not yet ignited` · `T2 - Second wave: ignited, not yet adopted` · `T3 - Adopted/transitioned (sustain)` · `T4 - Open visibility first: enabled, admins-only` · `T5 - Enablement motion: Spark not enabled` · `T6 - No outreach: churned / planning to churn`. What each tier changes: `context/initiatives/spark-in-practice.md`. |
| `custom.[SIP] Rank in Tier` | number | Priority rank within the tier. Lower is higher priority. Read-only. |
| `custom.⚡️ SIP Session Delivered?` | boolean | At least one call delivered titled "Spark in Practice". Computed, read-only. |
| `custom.⚡️ # of SIP Sessions Delivered` | number | How many Spark in Practice sessions were delivered. Computed, read-only. |
| `custom.⚡️ Igniting?` | boolean | Have talks about Spark started? AISE-writable (listed above). |
| `custom.AI Ready` | string | `Ignitable`, `Sparked`, `Preparing`, `Not Ready`. AISE-writable (listed above). |

**Spark exemption**

| Field ID | Type | Notes |
|---|---|---|
| `custom.Spark Exemption – SF` | boolean | Is this customer on the Spark exception approved list? **Salesforce-sourced** (`– SF`), read-only, never written. Renamed from `– SNF` on 2026-10-07; as of that date live Planhat metadata still reported the old `custom.Spark Exemption – SNF` ID. Use `– SF`; if a filter or `SELECT` errors on it, re-pull the Company metadata, and fall back to `– SNF` only until the rename lands. |
| `custom.Spark Exemption Context` | string (Rich text) | **AISE-writable.** Running context on Spark development for exempted accounts, sourced from `#ops-spark-exemption` and kept current by the account team: exemption reason, what was agreed and with whom, current status, open questions, next steps. **Format:** dated entries `YYYY-MM-DD – update – author`, **newest on top**. Never overwrite earlier entries; mark resolved items as resolved instead of deleting them. Leave empty if the account has no exemption. **Rich text – format per § Rich Text Field Formatting.** |

> **Read `custom.Spark Exemption Context` first.** Before any Spark-related action, outreach, draft, session prep or reporting on an account, read this field and treat its **newest dated entry as the current state**. An exempted account (`custom.Spark Exemption – SF` = `true`) is not a candidate for standard Spark in Practice outreach on the strength of its tier alone. Add to the field (a new dated entry on top) when a session or thread changes the exemption picture; never remove history.

#### `phase` vs `custom.AISE Journey Status`

| | `phase` | `custom.AISE Journey Status` |
|---|---|---|
| **Scope** | All Planhat companies | AISE-managed accounts only |
| **What it tracks** | Universal services lifecycle stage (Preparation → Activation → Adoption → Renewal → Churned) | AISE program-specific status (Presales / Active / Contracted to Scale / Churned) |
| **Segment rule** | AISE accounts (30k+ ARR) ✅ · AIPA accounts (under 30k ARR) ✅ | AISE accounts (30k+ ARR) ✅ · AIPA accounts (under 30k ARR) ❌ |
| **Source of value** | Directly set by the AISE | Directly set by the AISE |

> `phase` is the shared, segment-agnostic signal for where any customer sits in the services lifecycle. `custom.AISE Journey Status` is an AISE overlay that only applies to the 30k+ ARR accounts the AISE team manages. AIPA uses `phase` to track lifecycle stage — their accounts will not have an AISE Journey Status populated.

---

### Field-suffix conventions — `– SF` and `– SNF` are never writable

Two suffixes mark a field as **live-sourced from an upstream system**. Both use an en dash, not a hyphen.

| Suffix | Source | Rule |
|---|---|---|
| `– SF` | Salesforce, live | **Never write.** Planhat is downstream; a write is overwritten on the next sync and creates a silent disagreement in between. |
| `– SNF` | Snowflake, live | **Never write.** Same reasoning. These carry product-usage and Spark telemetry. |

This holds even when the model metadata reports `readonly: false` — several `– SNF` fields accept writes and should still never receive one. **Treat the suffix as authoritative over the `readonly` flag.**

When a field you need to write appears to be `– SF` or `– SNF`, the answer is not to write it anyway. Either the value belongs somewhere else, or the upstream pipeline needs to carry it — raise it rather than working around it.

## Write Rules

- **Never write SF-synced fields.** See the SF-synced table above. This includes account fields (Region, Segment, ARR, Makers, Slack, Account Executive, etc.), Deal records, and Line Item records. Do not write these even if the field appears blank — the sync owns them. Exact mapping is WIP; when uncertain, treat a field as SF-synced unless it appears in the AISE-writable table.
- **Never write read-only fields** — Planhat will error.
- **Custom field prefix:** always use `custom.` (e.g. `"custom.⚡️ Igniting?": true`). Note some field IDs include an emoji (`⚡️`) as a literal part of the ID — see the 2026-08-07 rename notes above.
- **Boolean custom fields:** use raw `true`/`false`, not strings.
- **Option values:** exact casing required (e.g. `"Not Ready"` not `"Not ready"`).
- **Do not overwrite `owner`** — managed by RevOps/CS leadership.
- **Company records are SF-synced** — do not create new Company records via MCP. Creation is handled by RevOps via Salesforce sync.
- **Unknown keys are dropped silently on create and update.** See § MCP Access → silent failure 3 for the verified evidence and the Task alias table (`name`/`assignee`/`dueDate` are the three that bite). Use exact field IDs from `get_model_action_parameters`, never a guessed or remembered alias.
- **Read back after every create.** `SELECT` the fields you just wrote and assert they landed with the right casing. A `200` proves nothing about which keys survived.

### Session record resolution — never create a duplicate

**Rule: never create a Task or Conversation for a session until you have proven that neither exists, keyed on the Google Calendar event ID.** Title search is not proof — it misses on renamed events, matches sibling meetings, and is what historically produced duplicate session records. This ladder is mandatory for every prep-notes write, every debrief write, and every backfill.

#### The key: the GCal event ID, in two forms

Planhat's Google Calendar sync stamps the calendar event ID onto the records it creates:

| Record | Field | Value |
|---|---|---|
| Task (`mainType: "event"`) | `sourceId` | The GCal event ID |
| Conversation (created when that Task is completed) | `externalId` | The same GCal event ID |

Two ID shapes exist and **both must be tried**:

| Shape | Example | When |
|---|---|---|
| Bare event ID | `ip5dj5rdolaa07e56is5m19lo4` | One-off events |
| Instance-stamped | `3vp2g7sd56da48ljp2qa1cgfvu_20261124T213000Z` | A single occurrence of a recurring event |

The Calendar MCP returns the instance-stamped form as `event.id` for recurring occurrences. Derive both candidates before querying: `event.id` as returned, and the segment before the first `_` when one is present.

#### Resolution ladder

Run in order. Stop at the first hit.

1. **Conversation by event ID** — `list_model_records(MODEL: "Conversation", FILTER: {"externalId[equal to]": "<candidate>"})`, once per candidate ID.
   → **Hit** means the session is already logged: someone marked the calendar Task done and Planhat converted it into this Conversation. Write prep notes, Gong details and session notes **here**. Do not create anything, and do not write to a Task.
2. **Task by event ID** — `list_model_records(MODEL: "Task", FILTER: {"sourceId[equal to]": "<candidate>"})`, once per candidate ID. `sourceId` is unique across Tasks, so the filter is exact and the Task-model result cap does not apply. **Use `equal to` only:** `sourceId[starts with]` fails with "Failed to fetch Task records" (observed 2026-10-06). A recurring occurrence may match only on the instance-stamped ID and not the bare base ID (seen on a weekly recurring sync), which is why both candidates are always tried.
   → **Hit** means the session is on the calendar and not yet logged. Write prep notes onto the **Task's** `custom.Prep Notes`, and set `type` if unset.
3. **Fallback match on company + date + title** — only reached when both ID lookups miss on both candidate forms (GCal sync disabled for the account, event created outside the synced calendar, or an AISE-authored record predating the sync). `search_records(QUERY: "<event title>")`, filtered to `companyId` and to a `startTime`/`endTime`/`date` day match. Treat a hit here as the session's record, and **note in the run report that it was matched by title rather than event ID** so the ID drift is visible.
4. **Create — last resort, and say so.** Only when steps 1–3 all miss. Create the record the ladder was looking for (a Task for a future session, a Conversation for a delivered one), set `sourceId` / `externalId` to the calendar event ID so the next run resolves at step 1 or 2, and report `"created — no GCal-synced record found for event <id>"`. **A create with no `sourceId` / `externalId` is a bug**: it has no dedup key, can never be matched again, and Planhat rejects later API updates to a Conversation that has no `externalId`.

#### The Task and its Conversation share an `_id`, but not their fields

When Planhat converts a completed event Task, the Conversation it creates carries the **same `_id`** as the Task (and `taskId` == `_id`). They remain two records with independent custom-field stores: writing `Conversation.custom.Prep Notes` does not touch `Task.custom.Prep Notes`.

**Planhat conversion carries `type`, `subject`, `externalId`, `endusers`, `users` and `custom.Motion Category`. It does not carry `custom.Prep Notes`, and it overwrites `date` with the conversion moment** (verified 2026-10-07: `date` came back as the conversion time, 08:54Z, against a 16:00Z Task `startTime`, with no Prep Notes). Every post-conversion write must therefore restore `date`, `startDate` and `custom.Prep Notes` from the Task, and read them back. The same applies after re-firing conversion (Task `status` `"To Do"` then `"done"`, which creates a fresh Conversation with `_id` = Task `_id`; verified 2026-10-07). Two consequences:

- **The Task's copy goes stale on purpose.** Once the ladder resolves to a Conversation, the Task is historical and nobody writes to it again — so a session prepped before its conversion keeps that older brief on the Task view indefinitely. Expected, not a bug.
- **It makes the timestamp fix cheap.** `get_model_record(MODEL: "Task", OBJECT_ID: "<conversation._id>")` returns the coupled Task — and its `startTime`, the real session start — in one call, with no `sourceId` lookup. That is why the ladder in § Session timestamp starts there.

#### Do not write to two records for the same session

If step 1 hits, the Task (if one still exists) is historical — leave it alone. If step 2 hits, the Conversation does not exist yet and must not be created ahead of the Task's completion; Planhat will create it. Writing the same prep notes to both is how the same session ends up looking like two.

### Session timestamp — always correct `Conversation.date` from a real source

**`Conversation.date` is wrong by default on every session record Planhat creates from a calendar event.** When a `mainType: "event"` Task is marked done, Planhat stamps the new Conversation's `date` with **the moment of conversion** — when the task was ticked off — not the session's start time. The drift is however long you took to mark it done. Verified 2026-08-29 on two untouched records:

| Record | Task `startTime` (truth) | Conversation `date` as created | Drift |
|---|---|---|---|
| IBS Software `6a8c5defe1739d6cb5c88886` | 2026-08-25T10:00:00Z | 2026-08-25T11:13:47.043Z | +74 min |
| Validity `6a75d97d97ccd97bc0fcd795` | 2026-08-25T20:30:00Z | 2026-08-27T16:00:27.712Z | +2 days, wrong day |

Millisecond precision on `date` is the tell — a real session start is a round minute, a write timestamp is not.

**This is a Planhat behavior we cannot switch off, so every agent that touches a session Conversation corrects it.** The correction is cheap: the true start time is preserved on the coupled Task and never overwritten.

#### The timestamp ladder — run in order, stop at the first hit

1. **Coupled Planhat Task `startTime`** — the record resolved by § Session record resolution. Cheapest and authoritative: the GCal sync wrote it and nothing overwrites it. Note the Task and its Conversation share an `_id`, so `get_model_record(MODEL: "Task", OBJECT_ID: "<conversation._id>")` fetches it in one call with no extra lookup.
2. **Google Calendar event start** — `event.start.dateTime` for the event the run already has in hand.
3. **Gong call date** — the `date` on the `👾 Gong Call` Conversation for the same call, or the call's start time from a Gong lookup the run already performed.
4. **No source available** → leave `date` untouched and report it. Never invent a time, and never fall back to midnight.

**Write the full UTC timestamp:** `date: "2026-08-27T08:30:00.000Z"`. Never `T00:00:00.000Z` — a midnight stamp is a silent data-loss bug, not a neutral default. It breaks date-proximity matching (`ph-reconcile-gong-gcal` scores a midnight target ~511 minutes off its own call and misses it inside the default ±4h window), it misorders same-day sessions on the account timeline, and it makes duration and same-day dedup checks meaningless.

`startDate` / `endDate` are typed `date` (day granularity), not `date time` — set the session day there, and keep the time in `date`.

**Correct on every touch, not only on create.** If a run resolves an existing session Conversation whose `date` disagrees with the ladder's source by more than a minute, include the corrected `date` in the same `update_model_record` call it was already making, and say so in the run report:

```
Corrected date: 2026-08-27T00:00:00.000Z → 2026-08-27T08:30:00.000Z (source: coupled Task startTime)
```

**Applies to session-type Conversations only** — the counted session types plus `📆 Onsite Workshop`, `📺 Webinar`, `🎙️ Demo` and `Internal Alignment`. Do **not** apply it to `💬 Slack Chat` (dated on the thread's last message by its own documented rule), to `email` / `chat` / `ticket` records (the source system's timestamp is correct), or to `👾 Gong Call` records (Gong's own call time is already right).

### Rich Text Field Formatting

Planhat rich text fields (type `Rich text`) are a ProseMirror editor (`ph-editor`) backed by **single-line HTML**. Markdown-style `- ` bullets do not render, and literal `\n` / `\r\n` are **stripped by the API on write** (verified 2026-08-27 against Task `custom.Prep Notes`) — every element must be adjacent on one line.

The tag set below is the editor's own serialization, captured by formatting a field by hand in the Planhat UI and reading the stored value back through MCP. Treat it as the whole allowed vocabulary: markup outside it is sanitized on load or renders broken.

| Element | Markup |
|---|---|
| Paragraph | `<p>text</p>` |
| Blank line / spacer | `<p></p>` |
| Section label | `<p><strong>Label</strong></p>` — **no `<h1>`–`<h6>`; the editor has no heading node** |
| Emphasis | `<strong>text</strong>` · `<em>text</em>` |
| Bulleted list | `<ul class="ph-editor__bullet-list"><li class="ph-editor__list-item"><p>text</p></li></ul>` |
| Numbered list | `<ol class="ph-editor__ordered-list"><li class="ph-editor__list-item"><p>text</p></li></ol>` |
| Quote / callout | `<blockquote><p>text</p></blockquote>` |
| Link | `<a href="{url}">text</a>` — stored unchanged and clickable in the Planhat UI (verified 2026-10-08) |
| Divider | `<hr>` |
| Table | `<table><colgroup><col style="width: 301px;"><col style="width: 301px;"></colgroup><tbody><tr><td data-colwidth="301"><p>cell</p></td><td data-colwidth="301"><p>cell</p></td></tr></tbody></table>` |

**List items require both the `ph-editor__*` classes and an inner `<p>`.** Bare `<ul><li>text</li></ul>` is the documented cause of the old "1. / blank / 2. / blank" mangling — the editor drops a list item that has no paragraph node inside it. The earlier guidance in this file to use bare `<ul><li>` was wrong and has been replaced.

Optional attributes the editor emits and accepts, but that are not needed on write: `style="text-align: left;"` on `<p>`, and `style=""` on `<table>`.

**Unverified:** `<u>`, `<s>`, `<code>`. Don't introduce them into a shipped write path without checking the rendered result first.

**Links:** never write a bare URL into a rich-text field — wrap it in `<a href>` so it is clickable. Artifact links use the Session artifact shape in `context/session-artifact-convention.md` § 6.

**Applies to every Planhat rich-text field, not just prep notes.** The same vocabulary and the same structure rules govern: `Task.custom.Prep Notes`, `Conversation.custom.Prep Notes`, `Conversation.description` (session notes), `Task.description`, `Company.custom.Next Step`, the `custom.SH_*` sales-handover fields, and Comment bodies. **Never write plain text or `\n`-separated text into any of them** – it lands as one unbroken run and is unskimmable. If a field's content has more than one part, it gets bolded labels and lists.

**Gold-standard reference record:** Task `6a73dff47c78485e7c3daa27` (Unit4 program sync, 27 Aug 2026) – `custom.Prep Notes`. Read it before writing a prep brief; it is the shape below, rendered.

### Canonical prep-brief structure

Section order, top to bottom. Skip a section when there is genuinely nothing in it; never reorder.

| # | Section | Markup | Content rule |
|---|---|---|---|
| 1 | Header | `<p><strong>…</strong></p>` | `{Customer} – {Session type} – {Day DD Mon YYYY, HH:MM–HH:MM TZ} ({duration}, {tool})` |
| 2 | Attendees | `<p>…</p>` | Named attendees with role in parentheses, plus who may join. One line, no list. |
| 3 | Booking note | `<blockquote><p>…</p></blockquote>` | The customer's verbatim ask **plus what it implies for how the session should run**. The implication is the point – a bare quote adds nothing. |
| 4 | Divider | `<hr>` | Separates the header block from the body. Exactly one. |
| 5 | Session artifact | `<p><strong>Session artifact</strong></p>` + `<ul>` | One `<li>` per artifact – `<strong>{ArtifactType}</strong> – <a href="{webViewLink}">{filename}</a>` – then `<strong>Folder</strong> – <a href="{folderUrl}">Customer Session Artifacts</a>`, then `<strong>Salesforce Account</strong> – {id}` as plain text. Exactly one such section, upserted by filename, never prepended above the header. Full rule: `context/session-artifact-convention.md` § 6. Omit when the run produced no artifact. |
| 6 | Account snapshot | label + `<ul>` | Journey status / priority / ARR / renewal, Spark state, Makers, tenure. Each item leads with a bolded label. |
| 7 | Agenda | label + `<ol class="ph-editor__ordered-list">` | `<strong>{topic}</strong> – {n} min. {what to establish}`. Minutes must sum to the session duration. |
| 8 | Goals | label + `<ul>` | Outcomes to leave with, not activities. 3–5 items. |
| 9 | Carried open items | label + `<ul>` | `<strong>{item}</strong> – {owner, and since when}`. This is the chase list. |
| 10 | Since last session ({date}) | label + `<ul>` | Date-led: `<strong>{DD Mon}</strong> – {what happened}`. Chronological. |
| 11 | Watch-fors | label + `<ul>` | Risks, relationship context, verbatim quotes worth having in front of you. |

**Structure rules for any rich-text write.** Bold section label, then a list – not prose paragraphs. Lead each list item with a bolded subject, date, or owner, then one sentence of detail. 3–6 items per section. Length: roughly 1,200–2,000 chars of visible text for a prep brief; markup does not count.

**Voice rules apply to the sentence content, every time.** Read `custom.AISE Profile preferences` on the user's Planhat User record first (§ the resolver in `CLAUDE.md`). For the current profile that means **en dashes (`–`) everywhere, never em dashes (`—`)**, US English, no semicolons in prose, and none of the listed filler openers. The examples in this file use en dashes deliberately – copy them literally rather than reaching for an em dash. Existing records in Planhat predate this rule and still contain em dashes; do not treat them as the style reference.

**Combined example** (a full prep brief, one line, en dashes throughout):

```html
<p><strong>Customer – Program sync – Thu 27 Aug 2026, 13:30–14:00 CEST (30 min, Zoom)</strong></p><p>Attendee Name (Product Operations Director). Second Attendee (Product Operations) may join.</p><blockquote><p>Booking note: "Migration update/questions" – they picked this week deliberately, right after their rollout lands, so expect live questions rather than a status readout.</p></blockquote><hr><p><strong>Agenda (30 min)</strong></p><ol class="ph-editor__ordered-list"><li class="ph-editor__list-item"><p><strong>Rollout status</strong> – 10 min. What went live, what broke, what is still open.</p></li><li class="ph-editor__list-item"><p><strong>Integration error</strong> – 5 min. Support ticket #145383; close the loop on where it stands.</p></li></ol><p><strong>Goals</strong></p><ul class="ph-editor__bullet-list"><li class="ph-editor__list-item"><p>Confirm the rollout is live and clear any blockers it surfaced.</p></li></ul><p><strong>Carried open items</strong></p><ul class="ph-editor__bullet-list"><li class="ph-editor__list-item"><p><strong>OAuth app setup</strong> – progress unconfirmed since 31 Jul.</p></li></ul><p><strong>Since last session (31 Jul)</strong></p><ul class="ph-editor__bullet-list"><li class="ph-editor__list-item"><p><strong>4 Aug</strong> – MCP closed beta confirmed live on their workspaces.</p></li></ul><p><strong>Watch-fors</strong></p><ul class="ph-editor__bullet-list"><li class="ph-editor__list-item"><p>Adoption is still single-threaded through one champion.</p></li></ul>
```

**Before writing, sanity-check the payload:** one line with no `\n`; every `<li>` carries `class="ph-editor__list-item"` and wraps its text in `<p>`; every `<ul>`/`<ol>` carries its `ph-editor__*` class; no `<h1>`–`<h6>`; no em dashes.

> **Custom field reads:** Custom fields are returned nested under a `custom` key in the response — e.g. `{"custom": {"SH_Current State": "<ul>...</ul>", "AISE Journey Status": "Active (Services)"}}`. Use `list_model_records` (not `get_model_record`) with an `_id[equal to]` filter for the most reliable custom field retrieval.
>
> **Schema sync:** The MCP connector caches the field registry at connection time. Custom fields added after the last connector sync will not appear in `get_model_action_parameters` and cannot be read back via SELECT until the connector is reconnected in Claude settings (Settings → Connectors → Planhat → reconnect). Writes to newly-added fields still succeed even before a reconnect.

---

---

## Planhat User IDs (AISE team)

Used when setting `ownerId`, `users`, or `followers` on Planhat records.

| Name | Email | Planhat `_id` |
|---|---|---|
| Klara Martinez | klara.martinez@productboard.com | `6a44ef76c9aade50502936d5` |
| Ozzy Gundogdu | ozan.gundogdu@productboard.com | `6a44ef5d102afd78d3f233ee` |
| Tesh Patel | tesh.patel@productboard.com | `6a44ef91c9aade0b562936eb` |
| Molly Goulding | molly.goulding@productboard.com | `6a4cc33f2af0cb301f0bd119` |
| Jennifer Bombera | jennifer.bombera@productboard.com | `6a6c84fcf260dae164c0d6e3` |
| Alexander Stergiou | alexander.stergiou@productboard.com | `6a51156d327589773c8fb61d` |
| Denae Foster | denae.foster@productboard.com | `6a6c90e1dcf4f051bd5d1159` |
| Alex Degregori | alex.degregori@productboard.com | `6a6c90e1dcf4f00a685d1139` |
| Michael Pang | michael.pang@productboard.com | `6a6c90e1dcf4f0408a5d1199` |
| Raphael Dozolme | raphael.dozolme@productboard.com | `6a6c84e02c2e343c6f9a5241` |
| Elizabeth Johnstone | elizabeth.johnstone@productboard.com | `6a4cc31c2af0cba3a10bd0fd` |
| Carson Mak | carson.mak@productboard.com | `6a4f72300b5e9f5803437923` |
| Darrel Wu | darrell.wu@productboard.com | `6a4f72473275894bcf89ee78` |
| Tomas Krivanek | tomas.krivanek@productboard.com | `6a50db36f7236907a27c11c3` |

**Runtime resolution:** agents that need Klara's Planhat ID (the current user) can use the hardcoded value above. For other team members, resolve via `list_model_records(MODEL: "User", FILTER: {"email[equal to]": "<email>"}, SELECT: ["firstName", "lastName", "email"])` if the ID is not in this table.

---

## Conversation (Planhat) ↔ Session (Notion)

> **Design note:** Planhat Conversations are the canonical home for AISE session history. AISE writes all delivered sessions (external and internal) as Conversations with `source: "AISE"`, using `externalId` as the dedup key back to Notion. Existing Conversations in Planhat are mostly Zendesk tickets (`source: "zendesk"`) and calendar events synced as Tasks (`mainType: event`). AISE-originated sessions are a distinct type and won't collide with those sources.

### `externalId` convention — live sources, no collision risk

Multiple tools write Conversations from session data, each with its own `externalId` format:

| Path | `externalId` source | Notes |
|---|---|---|
| `/session-debrief` (`post-session-debrief`) | Google Calendar event ID | Live, per-session debrief path. |
| `/session-backfill` | Google Calendar event ID (bare or instance-stamped) for calendar-sourced candidates; `gong_{gongCallId}` for a Gong-only candidate with no matching calendar event | **Rewritten 2026-09 — Notion is fully retired.** `/session-backfill` no longer sources sessions from Notion, so its old convention (Notion Session page ID, 32-char hex) no longer applies; historical records created under that convention still exist and are recognizable by their format. Reusing the GCal event ID for calendar-sourced backfills means a backfilled record and a later `/session-debrief` write for the same event resolve to the same Conversation via the session-record resolution ladder, rather than creating a second record. The `gong_` prefix on the Gong-only fallback keeps it distinct from both the GCal event ID shape and Gong's own native-sync `externalId` (`{gongCallId}-{sfAccountId}`, on a separate `👾 Gong Call` record). |
| `/log-slack-threads` | `slack_{channelId}_{parentTsDigits}` | Shared-channel Slack threads logged as `💬 Slack Chat` touchpoints. Prefixed, so it never collides with the ID formats above and is trivially identifiable. |

`externalId` is scoped per-company, and none of these formats collide with each other (different length/character set, or a distinguishing prefix), so all conventions coexist safely. Don't assume a Conversation's `externalId` is a Notion page ID just because an older record uses that format — check the format before parsing it.

---

### Slack Chat Conversations (`/log-slack-threads`)

Threads from a shared customer Slack channel are logged as touchpoints, one Conversation per thread. These are
**not sessions** – `💬 Slack Chat` is in the not-counted list above, and a Slack record must never be used to
close a session gap or retyped into a counted type to move a number.

| Field | Value | Notes |
|---|---|---|
| `type` | `💬 Slack Chat` | Exact string including the emoji. |
| `source` | `Slack` | |
| `date` | **Last** message of the thread, UTC | **Not** the first message, **not** the run date. Matches Planhat's own convention for multi-part conversations (a synced email thread carries `date` = most recent message, `createDate` = thread start, and is re-dated as it grows), so `custom.Last AISE Touch` and native `lastTouch` mean the same thing across every AISE type. Slack renders local time – convert per message, since a channel's history crosses the DST boundary. Thread start is preserved in `custom.First message time` and in the `externalId` parent ts, since `createDate` is read-only on records we create. |
| `externalId` | `slack_{channelId}_{parentTsDigits}` | **Dedup key. Required on every record, one format only.** Lower-case `slack_` prefix, Slack channel **ID** upper-case (never the `#name` – channels get renamed), thread **parent** ts with the dot removed. Canonical shape: `^slack_[A-Z0-9]+_\d{16}$`, e.g. `slack_C0AKKLJCB5E_1786006420396099`. The digit string is exactly what Slack uses in a permalink, so the key is reversible (`ts = digits[:10] + "." + digits[10:]`) – that reversibility is what makes the reply-backfill pass possible without a side table. Never include the customer name, date, subject, hash or run counter. Checked before every create, read back and asserted after every create. Off-format legacy keys are normalized in place (`externalId` only, never `date` or `subject`). One drift case fixed 2026-08-25: `slack-C02N37LS25C-1786373402.520939` → `slack_C02N37LS25C_1786373402520939`. |
| `subject` | `Slack – #{channel}: {topic} ({Mon D–D, YYYY})` | Topic names the feature or system in play, not "customer question". |
| `description` | Rendered thread HTML | See § Planhat rich-text constraints below. |
| `custom.Slack message Id` | Parent ts, dotted form | |
| `custom.Slack initiated by` | `Customer` \| `Productboard` | From the parent author's email domain. |
| `custom.First message time` | `YYYY-MM-DD HH:MM {tz}` | Human-readable local time of the first message. **Does not stick over MCP** – reported writable by `get_model_action_parameters`, but silently dropped on create and on a field-only update alike (confirmed twice, 2026-08-27, SAP LeanIX `6a905bcd793439e997b3f6a8`). Write it, read back, note it once, carry on – nothing is lost, since the thread start is carried exactly by `custom.Slack message Id` and the `externalId` parent ts. Do not retry past a second attempt or fail a run over it. |
| `users` | `[{_id, name}]` of the Productboard people who posted | **Required, not optional.** Resolved from `User` by email. Omit the key entirely if no PB person spoke – never write `[]`. |
| `endusers` | `[{_id, name}]` of the customer contacts who posted | **Required, not optional.** Resolved from `End User` scoped to the company. Authors only – an `@`-mention or a named follow-up owner is not a participant. Fails silently on write, so always read back and assert. A participant with no contact record is reported, never auto-created. Omit the key rather than writing `[]`. |

**Channel resolution and the cache.** The skill accepts either half of the pair. Given a channel, the company
is resolved from the modal non-`productboard.com` email domain across the channel's authors matched against
`Company.domains`, falling back on the channel name (`#ext-acme-corp-productboard` → `acme corp`) matched
against `Company.name`. Given a customer, the Company is matched on `name` and then, when that misses, on
`domains` using the typed name as a domain label – acquired subsidiaries only appear there (`leanix` misses on
name and resolves to **SAP SE** via `leanix.net`). The channel then comes from `Company.custom.External_Slack_Channel_ID`, then a
`slack_search_channels` sweep for the `#ext-{customer}` convention, then the user. `custom.Slack ID` and
`custom.Slack URL` are **never** consulted – they hold the internal PB account channel, not the shared one. Whatever resolves is written back to `custom.External_Slack_Channel_ID` (ID only,
upper-case, read back and asserted) so the next run is a single field read. A cached ID that fails to read is
reported rather than used as a trigger to fall through the ladder and overwrite the field.

**Contact identity data is never edited by this skill.** Slack logging *links* to `End User` records; it does
not modify `name` / `firstName` / `lastName` / `email` / `position` on them. Those fields are customer identity
data and are frequently Salesforce-synced, so a change propagates outward. Contacts that render badly (e.g.
`Philippe Not provided`, a missing last name) are reported in the run summary and corrected only on the user's
explicit instruction, as a separate action. Note that Planhat caches the contact's display name inside each
Conversation's `endusers` array, so renaming an `End User` does not refresh links already written – rewrite the
array on affected records if you want the display name to follow.

**Reply backfill.** Slack threads gain replies for months after they are logged, so every run re-checks
existing `💬 Slack Chat` records on the company dated within the last 365 days. There is no writable sync-cursor
field on `Conversation` (`numberOfParts` is read-only), so the cursor is the last line of the `description`:

```
Sync: {N} messages · last message ts {ts} · logged {YYYY-MM-DD}
```

A live thread whose message count or last ts exceeds the watermark gets its `description` rebuilt via
`update_model_record` on the existing `_id`, and `date` moves forward to the new last message in the same call
so the record stays consistent with its watermark and with `Last AISE Touch`. `externalId` and
`custom.First message time` are never touched, and `date` never moves backward.

### Planhat rich-text constraints (`description` on any Conversation)

Planhat's rich-text editor sanitizes HTML aggressively and reports nothing about what it dropped. Verified by
writing a record and reading it back in the UI:

| Never use | What Planhat does with it |
|---|---|
| `<div>` with `style` | Strips `background`, `border`, `border-radius`, `color`, `padding`; the empty container leaves a large vertical gap |
| Bare `<ol>` / `<ul>` (no `ph-editor__*` classes, no inner `<p>`) | Mangles into `1.` / blank / `2.` / blank, with the real text on the even items. **Lists themselves are fine** — emit them in the editor's own form, see § Rich Text Field Formatting |
| `<table>` | Visible cell borders plus phantom empty rows and columns. Works structurally, but reads badly in a Conversation body — keep tables out of `description` |
| Literal newlines between elements | Converted into extra paragraph breaks |
| Inline `color` on text | Dropped – colour-coded speakers all render black |

**Safe set:** the verified vocabulary in § Rich Text Field Formatting — `<p>` · `<p></p>` · `<strong>` · `<em>` ·
`<br>` · `<hr>` · `<blockquote><p>` · `<ul class="ph-editor__bullet-list">` / `<ol class="ph-editor__ordered-list">`
with `<li class="ph-editor__list-item"><p>` items — emitted as a single line with no literal newlines. Properly
classed lists render correctly; the manual `1.` / `2.` prefix workaround is no longer needed. This applies to
every Conversation `description`, not just Slack ones.

### How to look up a Planhat Conversation for a given session

**Check before creating:** use `externalId` as the dedup key. ⚠️ The Notion MCP returns page `id` as a dashed UUID (`39d97e9c-7d4f-802f-add4-f23c53322209`) — Planhat `externalId` must always be the hyphen-stripped, lowercase 32-char form (`notion_id.replace('-', '').lower()`). Writing the dashed form breaks dedup and silently duplicates the session on the next run. Until historical data is confirmed clean, check **both** forms:

```
list_model_records(
  MODEL: "Conversation",
  FILTER: {"externalId[equal to]": "<normalized-32-char-hex>"},
  SELECT: ["subject", "type", "date", "companyId", "externalId"]
)
list_model_records(
  MODEL: "Conversation",
  FILTER: {"externalId[equal to]": "<original-dashed-uuid>"},
  SELECT: ["subject", "type", "date", "companyId", "externalId"]
)
```

If either query returns a result, update it rather than creating a duplicate — and rewrite `externalId` to the normalized form if it was stored dashed.

### Field-level mapping: Notion Session → Planhat Conversation

| Notion field | Planhat field | Type | Direction | Notes |
|---|---|---|---|---|
| Session page ID (URL) | `externalId` | string | Write on create | **Dedup key.** Extract the Notion page `id`, then normalize: strip hyphens, lowercase. The Notion MCP returns a dashed UUID — never write that raw form. Unique within a company. |
| `Name` (title) | `subject` | string | Write | Session name as-is. |
| `Type` (select) | `type` | string | Write | See value mapping below. Custom string — Planhat accepts any value. |
| `Call Date` | `date` | datetime | Write | ISO 8601. Use `date:Call Date:start` from Notion. |
| `Session Length (h)` | `custom.Call Duration` | number | Write | Convert hours to minutes: `Session Length (h) × 60`. |
| `Customers` (relation) | `companyId` | string | Write | Planhat Company `_id`. Resolve via name-search or `sourceId` lookup (see Company section). |
| `Delivered By` (person, all values) | `users` | array | Write | Array of `{"id": "<planhat-user-id>"}`, one per presenter — never truncate to the first value (co-delivered sessions must keep all presenters). Resolve each: static User ID table above first, then live lookup (`notion-get-users` → email → `list_model_records(MODEL: "User", FILTER: {"email[equal to]": "<email>"})`) on a table miss. If still unresolvable, fall back to the session's `Current Account Owner`, then the Company's `owner`. Omit only if all fail, and log a `NEEDS ATTRIBUTION` warning. |
| `Next Steps` / session page body | `description` | string | Write | Summary/notes from the session. Truncate to ~2000 chars if long. |
| `Gong call` (url) | `custom.Call Recording` | string | Write | Write the URL to `custom.Call Recording`. Do **not** append to `description`. **Corrected 2026-08-27** — was `custom.Gong URL`; see § Conversation Full Field Reference. |
| `Call Status` | _(not mapped)_ | — | — | Notion-only status lifecycle. Not meaningful in Planhat. |
| `Consumed Package` | _(not mapped)_ | — | — | Notion credit-ledger concept. No Planhat equivalent. |
| `Do not count` | _(not mapped)_ | — | — | Notion-only billing flag. |
| `Spark conversation` | ~~`activityTags`~~ | array | ~~Write~~ | ~~If `__YES__`, include `"Spark"` in `activityTags`.~~ **Not writable via MCP — silently rejected by the API. Apply `Spark` tag manually in the Planhat UI.** |
| _(no equivalent)_ | `source` | string | Write (constant) | Always `"AISE"` for sessions written by this assistant. Distinguishes from Zendesk/GCal entries. |

#### Type value mapping: Notion → Planhat

> ⚠️ **Emojis are part of the configured option strings.** Always use the exact values in the "Planhat `type`" column — passing the text without the emoji will save but will not match the configured option filters.

> **Authoritative Planhat `type` option list** — pulled live via `get_model_action_parameters(MODEL: "Conversation")` on 2026-08-28 (same option list on Task `type`). **Never write a value outside this list**; anything else silently fails to match configured filters:
>
> `note` · `email` · `chat` · `call` · `ticket` · `other` · `🎓 Enablement` · `🔁 Sync` · `Internal Alignment` · `🏗️ Architecting` · `👟 Kick off` · `🔎 Discovery` · `🏁 Audit / Setup Review` · `📺 Webinar` · `🎙️ Demo` · `👾 Gong Call` · `Task` · `Sales Handover` · `💬 Slack Chat` · `🧑‍💻 Billable Task` · `📆 Onsite Workshop` · `Product Feedback` · `🔁 Renewal Call`
>
> **`📦 Other` and `🗣️ Sync` are Notion-only labels, not valid Planhat options.** Never write either literally — always resolve through this table. An unmapped value is the documented cause of a Conversation/Task silently falling back to `note`.

##### Customer-specific type overrides — check before the default mapping

| Customer | Event title pattern | Planhat `type` | Notes |
|---|---|---|---|
| SAP Signavio | "Insight-to-Impact Circle" / "Community of Champions" | `🏗️ Architecting` | Structured working session with decisions being made, despite the recurring cadence — not `🔁 Sync` or `Other`. |

##### Session-title overrides — all customers, check before the default mapping

| Title or Calendly event name contains | Planhat `type` | Also set | Notes |
|---|---|---|---|
| "Spark in Practice" or "Spark Session" (case-insensitive; includes "⚡️ Spark Session") | `🎓 Enablement` | Conversation `custom.Motion Category: ["Spark in Practice"]`; Task `custom.Spark Conversation: true` | Calendly-booked Spark sessions arrive on the GCal-synced Task typed `👟 Kick off` (observed 2026-10-06) – overwrite that on first touch. Scope and rules: `context/initiatives/spark-in-practice.md`. |

This row wins over the customer-specific table and the default mapping.

**Classifying an untracked call with no Notion Type source** (ad hoc title-based classification — no Notion Session record exists): check the override table above first; if no match, pick directly from the authoritative option list above — never write a raw inferred label like "Other" — default to `🔁 Sync` when nothing more specific applies. When in doubt between `Other`/`🔁 Sync` and `🏗️ Architecting`, prefer Architecting if the call is a structured working session with decisions being made — `🔁 Sync` is for ad hoc or purely social calls.

| Notion `Type` | Planhat `type` (exact) | Notes |
|---|---|---|
| `🏗️ Architecting` | `🏗️ Architecting` | Emoji matches — use as-is |
| `🗣️ Sync` | `🔁 Sync` | **Different emoji** (🗣️ → 🔁). Use Planhat's `🔁 Sync` |
| `🎓 Training` | `🎓 Enablement` | **Different label.** Use Planhat's `🎓 Enablement` |
| `👟 Kick off` | `👟 Kick off` | Emoji matches — use as-is |
| `🔎 Discovery` | `🔎 Discovery` | Emoji matches — use as-is |
| `📦 Other` (default) | `🔁 Sync` | Default fallback for general calls (e.g. licence discussions, commercial syncs). Check the customer-specific override table above first. |
| `📦 Other` + "Demo" in title | `🎙️ Demo` | **Title-pattern override:** if the session title contains "Demo" (case-insensitive), use `🎙️ Demo` instead of the default `🔁 Sync`. |
| `🫥 Internal` | `Internal Alignment` | No emoji in Planhat |
| _(Done Notion Task — auto-created Conversation)_ | `Task` | No emoji. Planhat auto-creates this Conversation when Task `status` is set to `"done"`. Set via `noteId` post-write. Canceled (`"ignored"`) tasks do not generate a Conversation. |

> **This table is the authoritative source for type mappings.** The former companion doc (`notion-planhat-field-mapping.md`) has been retired now that nothing writes from Notion.

> **Planhat types with no Notion equivalent:** `📺 Webinar`, `👾 Gong Call` — logged directly in Planhat. `🎙️ Demo` is also available and applied automatically to `Other` sessions with "Demo" in the title.
> **Generic Planhat types** (avoid for AISE writes): `note`, `email`, `chat`, `call`, `ticket`, `other` — these are Planhat system defaults for inbox/helpdesk syncs. AISE should only use the custom configured values above.

> **`👾 Gong Call` records are a duplicate of the real session, not the session itself — and their `externalId` cannot be used to find their target.** Gong's native Planhat sync writes every call as its own standalone Conversation, separate from the GCal-synced session Conversation for the same meeting. Verified live (2026-08-27): a Gong Call Conversation's `externalId` is `{gongCallId}-{salesforceAccountId}` (e.g. `7668611138330097753-001f400001GC38TAAT`) — it does **not** carry the Google Calendar event ID the way a GCal-synced Conversation's `externalId` does (e.g. `ip5dj5rdolaa07e56is5m19lo4`). The `Conversation` model also has **no `sourceId` field at all** (`sourceId` exists on `Task` and `Company` only) — so there is no shared key between a Gong Call record and its target. Neither the Gong MCP tools (`ask_account`/`ask_deal`/`generate_brief` are synthesis-only, no raw metadata) nor Glean's indexed Gong document (checked directly — full facet set is `app`/`call_duration_range`/`opportunity`/`external_participants`/`department`/`type`/`account`/`documentcategory`, no calendar reference) expose one either. Matching the two instead uses a weighted score within a `companyId` + time window: attendee overlap via `endusers`/`users` (0.40 — Gong's sync already resolves participants to Planhat `EndUser`/`User` IDs, so this is exact-ID overlap, not text fuzzing), subject similarity (0.35), and date proximity (0.25). See `agents/ph-reconcile-gong-gcal.md` for the full scoring procedure and the merge-then-delete cleanup that reconciles a pair — a manual stopgap while the Planhat↔Gong integration is reworked to do this automatically.

#### Which session types count toward delivery

Two different things get confused constantly: the **full option list** on `type`, and the **subset the reporting
formulas treat as a delivered session**. Leadership's session counts and the Company field
`custom.Last AISE Session` read the counted subset only.

**The counted set — exactly these eight:**

`🎓 Enablement` · `🔁 Sync` · `🏗️ Architecting` · `👟 Kick off` · `🔎 Discovery` · `🏁 Audit / Setup Review` · `🎙️ Demo` · `📆 Onsite Workshop`

The live formula behind `custom.Last AISE Session`:

~~~
FIND(Conversation.date & {
  "filters": [
    {"op": "any of", "field": {"id": "type"}, "value": [
      "🎓 Enablement", "🔁 Sync", "🏗️ Architecting", "👟 Kick off",
      "🔎 Discovery", "🏁 Audit / Setup Review", "🎙️ Demo", "📆 Onsite Workshop"
    ]}
  ],
  "sort": {"date": -1},
  "limit": 1
})
~~~

**NOT counted, even though they are valid `type` values:** `📺 Webinar`, `Internal Alignment`, `Sales Handover`,
`🧑‍💻 Billable Task`, `👾 Gong Call`, `Task`, `Product Feedback`, `💬 Slack Chat`, `🔁 Renewal Call`, and every
generic type (`note`, `email`, `chat`, `call`, `ticket`, `other`).

- **`🔁 Renewal Call` does not count.** It is not in the eight-value formula above. A renewal conversation logged
  under this type is correct for engagement history but will not move session counts or `custom.Last AISE Session`.
  Do not retype it to `🔁 Sync` to make a number move – that misrepresents what the call was.

Consequences worth remembering:

- **`📺 Webinar` does not count.** If webinar delivery is supposed to show up in session counts, that needs a
  different type or a formula change. Flag it rather than logging webinars and assuming they register.
- **Retyping between two uncounted types changes no number.** Moving a record from `note` to `👾 Gong Call` is
  pure hygiene. Never present it as a count fix.
- **Retyping across the boundary changes the count.** `👾 Gong Call` → `🔁 Sync` makes a previously invisible
  record count — a real fix, and a real risk if that record duplicates a counted one.
- **`archived: true` removes a record from the counted set.** Verified in the 2026-08 run: an archived record
  stops being returned by account-scoped queries and drops out of the count. This is how duplicates are retired
  without hard deletion.
- `custom.Not counted` is a separate, manual discount flag for Architecting/Enablement sessions that should not
  burn the roster. It does **not** affect `custom.Last AISE Session`.

**Live full option list on `Conversation.type`** — derive from `get_model_action_parameters` rather than trusting
this snapshot, it drifts:

`note` · `email` · `chat` · `call` · `ticket` · `other` · `🎓 Enablement` · `🔁 Sync` · `Internal Alignment` ·
`🏗️ Architecting` · `👟 Kick off` · `🔎 Discovery` · `🏁 Audit / Setup Review` · `📺 Webinar` · `🎙️ Demo` ·
`👾 Gong Call` · `Task` · `Sales Handover` · `💬 Slack Chat` · `🧑‍💻 Billable Task` · `📆 Onsite Workshop` ·
`Product Feedback` · `🔁 Renewal Call`

*(23 values, verified against `get_model_action_parameters` on 2026-08-25. `🔁 Renewal Call` was added since the
previous snapshot – note it shares the 🔁 emoji with `🔁 Sync`, so match on the full string, never the emoji alone.)*

#### Status mapping

| Notion `Call Status` | Action |
|---|---|
| `Delivered` | Create/update Conversation |
| `Canceled` | Skip — do not create |
| `Not started` / `Planned` / `Postponed` / `In progress` | Skip — session hasn't happened yet |

**Only sync Delivered sessions.** Future, in-progress, or canceled sessions don't belong in Planhat's interaction history. Internal sessions (`🫥 Internal`) are synced as `"Internal Alignment"` type — they are valid customer touchpoints for engagement tracking.

### Write rules

- **Never create a Conversation without `companyId`** — it's a required field.
- **`externalId` must be unique per company.** Always check before creating.
- **`type` is free-text** — use the values above consistently so Planhat filters work.
- **`source: "AISE"`** on every write so records are distinguishable from ticket/email sync.
- **Calendar events** (synced via GCal) already exist as Planhat Tasks (`mainType: event`) — do not duplicate them as Conversations.

### Planhat Conversation — Full Field Reference

#### Writable fields relevant to AISE sessions

| Field ID | Type | Required | Description |
|---|---|---|---|
| `type` | string | ✅ | Kind of interaction. Use AISE-prefixed values (see mapping above). |
| `subject` | string | — | Session name / title. |
| `description` | string | — | Summary, notes. |
| `date` | datetime | — | When the session took place (ISO 8601). |
| `startDate` | date | — | Call start date. Not used for session duration — use `custom.Call Duration` instead. |
| `endDate` | date | — | Call end date. Not used for session duration — use `custom.Call Duration` instead. |
| `companyId` | string | ✅ | Planhat Company `_id`. |
| `users` | array | — | `[{"id": "<planhat-user-id>"}]` — team members who delivered. |
| `endusers` | array | — | `[{"id": "<planhat-enduser-id>"}]` — customer contacts who attended. |
| `externalId` | string | — | Notion Session page ID. **Dedup key.** |
| `source` | string | — | Always `"AISE"`. |
| ~~`activityTags`~~ | array | — | ~~`["Spark"]` if `Spark conversation = YES`.~~ **Not writable via MCP — silently rejected. Apply manually in Planhat UI.** |
| `custom.Prep Notes` | string | — | Prep brief written by session-prepper before the session. Format: single-line HTML in the `ph-editor` vocabulary — see § Rich Text Field Formatting for the tag table and the canonical prep-brief example. Section labels are `<p><strong>…</strong></p>` (no `<h>` tags); lists **must** carry `ph-editor__bullet-list` / `ph-editor__ordered-list` + `<li class="ph-editor__list-item"><p>…</p></li>`; use `<p></p>` for a blank line and `<hr>` to separate the header block from the body. **Apply the user's `custom.AISE Profile preferences` voice rules to the sentence content** (dash style, etc.) — see `agents/session-prepper.md` § 1b/5b; this field has shipped with em dashes and no section spacing before that was fixed. Carry over from the linked Task when writing the Conversation post-session. |
| `transcript` | string | — | Full transcript text if available. |
| `taskId` | objectId | — | Links this conversation to its originating Planhat Task. Set when writing a Done Notion Task as a Conversation — look up the existing Planhat Task by `sourceId` and pass its `_id` here. Optional on backfill if the Task doesn't exist yet in Planhat. |
| `category` | string | — | One of: `Support`, `Feedback`, `Sales`, `Expansion`, `Billing & Contracts`, `Renewals`, `Legal`, `General Enquires`, `Spam`, `Marketing`. Leave blank for AISE sessions unless relevant. |
| `custom.Link to PB Note` | string | — | Productboard feedback note URL. Written by `/log-feedback` onto the Conversation auto-created when a `Product Feedback` Task transitions to `done` (see § Planhat Task auto-Conversation behavior) — links the touchpoint back to the submitted PB note. Write the raw URL. |
| `custom.Call Duration` | number | — | Session length in minutes. Derive from Notion `Session Length (h)` × 60. |
| `custom.Opportunity` | string → Deal | — | The customer contract the session was delivered under. Relation to a `Deal` record. Optional – set when the session is clearly attributable to one contract. **Replaces the former `custom.Services Package` field, which no longer exists on this model.** |
| `custom.Call Recording` | string | — | **Call recording link — Gong or otherwise.** Use this instead of appending to `description`. Write the raw URL. **Corrected 2026-08-27** — `custom.Gong URL` is no longer written by any agent; `custom.Call Recording` is the single field for every recording link regardless of source (was previously Gong-only reserved for `custom.Gong URL`, non-Gong-only reserved for this field — that split is retired). A one-time migration (2026-08-27) copied every populated `custom.Gong URL` value into this field workspace-wide so the legacy field could be safely deleted — see the removal note below. |
| ~~`custom.Gong URL`~~ | string | — | **Deprecated 2026-08-27, pending deletion — do not reintroduce.** Superseded by `custom.Call Recording` above. Kept out of this reference table as a live field on purpose; it is documented only where an agent still has to read it. **Before deleting it in Planhat:** confirm the one-time migration above completed with zero unresolved conflicts, and check the Gong↔Planhat integration config — Gong's *own* native sync writes its call link to this exact field name when it creates a `👾 Gong Call` Conversation, which is outside any agent's control. Deleting the field may either break that write path or cause Planhat to silently recreate the field the next time Gong writes to it, depending on how Gong's integration is configured. `agents/ph-reconcile-gong-gcal.md` still reads from it as the *source* field on new Gong Call records for exactly this reason — update that agent if the Gong integration is reconfigured to target a different field. |
| `custom.Handover Status` | string | — | `Not started` · `In progress` · `Validated – Ready`. Tracks the sales-to-AISE handover on a Sales Handover conversation. |
| `custom.Debrief Status` | string | — | **Set by `post-session-debrief` at the end of a run (`complete`, `partial - transcript pending`); `ignored` is written by `bulk-debrief` or by hand.** `complete` = the full debrief ran. `partial - transcript pending` = debrief ran but no transcript was available; placeholder notes written and a re-debrief task created. `skipped` = deliberately excluded from a bulk run. `ignored` = session was cancelled or did not occur (GCal-cancelled orphan, no-show, verbal cancellation) — `bulk-debrief` skips it permanently, never re-checks it, and `--rerun` has no effect (`--force-ignored <customer>` overrides). **Blank = not yet debriefed**, which is what `bulk-debrief` keys on to pick a session up. Declared `readonly: true` in MCP metadata but **writes do land** — verify with `get_model_record` + explicit `SELECT`, or a filter on the field's value, not with the metadata flag. |
| `custom.Motion Category` | array | — | Which time-boxed GTM motion this session belongs to. Currently one option: `Spark in Practice`. Set by `post-session-debrief` for sessions in an active initiative's scope — see `context/initiatives/`. This is the field that makes a motion reportable without adding a permanent Conversation type for a three-month experiment. **Planhat is the counting source for Spark in Practice** — an automation tags the record and the AISE corrects it by hand where needed. The calendar-title convention in the initiative doc feeds Boge's forecast report, not this count; do not conflate the two. |
| `custom.SH_Current State` | string (rich text) | — | Sales Handoff context captured at conversation level. Mirrors the Company-level `SH_` fields. Read for discovery context; not written by this assistant. |
| `custom.SH_Future State` | string (rich text) | — | As above. |
| `custom.SH_Negative Consequences` | string (rich text) | — | As above. **Note the Conversation field is `SH_Negative Consequences`; the Company field is `SH_Negative Impacts`.** Different names, same idea – do not copy one field ID to the other model. |
| `custom.SH_Positive Business Outcomes` | string (rich text) | — | As above. **Note the Conversation field is `SH_Positive Business Outcomes`; the Company field is `SH_Positive Outcomes`.** |

#### Read-only fields

`snippet`, `numberOfParts`, `parentId`, `parentType`, `createDate`, `companyName`, `isClassified`, `isSignalAnalyzed`, `shortSummary`, `isSeen`, `isOpen`, `isBounced`, `archived`, `scheduled`, `createdAt`, `updatedAt`

> **`custom.AISE Conversation` was removed — verified absent from the Conversation model 2026-09-12.** It was a
> system-derived boolean marking a record as AISE-originated. Do not read or write it. The live equivalents are the
> Company-level formulas `custom.Last AISE Touch`, `custom.Last AISE Session` and `custom.Total AISE Sessions`, which
> are driven by the counted-session type list rather than a per-record flag.

---

## Task priority & description defaults

Canonical logic for any agent creating a PB-side Planhat Task without an explicit priority, due date, or body content stated by the user. Originally a Notion-era pattern (Active Package `Status` + `ARR`); restated below entirely in Planhat terms. `post-session-debrief.md` is the reference implementation — other Task-creating agents (`customer-plan-next`, `session-backfill`, etc.) should read from here rather than duplicating their own copy.

### Account priority table — PB-side commitments

| Condition | Priority |
|---|---|
| `phase` = `1. Activation` or `2. Adoption` AND `custom.ARR – SF` ≥ $50k · or urgent/blocker language · or the item gates a dated commitment made to the customer | `P1` |
| `phase` = `3. Renewal` AND the item affects the renewal conversation | `P1` |
| `phase` = `1. Activation` or `2. Adoption` with `custom.ARR – SF` < $50k · or `phase` = `0. Preparation` with `custom.ARR – SF` ≥ $50k · or `custom.ARR – SF` unknown | `P2` |
| `phase` = `0. Preparation` with `custom.ARR – SF` < $50k · or `3. Renewal` with no renewal impact · or low-urgency | `P3` |

**Renewal proximity outranks the table:** when Company `renewalDate` is inside 45 days, nothing touching the renewal conversation goes below `P1`.

Always state the assigned priority with a one-line reason in the draft/report (e.g. `P1 (Renewal phase, gates the 26 Sept conversation)`), alongside the inferred due date, so the user can override before the write lands.

### Auto-due-date logic

Apply when a due date isn't explicitly stated. Base = today (system date). Skip weekends when computing business days.

| Task type (match by title pattern) | Default |
|---|---|
| "Reply to / Send [email/Slack/message]" | Today + 1 business day |
| "Schedule / Book / Invite" | Today + 2 business days |
| "Draft [document/artifact/email/follow-up]" | Today + 3 business days |
| "File product request / log feedback" | Today + 3 business days |
| "Review / Investigate / Explore / Analyze" | Today + 5 business days |
| Anything else | Today + 3 business days (safe default) |

Always state the assigned date and the matching pattern (e.g. `Due: Apr 30 (send email, +1 bd)`) — the user can override before confirming the write.

### Task description scaffold (required for every PB-side task)

Every Task's `description` should include a "best shot" scaffold so the user can act immediately rather than face a blank page, written as single-line HTML per § Rich Text Field Formatting above — bold `<p><strong>` label, then the scaffold content.

| Task type | Scaffold |
|---|---|
| "File product request" | Three parts: **Problem** (what the customer is experiencing), **Current workaround or process** (how they're managing today), **Desired outcome** (what they want PB to do). Seed from session notes/transcript. |
| "Reply to [person]" / "Send [email/Slack]" | **Draft reply** — a full message draft in the user's voice (per `custom.AISE Profile preferences` on the user's Planhat User record) following `communication-style-guide.md`. |
| "Draft [document/artifact]" | **Starter outline** with key sections or a first draft. |
| All other tasks | **Suggested approach** with 2–4 bullet steps toward completing the task. |

Label the scaffold with a bold heading, e.g. `<p><strong>Best shot — draft artifact</strong></p>`, so the user knows it's a starting point. Seed from real context only — never fabricate details.

---

## Task (Planhat) ↔ Task (Notion) — all statuses

> **Design note:** ALL Notion Tasks write to the Planhat **Task** model (`mainType: "task"`) — open, done, and canceled. When `status` is set to `"done"`, Planhat automatically creates a linked **Conversation** and stores its `_id` in `noteId` on the Task. Setting `status: "ignored"` (Canceled) does **not** trigger auto-Conversation — the record stays as a Task only. The auto-created Conversation's `type` may not be `"Task"`, so the write procedure includes a type-check step for `"done"` tasks.
>
> **Do not create Conversation records manually for done tasks.** Let Planhat auto-create them via the Task completion mechanism, then update the type if needed.

### Planhat Task auto-Conversation behavior

Auto-Conversation creation only fires on a `status` *transition* to `"done"` via `update_model_record` — **not** when a Task is created directly with `status: "done"` (confirmed by live test, 2026-08-05). Always create Done-mapped tasks as `"To Do"` first, then transition with a separate `update_model_record` call.

When `status` transitions to `"done"`:
1. Planhat creates a linked Conversation and stores a reference in `noteId` on the **update** response (not the create response — `noteId` is absent if the task was created directly as `"done"`).
2. The auto-created Conversation's `type` defaults to `"note"`, not `"Task"` (confirmed by live test) — it needs the update in step 3 below.
3. **Post-write step:** read `noteId` from the update response → check the Conversation's `type` → if `type != "Task"`, call `update_model_record` on the Conversation to set `type: "Task"`.
4. **The auto-created Conversation's `_id` is the same value as the Task's `_id`** (confirmed by live test) — it is not a separately generated ID. Relevant for any cleanup or dedup logic touching Conversations.

```
# After the update_model_record call that transitions status → "done"
# (noteId is NOT present on a create_model_record response):
update_response → noteId = "<conversation-_id>"

get_model_record(MODEL: "Conversation", OBJECT_ID: "<noteId>", SELECT: ["type"])
→ if type != "Task":
    update_model_record(MODEL: "Conversation", OBJECT_ID: "<noteId>", PARAMETERS: {"type": "Task"})
```

> **"unless already selected"** — skip the update if `type` is already `"Task"`. This avoids unnecessary writes and is safe to run idempotently.

### How to look up a Planhat Task for a given Notion task

**Use the attempt-create dedup pattern** — do NOT use `list_model_records` for Task dedup. The Task model has a hard **36-record cap** on `list_model_records` results and FILTER is unreliable, so pre-flight list checks will silently miss existing records and cause duplicates.

```
# Attempt-create pattern:
create_model_record(MODEL: "Task", PARAMETERS: { sourceId: "<notion-task-page-id>", mainType: "task", ... })
→ If response contains a `sourceId` collision error → Task already exists → switch to update_model_record
→ If create succeeds → new Task written
```

Alternatively, use `search_records(QUERY: "<task title>")` and scan results for a matching `sourceId` — this is more expensive but avoids the create-on-collision side effect.

### Field-level mapping: Notion Task → Planhat Task

| Notion field | Planhat field | Type | Direction | Notes |
|---|---|---|---|---|
| Notion Task page ID (URL) | `sourceId` | string | Write on create | **Dedup key.** Extract the Notion page `id`, then normalize: strip hyphens, lowercase — same rule as Conversation `externalId` above. |
| `Task` (title) | `action` | string | Write | Task title as-is. |
| `Status` | `status` | string | Write | See value mapping below. |
| `Due Date` | `endTime` | datetime | Write | ISO 8601. Set time to `T00:00:00.000Z` for date-only values. |
| `Customers` (relation) | `companyId` | string | Write | Planhat Company `_id`. Resolve via company lookup. **Skip if Customers = Productboard internal** — internal tasks don't belong in Planhat. |
| `Owner` (person) | `ownerId` | objectId | Write | Resolve Notion user UUID → Planhat user ID using the User ID table above. |
| `Priority` | `custom.Priority` | string | Write | `"1"` → `"P1"`, `"2"` → `"P2"`, `"3"` → `"P3"`. Stored in `custom.Priority` — **not** the `type` field. Full live option set is `P0`–`P4`. |
| `Do not count` | _(skip)_ | — | — | Notion billing flag. Not relevant to Planhat. |
| `Consumed Package` | _(skip)_ | — | — | No Planhat equivalent. |
| `Source Call` | _(skip)_ | — | — | No native foreign key in Planhat linking a Task back to its source Conversation. Skip — the relationship lives in Notion. |
| _(constant)_ | `mainType` | string | Write (constant) | Always `"task"`. |

#### Status value mapping

All Notion Task statuses write to the Planhat Task model. Only a `status` *transition* to `"done"` triggers Planhat's auto-Conversation creation (never `"ignored"`, and never a direct create with `status: "done"`) — the Conversation type is then checked and updated if needed.

| Notion `Status` | Planhat `status` | Post-write action |
|---|---|---|
| `Not started` | `"To Do"` | None — open task |
| `In progress` | `"in-progress"` | None — open task. **Hyphenated, lowercase.** `"In-Progress"` will fail |
| `Done` | `"done"` | Read `noteId` → check/update Conversation `type` to `"Task"` |
| `Canceled` | `"ignored"` | None — `"ignored"` does **not** trigger auto-Conversation. Task stays as Task only. |

#### What to skip

- Tasks where `Customers` = the Productboard internal record (these are internal, not customer-facing)
- Tasks with `Do not count = YES` (billing exclusions, rarely applicable to tasks but consistent with Sessions rule)

### Write rules

- **`mainType: "task"` is required** and must always be set explicitly.
- **`companyId` is required** — never create a Task without it.
- **`sourceId` is the dedup key** — check before creating.
- **Do not overwrite `ownerId`** on existing records if the task was already assigned in Planhat — only set on initial create from backfill.

### Planhat Task — Full Field Reference

#### Writable fields relevant to AISE tasks

| Field ID | Type | Required | Description |
|---|---|---|---|
| `mainType` | string | ✅ | `"task"` for action items, `"event"` for calendar meetings. Always `"task"` for AISE writes. |
| `action` | string | — | Task title / short description of what needs to be done. |
| `description` | string | — | Longer details. Append source session reference if present. |
| `status` | string | — | `"To Do"` · `"in-progress"` (hyphenated lowercase) · `"done"` · `"ignored"` · `"blocked"`. |
| `type` | string | — | Session type emoji string for AISE-created prep tasks (e.g. `🏗️ Architecting`). Use `"Task"` for generic Notion action items migrated from Notion. **Not used for Priority** — Priority maps to `custom.Priority`. |
| `endTime` | datetime | — | Due date (ISO 8601). Required for `mainType: event`; optional for tasks. |
| `startTime` | datetime | — | Start time. Optional for tasks; required for events. |
| `companyId` | objectId | ✅ | Planhat Company `_id`. |
| `ownerId` | objectId | — | Planhat User `_id` of the person responsible. |
| `sourceId` | string | — | Notion Task page ID. **Dedup key.** |
| `custom.Priority` | string | — | `P0` · `P1` · `P2` · `P3` · `P4`. **Corrected 2026-09-12** — this file previously listed only P1–P3; `P0` and `P4` are valid live options. See § Account priority table for which to use. |
| `custom.Prep Notes` | string | — | Prep brief written by session-prepper. Format: single-line HTML in the `ph-editor` vocabulary — see § Rich Text Field Formatting for the tag table and the canonical prep-brief example. Section labels are `<p><strong>…</strong></p>` (no `<h>` tags); lists **must** carry `ph-editor__bullet-list` / `ph-editor__ordered-list` + `<li class="ph-editor__list-item"><p>…</p></li>`; use `<p></p>` for a blank line and `<hr>` to separate the header block from the body. **Apply the user's `custom.AISE Profile preferences` voice rules to the sentence content** (dash style, etc.) — see `agents/session-prepper.md` § 1b/5b. Read and carried to the linked Conversation during post-session debrief. |
| `custom.Facilitation Playbook URL` | string | — | Google Drive link to the interactive HTML facilitation guide generated by `/session-facilitation`. The canonical facilitation link: written onto the session's Task so readers never have to parse it out of `custom.Prep Notes`. For `🏗️ Architecting`, `🔎 Discovery` and `👟 Kick off` sessions it is part of the prep gate (`context/session-artifact-convention.md` § Facilitation gate). Task model only (not on Conversations). Writable via `update_model_record` with `{"custom": {"Facilitation Playbook URL": "<url>"}}`; write and read-back verified 2026-10-06. Only the `Facilitation` artifact goes here; other artifact links stay in `custom.Prep Notes`. See `context/session-artifact-convention.md` § 6. |
| `custom.Slack message URL` | string | — | Slack permalink for a message this Task already produced, so a re-run updates the existing message instead of posting a duplicate. WIP. |
| `custom.Spark Conversation` | boolean | — | Marks the session as Spark-related. Replaces the `activityTags: ["Spark"]` route, which is not writable via MCP. |
| ~~`activityTags`~~ | array | — | ~~Freeform tags for filtering.~~ **Not writable via MCP — silently rejected. Apply manually in Planhat UI.** |
| `endusers` | array | — | Customer contacts involved: `[{"id": "<enduser-id>"}]`. |

#### Read-only fields

`ownerType`, `companyName`, `workflowId`, `workflowName`, `workflowTaskId`, `workflowStepId`, `workflowTemplateId`, `noteId`, `users`, `path`, `parentObject`, `createdAt`, `updatedAt`

---

## EndUser (Planhat) ↔ Contact (Notion)

> **Status:** Actively written by AISE as of 2026-09-12, and written automatically by `post-session-debrief` step 3b (and every `bulk-debrief` session that runs through it) as of 2026-09-14. The `custom.AISE *` fields below are the AISE's own read on a contact, maintained during session prep and debrief. Everything else on this model is Salesforce- or Snowflake-synced, or owned by another team — read it, do not overwrite it.

### The working set — who we actually deal with

A Company can carry 50+ EndUser records, most of them product users nobody has ever spoken to. Autorola has 52; nine have any interaction history at all. Two ways to narrow:

| Need | Use |
|---|---|
| Anyone we have exchanged a message with | `lastTouch[has value]` — derived from conversation matching, free, always current |
| The people we deliberately work with | `custom.AISE Relationship` — set by hand, survives junk records |

**Prefer `custom.AISE Relationship` for anything that matters.** `lastTouch` counts a CC the same as a champion, and it inherits every junk record on the account — Autorola alone holds six contacts named `Not provided` or `[[unknown]]`, a literal `khj-fake-bu-test@autorola.com`, and the same person duplicated across two domains.

### How to look up a Planhat EndUser

> **The model name is `End User`, with the space.** `MODEL: "EndUser"` is rejected outright — `{"message":"Invalid or unauthorized model: EndUser"}` — even though the model is referred to as `EndUser` in prose, in the `endusers` field on Conversations, and in the `modelRoute` (`endusers`). Verified 2026-09-14; every call in this repo was corrected in the same pass.

```
list_model_records(
  MODEL: "End User",
  FILTER: {"companyId[equal to]": "<planhat-company-id>"},
  SELECT: ["name", "email", "position", "primary", "companyId",
           "custom.AISE Relationship", "custom.AISE Read", "custom.Engagement Role"]
)
```

Or by email:
```
list_model_records(
  MODEL: "End User",
  FILTER: {"email[equal to]": "<contact-email>"},
  SELECT: ["name", "email", "position", "companyId"]
)
```

### Duplicate End Users — which record is the AISE contact

The same person often exists as two or more End User records on one account: two email domains (`jdoe@acme.com` and `jdoe@acme-group.com`), a Salesforce-synced record next to one the GCal or Gmail sync created, or a placeholder (`[[unknown]]`, an email as the name). AISE fields go on **one** record per person – the AISE contact – and every other record for that person is left untouched and reported as a duplicate.

**Treat records as the same person** when the email local part matches across the account's domains, or the full name matches and nothing contradicts it (different title, different team). Name-only matches on common names are reported, not acted on.

**Pick the AISE contact in this order – first rule that separates them wins:**

1. **`custom.PB_ID` filled.** The record linked to a real Productboard user is the one that carries Spark and usage telemetry and is the one Salesforce and Productboard reconcile against. Always prefer it, even when the other record has the more recent `lastTouch` or is the one linked on a Conversation's `endusers`.
2. `position` filled.
3. Most recent `lastTouch`.

Fetch `custom.PB_ID` with `get_model_record` on each candidate – it comes back blank in large multi-record lists.

**If the AISE fields already sit on the wrong record** (written before this rule, or the user corrects which record is canonical): copy `custom.AISE Relationship`, `custom.Engagement Role`, `custom.AISE Read` and `custom.AISE Read Reviewed` onto the AISE contact, then clear them on the duplicate: `custom.AISE Relationship` back to `6. Not filled`, `custom.Engagement Role` to `[]`, and `custom.AISE Read` / `custom.AISE Read Reviewed` to **`null`**. An empty string `""` clears `custom.AISE Read` but is silently ignored on the date field `custom.AISE Read Reviewed` (verified 2026-10-02) – only `null` clears it. Read both records back. Never archive, rename, merge or re-home the duplicate – identity cleanup belongs to RevOps / Salesforce – and report it under Gaps with both `_id`s and both `sourceId`s.

A user's explicit statement of which record is canonical overrides the order above for that person.

### AISE-writable fields

| Field ID | Type | Description |
|---|---|---|
| `custom.AISE Relationship` | string (list) | **The working-set filter.** How close this person sits to the program. Options are numbered so group-by sorts in order — **pass the full numbered string verbatim**: `1. Key contact` · `2. Engaged` · `3. Known` · `4. Not engaged` · `5. Left the company` · `6. Not filled`. Passing `Key contact` stores an off-list value that looks like a successful write. Blank means never assessed, which is not the same as `4. Not engaged`; `6. Not filled` is the explicit "looked, nothing to say" marker and is never written by an agent. Per-value criteria and the movement rules live in `agents/post-session-debrief.md` step 3b-B. |
| `custom.AISE Read` | string (rich text) | The AISE's read on the person — what they care about, what blocks them, how they behave in a room, whether anything depends on them alone. Not a job description; `position` and `custom.Job Title – SNF` already hold that. Two to four sentences of plain prose. Record uncertainty rather than smoothing it: a contested name or an unconfirmed inference belongs in the text. |
| `custom.AISE Read Reviewed` | date | When the read was last set or reconfirmed. Stores as `YYYY-MM-DDT00:00:00.000Z`; write plain `YYYY-MM-DD`. A read more than about two quarters old should not be trusted without a re-check. |
| `custom.Engagement Role` | array (list) | **The AISE team's own field, and distinct from AISE Relationship.** The person's *function*: `Champion` · `Power User` · `Main Contact` · `Executive Sponsor` · `Technical Contact`. Relationship says how close they are, Engagement Role says what they do. Leave blank rather than guessing — an unevidenced Champion is worse than none. Note the field also carries bulk-derived values on non-AISE accounts (Sysdig, Drata, Bridgestone), so absence of a value is not evidence either way. |
| `primary` | boolean | Main point of contact for the company. |
| `position` | string | Job title. Sparsely populated — 9 of 52 on Autorola. `custom.Job Title – SNF` is often healthier. |

`tags` (`Champion` · `Program Owner`) is the pre-2026-09 way of marking a champion and is superseded by the two fields above. Three records still carry it, all on North American Bancard. Migrate them and stop writing it — two places to say "champion" is one too many.

### Read-only context worth reading before a session

Snowflake-synced (`– SNF` suffix), refreshed on the usage pipeline's cadence:

- **Product role:** `custom.Is Maker – SNF`, `custom.Role – SNF`, `custom.Job Title – SNF`, `custom.Department – SNF`
- **Engagement:** `custom.Engagement Level – SNF` (`L1` / `L2`), `custom.Last Seen Date – SNF`, `custom.Last Response Date – SNF`
- **Spark:** `custom.Spark Activated – SNF`, `custom.Spark Activated Date – SNF`, `custom.Last Spark Activity Date – SNF`, `custom.Spark Active Days – SNF`, `custom.Spark AI Days – SNF`, `custom.Spark Messages – SNF`, `custom.Spark Threads Started – SNF`, `custom.Spark Skills Invoked – SNF`, `custom.Spark Credits Used – SNF`, `custom.Spark Events – SNF`, `custom.Spark Events 7d – SNF`, `custom.Spark Docs Created via AI – SNF`
- **Skills and habit:** `custom.Skills Created – SNF`, `custom.Skills Updated – SNF`, `custom.Skills Used – SNF`, `custom.Custom Skill Used – SNF`, `custom.Scheduled Tasks Set – SNF`, `custom.Skill Workspace Promoted – SNF`
- **Workspace activity:** `custom.Entities Created – SNF`, `custom.Feedback Created – SNF`, `custom.Feedback Processed – SNF`, `custom.Comments Created – SNF`, `custom.Integrations Used Max Day – SNF`
- **Identity:** `custom.PB_ID` — the Productboard user ID. **Corrected 2026-09-12:** this file previously documented it as `custom.User PB ID` (number). That field ID has never existed; the real one is `custom.PB_ID`, a read-only string.

Planhat-derived, read-only: `lastTouch`, `lastActive`, `convsTotal`, `convs14`, `relevance`, `beats`, `beatTrend`, `beatsTotal`, `experience`, `sentimentScore`.

Writable, but owned by other teams — read, do not set: `custom.Top Project Role` (**corrected 2026-09-12** — previously documented as `custom.Project Role`, which does not exist), `custom.# of Projects`, `custom.Active Projects`, `custom.Engaged with Spark`, `custom.Comms opt out`, `custom.Last Activity – SF`.

### Field-level mapping: Notion Contact → Planhat EndUser

| Notion field | Planhat field | Type | Notes |
|---|---|---|---|
| Contact name | `firstName` + `lastName` | string | Split on first space. |
| Email | `email` | string | Required if no `externalId`/`sourceId`. |
| Role / Job title | `position` | string | |
| `Customers` relation | `companyId` | string | Planhat Company `_id`. Required. |
| Main Contact flag | `primary` | boolean | `true` if this contact is the Notion `Main Contact` for the customer. |

### Writing a person record — rules

- **Never invent an Engagement Role to fill the field.** Silence in a session is data; record it in `custom.AISE Read` and leave the role blank.
- **Bad `OBJECT_ID`s fail loudly on this model** — a mistyped id returns `No such document` rather than writing to the wrong person. A person-write to the wrong record is not a silent risk here.
- **Set `custom.AISE Read Reviewed` on every read edit.** An unstamped read is indistinguishable from a stale one.

---

## Backfill Strategy: Notion → Planhat

> **Scope:** Sessions (Delivered only) and Tasks (non-canceled, non-internal) owned by the current user. Customers and Active Packages are already synced from Salesforce — do not re-create them.

### Migration gate: PH migrated + PH Last Migration Date (Notion Customer page)

Before migrating a customer, check the Notion Customer page for:
- **`PH migrated`** (checkbox): `true` = already migrated — skip unless running a delta sweep.
- **`PH Last Migration Date`** (date + time): timestamp of the last completed migration run. Used by delta-sweep logic to find Notion records created/updated **after** this date and push them to Planhat incrementally.

On **successful completion** of a migration run (zero errors), write both fields back to the Notion Customer page:

```
notion-update-page(
  page_id: "<Notion Customer page ID>",
  properties: {
    "PH migrated": { "checkbox": true },
    "PH Last Migration Date": { "date": { "start": "<current UTC datetime — YYYY-MM-DDTHH:MM:SS.000Z>" } }
  }
)
```

Get the current UTC datetime via Bash: `date -u +"%Y-%m-%dT%H:%M:%S.000Z"`

---

### Pre-flight checks

1. Confirm the Planhat Company exists for each customer before writing — use the name mapping table and the SF `sourceId` lookup (see Company section).
2. Resolve the current user's Planhat user ID from the table above (Klara → `6a44ef76c9aade50502936d5`).
3. Use `externalId` (Conversations) and `sourceId` (Tasks) as dedup keys — check before every create.

### Session backfill procedure

```
For each Session WHERE:
  - Current Account Owner LIKE '%<user-uuid>%' OR Delivered By LIKE '%<user-uuid>%'
  - Call Status = 'Delivered'

1. Extract Notion Session page ID from URL (32-char hex)
2. Check for existing Planhat Conversation: FILTER externalId = <session-page-id>
   → If found: update subject/description if stale; skip create (activityTags: not writable via MCP — apply manually in Planhat UI)
   → If not found: proceed to create
3. Resolve Planhat companyId via name search or sourceId lookup
4. Map fields per the Session → Conversation table above
5. create_model_record(MODEL: "Conversation", PARAMETERS: { ... })
6. Log result: session name, company, Planhat Conversation _id
```

### Task backfill procedure

```
For each Task WHERE:
  - (Owner LIKE '%<user-uuid>%' OR Current Account Owner LIKE '%<user-uuid>%')
  - Customers != Productboard internal record

1. Extract Notion Task page ID from URL (32-char hex)
2. Check for existing Planhat Task: FILTER sourceId = <task-page-id> AND mainType = 'task'
   → If found: update status/endTime if stale; skip create
   → If not found: proceed to create
3. Resolve Planhat companyId via name search or sourceId lookup
4. Map fields per the Task → Planhat Task table above
5. create_model_record(MODEL: "Task", PARAMETERS: { mainType: "task", ... })
6. Log result: task title, company, Planhat Task _id
```

### Backfill ordering

Run Sessions first, then Tasks. This way, if a Task references a Source Call, the Conversation already exists in Planhat when the Task is written (useful for future linking).

### Rate limiting / batching

Process one customer at a time. After each customer's sessions and tasks are written, pause briefly and log a summary before moving to the next account. This makes it easy to resume if interrupted.

---

---

## Asset / Workspace (Planhat)

> Planhat calls this model "Workspace" in the UI. It represents sub-entities of a Company — for example, a specific Productboard workspace, department, or project a customer operates.
>
> ⛔ **Synced from Salesforce and Snowflake. Never write Asset/Workspace records via MCP.** These records are managed by the SF → Planhat sync and the Snowflake data pipeline. Read them for context (e.g. staging space flag, AI consent status) but do not create or update them.

### Notion equivalent

No direct Notion DB equivalent. Not part of the AISE migration.

### Key fields

| Field ID | Type | Writable | Notes |
|---|---|---|---|
| `name` | string | ✅ | Workspace name. **Required.** |
| `companyId` | objectId | ✅ | Parent Company `_id`. **Required.** |
| `externalId` | string | ✅ | Your own external ID — use Notion Customer page ID if mapping a sub-account. |
| `sourceId` | string | ✅ | SF sync key if applicable. |
| `custom.Staging Space` | boolean | ✅ | Whether this is a staging/sandbox workspace. |
| `custom.AI Consent Granted – SF` | boolean | ❌ Read-only | Whether AI consent is granted for this workspace. System-managed, Salesforce-synced. **Corrected 2026-09-12** — previously documented as `custom.AI Consent Granted` without the suffix, which does not exist. |
| `custom.Admin Console` | string | ❌ Read-only | Link to the workspace's admin console. |
| `custom.Space Type – SF` | string | ❌ Read-only | Workspace classification from Salesforce. |
| `custom.Current Plan – SF` / `custom.Current Plan Version – SF` / `custom.Plan Name + Version` | string | ❌ Read-only | Plan on this specific workspace. Differs per workspace on multi-space accounts — the Company-level `custom.Plan Names` flattens them. |
| `custom.ARR – SF` | number | ❌ Read-only | ARR attributed to this workspace. |
| `custom.Has Services – SF` | boolean | ❌ Read-only | Whether this workspace has a services entitlement. |

#### Per-workspace Spark state — **read this before trusting the Company-level Spark fields**

The Company model carries one `custom.⚡️ Spark Stage` value for the whole account. On a multi-workspace customer that is a flattening, and it will be wrong for at least some of their spaces. Asset carries the real per-workspace state:

| Field ID | Type | Notes |
|---|---|---|
| `custom.Spark Enabled – SNF` | boolean | Spark on for this workspace. |
| `custom.Spark Activated Visibility – SNF` | boolean | Visibility has been activated at all. |
| `custom.Spark Visibility Everyone – SNF` | boolean | Open to all makers in this workspace. |
| `custom.Spark Visibility Admins – SNF` | boolean | Admin-only in this workspace. |
| `custom.Spark Activation Stage – SNF` | string | Furthest activation stage reached on this workspace. |
| `custom.Spark State – SNF` / `custom.Spark Engaged State – SNF` | string | Derived state labels. |
| `custom.Spark Engaged – SNF` | boolean | Someone reached L2 in this workspace. |
| `custom.Spark Engaged Change Date – SNF` | string | When engagement state last moved. |
| `custom.First Spark Activity – SNF` / `custom.Last Spark Activity – SNF` | string | First and most recent Spark activity. |
| `custom.Spark Active Days – SNF` | number | Distinct active days. |
| `custom.Days Since Last AI Activity – SNF` | number | Staleness signal. |
| `custom.Last Seen – SNF` | string | Last seen in this workspace. |
| `custom.Motion – SNF` | string | `Ignite` · `Strike`. |
| `custom.Plan Era – SNF` | string | Plan generation this workspace sits on. |

#### Spark visibility — what the flags mean and how to derive a single value

**Visibility is a two-step admin action, and that is the whole point of this section.** An admin must first actively enable Spark on the workspace, and then switch visibility on or off separately. The two steps are independent, which is why a workspace can sit enabled with nobody able to see it.

Snowflake exposes no single visibility column. It exposes booleans, and the state has to be derived. Verified against live data 2026-09-12:

| `Spark Enabled – SNF` | `Spark Visibility Everyone – SNF` | `Spark Visibility Admins – SNF` | Value | What it means |
|---|---|---|---|---|
| empty | — | — | *(blank)* | Workspace is not in the Snowflake feed. Not the same as off. |
| `false` | — | — | `Spark not enabled` | Spark was never switched on here. |
| `true` | `true` | `false` | `Everyone` | Open to all makers. |
| `true` | `false` | `true` | `Admins only` | Restricted to admins. |
| `true` | `false` | `false` | `Spark off` | **Enabled, then visibility deliberately turned off.** |

**`Spark off` is a decision, not an oversight.** Because enabling and granting visibility are separate deliberate acts, a workspace in this state had Spark switched on and visibility switched off afterwards. Treat it as a signal — a governance, trust or internal-policy call worth understanding — not as a forgotten toggle or a data gap. This is the opposite of `Spark not enabled`, which is simply a customer who never turned it on.

The two map onto the Spark in Practice tiers: `Spark not enabled` is T5 (enablement motion — do not book an Ignition Meeting), `Admins only` is T4 (open visibility to makers first), and `Spark off` is its own case that needs a conversation before any adoption push.

**Why `custom.Spark Activated Visibility – SNF` is not in the logic.** It is a precondition flag, and two live checks make it redundant: no record has `Activated Visibility = false` with either audience flag `true` (zero of either combination), and a workspace with `Activated Visibility = true` but neither audience flag set is `Spark off` like any other. Checking the two audience booleans alone is therefore provably equivalent. If Snowflake ever emits an audience flag with `Activated Visibility = false`, that equivalence breaks — re-verify with a pair of filter queries before assuming it still holds.

**Never write any of these fields.** All `– SNF`, all Snowflake-sourced.

---

#### Formula fields built on this (2026-09-12)

These were built and verified against Autorola, Brandwatch and SAP SE. **Before editing any of them, read `skills/planhat-formula-builder/SKILL.md` gotchas 16, 17 and 18** — all three were discovered building exactly these fields, and each one produces a field that looks built and silently returns the wrong answer.

**Workspace (Asset) · `Spark Visibility` · Text**

```
IF(
  IS_EMPTY(<<custom.Spark State – SNF>>),
  ,
  IF(
    <<custom.Spark Visibility Everyone – SNF>> == true,
    Everyone,
    IF(
      <<custom.Spark Visibility Admins – SNF>> == true,
      Admins only,
      IF(
        <<custom.Spark Enabled – SNF>> == true,
        Spark off,
        Spark not enabled
      )
    )
  )
)
```

`custom.Spark State – SNF` is the presence sentinel rather than the boolean, because `IS_EMPTY()` returns true for *any* boolean regardless of value (gotcha #17). The two fields are exactly co-populated — zero records carry one without the other — which is what makes the substitution safe. Literals are unquoted and the empty return is an empty position (gotcha #16).

**Company · four Number count fields**

Each counts Workspace (Asset) records, gated on `ARR – SF > 0` so free, trial, staging and abandoned spaces stay out. Those dominate the Asset table and would otherwise swamp every count.

| Field | Filters beyond `ARR – SF > 0` |
|---|---|
| `Spark WS Paying` | none — this is the denominator |
| `Spark WS Everyone` | `custom.Spark Visibility Everyone – SNF` = `true` |
| `Spark WS Admins Only` | `custom.Spark Visibility Admins – SNF` = `true` |
| `Spark WS Enabled` | `custom.Spark Enabled – SNF` = `true` |

```
COUNT(Asset & {
  "filters": [
    {"op": "equal to", "field": {"id": "custom.Spark Visibility Everyone – SNF"}, "value": true},
    {"op": "more than", "field": {"id": "custom.ARR – SF"}, "value": 0}
  ]
})
```

Values inside the options object keep their JSON quoting — the unquoting rule in gotcha #16 applies only to the formula body, never here.

**Company · `Spark Visibility (Account)` · Text**

```
IF(
  <<custom.Spark WS Paying>> == 0,
  No revenue-bearing workspace,
  IF(
    <<custom.Spark WS Everyone>> == <<custom.Spark WS Paying>>,
    Everyone,
    IF(
      <<custom.Spark WS Admins Only>> == <<custom.Spark WS Paying>>,
      Admins only,
      IF(
        <<custom.Spark WS Everyone>> > 0 || <<custom.Spark WS Admins Only>> > 0,
        Mixed,
        IF(
          <<custom.Spark WS Enabled>> > 0,
          Spark off,
          Spark not enabled
        )
      )
    )
  )
)
```

`Everyone` and `Admins only` require **every** paying workspace to agree. Anything else with at least one visible workspace is `Mixed`. The `||` is load-bearing: written as `<<A>> + <<B>> > 0` the branch silently never fires (gotcha #18), which produced a wrong `Spark off` on SAP SE until it was caught.

**Verified results:**

| Account | Paying | Everyone | Admins | Result |
|---|---|---|---|---|
| Autorola Group | 1 | 1 | 0 | `Everyone` |
| Brandwatch | 1 | 0 | 1 | `Admins only` |
| SAP SE | 2 | 1 | 0 | `Mixed` |

> **Read these instead of `Company.custom.⚡️ Spark Stage` for any scope or reporting decision.** Spark Stage holds one value for the whole account and is a flattening. Autorola reads `Everyone` there while its eight workspaces are one paying space open to everyone, two free spaces with Spark off, and five not in the feed at all. SAP SE reads `Everyone` off a $29.7k workspace while `signavio` at $614k sits deliberately dark.

#### Credits — per workspace, not per account

| Field ID | Type | Notes |
|---|---|---|
| `custom.Credit Allowance – SNF` | number | Credit allowance for this workspace. |
| `custom.Credits Used Current Period – SNF` | number | Consumed this period. |
| `custom.Credits Used Lifetime – SNF` | number | Consumed all time. |
| `custom.Credits Unlimited – SNF` | boolean | Whether the workspace is currently uncapped. |
| `custom.Trial End Date – SNF` | string | When a trial allowance ends. |

> **Use this whenever a customer asks about credits.** It is the only place the real per-workspace allowance and consumption live — there is no Company-level equivalent, and answering from memory or from the Company record will be wrong on any multi-workspace account.


### Write rules

- Tasks in Planhat can be linked to a Workspace via `custom.Workspace` (an objectId field on Task pointing to an Asset `_id`).
- Conversations can be linked to a Workspace via `custom.Services Package` (which resolves to a LineItem, but the Task→Workspace link is the relevant one for AISE).

---

## Objective (Planhat)

> Tracks customer-level goals and success metrics. Can contribute to the health score. Closest Notion equivalent would be engagement plan milestones or Active Package goals — but no formal mapping yet.

### Notion equivalent

No direct Notion DB equivalent. Potential future mapping: key milestones from the Engagement Plan in the Active Package body.

### Key fields

| Field ID | Type | Writable | Notes |
|---|---|---|---|
| `name` | string | ✅ | Goal name. **Required.** |
| `companyId` | objectId | ✅ | Parent Company `_id`. **Required.** |
| `health` | number | ✅ | Progress score (0–100) — feeds into Company health score if configured. |
| `externalId` | string | ✅ | Your own external ID. |
| `sourceId` | string | ✅ | SF sync key if applicable. |

---

## Workflow (Planhat)

> Planhat Workflows are structured playbooks — **series of Tasks that define what calls and tasks a customer program includes** (e.g. an AISE onboarding program with Kick-off → Architecting → Enablement). Each Workflow step maps to a Task (and eventually a Conversation once delivered). Two template types are active in the workspace:
> - `6a5667be04de5d468d2e4821`
> - `6a679b421d3fcc56aecaf2f2`
>
> Workflow `outcome` options (configured): `Completed – partial adoption` · `Not completed – disengaged` · `Program completed – champion embedded`
>
> Workflows are Planhat-native — they are not migrated from Notion. The Tasks and Conversations inside a Workflow are the same records as the standalone Tasks/Conversations AISE writes; the Workflow is just the container that tracks program progress and percentage completion.

### Notion equivalent

Closest equivalent: Engagement Plan in the Active Package body. No migration path — Workflows are forward-looking structures, not historical records.

### Write rules

- **Do not create Workflow records from migration backfill.** Use Planhat UI to instantiate programs from templates.
- To read active/past Workflows for an account: `list_model_records(MODEL: "Workflow", FILTER: {"companyId[equal to]": "<id>"}, SELECT: ["name", "status", "percentDone", "outcome", "startDate", "expectedEndDate"])`

---

## NPS (Planhat)

> Survey response records. Planhat model name: `Nps`.

### Notion equivalent

No Notion equivalent. NPS is Planhat/CS team native — not migrated from Notion.

### Key fields (read-only context)

| Field ID | Type | Notes |
|---|---|---|
| `score` | number | 0–10 NPS score |
| `comment` | string | Respondent's free-text feedback |
| `email` | string | Respondent email |
| `scoreType` | string (read-only) | `promoter` / `passive` / `detractor` (auto-computed from score) |
| `dateSent` | datetime | Survey sent date |
| `dateAnswered` | datetime | Response received |
| `cId` | objectId | Planhat Company `_id` (required) |
| `euId` | objectId | EndUser who responded |

---

## Issue (Planhat)

> Bugs, feature requests, or tracked cases — can link to multiple companies, end users, and conversations. Useful for tracking cross-customer patterns.
>
> ⛔ **Auto-synced from Zendesk. Never write Issue records via MCP.** Issues are pulled automatically from Zendesk — do not create or update them from Notion or manually via the API.

### Notion equivalent

No Notion equivalent. Not part of the AISE migration.

### Key fields (read-only context)

| Field ID | Type | Notes |
|---|---|---|
| `title` | string | Issue title. **Required.** |
| `description` | string | Details. |
| `status` | string | `Open` · `In Progress` · `Done` |
| `priority` | string | Free-text priority. |
| `issueType` | string | Issue category. |
| `companyIds` | array | One or more Planhat Company `_id` values (can span accounts). |
| `enduserIds` | array | Affected end users. |
| `conversationIds` | array | Linked conversations (e.g. the support call that surfaced the issue). |
| `sourceId` | string | External system ID (e.g. Jira issue key). |

---

## Churn (Planhat)

> Churn/cancellation records with reasons and revenue impact. Created when a customer fully churns.

### Notion equivalent

No Notion equivalent. Churn records are created in Planhat by the CSM when `custom.AISE Journey Status` is set to `Churned` and `phase` is set to `4. Churned`.

### Key fields

| Field ID | Type | Writable | Notes |
|---|---|---|---|
| `companyId` | objectId | ✅ | Parent Company `_id`. **Required.** |
| `churnDate` | date | ✅ | Date of churn. |
| `value` | number | ✅ | Lost ARR value. |
| `reasons` | array | ✅ | Churn reasons. |
| `description` | string | ✅ | Free-text notes. |
| `onlyDowngrade` | boolean | ✅ | True if this is a downgrade rather than a full churn. |

### Write rules

- Do not create Churn records via migration backfill — they should be created in real-time by the CSM at churn.
- When `phase` is set to `4. Churned`, check if a Churn record already exists for the account before creating one.

---

## Deal (Planhat) — read-only

> Tracks active and historical contracts. Synced from Salesforce. **Never write from Notion to Planhat.**

### Notion equivalent

Active Packages (functional equivalent). Each Deal in Planhat represents a contract, with `LineItem` records for individual SKUs (subscription lines, services credits).

### How to read Deal data for an account

```
list_model_records(
  MODEL: "Deal",
  FILTER: {"companyId[equal to]": "<planhat-company-id>"},
  SELECT: ["name", "stage", "mrr", "arr", "startDate", "endDate", "renewalDate", "custom.Renewal Risk"]
)
```

### Key fields (read context)

| Field ID | Type | Notes |
|---|---|---|
| `name` | string | Deal name (auto-populated from company) |
| `stage` | string | `Closed Won` · `Closed Lost` |
| `mrr` / `arr` | number | Revenue (locked — calculated from LineItems when lines exist) |
| `startDate` / `endDate` | date | Contract start/end (locked when LineItems exist) |
| `renewalDate` | date | Soonest renewal across all subscription LineItems |
| `custom.Renewal Risk` | string | `Will Renew` · `Likely to Renew` · `Risk to Renewal` · `Planning to Contract` · `Planning to Churn` · `Churned` · `Suspended (Non Payment)` · `High` · `Medium` · `Low` · `TBD` |
| `custom.Service Start Date – SF` | string | Services start from SF |
| `custom.Service End Date – SF` | string | Services end from SF |

---

## Product (Planhat) — read-only

> SKU templates used to populate LineItems on Deals. Synced from Salesforce. **Never write from Notion to Planhat.**

### Key fields (read context)

| Field ID | Type | Notes |
|---|---|---|
| `name` | string | Product/SKU name |
| `type` | string | `subscription` · `fee` |
| `mrr` / `arr` | number | Default pricing |
| `custom.SKU` | string | SKU identifier |
| `custom.Service SKU – SF` | boolean | Whether this is a services SKU (vs software license). **Corrected 2026-09-12** — needs the `– SF` suffix. |
| `custom.AISE Working Sessions` | number | Session quota for this SKU — both Architecting and Training (Enablement) sessions deduct from this shared pool |
| `custom.License Type – SF` | string | License classification. **Corrected 2026-09-12** — needs the `– SF` suffix, and it is read-only. |

---

## Line Item (Planhat) — read-only, per-customer session allocation

> Line-level rows on a Deal — the actual purchased instance of a Product/SKU for one customer. SF SSOT. **Never write from AISE workflows.** Verified live against `get_model_action_parameters` 2026-09.

### How to read a customer's contracted session pool

```
list_model_records(
  MODEL: "Line Item",
  FILTER: {"companyId[equal to]": "<planhat-company-id>", "status[equal to]": "ongoing"},
  SELECT: ["productName", "custom.AISE Working Sessions", "custom.Product Type – SF", "fromDate", "toDate"]
)
```

Sum `custom.AISE Working Sessions` across all `status: "ongoing"` lines to get the customer's total contracted Architecting + Training session pool. **It's one shared pool, not two separate caps** — the field description states this explicitly: "Both session types discount from this shared pool for simplicity." A customer with multiple active lines (e.g. a renewal alongside an add-on) sums across all of them; zero or no `ongoing` lines means no confirmed allocation — flag rather than assume unlimited.

### Key fields (read context)

| Field ID | Type | Notes |
|---|---|---|
| `companyId` | objectId | Parent Company. |
| `dealId` | objectId | Parent Deal. |
| `status` | string | `ongoing` · `renewed` · `lost`. Filter to `ongoing` for current allocation. |
| `productName` | string | Read-only, denormalized from the linked Product. |
| `custom.AISE Working Sessions` | number | This line's contribution to the customer's Architecting+Training pool. |
| `fromDate` / `toDate` | date | Line's active period. |

---

## Comment (Planhat)

> Used by `post-session-debrief` to post next-session planning + account-notable updates on the Company after every debrief (replaces the old Notion "Customer page update" + "next-session planning notes" writes).

### Key fields

| Field ID | Type | Notes |
|---|---|---|
| `commentableType` | string | **Required.** Target model — `"Company"` for AISE account-level comments. Also supports `Conversation`, `Task`, and most other models. |
| `commentableId` | objectId | **Required.** `_id` of the target record. |
| `text` | string | **HTML restricted to `<p>`, `<a>`, and mention tags only** — bold, bullets, and other markup are not supported and will render broken or get stripped. Structure multi-part content as separate `<p>` paragraphs, not a bulleted list. |

### Write rules

- **Content is plain-paragraph HTML only.** Don't reuse the `<strong>`/`<ul>` patterns used for Conversation/Task rich-text fields — Comment doesn't render them.
- No dedup key — comments are additive. Don't post an empty or redundant comment; skip the write if there's nothing to say.

### Read rules

> Used by the **Facilitator call notes in Planhat** check (`project-instructions.md` § Transcript lookup order) to pick up notes a facilitator left directly on the session's Task/Conversation instead of, or alongside, the Gong transcript.

`list_model_records(MODEL: "Comment", FILTER: {"commentableId[equal to]": "<task_or_conversation_id>", "commentableType[equal to]": "Task"}, SELECT: ["text", "createdAt", "userId"])` — swap `"Task"` for `"Conversation"` to check the linked Conversation. Run both when the session has both a Task and a Conversation record, since either could carry a comment. Empty results are normal — most sessions have none.

---

## Attachment (Planhat)

> Used by `post-session-debrief` to attach the KDD doc (`kdd-builder` output) to the session's Conversation — the Planhat equivalent of the old Notion `KDDs — …` sub-page.

### Key fields

| Field ID | Type | Notes |
|---|---|---|
| `name` | string | Display name for the attachment. |
| `documentableType` | string | **Required.** Target model — `"Conversation"` for session KDD attachments. |
| `documentableId` | objectId | **Required.** `_id` of the target record. |
| `sourceUrl` | string | **Required.** A public `http`/`https` URL, ≤25MB — **Planhat's server fetches and stores the file itself; there is no raw-content upload path.** |

### Write rules

- **`sourceUrl` must be directly fetchable, not a viewer page.** For Google Drive files, `https://drive.google.com/file/d/{id}/view` is an HTML wrapper and will not work — use `https://drive.google.com/uc?export=download&id={id}` instead, and only after the file has been explicitly shared "anyone with the link, reader" (Planhat's fetch isn't an authenticated Drive user, so default sharing silently fails).
- Confidentiality: sharing a customer-facing doc "anyone with the link" is a deliberate, minimal-necessary exposure — apply the same judgment already used for diagrams leaving the Notion boundary. Don't widen sharing beyond what the Attachment step needs.

---

## Known non-sessions (do not recreate)

Calendar events that look like delivered sessions but were cancelled, declined or never held. `session-log-auditor` must treat a matching event id as **not held** and skip it as a create candidate (§ Step 6a occurrence check).

An entry belongs here only when the erroneous record was **hard-deleted**. Archiving is the default reversal precisely because it leaves the `externalId` in place, which already blocks recreation — archived records need no entry.

| Date | Account | Calendar event id | Evidence it was not held | Removed |
|---|---|---|---|---|
| 2026-06-16 | Zoom | `4qrmdmlnsbol0t10orqo76vv5l_20260616T170000Z` | Gong (`001f400000yx4MtAAI`): zero calls, meeting declined. Corroborated by the 2026-06-26 email "Spark is now GA – ready when Zoom is". | Deleted 2026-08-24 (was `6a8cb62e6665ec9ae3c8e695`) |
| 2026-08-18 | Appspace | `0h4g3el21p8s0h1625u8on1neb_20260818T183000Z` | Gong: "canceled last minute by Sean Duffy from Appspace". Corroborated by Denae's 2026-08-19 email "Sorry for cancelling last minute". | Deleted 2026-08-24 (was `6a8cb6326665ec9ae3c8e73f`) |

---

## Models To Be Documented

The following models exist in Planhat but have no current AISE migration use case. Use `get_model_action_parameters(MODEL: "<model>")` if needed.

| Model | Notes |
|---|---|
| `Email Template` | Planhat-native marketing/CS email templates. No current AISE use case. |
