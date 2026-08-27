# Planhat Schema & Notion↔Planhat Traversal Guide

> **Status:** In-transition, moving toward Planhat as the primary AISE working record. Session debrief (`post-session-debrief`), product feedback discovery (`/log-feedback`), and account health/revenue/Spark tracking are Planhat-only as of 2026-08-19. Notion remains the working record only for agents/skills not yet migrated (session-prep, account-plan, engagement-planner, and historical data via `/session-backfill`) — treat it as a legacy system being phased out, not a co-equal source of truth. During the transition, Spark fields must still be kept in sync both ways until the remaining Notion-based agents migrate.
>
> **Last updated:** 2026-08-19

---

## MCP Access

| Detail | Value |
|---|---|
| MCP server ID | `7441c372-4b65-4805-95b0-baf2a081ceb3` |
| Key tools | `list_model_records`, `get_model_record`, `update_model_record`, `search_records`, `get_model_action_parameters` |
| Available models | `Company`, `EndUser`, `Task`, `Conversation`, `Deal`, `Nps`, `Issue`, `Workflow`, `Churn`, `Document`, `User`, `Product`, `LineItem`, `EmailTemplate`, `Comment`, `Attachment` |

---

## Planhat Record URLs

Planhat record links follow the workspace data-explorer route. Build them from the record's `_id` — do not invent `app.planhat.com/...` paths, and never cite a Planhat record without a link when one can be built.

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
| `Task` | `task` | ⚠️ Inferred |
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
| `ARR` (rollup) | `arr` | number | Planhat `arr` = annualized MRR from active licenses. Notion ARR = rollup from Active Packages. **Planhat `arr` is the financial source of truth** (synced from Salesforce via `custom.ARR – Salesforce`). |
| `Renewal Forecast` | _(no direct equivalent)_ | — | Planhat has `renewalDate` and `renewalArr` but no forecast select. |
| _(Notion only)_ | `h` (health score 0–10) | number | **[PLANHAT ONLY]** Computed health score. Useful context when prepping sessions. |
| _(Notion only)_ | `lastActive` | date | **[PLANHAT ONLY]** Last product activity date. |
| _(Notion only)_ | `nextTouch` / `lastTouch` | date | **[PLANHAT ONLY]** Next/last scheduled or logged interaction. |

#### Spark / AI readiness — **[SYNCED]**

These three fields are actively synced Notion → Planhat by the AISE assistant.

> **Renamed 2026-08-07** — all three ⚡️-prefixed fields below were renamed/relabeled in Planhat. Old field IDs (`custom.Spark Stage`, `custom.Igniting?`, `custom.Days in Current Ignite Stage`, without the emoji) and old `Spark Stage` option values (`Not Active`/`Active for Admins`/`Active for All`/`Active on Staging`) are stale — do not use them. `AI Ready` is unaffected.

| Notion field | Planhat field ID | Type | Value mapping |
|---|---|---|---|
| `Spark Customer Journey` | `custom.⚡️ Spark Stage` | string (select) | `Not Active` → `Off` · `AI Terms Review` → `AI Terms Review` · `Active for Admins (Production)` → `Admins only` · `Active for All (Production)` → `Everyone` · `Active (Staging only)` → `Admins only` · `Icebox` → `Icebox` |
| `AI Ready` | `custom.AI Ready` | string (select) | `Sparked` → `Sparked` · `Preparing` → `Preparing` · `Ignitable` → `Ignitable` · `Not ready` → `Not Ready` _(note capital R)_ |
| `Igniting?` | `custom.⚡️ Igniting?` | boolean | `__YES__` → `true` · `__NO__` → `false` |
| `Days in Current Ignite Phase` (formula) | `custom.⚡️ Days in Current Ignite Stage` | string (read-only) | Both are computed. Do not write either. |
| `Ignite Journey Last Edited` (date) | _(no equivalent)_ | — | Notion-only automation field. |
| _(no Notion equivalent)_ | `custom.⚡️ Spark Enabled` / `custom.⚡️ Spark Enabled Date` / `custom.⚡️ Spark Active For Since` / `custom.⚡️ Spark Engaged` / `custom.⚡️ Spark Engaged Date` / `custom.⚡️ AI Consent` / `custom.Spark Stage` | boolean / date / date / boolean / date / text / list | **Added 2026-08-07.** Written by `temp-ph-ignite-conversion-data-sync` skill from weekly CSV upload. CSV is the source of truth for these fields. |

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
2. Optionally cross-check Planhat: `search_records(QUERY: "<customer name>")` → `get_model_record(SELECT: ["custom.⚡️ Spark Stage", "custom.AI Ready", "custom.⚡️ Igniting?"])`
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
- **Planhat:** `search_records(QUERY: "<customer name>")` then filter for Task records, or `list_model_records(MODEL: "Task", FILTER: {"companyId[equal to]": "<planhat_company_id>"})` _(note: `list_model_records` on Task has a hard 36-record cap — use `search_records` for customers with many tasks)_

---

## Planhat Company — Full Field Reference

### Standard writable fields

| Field ID | Type | Description |
|---|---|---|
| `name` | string | Display name. **Required.** |
| `owner` | objectId → User | CSM / Account Manager. Do not overwrite from AISE logic. |
| `coOwner` | objectId → User | Secondary owner. |
| `phase` | string | Services lifecycle stage. **Configured options:** `0. Preparation` · `1. Activation` · `2. Adoption` · `3. Renewal` · `4. Churned`. See AISE-writable table for mapping from Active Package status. |
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

> **Last verified against live `get_model_action_parameters` output: 2026-08-25.** Field sets drift. When a
> write silently no-ops or a field is missing from a read, re-pull the metadata before assuming the doc is right.

> Fields marked **[SF-SYNCED]** are populated by the Salesforce → Planhat sync. **Never write these via MCP.** The exact SF mapping is WIP; treat any unmarked field as writable only if it appears as writable in `notion-planhat-field-mapping.md`.

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
| `custom.Slack URL` | string | — | **Internal** Productboard Slack channel for this account – the channel where PB staff discuss the customer. **Not** the shared external channel. See the Slack-fields callout below. |
| `custom.Salesforce URL` | string | — | SF account URL |
| `custom.AI Readiness – SF` | string | `AI-Forward (Inferred/Validated)`, `AI-Interested (Inferred/Validated)`, `AI-Resistant (Inferred/Validated)` | SF-synced AI readiness |
| `custom.AI Readiness Score` | number | — | Auto-computed. **Read-only as of the 2026-08-25 check** – an earlier version of this doc described it as manually settable. Do not write. |
| `custom.Customer Type` | string | `Contract`, `Subscription`, `Contract - SatisMeter Only` | Contract shape |
| `custom.Customer Since – SF` | string | — | First customer date |
| `custom.Subscription Start Date (Earliest)` | string | — | Earliest subscription start |
| `custom.Plan Names` | string | — | All plan names on the account |
| `custom.Plan Name + Version (Highest ARR)` | string | — | Dominant plan by ARR |
| `custom.Plan Version (Highest ARR)` | string | — | Version of the dominant plan |
| `custom.Services Plan` | string | — | Services SKU roll-up |
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
| `custom.Slack ID` | **Internal.** The PB-only channel for discussing this account. Channel ID, e.g. `C02N37LS25C`. | RevOps / SF | Read for internal context only. Never write. **Never log its messages to a customer-visible record.** |
| `custom.Slack URL` | **Internal.** Same channel as above, as an `/archives/` link. | RevOps / SF | Same. Never write. |
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
> (`EMEA`/`NOAM`/`APAC`/`LATAM`/`AUNZ`/`Missing`/`Exclude`/`Blacklisted`), and `custom.Slack ID`. These report as
> writable in `get_model_action_parameters` but are maintained upstream. An earlier version of this doc listed them
> as SF-synced read-only; the accurate statement is that the API will accept a write and you still should not make one.

> **Removed since the previous snapshot:** `custom.⚡️ Days in Current Ignite Stage` is no longer present on the
> Company model. Do not read or write it.

#### AISE-writable

| Field ID | Type | Options | Notes |
|---|---|---|---|
| `custom.Priority (temp – Notion)` | string | `P0`, `P1`, `P2`, `P3`, `P4` | ← Notion Customer `Priority`. Temp field pending a native Planhat solution. Omit if Notion value is `Insufficient Data`. |
| `custom.⚡️ Spark Stage` | string | `Off`, `AI Terms Review`, `Admins only`, `Everyone`, `Icebox`, `Mixed` | ← Notion `Spark Customer Journey`. **Renamed 2026-08-07** (was `custom.Spark Stage` with options `Not Active`/`Active for Admins`/`Active for All`/`Active on Staging`) — see value mapping table above. |
| `custom.AI Ready` | string | `Ignitable`, `Sparked`, `Preparing`, `Not Ready` | ← Notion `AI Ready` (unchanged) |
| `custom.⚡️ Igniting?` | boolean | `true` / `false` | ← Notion `Igniting?`. **Renamed 2026-08-07** (was `custom.Igniting?`). |
| `custom.AISE Journey Status` | string | `Presales`, `Active (no Services)`, `Active (Services)`, `Contracted to Scale`, `Churned` | ← Notion `Account Status`. **AISE-managed accounts only (30k+ ARR).** Do not write for AIPA accounts. **`Not started` is not a valid option — omit.** Note: field ID is `custom.AISE Journey Status`, not `custom.Journey Status`. |
| `phase` | string | **Configured options (not free-text):** `0. Preparation` · `1. Activation` · `2. Adoption` · `3. Renewal` · `4. Churned` | Universal field — applies to **all** Planhat companies (AISE and AIPA). Derived from the customer's current Active Package `Status` — see full mapping table in `notion-planhat-field-mapping.md`. `4. Churned` is set manually and aligns with `custom.AISE Journey Status = Churned`. |
| `custom.SH_Current State` | string (Rich text) | — | **Sales Handoff** (SH_ = "Sales Handoff"): current state from pre-sales. Auto-populated on deal close for AISE-segment accounts — not manually written by AISE. Read for discovery context. |
| `custom.SH_Future State` | string (Rich text) | — | Sales Handoff: desired future state from pre-sales. Auto-populated on deal close. |
| `custom.SH_Negative Impacts` | string (Rich text) | — | Sales Handoff: pain points from pre-sales. Auto-populated on deal close. |
| `custom.SH_Positive Outcomes` | string (Rich text) | — | Sales Handoff: value / expected outcomes from pre-sales. Auto-populated on deal close. |
| `custom.Services Package?` | array | `V13`, `Premier Services`, `Custom SOW`, `Essentials`, `N/A` | **To be architected in Planhat** as a roll-up from the Active Product with the services SKU toggle — not a direct Notion field write. Do not populate from Notion during migration. |
| `custom.Next Step` | string | — | **The account's current next action.** Free text. Written after an outbound touchpoint actually lands, not when a draft is created. Keep it a short dated sequence with owners: what was just done, what is being waited on, what happens when it clears. Overwrite rather than append – this is a current-state field, not a log. Session history belongs in Conversations. |
| `custom.[SIP] Tier` | string | `T1 - Priority outreach: enabled + visible, not yet ignited` · `T2 - Second wave: ignited, not yet adopted` · `T3 - Adopted/transitioned (sustain)` · `T4 - Open visibility first: enabled, admins-only` · `T5 - Enablement motion: Spark not enabled` · `T6 - No outreach: churned / planning to churn` | Spark in Practice tiering. Pass the **full option string**, not just `T1`. See `context/initiatives/spark-in-practice.md` for what each tier changes about the motion. |
| `custom.[SIP] Rank in Tier` | number | — | Priority rank within the tier. Lower is higher priority. |
| `custom.⚡️ Spark Enabled` | boolean | `true` / `false` | Whether Spark is switched on for the account at all. The gate for Spark in Practice scope. |
| `custom.⚡️ Spark Enabled Date` | string | — | When Spark was enabled. |
| `custom.⚡️ Spark Active For Since` | string | — | When the current `⚡️ Spark Stage` visibility setting took effect. |
| `custom.⚡️ Spark Engaged` | boolean | `true` / `false` | Someone in the account reached L2 – ran a skill or submitted a Spark prompt. **Live value, not the weekly snapshot.** |
| `custom.⚡️ Spark Engaged Date` | string | — | When engagement was first detected. |
| `custom.⚡️ AI Consent` | string | — | Where the account stands on AI terms. Set this when a terms review, extension request, or acceptance moves – it is the field that tells the rest of the team the account is mid-flight rather than untouched. |
| `custom.AIPA Journey Status` | string | `Spark Activation`, `Re-Engagement` | AIPA-segment equivalent of `custom.AISE Journey Status`. Do not write for AISE-managed accounts. |
| `custom.Gong Summary` | string | — | Rolling Gong-derived account summary. |
| `custom.CAB Customer` | boolean | `true` / `false` | Customer Advisory Board member. |
| `custom.External_Slack_Channel_ID` | string | — | **The customer ↔ shared external Slack channel pairing, cached.** Channel **ID** only, upper-case (`C0AKKLJCB5E`) – never a `#name` (channels get renamed), never a URL (the value feeds `slack_read_channel` and the `/log-slack-threads` `externalId` builder directly). Written by `/log-slack-threads` the first time it resolves a channel for the account; read on every later run, which is what lets that skill take a channel *or* a customer name as input. Write only when empty or when the user has just corrected it – a resolved channel that disagrees with a populated value is a conflict to surface, not a value to overwrite (an account can have two shared channels; the field holds one). **New field: Planhat custom fields lag in MCP metadata, so it may be absent from `get_model_action_parameters` and reject writes for a while. A failed write is reported, not fatal.** Strictly the **external** channel – see the Slack-fields callout above; `custom.Slack ID` / `custom.Slack URL` are the internal channel and are never a substitute. |

#### `phase` vs `custom.AISE Journey Status`

| | `phase` | `custom.AISE Journey Status` |
|---|---|---|
| **Scope** | All Planhat companies | AISE-managed accounts only |
| **What it tracks** | Universal services lifecycle stage (Preparation → Activation → Adoption → Renewal → Churned) | AISE program-specific status (Presales / Active / Contracted to Scale / Churned) |
| **Segment rule** | AISE accounts (30k+ ARR) ✅ · AIPA accounts (under 30k ARR) ✅ | AISE accounts (30k+ ARR) ✅ · AIPA accounts (under 30k ARR) ❌ |
| **Source of value** | Active Package `Status` via Notion sync | Notion `Account Status` |

> `phase` is the shared, segment-agnostic signal for where any customer sits in the services lifecycle. `custom.AISE Journey Status` is an AISE overlay that only applies to the 30k+ ARR accounts the AISE team manages. AIPA uses `phase` to track lifecycle stage — their accounts will not have an AISE Journey Status populated.

---

## Write Rules

- **Never write SF-synced fields.** See the SF-synced table above. This includes account fields (Region, Segment, ARR, Makers, Slack, Account Executive, etc.), Deal records, and Line Item records. Do not write these even if the field appears blank — the sync owns them. Exact mapping is WIP; when uncertain, treat a field as SF-synced unless it appears in the AISE-writable table.
- **Never write read-only fields** — Planhat will error.
- **Custom field prefix:** always use `custom.` (e.g. `"custom.⚡️ Spark Stage": "Everyone"`). Note some field IDs include an emoji (`⚡️`) as a literal part of the ID — see the 2026-08-07 rename notes above.
- **Boolean custom fields:** use raw `true`/`false`, not strings.
- **Option values:** exact casing required (e.g. `"Not Ready"` not `"Not ready"`).
- **Do not overwrite `owner`** — managed by RevOps/CS leadership.
- **Company records are SF-synced** — do not create new Company records via MCP. Creation is handled by RevOps via Salesforce sync.

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
| Divider | `<hr>` |
| Table | `<table><colgroup><col style="width: 301px;"><col style="width: 301px;"></colgroup><tbody><tr><td data-colwidth="301"><p>cell</p></td><td data-colwidth="301"><p>cell</p></td></tr></tbody></table>` |

**List items require both the `ph-editor__*` classes and an inner `<p>`.** Bare `<ul><li>text</li></ul>` is the documented cause of the old "1. / blank / 2. / blank" mangling — the editor drops a list item that has no paragraph node inside it. The earlier guidance in this file to use bare `<ul><li>` was wrong and has been replaced.

Optional attributes the editor emits and accepts, but that are not needed on write: `style="text-align: left;"` on `<p>`, and `style=""` on `<table>`.

**Unverified:** `<a href>` inside these fields (the editor has a link control, so it is very likely fine), `<u>`, `<s>`, `<code>`. Don't introduce them into a shipped write path without checking the rendered result first.

**Combined example** (the canonical prep-brief shape):

```html
<p><strong>Customer — Session type — Thu 27 Aug 2026, 13:30–14:00 CEST (30 min, Zoom)</strong></p><p>Attendee name (role). Second attendee may join.</p><blockquote><p>Booking note: verbatim customer ask, plus what it implies for how the session should run.</p></blockquote><hr><p><strong>Agenda (30 min)</strong></p><ol class="ph-editor__ordered-list"><li class="ph-editor__list-item"><p><strong>Topic</strong> — 10 min. What to establish.</p></li></ol><p><strong>Goals</strong></p><ul class="ph-editor__bullet-list"><li class="ph-editor__list-item"><p>Outcome to leave the session with.</p></li></ul><p><strong>Watch-fors</strong></p><ul class="ph-editor__bullet-list"><li class="ph-editor__list-item"><p>Risk to keep an eye on.</p></li></ul>
```

**Structure rules for any rich-text write.** Bold section label, then a list — not prose paragraphs. Lead each list item with a bolded subject, date, or owner, then one sentence of detail. 3–6 items per section. Apply the user's `custom.AISE Profile preferences` voice rules (dash style, English variant, forbidden filler) to the sentence content.

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

### `externalId` convention — two live sources, no collision risk

Two different tools write Conversations from session data, each with its own `externalId` format:

| Path | `externalId` source | Notes |
|---|---|---|
| `/session-backfill` | Notion Session page ID (32-char hex) | Historical migration — one-time backfill of past sessions still tracked in Notion. |
| `/session-debrief` (`post-session-debrief`) | Google Calendar event ID | Live, per-session debrief path — Notion is not consulted. |

`externalId` is scoped per-company, and the two ID formats never collide (different length/character set), so both conventions coexist safely. Don't assume a Conversation's `externalId` is a Notion page ID just because older records use that format — check the format before parsing it.

A third writer was added in v2.45.0:

| Path | `externalId` source | Notes |
|---|---|---|
| `/log-slack-threads` | `slack_{channelId}_{parentTsDigits}` | Shared-channel Slack threads logged as `💬 Slack Chat` touchpoints. Prefixed, so it never collides with the two ID formats above and is trivially identifiable. |

---

### Slack Chat Conversations (`/log-slack-threads`)

Threads from a shared customer Slack channel are logged as touchpoints, one Conversation per thread. These are
**not sessions** – `💬 Slack Chat` is in the not-counted list above, and a Slack record must never be used to
close a session gap or retyped into a counted type to move a number.

| Field | Value | Notes |
|---|---|---|
| `type` | `💬 Slack Chat` | Exact string including the emoji. |
| `source` | `Slack` | |
| `date` | First message of the thread, UTC | **Not** the last reply, **not** the run date. Slack renders local time – convert per message, since a channel's history crosses the DST boundary. |
| `externalId` | `slack_{channelId}_{parentTsDigits}` | **Dedup key. Required on every record, one format only.** Lower-case `slack_` prefix, Slack channel **ID** upper-case (never the `#name` – channels get renamed), thread **parent** ts with the dot removed. Canonical shape: `^slack_[A-Z0-9]+_\d{16}$`, e.g. `slack_C0AKKLJCB5E_1786006420396099`. The digit string is exactly what Slack uses in a permalink, so the key is reversible (`ts = digits[:10] + "." + digits[10:]`) – that reversibility is what makes the reply-backfill pass possible without a side table. Never include the customer name, date, subject, hash or run counter. Checked before every create, read back and asserted after every create. Off-format legacy keys are normalized in place (`externalId` only, never `date` or `subject`). One drift case fixed 2026-08-25: `slack-C02N37LS25C-1786373402.520939` → `slack_C02N37LS25C_1786373402520939`. |
| `subject` | `Slack – #{channel}: {topic} ({Mon D–D, YYYY})` | Topic names the feature or system in play, not "customer question". |
| `description` | Rendered thread HTML | See § Planhat rich-text constraints below. |
| `custom.Slack message Id` | Parent ts, dotted form | |
| `custom.Slack initiated by` | `Customer` \| `Productboard` | From the parent author's email domain. |
| `custom.First message time` | `YYYY-MM-DD HH:MM {tz}` | Human-readable local time of the first message. |
| `users` | `[{_id, name}]` of the Productboard people who posted | **Required, not optional.** Resolved from `User` by email. Omit the key entirely if no PB person spoke – never write `[]`. |
| `endusers` | `[{_id, name}]` of the customer contacts who posted | **Required, not optional.** Resolved from `End User` scoped to the company. Authors only – an `@`-mention or a named follow-up owner is not a participant. Fails silently on write, so always read back and assert. A participant with no contact record is reported, never auto-created. Omit the key rather than writing `[]`. |

**Channel resolution and the cache.** The skill accepts either half of the pair. Given a channel, the company
is resolved from the modal non-`productboard.com` email domain across the channel's authors matched against
`Company.domains`, falling back on the channel name (`#ext-acme-corp-productboard` → `acme corp`) matched
against `Company.name`. Given a customer, the channel comes from `Company.custom.External_Slack_Channel_ID`, then a
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
`update_model_record` on the existing `_id`. `date` and `externalId` are never touched – re-dating on backfill
scatters the timeline and makes the update look like a duplicate.

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
| `Gong call` (url) | `custom.Gong URL` | string | Write | Write the URL to `custom.Gong URL`. Do **not** append to `description`. |
| `Call Status` | _(not mapped)_ | — | — | Notion-only status lifecycle. Not meaningful in Planhat. |
| `Consumed Package` | _(not mapped)_ | — | — | Notion credit-ledger concept. No Planhat equivalent. |
| `Do not count` | _(not mapped)_ | — | — | Notion-only billing flag. |
| `Spark conversation` | ~~`activityTags`~~ | array | ~~Write~~ | ~~If `__YES__`, include `"Spark"` in `activityTags`.~~ **Not writable via MCP — silently rejected by the API. Apply `Spark` tag manually in the Planhat UI.** |
| _(no equivalent)_ | `source` | string | Write (constant) | Always `"AISE"` for sessions written by this assistant. Distinguishes from Zendesk/GCal entries. |

#### Type value mapping: Notion → Planhat

> ⚠️ **Emojis are part of the configured option strings.** Always use the exact values in the "Planhat `type`" column — passing the text without the emoji will save but will not match the configured option filters.

| Notion `Type` | Planhat `type` (exact) | Notes |
|---|---|---|
| `🏗️ Architecting` | `🏗️ Architecting` | Emoji matches — use as-is |
| `🗣️ Sync` | `🔁 Sync` | **Different emoji** (🗣️ → 🔁). Use Planhat's `🔁 Sync` |
| `🎓 Training` | `🎓 Enablement` | **Different label.** Use Planhat's `🎓 Enablement` |
| `👟 Kick off` | `👟 Kick off` | Emoji matches — use as-is |
| `🔎 Discovery` | `🔎 Discovery` | Emoji matches — use as-is |
| `📦 Other` (default) | `🔁 Sync` | Default fallback for general calls (e.g. licence discussions, commercial syncs). |
| `📦 Other` + "Demo" in title | `🎙️ Demo` | **Title-pattern override:** if the session title contains "Demo" (case-insensitive), use `🎙️ Demo` instead of the default `🔁 Sync`. |
| `🫥 Internal` | `Internal Alignment` | No emoji in Planhat |
| _(Done Notion Task — auto-created Conversation)_ | `Task` | No emoji. Planhat auto-creates this Conversation when Task `status` is set to `"done"`. Set via `noteId` post-write. Canceled (`"ignored"`) tasks do not generate a Conversation. |

> **`notion-planhat-field-mapping.md` is the authoritative source for type mappings.** If this table and that file ever disagree, that file wins.

> **Planhat types with no Notion equivalent:** `📺 Webinar`, `👾 Gong Call` — logged directly in Planhat, not from Notion. `🎙️ Demo` is also available and applied automatically to `Other` sessions with "Demo" in the title.
> **Generic Planhat types** (avoid for AISE writes): `note`, `email`, `chat`, `call`, `ticket`, `other` — these are Planhat system defaults for inbox/helpdesk syncs. AISE should only use the custom configured values above.

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
| `description` | string | — | Summary, notes, Gong URL. |
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
| `custom.Gong URL` | string | — | Gong call link. **Use this instead of appending to `description`.** Write the raw URL. |
| `custom.Link to PB Note` | string | — | Productboard feedback note URL. Written by `/log-feedback` onto the Conversation auto-created when a `Product Feedback` Task transitions to `done` (see § Planhat Task auto-Conversation behavior) — links the touchpoint back to the submitted PB note. Write the raw URL. |
| `custom.Call Duration` | number | — | Session length in minutes. Derive from Notion `Session Length (h)` × 60. |
| `custom.Opportunity` | string → Deal | — | The customer contract the session was delivered under. Relation to a `Deal` record. Optional – set when the session is clearly attributable to one contract. **Replaces the former `custom.Services Package` field, which no longer exists on this model.** |
| `custom.Call Recording` | string | — | Recording link when the call was not captured in Gong (for example a Zoom cloud recording). Use `custom.Gong URL` for Gong calls. Write the raw URL. |
| `custom.Handover Status` | string | — | `Not started` · `In progress` · `Validated – Ready`. Tracks the sales-to-AISE handover on a Sales Handover conversation. |
| `custom.SH_Current State` | string (rich text) | — | Sales Handoff context captured at conversation level. Mirrors the Company-level `SH_` fields. Read for discovery context; not written by this assistant. |
| `custom.SH_Future State` | string (rich text) | — | As above. |
| `custom.SH_Negative Consequences` | string (rich text) | — | As above. **Note the Conversation field is `SH_Negative Consequences`; the Company field is `SH_Negative Impacts`.** Different names, same idea – do not copy one field ID to the other model. |
| `custom.SH_Positive Business Outcomes` | string (rich text) | — | As above. **Note the Conversation field is `SH_Positive Business Outcomes`; the Company field is `SH_Positive Outcomes`.** |

#### Read-only fields

`snippet`, `numberOfParts`, `parentId`, `parentType`, `createDate`, `companyName`, `isClassified`, `isSignalAnalyzed`, `shortSummary`, `isSeen`, `isOpen`, `isBounced`, `archived`, `scheduled`, `createdAt`, `updatedAt`, `custom.AISE Conversation`

`custom.AISE Conversation` is a system-derived boolean marking the record as AISE-originated. It is read-only – do not
attempt to set it to force a record into AISE reporting.

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
| `Priority` | `custom.Priority` | string | Write | `"1"` → `"P1"`, `"2"` → `"P2"`, `"3"` → `"P3"`. Stored in `custom.Priority` — **not** the `type` field. |
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
| `custom.Priority` | string | — | `"P1"`, `"P2"`, `"P3"` mapped from Notion `Priority` field. |
| `custom.Prep Notes` | string | — | Prep brief written by session-prepper. Format: single-line HTML in the `ph-editor` vocabulary — see § Rich Text Field Formatting for the tag table and the canonical prep-brief example. Section labels are `<p><strong>…</strong></p>` (no `<h>` tags); lists **must** carry `ph-editor__bullet-list` / `ph-editor__ordered-list` + `<li class="ph-editor__list-item"><p>…</p></li>`; use `<p></p>` for a blank line and `<hr>` to separate the header block from the body. **Apply the user's `custom.AISE Profile preferences` voice rules to the sentence content** (dash style, etc.) — see `agents/session-prepper.md` § 1b/5b. Read and carried to the linked Conversation during post-session debrief. |
| ~~`activityTags`~~ | array | — | ~~Freeform tags for filtering.~~ **Not writable via MCP — silently rejected. Apply manually in Planhat UI.** |
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
| `custom.AI Consent Granted` | boolean | ❌ Read-only | Whether AI consent is granted for this workspace. System-managed. |

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
| `custom.Service SKU` | boolean | Whether this is a services SKU (vs software license) |
| `custom.AISE Working Sessions` | number | Session quota for this SKU — both Architecting and Training (Enablement) sessions deduct from this shared pool |
| `custom.License Type` | string | License classification |

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

| Model | Notion equivalent | Notes |
|---|---|---|
| `Line Item` | Individual credit/session lines on Active Packages | SF SSOT. Read only. Contains `custom.AISE Working Sessions` (session quota per SKU). |
| `Email Template` | N/A | Planhat-native marketing/CS email templates. |
