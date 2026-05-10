# Notion Writer Playbook

The procedural layer for writing to the Customer Tracker. Pairs with `notion-schema.md` (authoritative schema — this file does not repeat it).

---

## When to load this

Claude loads this playbook whenever a task involves creating or updating records in the Customer Tracker. Common triggers:

- "Log this session" / "Record the [X] call"
- "Create tasks from [session/notes/email]"
- "Add [person] to [customer]" / "Update [person]'s role"
- "Update [customer] status" / "Move [customer] to [phase]"
- "Record decisions from..."
- Any post-session processing that should persist to Notion

---

## Core principles

1. **Propose before write.** Always draft the record(s) in chat first. Wait for explicit confirmation before calling any Notion write tool.
2. **Resolve relations first.** Every write needs to link to existing records (Customer, Active Package, Contacts). Query those first. Never invent or guess an ID.
3. **Match the schema exactly.** Status values, select options, and relation shapes must match `notion-schema.md`. If a value isn't in the schema, surface it as a new option the user needs to approve — don't improvise.
4. **Flag conflicts.** If an update contradicts existing data, show both values side-by-side before overwriting.
5. **Preserve decisions.** Don't change wording the user committed to, dates she set, or scope she agreed.
6. **Source-link when possible.** When a record came from a specific Gong call, email, or Slack thread, include the link in the record body under a `**Source**` bullet.

---

## Standard write flow

For every operation:

1. **Parse input** — identify the customer, session, people, and actions in the source material.
2. **Resolve relations** — search Notion for existing records:
   - Customer by name (check `notion-schema.md` for exact casing/shorthand)
   - Contacts by name, then email
   - Active Package = query APs DB where `"Customer"` LIKE customer-page-id AND `Active? = YES`
3. **Draft the record(s)** in chat using the per-operation template below.
4. **Confirm with the user** — explicit go-ahead before writing.
5. **Write via Notion MCP** — use the exact data source ID from the schema file.
6. **Verify and surface the link** — after every write (create or update), confirm key values landed correctly and **always include the direct Notion page URL in the chat confirmation message**. No exceptions — this applies whether the write was done directly, via notion-writer, or via any sub-agent (post-session-debrief, session-prepper, etc.).

---

## Operation 1: Create Session

**Triggered by:** "Log the [Foundations/Discovery/etc.] session with [Customer]" or generated from post-session processing.

**Required fields (resolve or ask):**

| Field | Source / Convention |
|---|---|
| `Name` | Format: `[Customer] — [Session Type] — [YYYY-MM-DD]` (e.g. `Acme — Foundations — 2026-04-21`) |
| `Customers` | Resolve Customer page |
| `Call Date` | From calendar event. Default to today only if session just happened. Never invent a date. |
| `Type` | Map: Discovery → `🔎 Discovery`; Foundations / Insights / Prioritization / Roadmaps / Spark → `🏗️ Architecting`; Success Planning / QBR / Check-in → `🗣️ Sync`; Kickoff → `👟 Kick off`; Training → `🎓 Training`; Anything else → `📦 Other` |
| `Session Length (h)` | From calendar event or stated duration |
| `Call Status` | `Delivered` if already occurred; `Planned` if scheduled; others per schema as explicitly stated |
| `Consumed Package` | Resolve the customer's currently-active Active Package (`Active?: true`) |
| `Delivered By` | Set to the actual presenter(s). For own sessions: user's UUID. For stand-in or backfilled sessions: the presenter's UUID if resolvable, otherwise leave blank and flag. |
| `Attendees` | Resolve Contact page IDs for each named attendee. Flag unknown people as "create new Contact?" — don't auto-create without confirmation. |
| `Next Steps` | 1–3 short bullets. Declarative, outcome-focused. |

**Draft format for the user:**

```
**Proposed Session record**
- Name: Acme — Foundations — 2026-04-21
- Customer: Acme Corp (linked)
- Call Date: 2026-04-21
- Type: 🏗️ Architecting
- Length: 1.5h
- Status: Delivered
- Consumed Package: Acme — Enterprise Services (active)
- Delivered By: Klara Martinez
- Attendees: Sarah Chen, Tom Rodriguez (linked); ⚠️ "Priya Mehta" not found — create new Contact?
- Next Steps:
  - Finalize product hierarchy draft by Fri
  - Schedule Insights session for next week
  - Tom to share current Jira workflow

Confirm to write?
```

**After the create — apply session template (mandatory):**
Call `notion-update-page` with `command: apply_template` and the template ID matching the session's `Type` (see `context/notion-schema.md` § Session Templates). This populates the standard page structure. Skip if the page already existed (dedup hit).

**Body content:** Write session summary, decisions, and a `**Source**` link inside the `📋 Prep — [date]` toggle that the template places at the top of the page. Keep it scannable — bolded labels, bullets. Populate Decisions, Risks / Blockers, and Next Steps sections from the session content.

---

## Operation 2: Create Tasks

**Triggered by:** "Create tasks from [session/notes/email]" — almost always cascades from a Session create.

**Required fields per task:**

| Field | Source / Convention |
|---|---|
| `Task` (title) | Active voice, specific, outcome-oriented. Good: `Draft product hierarchy for Acme's Platform tribe`. Bad: `Review stuff`. |
| `Customers` | Resolve. **Every task must have a Customer relation.** For customer-tied work, use the relevant Customer page. For internal / non-customer-specific tasks (team admin, training, internal research), use the Productboard internal record: `https://app.notion.com/29997e9c7d4f80e6a011f053bdec1ab5`. |
| `Owner` | Set to the current user on create (`["<user-uuid>"]`). This is the creator field — distinguishes tasks the user logged from tasks inherited via account handoff. (Renamed from `Assignee` May 2026.) |
| `Current Account Owner` | Set to the current user explicitly on create (`["<user-uuid>"]`). The Resync button propagates this afterwards, but on initial create it hasn't fired. |
| `Due Date` | See auto-due-date logic below. |
| `Priority` | See auto-priority logic below. |
| `Source Call` | Link to the Session record this came from (if cascaded). |
| `Status` | Default `Not started`. |
| `Time (h)` | Leave blank unless the user states an estimate. |

### Auto-priority logic

Apply when priority isn't explicitly stated. Read the Active Package `Status` and `ARR` from the Active Package record (already resolved during the write flow). If ARR is unknown, default to P2.

| Condition | Priority |
|---|---|
| Active Package Status = `Activating` or `Adopting` AND ARR ≥ $50k, OR any urgent/blocker language in the task | **P1** |
| Active Package Status = `Activating` or `Adopting` with ARR < $50k, OR Status = `Preparing` with ARR ≥ $50k | **P2** |
| Active Package Status = `Not started`, `Service Quota Used`, `Package Expired`, or `Contracted below PS`, OR low-urgency task | **P3** |

Always state the assigned priority and reason in the draft (e.g. `Priority: 2 (Adopting, ARR $37k)`).

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

Always state the assigned date and the matching pattern in the draft (e.g. `Due: Apr 30 (send email, +1 bd)`). the user can override before confirming the write.

### Body content (required for every PB-side task)

Every task page body must include a "best shot" scaffold so the user can act immediately rather than face a blank page. The scaffold is typed to the task:

| Task type | Scaffold |
|---|---|
| "File product request" | Three paragraphs: **Problem** (what the customer is experiencing), **Current workaround or process** (how they're managing today), **Desired outcome** (what they want PB to do). Seed from session notes/transcript. |
| "Reply to [person]" / "Send [email/Slack]" | **Draft reply** section with a full message draft in the user's voice (per `about/voice.md`) per `communication-style-guide.md`. |
| "Draft [document/artifact]" | **Starter outline** with key sections or a first draft. |
| All other tasks | **Suggested approach** with 2–4 bullet steps toward completing the task. |

Label the scaffold with a bold heading: **"Best shot — [task type]"** so the user knows it is a starting point. Append after the `**Source**` link (if present). Seed from real context only — never fabricate details.

**Draft format:** One bullet per task with key fields inline, including the auto-assigned priority and due date with parenthetical reason. Show the scaffold content for each PB-side task in the draft (after the bullet line) so the user can review it before the write. PB-side only — customer-side actions go in summaries/follow-ups, not the Tasks DB.

```
**Proposed Tasks (5)**

_PB-side (2)_
- Draft Acme product hierarchy v1 — Owner: [user], Due: May 2 (draft artifact, +3 bd), Priority: 2 (Adopting, ARR $85k)
  > Best shot — draft artifact: [Starter outline with key sections seeded from session context]
- Send Foundations recap email — Owner: [user], Due: Apr 30 (send email, +1 bd), Priority: 1 (Adopting, ARR $85k, ≥$50k)
  > Best shot — reply/send: [Draft email seeded from session decisions and next steps]

_Customer-side (3)_
- Tom: share current Jira workflow export — Due: Apr 24
- Sarah: confirm BU lead list for seat planning — Due: Apr 25
- Priya: validate proposed teamspace structure — Due: Apr 29

All linked to Session: Acme — Foundations — 2026-04-21.

Confirm to write?
```

---

## Operation 3: Upsert Contact

**Triggered by:** "Add [person] to [customer]" or surfaced during Session create when an attendee isn't found.

**Check first:** Search Contacts by name AND email. If found → UPDATE; if not → CREATE.

**Required for create:**

| Field | Source / Convention |
|---|---|
| `Name` | Full name |
| `Customer` | Resolve |
| `Email` | From calendar invite, email thread, or signature |
| `Position` | From email signature / LinkedIn / calendar. If unknown, leave blank — don't guess. |
| `Role` | Map from observed behavior: Champion, Program Sponsor, Program Owner, Technical Manager, Product Manager. Default: blank. |
| `Status` | `Active` |
| `Sentiment` | Leave blank on creation. Update later based on observed signals. |
| `LinkedIn` | Only if the user provides it or it's already in context — don't web-search. |

**For update:** Only change fields where there's new information. Preserve existing `Sentiment`, `Note`, and `Role` unless the user explicitly wants them changed.

---

## Operation 4: Update Customer

**Triggered by:** "Update [customer] status" or cascaded from session outcomes.

**Common updates:**

- `Account Status` transitions (e.g. `Preparing` → `Active` after kickoff delivered)
- `Start Date` / `End Date` when engagement bounds change
- `Main Contact` change
- Adding/removing `Contacts` or `PB Team` members
- `Preferred Conferencing` updates

**Convention — never touch:**

- Rollup fields (`ARR`, `Days Left`, `Delivered`, `∑ Architecting`, `∑ Credit`, `∑ Time`, `∑ Training`, `Counted/Real`) — these are computed. If they look wrong, the upstream record (Active Package, Sessions, Tasks) is where to fix.
- `Next Call` / `Next Steps` — rolled up from Sessions.

**Conflict handling:** If current value differs from the proposed new value, show both side-by-side and ask for explicit confirmation:

```
⚠️ Conflict on Account Status
- Current: Preparing (last edited 2026-04-10)
- Proposed: In progress (from Foundations session 2026-04-21)

Overwrite?
```

---

## Operation 5: Active Package (rare — treat as financial ledger)

**Triggered by:** New engagement setup, package expansion, or package end.

**Standard sequence:**

1. Confirm which Master Package template applies (named pattern like `Essential Services — 40 hrs` or `Enterprise — 12 months`).
2. Create Active Package with: `Name`, `Customer` relation (sole customer link — always set), `Master Package` relation, `Start Date`, `End Date`, `ARR`, `Active?: true`, `Current Account Owner: <user-uuid>`, `Status: Preparing` (or `Not started` / `Activating` / `Adopting` as appropriate).
2b. Apply the Active Package template immediately after create: `notion-update-page`, `command: apply_template`, `template_id: 29697e9c7d4f806fb251df6f1d20bf88`. This places the `🗺️ Program Plan`, `🧠 Working Notes`, and `📋 Account History` structural toggles on the new page (see `context/notion-schema.md` § Active Package Template).
3. Flip any previous Active Package for that customer to `Active?: false` and `Status: Service Quota Used` (credits exhausted but contract live) or `Package Expired` (contract end date passed — true terminal state).

**Rule:** Always confirm with the user before creating or modifying Active Packages. This is the financial ledger — the stakes of getting it wrong are higher than any other operation in this playbook.

---

## Cross-cutting conventions

**Session naming:** `[Customer short name] — [Session type] — [YYYY-MM-DD]`. Use the customer's short name if one exists on the Customer record; otherwise use the full name.

**Dates:** ISO format (YYYY-MM-DD) internally. Never infer a date the user didn't state. "Today" = system date.

**Splitting action items:** Every action item must land under `PB` or `Customer`. Ambiguous items get flagged, not guessed.

**Task time estimates:** Leave `Time (h)` blank unless the user explicitly states one.

**`Do not count` checkbox:** Off by default. Only flip to `true` if the user explicitly says the session/task shouldn't burn credit (internal prep, casual check-ins, sales alignment, etc.).

**Source linking & discovery order:** If the record came from a call or message, add the URL in the page body under a `**Source**` bullet. Check sources in this order and link the first one found:

1. **Gong** — via `Glean:meeting_lookup` or Glean search (app: `gong`)
2. **Notion meeting transcripts** — via `notion-query-meeting-notes` (fallback when no Gong call is located)
3. **Gmail thread** — via Gmail search
4. **Slack message** — via Slack search

This is how the user later traces "why did we decide this?"

**Language:** American English spelling throughout record bodies.

---

## Conflict resolution

**Source vs Notion:**

1. Don't silently overwrite. Show both values.
2. Timestamp both: `Current (last edit: [date]): X. Proposed from [source, date]: Y.`
3. Ask which is correct — or propose a merge (update + note the change in body).

**Source vs source** (e.g. Gong says one decision, the user's chat says another):

- Default to the user's statement as most current.
- Flag the discrepancy in the draft output.

**Schema conflict** (a value not in the current select/status options):

- Don't invent. Surface it: "This would require adding `[value]` as a new option in `[field]`. Confirm and I'll write a record with existing options, or we add the option first?"

---

## Error handling

**If a Notion call returns a 429 (rate limit):**

- Wait **5 seconds**, then retry the **exact same call once**.
- If the retry also returns 429, surface the error and stop: "Notion rate limit hit on [query/write]. Wait a moment and re-run, or reduce concurrent queries."
- Do **not** retry more than once — backing off further is the user's call, not the agent's.
- This applies to reads (`notion-query-data-sources`, `notion-fetch`, `notion-search`) and writes (`notion-update-page`, `notion-create-pages`) equally.

**Rate limit hygiene — agents that fire multiple Notion queries:**

- Fire no more than **2 Notion calls concurrently**. For agents with 3+ queries, run them in pairs with a 2-second pause between batches rather than fully parallel.
- If a bulk operation (e.g. looping over 10+ customers) hits a 429 mid-loop, pause for **10 seconds** before continuing to the next customer.

**If a Notion write fails for any other reason:**

- Report the error verbatim.
- Don't retry blindly.
- Common causes: relation ID not found (re-resolve), status/select value not in schema (check `notion-schema.md`), permission issue (surface to the user).

**If a relation can't be resolved** (e.g. Customer not found by name):

- Surface the exact search tried.
- Ask the user to confirm the name — or create the parent record first.

---

## Quick reference: data source IDs

Copied from `notion-schema.md` for convenience:

| Database | Data source ID |
|---|---|
| Customers | `29397e9c-7d4f-8067-b290-000b1c2d57e1` |
| Sessions | `29397e9c-7d4f-8052-886b-000b9e3479d7` |
| Tasks | `29397e9c-7d4f-808f-bcd4-000b66a94678` |
| Active Packages | `29697e9c-7d4f-8031-9f76-000b7e932b36` |
| Master Packages | `29397e9c-7d4f-8079-b9d6-000bd95ee92f` |
| Contacts | `29497e9c-7d4f-80be-b224-000bbec4980b` |

---

## Operation 6: Working Notes (🧠 Working Notes toggle on Active Package page)

**What it is:** A structured toggle section on the Active Package page body that holds per-customer operational memory — program state, open risks, terminology, and mid-program discoveries. Maintained by agents; read by all agents doing customer work.

**Location:** Active Package page body. Toggle heading: `🧠 Working Notes — [Customer Name]`.

**Format:**

```
🧠 Working Notes — [Customer Name]
Last updated: YYYY-MM-DD

**Program state**
- [session log: what's done / what's next, e.g. "A1 complete 2026-03-12, D17–D26 logged. A2 next."]

**Open risks / flags**
- [named risks + owners, e.g. "Florian Pasques absent from 2 sessions — confirm before every session."]

**Terminology**
- [customer-specific naming, e.g. "They say 'crews', not 'squads'. 'Tribes' is acceptable."]

**Discoveries / carry-forwards**
- [mid-program discoveries and open questions, e.g. "Nat Gas may split — watch for A2 implications."]
```

**Read flow:** Fetch the Active Package page. Look for a toggle heading starting with `🧠 Working Notes`. Extract its contents as operational context before doing any customer work.

**Write flow — always targeted, never overwrite:**

- Update the relevant sub-section only (e.g., add a bullet to **Program state** or **Open risks**).
- Update the `Last updated: YYYY-MM-DD` line on every write.
- Append to lists — don't replace existing bullets unless they're superseded (in which case strike through or remove the old entry and add the new one).
- The `🧠 Working Notes` toggle is placed by the Active Package template on all new pages. If absent (legacy page without template), create it on first write.

**Who writes:**

| Trigger | Agent | What it writes |
|---|---|---|
| After session summary | `session-summarizer` / `post-session-debrief` | Program state update, new risks/discoveries |
| Customer fact corrected in chat | `context-keeper` | Targeted update to the relevant sub-section |
| Program plan approved | `engagement-planner` | Initializes the section; writes starting program state |

---

## Checklist before every write

- [ ] Customer relation resolved (page ID confirmed)
- [ ] Active Package resolved (if relevant)
- [ ] All status/select values verified against schema
- [ ] No rollup fields being written
- [ ] Source link included in body (if applicable)
- [ ] Draft shown to the user and confirmed
- [ ] Conflicts surfaced (if any)
- [ ] Direct Notion page URL included in chat confirmation after write
