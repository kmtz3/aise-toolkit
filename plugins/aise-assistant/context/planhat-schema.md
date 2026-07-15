# Planhat Schema & Notion↔Planhat Traversal Guide

> **Status:** In-transition. Notion remains the primary AISE working record (sessions, tasks, program plans). Planhat is the CS platform of record for account health, revenue, and Spark/AI readiness tracking. During the transition, **both systems must be kept in sync** for Spark fields. Agents should read from Notion for session/program context and from Planhat for CS health signals.
>
> **Last updated:** 2026-07-10

---

## MCP Access

| Detail | Value |
|---|---|
| MCP server ID | `7441c372-4b65-4805-95b0-baf2a081ceb3` |
| Key tools | `list_model_records`, `get_model_record`, `update_model_record`, `search_records`, `get_model_action_parameters` |
| Available models | `Company`, `EndUser`, `Task`, `Conversation`, `Deal`, `Nps`, `Issue`, `Workflow`, `Churn`, `Document`, `User`, `Product`, `LineItem`, `EmailTemplate`, `Comment` |

---

## System Mapping: Notion ↔ Planhat

### Database equivalents

| Notion DB | Planhat Model | Notes |
|---|---|---|
| **Customers** | **Company** | Core account record. Primary mapping target. |
| **Contacts** | **EndUser** | Individual contacts at accounts. Not yet mapped. |
| **Tasks** | **Task** | Action items. Planhat Tasks are CS-team facing. Not yet mapped. |
| **Sessions** | **Conversation** (partial) | Calls/interactions. Planhat Conversations cover emails, calls, notes. No direct session equivalent yet. |
| **Active Packages** | _(no direct equivalent)_ | Planhat uses `Deal` + `LineItem` for contract/revenue tracking. |
| **Master Packages** | _(no direct equivalent)_ | SKU logic lives in Planhat `Product`. |

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
| `ARR` (rollup) | `arr` | number | Planhat `arr` = annualized MRR from active licenses. Notion ARR = rollup from Active Packages. **Planhat `arr` is the financial source of truth** (synced from Salesforce via `custom.ARR – Salesforce`). |
| `Renewal Forecast` | _(no direct equivalent)_ | — | Planhat has `renewalDate` and `renewalArr` but no forecast select. |
| _(Notion only)_ | `h` (health score 0–10) | number | **[PLANHAT ONLY]** Computed health score. Useful context when prepping sessions. |
| _(Notion only)_ | `lastActive` | date | **[PLANHAT ONLY]** Last product activity date. |
| _(Notion only)_ | `nextTouch` / `lastTouch` | date | **[PLANHAT ONLY]** Next/last scheduled or logged interaction. |

#### Spark / AI readiness — **[SYNCED]**

These three fields are actively synced Notion → Planhat by the AISE assistant.

| Notion field | Planhat field ID | Type | Value mapping |
|---|---|---|---|
| `Spark Customer Journey` | `custom.Spark Stage` | string (select) | `Not Active` → `Not Active` · `AI Terms Review` → `AI Terms Review` · `Active for Admins (Production)` → `Active for Admins` · `Active for All (Production)` → `Active for All` · `Active (Staging only)` → `Active on Staging` · `Icebox` → `Icebox` |
| `AI Ready` | `custom.AI Ready` | string (select) | `Sparked` → `Sparked` · `Preparing` → `Preparing` · `Ignitable` → `Ignitable` · `Not ready` → `Not Ready` _(note capital R)_ |
| `Igniting?` | `custom.Igniting?` | boolean | `__YES__` → `true` · `__NO__` → `false` |
| `Days in Current Ignite Phase` (formula) | `custom.Days in Current Ignite Stage` | string (read-only) | Both are computed. Do not write either. |
| `Ignite Journey Last Edited` (date) | _(no equivalent)_ | — | Notion-only automation field. |

**Write direction:** Notion → Planhat. Notion is the source of truth for Spark fields during the current transition. When updating Spark status, write to Notion first (via `notion-update-page`), then sync to Planhat (via `update_model_record`).

#### Financial

| Notion field | Planhat field ID | Notes |
|---|---|---|
| _(no equivalent)_ | `mrr` | Monthly Recurring Revenue — Planhat only |
| _(no equivalent)_ | `arr` | Annual Recurring Revenue — Planhat only |
| _(no equivalent)_ | `renewalDate` | Contract renewal date — Planhat only |
| _(no equivalent)_ | `renewalDaysFromNow` | Days until next renewal — Planhat only, read-only |
| _(no equivalent)_ | `custom.ARR – Salesforce` | ARR from Salesforce — Planhat only |
| _(no equivalent)_ | `custom.Customer Status – SF` | Salesforce lifecycle status — Planhat only |
| _(no equivalent)_ | `custom.Region` | Geographic region — Planhat only |
| _(no equivalent)_ | `custom.Segment` | Customer segment — Planhat only |

---

## Customer Name Mapping: Notion → Planhat

Some accounts are named differently across systems. Always check this table before concluding no Planhat record exists.

| Notion name | Planhat name | Planhat `_id` | Match method |
|---|---|---|---|
| WeClapp GMBH | weclapp GmbH | `6a4cd728ef3ea36a06911298` | Name |
| Ecovadis | ECOVADIS SAS | `6a4cd724ef3ea30f44910507` | Name |
| Qlik (Talend) | Talend | `6a4cd728ef3ea333c991129e` | Name |
| Verisk SBS | Verisk | `6a4cd722ef3ea3fb9a9101fc` | Name |
| Onfido | Onfido Ltd | `6a4cd728ef3ea31463911108` | Name |
| Outsystems | OutSystems | `6a4cd728ef3ea3b89e91110b` | Name |
| SymphonyAI | Symphony AI | `6a4cd728ef3ea37f3c91135c` | Name |
| Hilti AG | Hilti | `6a4cd722ef3ea3deb09101a6` | Name |
| S&P Global Market Intelligence | S&P Global | `6a4cd728ef3ea3132a91125d` | Name |
| S&P Global Ratings | S&P Global | `6a4cd728ef3ea3132a91125d` | Name — same Planhat Company; both Notion records map here |
| North SALIDO | North American Bancard | `6a4cd722ef3ea332c691015a` | SF sourceId |

### Known conflicts

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

1. Search Notion Customers DB for customer X → get `Spark Customer Journey`, `Igniting?`, `AI Ready`
2. Optionally cross-check Planhat: `search_records(QUERY: "<customer name>")` → `get_model_record(SELECT: ["custom.Spark Stage", "custom.AI Ready", "custom.Igniting?"])`
3. If they differ, **Notion is the source of truth** — flag the discrepancy and offer to re-sync Planhat.

### "Update Spark status for customer X"

1. Write to Notion Customer page via `notion-update-page`
2. Find the Planhat Company record (name search or SF sourceId)
3. Write to Planhat via `update_model_record` with mapped values (see value mapping table above)
4. Confirm both writes succeeded before reporting done

### "What's the health / ARR / renewal date for customer X?"

Planhat only — Notion does not track these in real time.
1. `search_records(QUERY: "<customer name>")` → get `_id`
2. `get_model_record(MODEL: "Company", OBJECT_ID: "<id>", SELECT: ["h", "arr", "mrr", "renewalDate", "renewalDaysFromNow", "csmScore", "lastActive", "custom.Customer Status – SF", "custom.Region", "custom.Segment"])`

### "Who are the contacts at customer X?"

- **Notion:** query Contacts DB linked via the Customer's `Contacts` relation
- **Planhat:** `list_model_records(MODEL: "EndUser", FILTER: {"companyId[equal to]": "<planhat_company_id>"})` _(EndUser schema not yet fully documented — run `get_model_action_parameters(MODEL: "EndUser")` first)_

### "Show me open tasks for customer X"

- **Notion:** query Tasks DB with `Customers LIKE '%<customer-id>%'`
- **Planhat:** `list_model_records(MODEL: "Task", FILTER: {"companyId[equal to]": "<planhat_company_id>"})` _(Task schema not yet fully documented)_

---

## Planhat Company — Full Field Reference

### Standard writable fields

| Field ID | Type | Description |
|---|---|---|
| `name` | string | Display name. **Required.** |
| `owner` | objectId → User | CSM / Account Manager. Do not overwrite from AISE logic. |
| `coOwner` | objectId → User | Secondary owner. |
| `phase` | string | Lifecycle stage (free-text or from a configured list). |
| `tags` | array | Freeform labels for segmentation. |
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
| `arr` | Annual Recurring Revenue (annualized MRR) |
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

> Fields marked **[SF-SYNCED]** are populated by the Salesforce → Planhat sync. **Never write these via MCP.** The exact SF mapping is WIP; treat any unmarked field as writable only if it appears as writable in `notion-planhat-field-mapping.md`.

#### SF-synced — do not write

| Field ID | Type | Options | Notes |
|---|---|---|---|
| `custom.ARR – Salesforce` | number | — | ARR from SF |
| `custom.Customer Status – SF` | string | `1.0 Customer`, `2.0 Pipeline`, `4.0 Lost`, `5.0 Churn` | SF lifecycle |
| `custom.Account Executive` | objectId → User | — | AE — managed by RevOps via SF |
| `custom.Renewals Manager` | objectId → User | — | RM — managed by RevOps via SF |
| `custom.Segment` | string | — | Customer segment |
| `custom.Region` | string | `EMEA`, `NOAM`, `APAC`, `LATAM`, `AUNZ`, `Missing`, `Exclude`, `Blacklisted` | Region |
| `custom.Purchased Makers` | number | — | Contracted maker seats |
| `custom.Current Makers` | number | — | Active maker seat count |
| `custom.Slack URL` | string | — | Slack channel URL |
| `custom.Slack ID` | string | — | Slack channel ID |
| `custom.Salesforce URL` | string | — | SF account URL — system read-only |
| `custom.AI Readiness – SF` | string | `AI-Forward (Inferred/Validated)`, `AI-Interested (Inferred/Validated)`, `AI-Resistant (Inferred/Validated)` | SF-synced AI readiness |
| `custom.Days in Current Ignite Stage` | string | — | Auto-computed. Read-only. |

#### AISE-writable

| Field ID | Type | Options | Notes |
|---|---|---|---|
| `custom.Spark Stage` | string | `Not Active`, `AI Terms Review`, `Active for Admins`, `Active for All`, `Icebox`, `Active on Staging` | ← Notion `Spark Customer Journey` |
| `custom.AI Ready` | string | `Ignitable`, `Sparked`, `Preparing`, `Not Ready` | ← Notion `AI Ready` |
| `custom.Igniting?` | boolean | `true` / `false` | ← Notion `Igniting?` |
| `custom.AISE Journey Status` | string | `Presales`, `Active (no Services)`, `Active (Services)`, `Contracted to Scale`, `Churned` | ← Notion `Account Status`. **`Not started` is not a valid option — omit.** Note: field ID is `custom.AISE Journey Status`, not `custom.Journey Status`. |
| `phase` | string | Free-text lifecycle stage (e.g. `Onboarding`, `Adoption`, `Renewal`) | Standard Planhat field. Replaces the deleted `custom.Services Phase`. Use this to track where a customer is in their services journey. |
| `custom.AI Readiness Score` | number | — | Set manually in Planhat if needed |

---

## Write Rules

- **Never write SF-synced fields.** See the SF-synced table above. This includes account fields (Region, Segment, ARR, Makers, Slack, Account Executive, etc.), Deal records, and Line Item records. Do not write these even if the field appears blank — the sync owns them. Exact mapping is WIP; when uncertain, treat a field as SF-synced unless it appears in the AISE-writable table.
- **Never write read-only fields** — Planhat will error.
- **Custom field prefix:** always use `custom.` (e.g. `"custom.Spark Stage": "Active for All"`).
- **Boolean custom fields:** use raw `true`/`false`, not strings.
- **Option values:** exact casing required (e.g. `"Not Ready"` not `"Not ready"`).
- **Do not overwrite `owner`** — managed by RevOps/CS leadership.
- **Company records are SF-synced** — do not create new Company records via MCP. Creation is handled by RevOps via Salesforce sync.

### Rich Text Field Formatting

Planhat rich text fields (type `Rich text`) require **HTML** — plain text with markdown-style `- ` bullets or `\n` line breaks does not render as formatted content.

**Bullet lists:** use `<ul><li>` tags:
```html
<ul><li>First point</li><li>Second point</li><li>Third point</li></ul>
```

**Numbered lists:**
```html
<ol><li>First step</li><li>Second step</li></ol>
```

**Bold text:** `<strong>text</strong>`

**Line breaks:** `<br>` or wrap paragraphs in `<p>` tags.

**Combined example:**
```html
<ul><li><strong>Current tool:</strong> Aha! for product management</li><li>Azure DevOps for delivery execution</li></ul>
```

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
| Elizabeth Johnstone | elizabeth.johnstone@productboard.com | `6a4cc31c2af0cba3a10bd0fd` |
| Carson Mak | carson.mak@productboard.com | `6a4f72300b5e9f5803437923` |
| Darrel Wu | darrell.wu@productboard.com | `6a4f72473275894bcf89ee78` |
| Tomas Krivanek | tomas.krivanek@productboard.com | `6a50db36f7236907a27c11c3` |

**Runtime resolution:** agents that need Klara's Planhat ID (the current user) can use the hardcoded value above. For other team members, resolve via `list_model_records(MODEL: "User", FILTER: {"email[equal to]": "<email>"}, SELECT: ["firstName", "lastName", "email"])` if the ID is not in this table.

---

## Conversation (Planhat) ↔ Session (Notion)

> **Design note:** Planhat Conversations are the canonical home for AISE session history. AISE writes all delivered sessions (external and internal) as Conversations with `source: "AISE"`, using `externalId` as the dedup key back to Notion. Existing Conversations in Planhat are mostly Zendesk tickets (`source: "zendesk"`) and calendar events synced as Tasks (`mainType: event`). AISE-originated sessions are a distinct type and won't collide with those sources.

### How to look up a Planhat Conversation for a given session

**Check before creating:** use `externalId` as the dedup key.

```
list_model_records(
  MODEL: "Conversation",
  FILTER: {"externalId[equal to]": "<notion-session-page-id>"},
  SELECT: ["subject", "type", "date", "companyId", "externalId"]
)
```

If a result is returned, update it rather than creating a duplicate.

### Field-level mapping: Notion Session → Planhat Conversation

| Notion field | Planhat field | Type | Direction | Notes |
|---|---|---|---|---|
| Session page ID (URL) | `externalId` | string | Write on create | **Dedup key.** Extract the 32-char hex ID from the Notion page URL. Unique within a company. |
| `Name` (title) | `subject` | string | Write | Session name as-is. |
| `Type` (select) | `type` | string | Write | See value mapping below. Custom string — Planhat accepts any value. |
| `Call Date` | `date` | datetime | Write | ISO 8601. Use `date:Call Date:start` from Notion. |
| `Session Length (h)` | `startDate` / `endDate` | date | Write | `startDate = Call Date`. `endDate = Call Date + Session Length (h)` as a duration offset. Both are date-only (not datetime). |
| `Customers` (relation) | `companyId` | string | Write | Planhat Company `_id`. Resolve via name-search or `sourceId` lookup (see Company section). |
| `Delivered By` (person) | `users` | array | Write | Array of `{"id": "<planhat-user-id>"}`. Resolve from AISE User ID table above. |
| `Next Steps` / session page body | `description` | string | Write | Summary/notes from the session. Truncate to ~2000 chars if long. |
| `Gong call` (url) | `description` (appended) | string | Write | Append `\n\nGong: <url>` to description if present. |
| `Call Status` | _(not mapped)_ | — | — | Notion-only status lifecycle. Not meaningful in Planhat. |
| `Consumed Package` | _(not mapped)_ | — | — | Notion credit-ledger concept. No Planhat equivalent. |
| `Do not count` | _(not mapped)_ | — | — | Notion-only billing flag. |
| `Spark conversation` | `activityTags` | array | Write | If `__YES__`, include `"Spark"` in `activityTags`. |
| _(no equivalent)_ | `source` | string | Write (constant) | Always `"AISE"` for sessions written by this assistant. Distinguishes from Zendesk/GCal entries. |

#### Type value mapping: Notion → Planhat

These are the exact Planhat conversation type values configured in the workspace.

| Notion `Type` | Planhat `type` | Notes |
|---|---|---|
| `🏗️ Architecting` | `"Architecting"` | |
| `🗣️ Sync` | `"Sync"` | |
| `🎓 Training` | `"Enablement"` | Planhat uses "Enablement" not "Training" |
| `👟 Kick off` | `"Kick off"` | |
| `🔎 Discovery` | `"Discovery"` | |
| `📦 Other` | `"Audit / Setup Review"` | Catch-all for QBRs, ad hoc, setup calls |
| `🫥 Internal` | `"Internal Alignment"` | Sync to Planhat — appears under Internal section |

> **Planhat types with no Notion equivalent:** `Webinar`, `Demo` — used for non-AISE sessions logged directly in Planhat. Do not create Notion sessions for these types.

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
| `description` | string | — | Summary, notes, Gong URL. |
| `date` | datetime | — | When the session took place (ISO 8601). |
| `startDate` | date | — | Call start date. |
| `endDate` | date | — | Call end date (derived from duration). |
| `companyId` | string | ✅ | Planhat Company `_id`. |
| `users` | array | — | `[{"id": "<planhat-user-id>"}]` — team members who delivered. |
| `endusers` | array | — | `[{"id": "<planhat-enduser-id>"}]` — customer contacts who attended. |
| `externalId` | string | — | Notion Session page ID. **Dedup key.** |
| `source` | string | — | Always `"AISE"`. |
| `activityTags` | array | — | `["Spark"]` if `Spark conversation = YES`. |
| `transcript` | string | — | Full transcript text if available. |
| `category` | string | — | One of: `Support`, `Feedback`, `Sales`, `Expansion`, `Billing & Contracts`, `Renewals`, `Legal`, `General Enquires`, `Spam`, `Marketing`. Leave blank for AISE sessions unless relevant. |

#### Read-only fields

`snippet`, `numberOfParts`, `parentId`, `parentType`, `createDate`, `companyName`, `isClassified`, `isSignalAnalyzed`, `shortSummary`, `isSeen`, `isOpen`, `isBounced`, `archived`, `scheduled`, `createdAt`, `updatedAt`

---

## Task (Planhat) ↔ Task (Notion)

> **Design note:** Planhat Tasks have two `mainType` values: `"task"` (to-dos, action items) and `"event"` (calendar meetings). Calendar events are already synced separately via GCal. AISE writes `mainType: "task"` records only. Currently no AISE-originated tasks exist in Planhat — this is a clean backfill.

### How to look up a Planhat Task for a given Notion task

**Check before creating:** use `sourceId` as the dedup key.

```
list_model_records(
  MODEL: "Task",
  FILTER: {"sourceId[equal to]": "<notion-task-page-id>", "mainType[equal to]": "task"},
  SELECT: ["action", "status", "companyId", "sourceId"]
)
```

### Field-level mapping: Notion Task → Planhat Task

| Notion field | Planhat field | Type | Direction | Notes |
|---|---|---|---|---|
| Notion Task page ID (URL) | `sourceId` | string | Write on create | **Dedup key.** Extract 32-char hex ID. |
| `Task` (title) | `action` | string | Write | Task title as-is. |
| `Status` | `status` | string | Write | See value mapping below. |
| `Due Date` | `endTime` | datetime | Write | ISO 8601. Set time to `T00:00:00.000Z` for date-only values. |
| `Customers` (relation) | `companyId` | string | Write | Planhat Company `_id`. Resolve via company lookup. **Skip if Customers = Productboard internal** — internal tasks don't belong in Planhat. |
| `Owner` (person) | `ownerId` | objectId | Write | Resolve Notion user UUID → Planhat user ID using the User ID table above. |
| `Priority` | `type` | string | Write | `"1"` → `"P1"`, `"2"` → `"P2"`, `"3"` → `"P3"`. Stored in the free-text `type` field. |
| `Do not count` | _(skip)_ | — | — | Notion billing flag. Not relevant to Planhat. |
| `Consumed Package` | _(skip)_ | — | — | No Planhat equivalent. |
| `Source Call` | `description` (appended) | string | Write | Append `"Source session: <session name>"` if present. |
| _(constant)_ | `mainType` | string | Write (constant) | Always `"task"`. |

#### Status value mapping

| Notion `Status` | Planhat `status` | Notes |
|---|---|---|
| `Not started` | `"To Do"` | |
| `In progress` | `"In-Progress"` | |
| `Done` | `"Done"` | |
| `Canceled` | _(skip — do not create)_ | Canceled tasks aren't worth backfilling. |

#### What to skip

- Tasks where `Customers` = the Productboard internal record (these are internal, not customer-facing)
- Tasks with `Status = Canceled`
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
| `status` | string | — | `"To Do"`, `"In-Progress"`, `"Done"`. |
| `type` | string | — | Priority label: `"P1"`, `"P2"`, `"P3"`. |
| `endTime` | datetime | — | Due date (ISO 8601). Required for `mainType: event`; optional for tasks. |
| `startTime` | datetime | — | Start time. Optional for tasks; required for events. |
| `companyId` | objectId | ✅ | Planhat Company `_id`. |
| `ownerId` | objectId | — | Planhat User `_id` of the person responsible. |
| `sourceId` | string | — | Notion Task page ID. **Dedup key.** |
| `activityTags` | array | — | Freeform tags for filtering. |
| `endusers` | array | — | Customer contacts involved: `[{"id": "<enduser-id>"}]`. |

#### Read-only fields

`ownerType`, `companyName`, `workflowId`, `workflowName`, `workflowTaskId`, `workflowStepId`, `workflowTemplateId`, `noteId`, `users`, `path`, `parentObject`, `createdAt`, `updatedAt`

---

## EndUser (Planhat) ↔ Contact (Notion)

> **Status:** Schema documented. Not yet actively written by AISE. Read-only for now — used during session prep to identify attendees and during debrief to link `endusers` on Conversations.

### How to look up a Planhat EndUser

```
list_model_records(
  MODEL: "EndUser",
  FILTER: {"companyId[equal to]": "<planhat-company-id>"},
  SELECT: ["name", "email", "position", "primary", "companyId"]
)
```

Or by email:
```
list_model_records(
  MODEL: "EndUser",
  FILTER: {"email[equal to]": "<contact-email>"},
  SELECT: ["name", "email", "position", "companyId"]
)
```

### Field-level mapping: Notion Contact → Planhat EndUser

| Notion field | Planhat field | Type | Notes |
|---|---|---|---|
| Contact name | `firstName` + `lastName` | string | Split on first space. |
| Email | `email` | string | Required if no `externalId`/`sourceId`. |
| Role / Job title | `position` | string | |
| `Customers` relation | `companyId` | string | Planhat Company `_id`. Required. |
| Main Contact flag | `primary` | boolean | `true` if this contact is the Notion `Main Contact` for the customer. |

### Custom fields (Productboard EndUser)

| Field ID | Type | Description |
|---|---|---|
| `custom.Project Role` | string | Role within the Productboard project/engagement. |
| `custom.# of Projects` | number | Number of PB projects the contact is involved in. |
| `custom.Engaged with Spark` | boolean | Whether the contact has engaged with Spark AI features. |
| `custom.User PB ID` | number | The contact's Productboard user ID (for cross-referencing PB product usage). |
| `custom.Last Activity – SF` | string | Last Salesforce activity date — read-only, synced from SF. |

---

## Backfill Strategy: Notion → Planhat

> **Scope:** Sessions (Delivered only) and Tasks (non-canceled, non-internal) owned by the current user. Customers and Active Packages are already synced from Salesforce — do not re-create them.

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
   → If found: update subject/description/activityTags if stale; skip create
   → If not found: proceed to create
3. Resolve Planhat companyId via name search or sourceId lookup
4. Map fields per the Session → Conversation table above
5. create_model_record(MODEL: "Conversation", DATA: { ... })
6. Log result: session name, company, Planhat Conversation _id
```

### Task backfill procedure

```
For each Task WHERE:
  - (Owner LIKE '%<user-uuid>%' OR Current Account Owner LIKE '%<user-uuid>%')
  - Status NOT IN ('Canceled')
  - Customers != Productboard internal record

1. Extract Notion Task page ID from URL (32-char hex)
2. Check for existing Planhat Task: FILTER sourceId = <task-page-id> AND mainType = 'task'
   → If found: update status/endTime if stale; skip create
   → If not found: proceed to create
3. Resolve Planhat companyId via name search or sourceId lookup
4. Map fields per the Task → Planhat Task table above
5. create_model_record(MODEL: "Task", DATA: { mainType: "task", ... })
6. Log result: task title, company, Planhat Task _id
```

### Backfill ordering

Run Sessions first, then Tasks. This way, if a Task references a Source Call, the Conversation already exists in Planhat when the Task is written (useful for future linking).

### Rate limiting / batching

Process one customer at a time. After each customer's sessions and tasks are written, pause briefly and log a summary before moving to the next account. This makes it easy to resume if interrupted.

---

## Models To Be Documented

Run `get_model_action_parameters(MODEL: "<model>")` to pull the full field list when needed.

| Model | Notion equivalent | Priority | Notes |
|---|---|---|---|
| `Deal` | Active Packages (partial) | Low | Revenue tracked separately via Salesforce sync. |
| `Nps` | _(none)_ | Low | |
| `Issue` | _(none)_ | Low | |
| `Workflow` | _(none)_ | Low | |
