---
name: log-feedback
description: Discover outstanding Planhat product-feedback Tasks, OR source feedback ad-hoc from a named customer/call, draft structured Productboard GTM feedback notes, and submit with HITL confirmation on customer mapping and content. Triggers: /log-feedback, 'log PB feedback', 'submit feedback to productboard', 'log outstanding customer feedback', 'log <customer> feedback'.
---

Log customer feedback to Productboard in the GTM format, from either of two sources — **Mode A**: outstanding `type: "Product Feedback"` Tasks in Planhat (created by `post-session-debrief` step 8), or **Mode B**: an ad-hoc named customer/call with no pre-existing Task, sourced directly from Gong transcripts and/or Planhat Conversations. Both modes converge on the same draft format, platform-capability check, and HITL confirmation before every submission via the PB MCP.

**Trigger phrases:** /log-feedback · "log PB feedback" · "submit feedback to productboard" · "any outstanding feedback to log" · "log outstanding customer feedback" · "log [customer] feedback" · "log feedback from the [customer] call"

---

## Step 1: Load AISE context

Read `context/project-instructions.md` to understand workflow rules, search strategy, and tool conventions.

**Never read `context/planhat-schema.md` whole.** It is ~1,750 lines and a full read truncates partway through, leaving a partial page you must not answer from. Load only the sections this skill uses: `Grep` for each heading with `-n`, then `Read` with `offset` at that line and a `limit` that runs to the next heading of the same level:

| Section heading | Used in |
|---|---|
| `### Three silent MCP failures` | every write |
| `### API Quirks: result caps and paging` | Step 3, Step 4.5 |
| `## Customer name aliases` (includes `### Known conflicts`) | Step 3 |
| `### ARR — always use` | Step 4.4 |
| `## Planhat Record URLs` | Step 6 preview, Step 8 |
| `## EndUser` (lookup + `### Duplicate End Users`) | Step 4.5 |
| `### Planhat Task auto-Conversation behavior` | Step 8 |

Read any other section the same way, only when a step actually needs it.

---

## Step 2: Resolve user identity

Resolve `planhat_user_id` via `list_model_records(MODEL:"User", FILTER:{"email[equal to]":"<email>"}, SELECT:["firstName","lastName","email"])` (or the pre-resolved table in `context/planhat-schema.md` § Planhat User IDs). All Task queries in this skill filter by `ownerId = planhat_user_id`.

---

## Step 3: Determine entry mode and discover source material

**Decide the mode from how the skill was invoked:**

- **Mode A — Task-driven** (default for bare `/log-feedback` or `/log-feedback <customer/topic>` when a matching open Task exists): discover outstanding Planhat Tasks as below.
- **Mode B — Ad-hoc, source-driven** (triggered when Klara names a customer or a specific call directly, e.g. "log Symphony AI feedback", "log feedback from the Acme call", or when Mode A's Task query for a named customer/topic comes back empty): skip the Task query and go straight to Gong/Planhat Conversation sourcing. Mode B does not require a pre-existing `Product Feedback` Task — it's for feedback surfaced live in conversation that hasn't been logged as a Task yet.

### Mode A — discover outstanding feedback tasks

**When a customer argument is given** (e.g. `/log-feedback acme`), scope by Company, not by owner across the portfolio:
1. Resolve the argument to a Company `_id` via `planhat-schema.md` § Customer name aliases (check § Known conflicts too); fall back to the Mode B step 1 lookup if it isn't in the table.
2. Query `list_model_records(MODEL: "Task", FILTER: {"companyId[equal to]": "<companyId>", "type[equal to]": "Product Feedback"}, SELECT: ["action", "description", "companyId", "companyName", "status", "ownerId", "createdAt"])`, paging per § API Quirks.
3. Apply the `ownerId = planhat_user_id` and open-status (`status` not `done` / `ignored`) filters locally on the result.
4. Tell the user the open-item count before starting HITL ("6 open feedback items for Acme Corp").

**When no customer is given**, query Planhat for all your open product-feedback Tasks:
```
list_model_records(MODEL: "Task", FILTER: {"type[equal to]": "Product Feedback", "status[not equal to]": "done", "ownerId[equal to]": "<planhat_user_id>"}, SELECT: ["action", "description", "companyId", "companyName", "status", "createdAt"])
```

**Note the 36-record hard cap on `list_model_records` for Task** (per `context/planhat-schema.md`). If a customer/topic scope is given and the list comes back empty or suspiciously short, fall back to `search_records(QUERY: "<customer or topic>")` filtered to `model: "Task"` and scan for `type: "Product Feedback"`.

If the argument is a topic rather than a customer (e.g. `/log-feedback API linking`), run the unscoped query and filter to matching items locally.

If no matching tasks are found for a named customer/topic, drop into **Mode B** for that customer rather than stopping. If no customer/topic was given and no tasks are found at all, say so and stop.

### Mode B — source directly from Gong/Planhat for a named customer or call

1. Resolve the Planhat Company record for the named customer: `search_records(QUERY: "<customer name>")` filtered to `model: "Company"`, or `list_model_records(MODEL: "Company", FILTER: {"name[equal to]": "<customer name>"})`. If ambiguous (multiple matches), ask which one.
2. Find the relevant call(s) — try both, in parallel:
   - Planhat `👾 Gong Call` Conversations for the Company (transcript lookup order step 0 in `context/project-instructions.md` §3): `list_model_records(MODEL: "Conversation", FILTER: {"companyId[equal to]": "<companyId>", "type[equal to]": "👾 Gong Call"}, SORT: "-date", LIMIT: 5, SELECT: ["subject", "date", "custom.Call Recording", "endusers", "users"])`. If none exist, `mcp__claude_ai_Gong__ask_account` with the customer name and any topic keywords given (e.g. "API linking") to identify the call(s) and get their links.
   - Planhat session Conversations on the Company record: `list_model_records(MODEL: "Conversation", FILTER: {"companyId[equal to]": "<companyId>"}, SELECT: ["title", "date", "notes", "custom.Call Recording"])`, sorted most recent first.
3. If a specific call was named, use that one. If multiple candidate calls exist and none was specified, prefer the most recent one that plausibly touches product feedback (title/notes mention a gap, blocker, or feature ask); if still ambiguous, ask Klara which call to source from.
4. Read the transcript/notes (`get_model_record` on the `👾 Gong Call` Conversation for its `transcript` + `description`; if there is no Planhat record, the call's file in the Gong transcripts Drive folder (transcript lookup step 1b, verbatim), else `ask_account` scoped to that call date for a synthesized summary; or the session Conversation's `notes` field) and distill every distinct pain point raised into a Problem / Current workaround / Desired outcome triple. **A single call can surface more than one feedback item** — treat each distinct pain point as its own candidate note and run it through Steps 4–8 independently (including its own HITL confirmation in Step 6).
5. Continue into Step 4 to fill in ARR, contact, and remaining context for each candidate item — Step 4's context-gathering applies to both modes; where it references "the task's description," Mode B uses the transcript/Conversation notes distilled in step 4 above instead.

If no feedback-worthy content is found in the named call/customer's recent activity, say so and stop rather than fabricating a note.

---

## Step 4: For each candidate item — gather context

For each candidate (a Task in Mode A, or a distilled pain point in Mode B), pull supporting context in parallel:

1. **Mode A:** read the task's `description` field (already returned by the list query) — this is the full PM-formatted log entry `post-session-debrief` wrote, including session date and any customer quote captured at debrief time.
   **Mode B:** use the Problem/Workaround/Desired-outcome distillation already produced in Step 3B.4 as the equivalent source material.

   **Cost-saving check (Mode A only) — skip steps 2–3 when the description is already sufficient:** if the task's `description` already contains enough to populate Problem, Current workaround, and Desired outcome (i.e. `post-session-debrief` already distilled it at debrief time — check for language covering what's broken, what they're doing instead, and what good looks like, plus a session date/quote if present), use it directly and **do not** run the Gong Call lookup / `ask_account`. Only fall through to steps 2–3 if the description is thin (e.g. just a one-line action with no business context or quote).

   **Gong URL missing from the Task (Mode A).** `post-session-debrief` now writes the Gong link and the session Conversation `_id` on the Source/Session lines; older Tasks may not have them. Before any `ask_account` call: if the description names a Conversation `_id`, `get_model_record` it for `custom.Call Recording`. Otherwise list Conversations for the `companyId` with `date` ±1 day of the session date in the Task — plain `YYYY-MM-DD` bounds (`"date[greater than]": "<day-1>"`, `"date[less than]": "<day+1>"`), metadata-only `SELECT: ["subject", "date", "type", "custom.Call Recording"]` — and take `custom.Call Recording` from the session or `👾 Gong Call` record. Only if that misses, fall through to step 2.
2. Find the relevant Gong call(s) for the linked customer (`companyName`) via the transcript lookup order in `context/project-instructions.md` §3 — step 0 Planhat `👾 Gong Call` Conversation, step 1 `mcp__claude_ai_Gong__ask_account`, step 1b the Gong transcripts Drive folder — if not already identified in Mode B and not skipped by the cost-saving check above. Try the customer name and/or keywords from the task's `action` (Mode A) or the pain point topic (Mode B).
3. If a Gong transcript is found (or wasn't already fully read in Mode B, and wasn't skipped by the cost-saving check above), read it — `get_model_record` on the `👾 Gong Call` Conversation (`transcript`, `description`), the call's file in the Gong transcripts Drive folder (`read_file_content`, verbatim), or `mcp__claude_ai_Gong__ask_account` scoped to the call date (synthesized, no verbatim transcript, so quotes may be unavailable) — to extract:
   - Exact customer quotes (attributed to speaker name, side — customer or Productboard — and role)
   - Business context
   - Workaround description
   - Desired outcome language
4. Pull ARR, renewal date, and Salesforce Account ID directly from the Planhat Company record: `get_model_record(MODEL: "Company", OBJECT_ID: "<companyId>", SELECT: ["name", "custom.ARR – SF", "renewalDate", "sourceId", "domains", "website"])` — `domains`/`website` feed the contact pick (4.5a) and `companyDomain` (Step 7). Reconstruct the Salesforce Account URL from `sourceId`: `https://productboard.lightning.force.com/lightning/r/Account/<sourceId>/view`.

**Before drafting, confirm you have retrieved all of the following (or explicitly marked each `-`):**
- [ ] ARR — from Planhat Company `custom.ARR – SF`
- [ ] Contract end date (renewal) — from Planhat Company `renewalDate`
- [ ] Salesforce Account URL — reconstructed from Planhat Company `sourceId`
- [ ] Gong call URL — from the task's `description` or `custom.Call Recording` on the linked Conversation (use as `sourceUrl` AND in the Gong section)
- [ ] Contact email — via the lookup chain below

Do not begin drafting until all five are resolved (or explicitly marked `-`).

5. Find the contact's email address using this lookup chain — stop at the first hit:
   a. **Planhat EndUser records — by name, not the whole company.** Never rely on one unfiltered page of the company's End Users: large accounts exceed the row cap and the contact silently falls off the list.
      1. **Name from the Task.** Take the contact's name from the Task description — the person who raised the item, or who owns the artifact it's about (customer-side speaker only). Query `list_model_records(MODEL: "End User", FILTER: {"companyId[equal to]": "<companyId>", "name[contains]": "<last name>"}, SELECT: ["name", "email", "position", "primary", "lastTouch"])`; if that misses, retry with `"email[contains]": "<first or last name, lowercased>"`.
      2. **No name in the Task.** Fall back to `"primary[equal to]": true` on the company, then to the `endusers` on the most recent session Conversation for the company (resolve each `_id` with `get_model_record`).
      3. **If you do list the company's End Users**, page per `planhat-schema.md` § API Quirks — never stop on one page.
      4. **Same person, several records.** If the person has End User records on more than one of the Company's `domains`, prefer the one on the Company's current/primary domain (the domain on its `website`, or the first in `domains` if there's no website); then apply § Duplicate End Users (`custom.PB_ID` → `position` → `lastTouch`) to break any remaining tie. Never pick silently: name the alternative record and email in the HITL preview so the user can swap it.
   b. **Gmail search** — `mcp__claude_ai_Gmail__search_threads` with `query: "[contact name] [company]"`. Scan the results for the contact's email address in thread senders, recipients, or signatures.
   c. **Planhat `email` Conversations** — `list_model_records(MODEL: "Conversation", FILTER: {"companyId[equal to]": "<companyId>", "type[equal to]": "email"}, SORT: "-date", LIMIT: 20, SELECT: ["subject", "date", "endusers"])`. Scan the `endusers` for the contact (covers mail from teammates' mailboxes too).
   d. If all three fail, mark the email as **⚠️ MISSING** and surface it as a required gap in the HITL step — do not guess or fabricate an email address.

---

## Step 4b: Pre-draft platform capability check

Before drafting any feedback note, check whether the topic touches **Spark features** or **PB platform capabilities** (MCP, API, integrations). If it does, verify current feature availability in `#releases` before drafting — do not assume a capability is missing without checking.

**When to run this check — MANDATORY and blocking:**
- Note involves Spark AI features (scheduled tasks, event-based triggers, external integrations, knowledge sources, authentication)
- Note involves PB platform capabilities (MCP server scope, API v2, feedback/insight management, entity creation, integration/connector access)

For any task whose title or content references Spark, MCP, or API capabilities: **STOP before drafting.** Run the `#releases` check first. If the capability is confirmed already available, mark the Planhat task done (append "Resolved — now available via [feature]" to `description`, per Step 8) and skip to the next item. Do not draft a feedback note for a gap that no longer exists.

**How to check:**
Search `#releases` using `mcp__claude_ai_Slack__slack_search_public_and_private` with the relevant feature keyword. Read any recent announcements before forming the draft framing.

**Known facts** — *Last verified: 2026-10-27.* Use these as the starting point, but the `#releases` check still runs. **If a `#releases` result contradicts a Known fact, trust the release:** say so in chat ("`#releases` says X shipped on <date>, which contradicts the Known fact Y") and flag the fact for update (suggest `/assistant-remember`).
- Spark scheduled tasks: available
- Spark event-based triggers: NOT yet available
- Spark external system auth (SharePoint, OneDrive, etc.): NOT possible without a customer-managed API token — live sync workarounds are not viable
- Spark can edit feedback notes: owner, tags, customer attribution (GA Oct 2026)
- PB MCP server (shipped Jun 4 2026): search/fetch specs, edit docs, post/read comments, update entity status. MCP Phase 2 (Aug 2026): create/edit entities. Oct 2026: list/move/create knowledge docs and folders. Verify current scope in `#releases` before claiming any gap (as of the stamp above, custom driver field writes, feedback/insight management and hierarchy management were not confirmed shipped).
- Integration/MCP connector access uses a request-to-connect flow (GA Sep 2026): makers request integration access, and makers connect MCPs directly once approved.

**Framing rule:** All notes touching Spark or PB platform capabilities must frame the gap as **current state → gap → desired state** — never "the feature doesn't exist" without verification, and never assume unavailability without checking `#releases`.

---

## Step 5: Draft the feedback note

> ⚠️ **STRICT FORMAT REQUIREMENT:** The `content` field MUST use the exact HTML template below — no substitutions. Do not use `<p>`, `<strong>`, markdown, or any other structure. Every section must appear in order, blank sections get a literal dash (`-`), and the Klara Martinez `<small>` disclaimer must be the final line. Failure to follow this template exactly is a submission error.
>
> ⚠️ **Write the tags raw — never HTML-escape the body.** Productboard renders `content` as HTML, so an escaped `&lt;b&gt;` is decoded back into a visible `<b>` and every section label ships as literal markup in the note. Put `<b>`, `<br>`, `<a href>` and `<small>` directly into the tool argument, with no entity encoding anywhere in the body.

Compose the feedback note using this EXACT HTML template. All section labels use `<b>` tags. Do NOT use markdown in the content body. Blank sections get a literal dash (`-`).

**Title (`title` tool field):** `[concise problem statement — max 10 words, no "Feedback form (GTM):" prefix]`
This is the short summary displayed in PB feedback lists and search results. Do NOT prepend any prefix — just the problem statement.

**Content (`content` tool field — full HTML body):**
Do NOT repeat the title as a `<b>Note title</b>` section — it is already in the `title` field. Start directly with `<b>Importance</b>`.

Each section uses `<b>Label</b><br>` so the label and its content appear on separate lines, followed by `<br><br>` before the next section. All URL fields (Salesforce, Gong) must be wrapped in `<a href="...">` tags so they are clickable.

```
<b>Importance</b><br>
[critical / important — critical if blocking adoption or at renewal risk, else important. NOTE: this is informational text in the body only; there is no dedicated importance field in the PB feedback tool.]
<br><br>
<b>Select Tags</b><br>
[relevant tags as a comma-separated list in the body, e.g. API, data model, workflow — or -. The tool's separate `tags` parameter takes these as a string array.]
<br><br>
<b>Account Type</b><br>
[Customer / Prospect / -]
<br><br>
<b>Pain point</b><br>
[Rich narrative: what the problem is, customer business context, session reference with date
(e.g. "A-22, May 7 2026"), direct customer quote if available (format: "quote text" —
First Last, Role), what this blocks them from doing, how widespread/priority the issue is.
IMPORTANT: only include specific details (tool names, system names, prior solutions) if they
appear in verbatim customer quotes or explicit customer statements — not inferred from
AI-generated meeting summaries. If uncertain, describe generically: "previously had a fully
automated solution" rather than naming a specific tool.]
<br><br>
<b>Workaround</b><br>
[What they're doing today to compensate, including any workaround Klara already suggested to the customer. Check the task notes and Gong transcript for suggestions Klara made. If a suggestion was made but has limitations, frame as: "X was suggested but [limitation]." Or - if none.]
<br><br>
<b>Desired Outcome</b><br>
[Concrete outcome in customer terms — what good looks like when this is solved]
<br><br>
<b>ARR Impact</b><br>
[ARR value from Planhat Company `custom.ARR – SF`, or -]
<br><br>
<b>Salesforce Opp or Account URL</b><br>
[<a href="[URL]">[URL]</a> — or -]
<br><br>
<b>Gong snippet link</b><br>
[<a href="[URL]">[URL]</a> — or -]
<br><br>
<b>Upcoming renewal date</b><br>
[Date from Planhat Company `renewalDate`, or -]
<br><br>
<small><i>Submitted via the aise-assistant plugin. Questions about this tool? Contact <a href="https://productboard.slack.com/archives/D07818Y71HA">Klara Martinez</a>.</i></small>
```

**Pain point quality bar** — the section should:
- Open with what specifically doesn't work (concrete, not vague)
- Include customer business context (how they've structured their workspace / workflow)
- Reference the session where this surfaced (session type + date)
- Include a direct customer quote where available (see Q1 below)
- Explain the downstream impact (what it blocks, who it affects)
- Mention if this has come up across multiple sessions / customers (priority signal)

Good example:
> "Formula fields only support math operators, no if/else or dropdown references. Blocks the automated priority scoring Eric requested. S&P GR has calculated P0–P5 priority fields based on dropdowns. The current formulas in PB are limited to CIS, Drivers, Numbers, and mathematical operators. Surfaced in A-4 (Apr 24, 2026) — Eric Parikh (Solutions Engineer) flagged this as a critical blocker for their scoring automation initiative."

**Drafting rules:**

**Q1 — Only customer-side speakers are quoted as customer voice.** Render a quote in the Pain point only if the Task (or transcript) marks its speaker as customer-side. A Productboard-side line (e.g. the AISE explaining what Spark was meant to do) is paraphrased as context, never quoted as the customer. An unattributed quote is paraphrased too, never guessed onto a speaker. Attribution format: `"quote" — First Last, Role` when the speaker has an End User record with a `position`; `"quote" — First name, Company` when they don't have a record or a role.

**F4 — Use the customer's stated language.** The note title and pain point must reflect the customer's own framing from the task notes and verbatim quotes. If the customer said "feedback," draft around "feedback" — not internal PB terminology like "insights" or "notes." Do not reframe the problem through a PB product lens.

**F5 — Never reference AI-linking or Linked by AI.** Do not mention "AI-linking", "Linked by AI", or the passive batch-mode AI link suggestion background feature in any feedback note — this feature is not recommended for use by product. If a note touches note-to-feature linking via Spark or AI, frame the request in terms of the active, in-session user experience only (e.g. "Spark surfaces evidence but doesn't persist it as Insights"). Exception: if the customer's own verbatim quote uses this terminology, you may include the quote but must not editorially add or expand on the term.

**P2 — Spark external auth limitation.** When the gap involves Spark accessing external document systems (SharePoint, OneDrive, Google Drive, etc.), do NOT suggest live sync as a workaround — Spark cannot authenticate to external systems without a customer-managed API token, making live sync non-viable. The correct workaround framing is: "Customer would need to periodically distill content from [source] into Spark agent knowledge docs manually."

**F6 — Never use internal team names in note content.** Do not reference "AISE", "Solutions Architect", or individual names (e.g. "Klara") in the Pain point or Workaround sections. Use generic equivalents: "Productboard support team", "a Productboard team member", or "PB support". Exception: if the customer's own verbatim quote names a specific person or team, include the quote but do not editorially expand on it.

**P3 — PB MCP gap workarounds.** Applies only to capabilities **still confirmed missing** after this run's Step 4b `#releases` check — never to one the Known facts or `#releases` show as shipped (entity create/edit has shipped since Aug 2026, for example). When the gap is confirmed, the Workaround section must include both options:
1. Direct PB API v2 calls (customer manages auth + plumbing, no Spark integration)
2. Custom MCP server built on top of PB API v2 (customer manages auth + plumbing, no Spark integration)
Both options require the customer to own authentication and tooling — note this explicitly.

---

## Step 6: HITL confirmation — one item at a time

**Email gate:** If `customerEmail` is still unresolved after all four lookup steps, do NOT proceed to HITL — surface a blocker:

> ⚠️ Contact email not found. Please provide the email address for [Name] at [Company] before I can submit this note.

Wait for Klara to supply it before continuing.

**Shared context once per batch.** When several items share a Company and session, show one summary block of the shared fields before the first preview: ARR, renewal date, Salesforce URL, Gong URL, contact + email (and any alternative End User record from Step 4.5a), and `companyDomain` (with `companyExternalId` if Step 7 uses it). Still render every field in each item's full preview below, since that preview is the last check before a create-only submission.

Present each drafted feedback note to Klara for review before submitting anything. Render the content preview in chat with these headers:

```
📋 FEEDBACK NOTE READY FOR REVIEW
Source task: [Planhat task action]
Title: [proposed title]
Customer: [Company name] — [contact name] ([contact email])
Company domain: [companyDomain] [+ "· externalId [sourceId]" when used; "· other domains: [x, y]" when the Company has several]
Importance: [critical/important]

Content preview:
[full content rendered]
```

If Gong context is thin, flag it above the AskUserQuestion call as: **⚠️ Limited session context — pain point may need enrichment.**

After rendering the preview, call the `AskUserQuestion` tool with:

- **Question 1** (header: "Submit?", single-select): "Ready to submit this note to Productboard?"
  - Options: "I confirm and submit" | "Edit first" | "Skip – mark ignored" | "Skip – leave open"
  - "Stop processing" is not a button (AskUserQuestion caps at 4 options); the user can still type it via Other, and you honor it.

Wait for the AskUserQuestion response before calling `feedback_create_feedback`.

If the user selects "Edit first", ask which section to edit and apply the change, then re-show the preview and re-trigger AskUserQuestion.

**"Skip – mark ignored"** closes the item out: transition the Task with `update_model_record(MODEL: "Task", OBJECT_ID: "<task_id>", PARAMETERS: {"status": "ignored"})`. `"ignored"` keeps the Task on the customer record and out of the open queue without triggering the auto-Conversation that `"done"` creates, which is right here: nothing was logged to Productboard, so there is no touchpoint to record. Free-text equivalents ("skip and mark as ignored", "skip and ignore this in Planhat") map to this option. In Mode B there is no Task, so treat it as a plain skip.

**"Skip – leave open"** leaves the Planhat Task untouched and still open. Never set `ignored` unless the user chose the ignore option or asked for it in words.

---

## Step 7: Submit confirmed items

Proceed with submission only when the user chose "I confirm and submit". Block on "Edit first", either Skip option, or "Stop processing" — do not submit.

For confirmed items, call `mcp__claude_ai_Productboard__feedback_create_feedback` with:
- `title`: the problem statement only — no prefix (matches the title drafted in Step 5)
- `content`: the complete HTML body (all `<b>` section labels, `-` for empty sections) — **passed as raw HTML, never entity-escaped.** Before calling the tool, scan the exact string you are about to send for `&lt;`, `&gt;` and `&amp;`. If any appear, the body is escaped and will render as literal markup; fix it and re-check before submitting.
- `customerEmail`: the customer contact's email address — **never Klara's own email (klara.martinez@productboard.com)**
- `companyDomain`: the customer's company domain extracted from the contact's email or the Planhat Company record (e.g. `acme.com`) — **never `productboard.com` or any internal domain**
  - **Multi-domain Companies** (Planhat `domains` has more than one entry): derive `companyDomain` from the chosen `customerEmail` so the two always match. Never pick one of the domains by assumption: the wrong one makes Productboard file the note under a second company (e.g. a parent brand) instead of the existing customer.
- `companyExternalId`: the Planhat Company `sourceId` (Salesforce Account ID). **Always send it alongside `companyDomain` when the Company has more than one domain.** The MCP gives no way to check which domain PB already files the account under, and sending both makes PB match the existing company by Salesforce ID first, so it won't create a new one. Optional for single-domain Companies. Never send it alone: an unknown ID with no domain returns an error.
- `sourceUrl`: the Gong call URL if available. If there is no Gong recording, use whatever URL actually holds the source — a Slack thread permalink, a support ticket, an email thread — and fall back to `-` only when no source URL exists at all. The `Gong snippet link` section in the body stays `-` when there is genuinely no Gong recording, even where `sourceUrl` points elsewhere.
- `tags`: a **JSON string array** of tag values extracted from the Select Tags section (e.g. `["API", "portal", "automation"]`) — not a comma-separated string

**Submission is one-way — the tool call is the last checkpoint.** The Productboard MCP exposes `feedback_create_feedback` and `feedback_list_feedback` and nothing else: there is no update, no archive, no delete. A malformed note cannot be repaired or removed from here, and it cannot even be read back — `feedback_list_feedback` filters by linked entity, and a freshly created note has no entity. The Step 6 HITL preview renders as prose in chat and will look perfectly correct even when the `content` string is malformed, so re-read the actual tool argument, not the preview.

If a bad note does ship: say so immediately rather than letting it stand, tell the user plainly that it has to be archived or deleted by hand in the Productboard UI, re-submit a corrected note once they confirm, and point the Step 8 write-back at the corrected note's URL — adding a line to the Task `description` that names the orphaned note id so the cleanup does not get lost. Do this promptly: Productboard's AI pipeline starts extracting insights and themes from a note on arrival, so a duplicate left in place produces duplicate insights.

---

## Step 8: Record the submission back in Planhat

**Mode A — mark the Planhat task complete.** After successful submission, execute exactly these three steps — no others:

**Step 8a — Append confirmation to `description`:**
Task `description` is rich text (HTML, single line), so markdown `---` and newlines don't render. Take the task's current `description` HTML (already in context from Step 4) and append exactly this suffix, no variation:
```
<hr><p>✅ Logged to PB – YYYY-MM-DD</p><p><a href="<PB note URL>"><PB note URL></a></p>
```
Replace the date with the actual submission date and both `<PB note URL>` slots with the actual note URL. If the PB MCP does not return a URL or ID, use `<p>Note submitted – no URL returned by API</p>` in place of the link paragraph. Rewrite the field whole, existing HTML + suffix, never as markdown or with literal newlines: `update_model_record(MODEL: "Task", OBJECT_ID: "<task_id>", PARAMETERS: {"description": "<existing HTML><suffix>"})`.

**Step 8b — Transition status to done:**
`update_model_record(MODEL: "Task", OBJECT_ID: "<task_id>", PARAMETERS: {"status": "done"})`. This must be a separate `update_model_record` call, not combined with the create or with any other field — per `context/planhat-schema.md`, only a `status` *transition* via update triggers Planhat's auto-Conversation creation, and it's a reasonable side effect here: it logs the feedback submission as a company touchpoint. Capture `noteId` from this update's response (per `context/planhat-schema.md` § Planhat Task auto-Conversation behavior — `noteId` is absent from a create response, only present on the transitioning update).

**Step 8c — Write the PB note link onto the auto-created Conversation:**
**If the source Task's `type` is `Product Feedback`** (every Mode A Task from `post-session-debrief`), skip the type fetch: the auto-Conversation inherits `Product Feedback`, which is correct. Just write `custom.Link to PB Note`: `update_model_record(MODEL: "Conversation", OBJECT_ID: "<noteId>", PARAMETERS: {"custom.Link to PB Note": "<PB note URL>"})`.

**Only for Tasks of any other type:** using the `noteId` captured in 8b, fetch the Conversation's current `type` (`get_model_record(MODEL: "Conversation", OBJECT_ID: "<noteId>", SELECT: ["type"])`), then write both in a single `update_model_record` call:
- `custom.Link to PB Note`: the PB note URL from the submission response (same URL used in the 8a confirmation block)
- `type: "Task"` — only include this if the fetched `type` is missing or generic; skip it if it is already `"Task"`, per the idempotency note in `context/planhat-schema.md`. **Also skip it when the auto-Conversation has inherited the Task's own type** — a Task of `type: "Product Feedback"` produces a Conversation typed `Product Feedback`, which is more accurate than `Task` and should be left alone. The point of this step is to stop the Conversation landing untyped, not to force every one to `Task`.

If the PB MCP didn't return a note URL, skip this step's `custom.Link to PB Note` write (there's nothing to link) but still run the `type` check/fix if needed.

**Mode B — no Task exists to close.** There's nothing to transition to `done`. Instead:
- If the source was a Planhat Conversation (Step 3B.2), append the same HTML suffix from Step 8a to that Conversation's `notes` field, rewriting it whole as existing HTML + suffix: `update_model_record(MODEL: "Conversation", OBJECT_ID: "<conversation_id>", PARAMETERS: {"notes": "<existing HTML><suffix>"})`.
- If the source was a Gong call with no corresponding Planhat Conversation, skip the write-back entirely — do not create a new Task or Conversation just to hold the confirmation. Note the PB link in the Step 9 summary instead so it isn't lost.

---

## Step 9: Summary

After processing all items (or after "stop"), show a summary:
- X submitted successfully (note which mode each came from: Task-driven vs. ad-hoc)
- X skipped (split: marked ignored vs left open)
- Links to submitted notes (if the MCP returns a URL/ID) — for Mode B items with no Conversation to write the confirmation to, this is the only place the link is recorded

---

## Tools required

Named by role. The prefix depends on the host (`mcp__claude_ai_<Service>__`, `mcp__<Service>__`, …), so match each role to whichever prefixed tool the session exposes, per `context/project-instructions.md` § Tool names differ by host. Full IDs elsewhere in this skill are examples, not requirements.

- Planhat: `list_model_records`, `get_model_record`, `update_model_record`, `search_records`
- Gong: `ask_account` (call lookup / summary when no Planhat Gong Call record exists)
- Google Drive: `search_files`, `read_file_content` (Gong transcripts Drive folder, transcript lookup step 1b)
- Gmail: `search_threads` (contact email lookup fallback)
- Productboard: `feedback_create_feedback`
- Slack: `slack_search_public_and_private` (pre-draft `#releases` check)
- `Read`, `Grep` (context files, targeted section reads per Step 1)
- `AskUserQuestion` (HITL confirmation widget in Step 6)

---

## Critical rules

1. **NEVER call `feedback_create_feedback` without explicit "submit" from Klara.**
2. **NEVER use Klara's own email (`klara.martinez@productboard.com`) as `customerEmail`** — this must always be the customer contact's email.
3. **If no contact email can be found with confidence**, surface it as a gap in the HITL step and ask Klara to provide it before allowing submission.
4. **If Gong context is thin**, flag it in the HITL preview as "⚠️ Limited session context — pain point may need enrichment."
5. **`companyDomain` must be the customer's company domain** — never `productboard.com` or any internal domain.
6. **Every section gets a value or a literal dash (`-`)** — never leave a section blank or omit it.
7. **Owner-filter every Task result** (`ownerId` = current user's Planhat id). Without a customer, filter in the query; with a customer, query by `companyId` + `type` and apply the `ownerId` filter locally (Step 3, Mode A).
8. **`status: "done"` must be its own `update_model_record` transition** — never combine it with the `description` append in the same call, and never set it on create.
9. **Reuse an already-sufficient Task `description` instead of re-fetching Gong** — only go to Gong (`ask_account`, the Drive transcripts folder) when the description is too thin to draft from; a missing Gong URL is resolved first via the Conversation ±1-day lookup (Step 4's cost-saving check).
10. **Mode B never fabricates a Task.** If no Product Feedback Task exists for the item, don't create one solely to satisfy Step 8 — either write the confirmation to the sourcing Planhat Conversation, or note it in the Step 9 summary if there's no Conversation to write to.
11. **Never HTML-escape the `content` body.** Productboard renders the field as HTML, so `&lt;b&gt;` decodes to a visible `<b>` and every section label ships as literal markup. Scan the argument for `&lt;` / `&gt;` before every `feedback_create_feedback` call.
12. **PB feedback is create-only over MCP** — no update, no archive, no delete, and no read-back for an unlinked note. A malformed submission costs the user a manual cleanup in the Productboard UI, so the tool call is the last checkpoint, not the HITL preview.
13. **`status: "ignored"` closes out a skipped item, and only on the user's choice.** Set it when the user picks "Skip – mark ignored" (or asks for it in words). It keeps the Task on the record without creating the auto-Conversation that `"done"` triggers, which is correct when nothing was logged to Productboard. "Skip – leave open" leaves the Task open and untouched.
14. **Never read `context/planhat-schema.md` whole.** Targeted section reads only (Step 1).
15. **A Productboard-side or unattributed quote is never rendered as customer voice** (Step 5, Q1).
16. **On multi-domain Companies, `companyDomain` follows `customerEmail`, and `companyExternalId` = Company `sourceId` goes with it** (Step 7).
