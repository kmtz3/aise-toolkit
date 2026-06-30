---
name: log-feedback
description: Discover outstanding Notion tasks representing product feedback, draft structured Productboard GTM feedback notes, and submit with HITL confirmation on customer mapping and content. Triggers: /log-feedback, 'log PB feedback', 'submit feedback to productboard', 'log outstanding customer feedback'.
---

Discover outstanding feedback tasks from Klara's Notion Tasks database, draft structured Productboard feedback notes in the GTM format, and submit them via the PB MCP — with explicit HITL confirmation before every submission.

**Trigger phrases:** /log-feedback · "log PB feedback" · "submit feedback to productboard" · "any outstanding feedback to log" · "log outstanding customer feedback"

---

## Step 1: Load AISE context

Read `context/aise-context.md` (or equivalent) to understand the customer portfolio, Notion schema, and tool conventions. Also read `context/notion-schema.md` for the Tasks DB structure and field names.

---

## Step 2: Resolve user identity

**Resolve PLUGIN_DATA_DIR first:** use the Read tool on `~/.claude/aise-assistant.datadir` — the file content is the absolute path. Never use the `CLAUDE_PLUGIN_DATA` env variable.

Then call `notion-get-users` and `notion-search("AISE Identity — {display_name}") → notion-fetch` to get the user's Notion UUID. All Notion queries must filter by this UUID (Owner contains current user).

---

## Step 3: Discover outstanding feedback tasks

Query the Notion Tasks database using `mcp__claude_ai_Notion__notion-query-data-sources` for tasks that appear to be outstanding product feedback items. Filter by Owner = current user. Match on ANY of:
- Title contains keywords: "feedback", "PB feedback", "log feedback", "product gap", "feature request", "workaround", "log to PB"
- Status is open / not completed
- Due date is past or this week

If the user invoked with a customer name or topic as an argument (e.g. `/log-feedback LumApps API linking`), scope the search to that customer/topic.

If no matching tasks are found, say so and stop.

---

## Step 4: For each candidate task — gather context

For each task found, pull supporting context in parallel:

1. Read the task's Notion page body (`mcp__claude_ai_Notion__notion-fetch`) for session notes and description.
2. Use `mcp__claude_ai_Glean__meeting_lookup` to find the relevant Gong call(s) referenced in the task or for the linked customer. Try the customer name and/or keywords from the task title.
3. If a Gong transcript is found, use `mcp__claude_ai_Glean__read_document` on it to extract:
   - Exact customer quotes (attributed to name + role)
   - Business context
   - Workaround description
   - Desired outcome language
4. Check the customer's Active Package in Notion for ARR, upcoming renewal date, and Salesforce Opp URL.

**Before drafting, confirm you have retrieved all of the following (or explicitly marked each `-`):**
- [ ] ARR — from Active Package `ARR` property in Notion
- [ ] Contract end date (renewal) — from Active Package `End Date` property
- [ ] Salesforce Account URL — from Customer page `SFDC` property
- [ ] Gong call URL — from Session page `Gong call` property (use as `sourceUrl` AND in Gong section)
- [ ] Contact email — via the 4-step lookup chain below

Do not begin drafting until all five are resolved (or explicitly marked `-`).

5. Find the primary contact's email address using this lookup chain — stop at the first hit:
   a. **Notion Contacts DB** — query `collection://29497e9c-7d4f-80be-b224-000bbec4980b` filtered by the linked Customer page URL; look for an Email property.
   b. **Glean Gmail search** — `mcp__claude_ai_Glean__search` with `query: "[contact name] [company]"` and `app: gmailnative`. Scan the results for the contact's email address in thread senders, recipients, or signatures.
   c. **Glean Gong search** — `mcp__claude_ai_Glean__search` with `query: "[contact name] [company]"` and `app: gong`. Scan for email in participant metadata.
   d. If all three fail, mark the email as **⚠️ MISSING** and surface it as a required gap in the HITL step — do not guess or fabricate an email address.

---

## Step 4b: Pre-draft platform capability check

Before drafting any feedback note, check whether the topic touches **Spark features** or **PB platform capabilities** (MCP, API, integrations). If it does, verify current feature availability in `#releases` before drafting — do not assume a capability is missing without checking.

**When to run this check — MANDATORY and blocking:**
- Note involves Spark AI features (scheduled tasks, event-based triggers, external integrations, knowledge sources, authentication)
- Note involves PB platform capabilities (MCP server scope, API v2, feedback/insight management, entity creation)

For any task whose title or content references Spark, MCP, or API capabilities: **STOP before drafting.** Run the `#releases` check first. If the capability is confirmed already available, mark the Notion task Done with a note "Resolved — now available via [feature]" and skip to the next item. Do not draft a feedback note for a gap that no longer exists.

**How to check:**
Search `#releases` using `mcp__claude_ai_Slack__slack_search_public_and_private` with the relevant feature keyword. Read any recent announcements before forming the draft framing.

**Known facts (do not re-verify these):**
- Spark scheduled tasks: available
- Spark event-based triggers: NOT yet available
- Spark external system auth (SharePoint, OneDrive, etc.): NOT possible without a customer-managed API token — live sync workarounds are not viable
- PB MCP server (shipped Jun 4 2026): supports search/fetch specs, edit docs, post/read comments, update entity status. Does NOT support entity creation, custom driver field writes, feedback/insight management, or hierarchy management.

**Framing rule:** All notes touching Spark or PB platform capabilities must frame the gap as **current state → gap → desired state** — never "the feature doesn't exist" without verification, and never assume unavailability without checking `#releases`.

---

## Step 5: Draft the feedback note

> ⚠️ **STRICT FORMAT REQUIREMENT:** The `content` field MUST use the exact HTML template below — no substitutions. Do not use `<p>`, `<strong>`, markdown, or any other structure. Every section must appear in order, blank sections get a literal dash (`-`), and the Klara Martinez `<small>` disclaimer must be the final line. Failure to follow this template exactly is a submission error.

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
[ARR value from Notion/Salesforce, or -]
<br><br>
<b>Salesforce Opp or Account URL</b><br>
[<a href="[URL]">[URL]</a> — or -]
<br><br>
<b>Gong snippet link</b><br>
[<a href="[URL]">[URL]</a> — or -]
<br><br>
<b>Upcoming renewal date</b><br>
[Date from Notion Active Package, or -]
<br><br>
<small><i>Submitted via the aise-assistant plugin. Questions about this tool? Contact <a href="https://productboard.slack.com/archives/D07818Y71HA">Klara Martinez</a>.</i></small>
```

**Pain point quality bar** — the section should:
- Open with what specifically doesn't work (concrete, not vague)
- Include customer business context (how they've structured their workspace / workflow)
- Reference the session where this surfaced (session type + date)
- Include a direct customer quote where available
- Explain the downstream impact (what it blocks, who it affects)
- Mention if this has come up across multiple sessions / customers (priority signal)

Good example:
> "Formula fields only support math operators, no if/else or dropdown references. Blocks the automated priority scoring Eric requested. S&P GR has calculated P0–P5 priority fields based on dropdowns. The current formulas in PB are limited to CIS, Drivers, Numbers, and mathematical operators. Surfaced in A-4 (Apr 24, 2026) — Eric Parikh (Solutions Engineer) flagged this as a critical blocker for their scoring automation initiative."

**Drafting rules:**

**F4 — Use the customer's stated language.** The note title and pain point must reflect the customer's own framing from the task notes and verbatim quotes. If the customer said "feedback," draft around "feedback" — not internal PB terminology like "insights" or "notes." Do not reframe the problem through a PB product lens.

**F5 — Never reference AI-linking or Linked by AI.** Do not mention "AI-linking", "Linked by AI", or the passive batch-mode AI link suggestion background feature in any feedback note — this feature is not recommended for use by product. If a note touches note-to-feature linking via Spark or AI, frame the request in terms of the active, in-session user experience only (e.g. "Spark surfaces evidence but doesn't persist it as Insights"). Exception: if the customer's own verbatim quote uses this terminology, you may include the quote but must not editorially add or expand on the term.

**P2 — Spark external auth limitation.** When the gap involves Spark accessing external document systems (SharePoint, OneDrive, Google Drive, etc.), do NOT suggest live sync as a workaround — Spark cannot authenticate to external systems without a customer-managed API token, making live sync non-viable. The correct workaround framing is: "Customer would need to periodically distill content from [source] into Spark agent knowledge docs manually."

**F6 — Never use internal team names in note content.** Do not reference "AISE", "Solutions Architect", or individual names (e.g. "Klara") in the Pain point or Workaround sections. Use generic equivalents: "Productboard support team", "a Productboard team member", or "PB support". Exception: if the customer's own verbatim quote names a specific person or team, include the quote but do not editorially expand on it.

**P3 — PB MCP gap workarounds.** When the gap involves capabilities the PB MCP server does not support (entity creation, feedback/insight management, custom driver field writes, hierarchy management), the Workaround section must include both options:
1. Direct PB API v2 calls (customer manages auth + plumbing, no Spark integration)
2. Custom MCP server built on top of PB API v2 (customer manages auth + plumbing, no Spark integration)
Both options require the customer to own authentication and tooling — note this explicitly.

---

## Step 6: HITL confirmation — one item at a time

**Email gate:** If `customerEmail` is still unresolved after all four lookup steps, do NOT proceed to HITL — surface a blocker:

> ⚠️ Contact email not found. Please provide the email address for [Name] at [Company] before I can submit this note.

Wait for Klara to supply it before continuing.

Present each drafted feedback note to Klara for review before submitting anything. Render the content preview in chat with these headers:

```
📋 FEEDBACK NOTE READY FOR REVIEW
Source task: [Notion task title]
Title: [proposed title]
Customer: [Company name] — [contact name] ([contact email])
Importance: [critical/important]

Content preview:
[full content rendered]
```

If Gong context is thin, flag it above the AskUserQuestion call as: **⚠️ Limited session context — pain point may need enrichment.**

After rendering the preview, call the `AskUserQuestion` tool with:

- **Question 1** (header: "Submit?", single-select): "Ready to submit this note to Productboard?"
  - Options: "I confirm and submit" | "Edit first" | "Skip this item" | "Stop processing"

Wait for the AskUserQuestion response before calling `feedback_create_feedback`.

If the user selects "Edit first", ask which section to edit and apply the change, then re-show the preview and re-trigger AskUserQuestion.

---

## Step 7: Submit confirmed items

Proceed with submission only when the user chose "I confirm and submit". Block on "Edit first", "Skip this item", or "Stop processing" — do not submit.

For confirmed items, call `mcp__claude_ai_Productboard__feedback_create_feedback` with:
- `title`: the problem statement only — no prefix (matches the title drafted in Step 5)
- `content`: the complete HTML body (all `<b>` section labels, `-` for empty sections)
- `customerEmail`: the customer contact's email address — **never Klara's own email (klara.martinez@productboard.com)**
- `companyDomain`: the customer's company domain extracted from email or Notion (e.g. `lumapps.com`) — **never `productboard.com` or any internal domain**
- `sourceUrl`: the Gong call URL if available; if no Gong link, use the Notion meeting transcript URL as the fallback source
- `tags`: a **JSON string array** of tag values extracted from the Select Tags section (e.g. `["API", "portal", "automation"]`) — not a comma-separated string

---

## Step 8: Mark Notion task complete

After successful submission, execute exactly these two calls — no others:

**Step 8a — Mark Done:**
Call `mcp__claude_ai_Notion__notion-update-page` with `command: "update_properties"` to set `Status` to `Done` on the task page. **The parameter name is `page_id` (snake_case), not `pageId` — always use `page_id`.**

The Tasks DB has **only one writable property for this purpose: `Status`**. There is NO `Notes` property, NO `URL` property, and NO other field to write the PB note URL into. Do not attempt to set any property other than `Status` — it will fail.

**Step 8b — Append confirmation to body:**
Call `mcp__claude_ai_Notion__notion-update-page` with `command: "insert_content"` and `position: {"type": "end"}` to append this block to the task page body.

**The appended text must be exactly this (no variation):**
```
---
✅ Logged to PB — 2026-06-30
https://pb.productboard.com/all-notes/notes/XXXXXXXX
```

Do not use "PB note:", omit the `---` separator, or skip the date. Replace the date with the actual submission date (YYYY-MM-DD) and the URL with the actual PB note URL. If the PB MCP does not return a URL or ID, still complete both steps — mark Done and append the confirmation block with "Note submitted — no URL returned by API" in place of the URL.

---

## Step 9: Summary

After processing all items (or after "stop"), show a summary:
- X submitted successfully
- X skipped
- Links to submitted notes (if the MCP returns a URL/ID)

---

## Tools required

- `mcp__claude_ai_Notion__notion-query-data-sources`
- `mcp__claude_ai_Notion__notion-fetch`
- `mcp__claude_ai_Notion__notion-search`
- `mcp__claude_ai_Notion__notion-update-page`
- `mcp__claude_ai_Notion__notion-get-users`
- `mcp__claude_ai_Glean__meeting_lookup`
- `mcp__claude_ai_Glean__read_document`
- `mcp__claude_ai_Glean__search` (email lookup via Gmail/Gong fallback)
- `mcp__claude_ai_Productboard__feedback_create_feedback`
- `mcp__claude_ai_Slack__slack_search_public_and_private` (pre-draft #releases check)
- `Read` (for context files and PLUGIN_DATA_DIR pointer)
- `AskUserQuestion` (HITL confirmation widget in Step 6)

---

## Critical rules

1. **NEVER call `feedback_create_feedback` without explicit "submit" from Klara.**
2. **NEVER use Klara's own email (`klara.martinez@productboard.com`) as `customerEmail`** — this must always be the customer contact's email.
3. **If no contact email can be found with confidence**, surface it as a gap in the HITL step and ask Klara to provide it before allowing submission.
4. **If Gong context is thin**, flag it in the HITL preview as "⚠️ Limited session context — pain point may need enrichment."
5. **`companyDomain` must be the customer's company domain** — never `productboard.com` or any internal domain.
6. **Every section gets a value or a literal dash (`-`)** — never leave a section blank or omit it.
7. **Owner-filter every Notion query** — always scope to the current user's records.
8. **The Tasks DB has NO `Notes` property** — the only Notion property to write during closeout is `Status`. The PB note URL goes in the page body via `insert_content`, never in a property field.
