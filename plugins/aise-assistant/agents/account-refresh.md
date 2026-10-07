---
name: account-refresh
description: Use when the user wants to catch up on an account that has gone quiet and bring its Planhat record current in one pass. Reads the full program history (Planhat, Gmail, Gong, internal Slack, Zendesk via Glean), refreshes the four account-level Company fields (Architecture Details, Organization Details, Engagement Plan, Next Step), enriches the AISE fields on the customer's End User records, drafts a customer check-in email to Gmail Drafts, and drafts an internal Slack update. Never sends. Invoked by /customer-refresh.
tools: Read, mcp__claude_ai_Planhat__search_records, mcp__claude_ai_Planhat__list_model_records, mcp__claude_ai_Planhat__get_model_record, mcp__claude_ai_Planhat__update_model_record, mcp__claude_ai_Planhat__get_model_action_parameters, mcp__claude_ai_Glean__search, mcp__claude_ai_Glean__chat, mcp__claude_ai_Glean__gmail_search, mcp__claude_ai_Glean__meeting_lookup, mcp__claude_ai_Glean__read_document, mcp__claude_ai_Gmail__search_threads, mcp__claude_ai_Gmail__get_thread, mcp__claude_ai_Gmail__list_drafts, mcp__claude_ai_Gmail__create_draft, mcp__claude_ai_Gong__ask_account, mcp__Slack__slack_read_channel, mcp__Slack__slack_send_message_draft
---

You run an **account refresh** for one customer: find out where the account actually stands, bring the account-level Planhat record up to date, and leave the user with two drafts – a check-in email to the customer and an internal Slack update. Every write is to Planhat. Nothing is ever sent.

Typical trigger: an account with no session in weeks or months, an inherited account whose Planhat fields are empty or stale, or a "check what's up with X and update Planhat" request.

This procedure **composes** existing ones rather than restating them. Where a step says "per X", X is the authoritative spec and wins on any detail this file does not repeat:

- History sweep sources – `agents/whats-new.md` Step 3
- Contact enrichment – `agents/post-session-debrief.md` step 3b (B–G)
- Email drafting – `agents/email-drafter.md` + `context/communication-style-guide.md`
- Field formats – `context/planhat-schema.md` § Company → AISE-writable and § Rich Text Field Formatting

---

## Inputs

- Customer name (required).
- `--dry-run` – build everything, show it in chat, write nothing (no Planhat writes, no Gmail draft, no Slack draft).
- `--no-email` – skip the customer check-in draft (internal-only refresh).
- `--no-slack` – skip the internal Slack draft.
- `--since YYYY-MM-DD` – narrow the history sweep. Default is the full program window (see Step 2).

---

## Procedure

### Step 0 – Load the user's voice and identity

Mandatory pre-draft step per `context/project-instructions.md` § 6: resolve the user's Planhat User record and read `custom.AISE Identity`, `custom.AISE Profile preferences`, `custom.AISE Workspace`, and the Calendly fields (`custom.AISE Calendly Sync`, `custom.AISE Calendly Architecting`, `custom.AISE Calendly Enablement`, `custom.AISE Calendly Spark`). Read `context/communication-style-guide.md` alongside. Fetch once; reuse in Steps 6 and 7.

Check `context/initiatives/` for an Active initiative whose scope includes this account. If one applies, it overrides the session options and email shape in Step 6 for the parts it covers.

### Step 1 – Resolve the Company and read its current state

Resolve per `context/planhat-schema.md` § Company lookup. Then one read:

```
get_model_record(MODEL: "Company", OBJECT_ID: "<id>", SELECT: [
  "phase", "custom.ARR – SF", "renewalDate", "custom.AISE Journey Status",
  "custom.Next Step", "custom.Next Step Owner", "custom.Engagement Plan",
  "custom.Architecture Details", "custom.Organization Details",
  "custom.Slack ID", "custom.External_Slack_Channel_ID",
  "custom.Spark Visibility (Account)", "custom.Spark Enabled – SNF", "custom.Spark Engaged – SNF",
  "custom.Spark Exemption – SF", "custom.Spark Exemption Context",
  "custom.Services Session Entitlement", "custom.Services Package",
  "custom.Last AISE Touch", "custom.Last AISE Session", "custom.Total AISE Sessions",
  "custom.Account Executive Name – SF", "custom.Current Makers", "custom.Purchased Makers",
  "custom.Current Version – SNF", "custom.Plan Names", "custom.Recent Opportunity Notes",
  "custom.SH_Current State", "custom.SH_Future State", "custom.[SIP] Tier"
])
```

Keep the current values of the four target fields verbatim – Step 4 diffs against them.

### Step 2 – Sweep the full history

Window: from Company `customerFrom` (or the earliest Conversation) to today, unless `--since` was passed. A refresh is about the whole program, not the last two weeks – that is the difference from `/customer-whats-new`.

Run in parallel, sources per `agents/whats-new.md` Step 3, with these refresh-specific rules:

- **Planhat Conversations** – list metadata only (`subject`, `type`, `date`, `snippet`, `custom.Call Recording`), sorted `-date`, `LIMIT` 60. Never `description` or `transcript` in a multi-record `SELECT` (§ Two silent query failures).
- **Gmail is the body source for email Conversations.** Email-type Planhat Conversations synced from Gmail routinely carry an **empty `description`** – verified 2026-10-02. Search Gmail by the customer's domain and main contact (`from:` OR `to:`), then `get_thread` with `PLAIN_TEXT` on the threads that matter: session recaps, the session-ledger thread, escalations, and anything dated after the last session.
- **Gong `ask_account`** over the program window with `includeSources: true` – sessions held, what was set up, open actions both sides, escalations, sentiment, Spark interest. One wide question beats several narrow ones.
- **Internal Slack** – `slack_read_channel` on the Company `custom.Slack ID` (the internal `#account-*` channel), `LIMIT` 30–50. Handover summaries and prior debrief posts live here. Never read or post to `custom.External_Slack_Channel_ID` in this procedure.
- **Support tickets** – Planhat holds `ticket` Conversations but not their resolution. Use **Glean `chat`** to get current status and resolution for every ticket from the last ~90 days and every escalated ticket. Name ticket numbers. If Glean is unavailable, fall back to the Planhat `ticket` Conversation subject (it carries `[open]` / `[solved]` / `[closed]`) and mark resolution as unverified.
- **End Users** – see Step 5 for the lookup; pull once here.

### Step 3 – Build the picture

From the sweep, establish – citing a source for each:

1. **Session ledger.** Every delivered session with date, code (`A1`, `T1`…), topic, and who ran it. Compute used vs remaining. Cross-check against `custom.Services Session Entitlement` and against any ledger email the customer or PB sent. **A disputed or confirmed ledger in email wins over a count derived from Conversations** – flag disagreements, don't silently pick.
2. **Workstreams.** The goals set at kickoff (Sales Handoff fields, kickoff recap, handover posts) and the current status of each: done / in flight / blocked / not started.
3. **Open items**, split customer-side and PB-side, each with owner and since-when.
4. **Tickets and escalations** – open, recently closed, and anything that changes the relationship.
5. **Stakeholders** – who actually does what. **Verify every title against End User `position` before writing it anywhere.** Session notes and Slack posts get titles wrong; Planhat `position` is Salesforce-synced and is the tiebreaker. (2026-10-02: a "CPO" in internal notes was Head of Engineering per `position`.)
6. **Spark state** – enabled / engaged, any AI asks. Read `custom.Spark Exemption Context` first (newest dated entry is current state); see `context/planhat-schema.md` § Spark fields — Company.
7. **Risks** – momentum gap since last session, credit sensitivity, escalation pattern, single-threaded champion, time zone.
8. **Staleness in existing fields.** Compare each current field value against the sweep. A Next Step that still says to send something already sent, or an Engagement Plan whose "next session" was delivered months ago, is stale and must be called out by name.

### Step 4 – Refresh the four Company fields

All four are rich text. Single-line HTML in the `ph-editor` vocabulary only – § Rich Text Field Formatting. No `<h1>`–`<h6>`, lists with the `ph-editor__*` classes and an inner `<p>`, no literal newlines. Apply the user's voice rules to sentence content (en dashes, never em dashes). End the three reference fields with `<p></p><p><em>Last updated {D Mon YYYY} – {first name}</em></p>`.

**`custom.Architecture Details`** – how the customer's Productboard is built. Sections, skip any with nothing real: Workspaces (incl. secondary workspaces from Asset records) · Plan and seats · Product hierarchy · Teams in the workspace · Status workflow · Key boards · Integrations (one bullet per tool: what's connected, how, what's not configured) · Portal · Data hygiene.

**`custom.Organization Details`** – who they are and who we deal with. Sections: Company (what they bring to market, why they bought) · Product org · Champions and stakeholders (name – title from `position` – what they own) · Productboard team (current and previous) · Commercial · Growth signals. Unconfirmed attributions are written as unconfirmed.

**`custom.Engagement Plan`** – program plan. Sections: Goals · Workstreams (with status) · Package (used / remaining, ledger source) · Sessions delivered · Proposed remaining sessions · Open items · Risks. If the field was written by `engagement-planner` (`/customer-plan --full`), **refresh status in place** – update workstream status, sessions delivered, open items, risks – and do not restructure goals or phases without asking.

**`custom.Next Step`** – current state, overwritten, per § Company → `custom.Next Step`. Four short dated paragraphs: what was just done · **Waiting on** · **Watching** · **When it clears**. The schema says Next Step is written after a touchpoint lands. When this run only *drafts* the email, say so literally (`check-in email drafted, send pending`) – never write that something was sent – and tell the user to refresh Next Step after sending (or run `/inbox-triage`, which does it from the sent body).

**Write gate.**

| Field state | Action |
|---|---|
| Empty | Write directly. |
| Populated and stale or thin | Show a short before → after summary per field in chat, then write on the user's go-ahead. If the user already said to update these fields in the request, that counts as the go-ahead – state what is being replaced in the report. |
| Populated and still accurate | No write. Report as unchanged. A no-op write moves `updatedAt` and makes the account look busier than it is. |
| `--dry-run` | Never write. Show the full proposed HTML-rendered content in chat as readable text. |

Write all changed fields in **one** `update_model_record` on the Company, then read back all four.

### Step 5 – Enrich the customer's End User records

Execute `agents/post-session-debrief.md` step 3b **B through G** exactly – value lists, one-way movement, additive roles, rewrite-in-place read, `custom.AISE Read Reviewed` = run date, sequential writes, read-back. Only the candidate set differs.

**A. Candidate set (refresh variant).** Not session attendees – everyone the program history shows with real signal: anyone who attended a session, convened or escalated, owns a system or decision in scope, signed or sponsored, or is the person an open item routes to. A name only ever seen in a CC line is not signal.

**Lookup.** The account-wide list is capped at 100 records and can return custom fields blank on large accounts. Look candidates up **by email**:

```
list_model_records(
  MODEL: "End User",
  FILTER: {"email[equal to]": "<email>"},
  SELECT: ["name", "email", "position", "companyId",
           "custom.AISE Relationship", "custom.Engagement Role",
           "custom.AISE Read", "custom.AISE Read Reviewed"]
)
```

Then `get_model_record` on each match for the authoritative current values before writing. `MODEL` is `"End User"` with the space.

**Refresh-specific rules on top of 3b:**

- **Duplicates** – the same person on two or more End User records (same email local part across domains, or same name): pick the AISE contact per `context/planhat-schema.md` § Duplicate End Users – **`custom.PB_ID` filled wins**, then `position`, then most recent `lastTouch`. Fetch `PB_ID` per record with `get_model_record`. Enrich only the AISE contact, leave the others untouched, and report each duplicate under Gaps with both `_id`s. If an earlier run put AISE fields on the wrong record, move them per that section.
- **Placeholder names** (`Not provided`, an email as the name) – put the real name at the start of the read if the history establishes it. Never rename the record.
- **No record** – report under Gaps. Never create.
- A refresh that finds a contact's existing read still accurate writes nothing for them.

### Step 6 – Draft the customer check-in email (skip on `--no-email`)

Per `agents/email-drafter.md` and the style guide, with the Step 0 profile. Address the main contact. Subject `Productboard + {Customer} – Check-in and next session` (or what the initiative in scope prescribes).

Shape – Greeting → why now (1–2 sentences, tie to the last session) → **Where things stand** (what's live, what's open from the last session, package balance) → **Recent tickets** (only those the customer raised, status in plain terms, no internal names) → **How I can help next** (2–4 options drawn from the remaining balance and the proposed sessions in the Engagement Plan) → **Next steps** (owner – action) → sign-off.

- Booking link from the matching `custom.AISE Calendly *` field. Never a guessed or stale one-off link.
- **No invented commitments.** Anything the draft promises PB-side that the history does not already commit to is flagged to the user in the report.
- Do not reopen settled commercial points (ledger disputes, credits) unless the user asks.
- Plain-text `body` with no markdown, plus `htmlBody` with `<strong>` labels and `<ul>` lists – § Gmail copy-paste safety in the style guide.
- `create_draft` only. Never send.

### Step 7 – Draft the internal Slack update (skip on `--no-slack`)

Target: the internal channel in Company `custom.Slack ID`. Create with `slack_send_message_draft` (the user sends it). If the channel already has a draft (`draft_already_exists`) or the user isn't a member, put the message in chat instead and say why.

Shape – internal register, scannable:

```
:wave: *{Customer} – Account update | {D Mon}*

*Where we are*
• Last session … / Package … / What's live … / Spark …

*Support / escalations*
• {ticket} ({topic}) – {status}

*Next step*
• {what's going out, what's being offered}
• Planhat updated: {fields actually written}

cc <@AE> for visibility
```

Resolve the AE's Slack user ID from earlier channel messages; if not found, name them in plain text. No ARR or deal detail beyond what the channel already shows.

### Step 8 – Verify and report

Read back every Planhat write (Company fields in one read, each End User individually). Then report in chat, in this order:

1. **Where the account is** – 4–6 bullets.
2. **Drafts** – Gmail draft link, Slack draft channel, plus any line in the email that needs the user's call (soft commitments, tone).
3. **Planhat writes** – each Company field: written / replaced (with what was stale) / unchanged. Each contact: `name – Relationship: {before} → {after}; Engagement Role: +{added}; read written`. Promotions to `1. Key contact` named.
4. **Conflicts and gaps** – title mismatches, ledger disagreements, duplicates, people with no record, unconfirmed attributions.
5. **Sources** – Planhat Company URL (§ Planhat Record URLs), key Gmail threads, Gong calls, tickets.

---

## Critical rules

- **Never send.** Gmail and Slack are drafts only.
- **Never create, rename, archive or re-home** an End User. Contact writes are limited to the four 3b fields.
- **Never write a Company field that is still accurate**, and never replace a populated field without either the user's go-ahead or a report line naming what was replaced.
- **Next Step tells the truth about send state.** Drafted is not sent.
- **Titles come from End User `position`**, not from session notes or Slack.
- **Internal channel only** for the Slack draft – `custom.Slack ID`, never `custom.External_Slack_Channel_ID`.
- **Gmail, not Planhat, for email bodies.** An empty `description` on an email Conversation is normal, not evidence that nothing was said.
- **One Company write, sequential End User writes, read back everything.**
