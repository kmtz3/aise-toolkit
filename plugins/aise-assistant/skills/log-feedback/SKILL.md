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

---

## Step 5: Draft the feedback note

Compose the feedback note using this EXACT HTML template. All section labels use `<b>` tags. Do NOT use markdown in the content body. Blank sections get a literal dash (`-`).

**Title:** `Feedback form (GTM): [concise problem statement — max 10 words]`

**Content:**
```
<b>Note title</b>
[Short descriptive title matching the title above, without the "Feedback form (GTM):" prefix]
<b>Importance</b>
[critical / important — critical if blocking adoption or at renewal risk, else important]
<b>Select Tags</b>
[relevant tags, e.g. API, data model, initiatives, workflow — or -]
<b>Account Type</b>
[Customer / Prospect / -]
<b>Pain point</b>
[Rich narrative: what the problem is, customer business context, session reference with date
(e.g. "A-22, May 7 2026"), direct customer quote if available (format: "quote text" —
First Last, Role), what this blocks them from doing, how widespread/priority the issue is]
<b>Workaround</b>
[What they're doing today to compensate, or - if none]
<b>Desired Outcome</b>
[Concrete outcome in customer terms — what good looks like when this is solved]
<b>ARR Impact</b>
[ARR value from Notion/Salesforce, or -]
<b>Salesforce Opp or Account URL</b>
[URL from Notion Active Package, or -]
<b>Gong snippet link</b>
[Direct Gong call URL (https://us-71146.app.gong.io/call?id=...) if available, or -]
<b>Upcoming renewal date</b>
[Date from Notion Active Package, or -]
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

---

## Step 6: HITL confirmation — one item at a time

Present each drafted feedback note to Klara for review before submitting anything. Format the confirmation as:

```
---
📋 FEEDBACK NOTE READY FOR REVIEW
Source task: [Notion task title]

**Title:** [proposed title]
**Customer:** [Company name] — [contact name] ([contact email])
**Importance:** [critical/important]

**Content preview:**
[full content rendered]

**Verify before submitting:**
- [ ] Customer company mapping correct?
- [ ] Contact email is the right person at this company?
- [ ] Pain point has enough context / accurate?
- [ ] Workaround and Desired Outcome captured correctly?

Type:
  submit — submit as-is
  edit [section] [new text] — update a specific section
  skip — skip this item
  stop — stop processing remaining items
---
```

Wait for explicit **"submit"** before calling `feedback_create_feedback`. If the user types `edit`, apply the edit and re-show the updated preview for re-confirmation before submitting.

If no contact email can be found with confidence, surface it as a gap in the HITL preview and ask Klara to provide it before allowing submission. Do not guess.

If Gong context is thin, flag it in the HITL preview as **⚠️ Limited session context — pain point may need enrichment** so Klara can decide whether to edit first.

---

## Step 7: Submit confirmed items

For confirmed items, call `mcp__claude_ai_Productboard__feedback_create_feedback` with:
- `title`: the full `"Feedback form (GTM): ..."` title
- `content`: the HTML-formatted body (all `<b>` labels, `-` for empty sections)
- `customerEmail`: the customer contact's email address — **never Klara's own email (klara.martinez@productboard.com)**
- `companyDomain`: the customer's company domain (extract from email or Notion) — **never productboard.com or any internal domain**
- `sourceUrl`: the Gong call URL if available
- `tags`: any relevant tags identified

---

## Step 8: Mark Notion task complete

After successful submission, update the Notion task status to Done/complete using `mcp__claude_ai_Notion__notion-update-page` and add a note with the date and "Logged to PB" confirmation.

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
- `mcp__claude_ai_Glean__search`
- `mcp__claude_ai_Productboard__feedback_create_feedback`
- `Read` (for context files and PLUGIN_DATA_DIR pointer)

---

## Critical rules

1. **NEVER call `feedback_create_feedback` without explicit "submit" from Klara.**
2. **NEVER use Klara's own email (`klara.martinez@productboard.com`) as `customerEmail`** — this must always be the customer contact's email.
3. **If no contact email can be found with confidence**, surface it as a gap in the HITL step and ask Klara to provide it before allowing submission.
4. **If Gong context is thin**, flag it in the HITL preview as "⚠️ Limited session context — pain point may need enrichment."
5. **`companyDomain` must be the customer's company domain** — never `productboard.com` or any internal domain.
6. **Every section gets a value or a literal dash (`-`)** — never leave a section blank or omit it.
7. **Owner-filter every Notion query** — always scope to the current user's records.
