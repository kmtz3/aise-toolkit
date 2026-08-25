---
name: slack-thread-logger
description: Procedure for logging shared-Slack-channel threads as Planhat Conversations of type "💬 Slack Chat" on the customer – one Conversation per thread, dated on the first message, deduplicated on a deterministic Slack externalId, with a reply-backfill pass over the previous 365 days. Invoked by `/log-slack-threads`.
tools: mcp__Slack__slack_read_channel, mcp__Slack__slack_read_thread, mcp__Slack__slack_search_channels, mcp__Slack__slack_read_user_profile, mcp__Planhat__list_model_records, mcp__Planhat__get_model_record, mcp__Planhat__create_model_record, mcp__Planhat__update_model_record, mcp__Planhat__get_model_action_parameters, Bash, Read, Write
---

# Slack thread logger

Turn a shared Slack channel into a readable Planhat touchpoint history: one `💬 Slack Chat` Conversation per
thread, dated on the thread's first message, so the customer's Planhat timeline interleaves Slack support
traffic with sessions, emails and Gong calls in the right order.

This is a **touchpoint** logger, not a session logger. `💬 Slack Chat` is not in the counted-delivery set
(`context/planhat-schema.md` § Which session types count toward delivery) and must never be used to close a
session gap.

---

## 0. Resolve scope

**Channel.** Accept any of: a pasted archive URL (`https://<workspace>.slack.com/archives/C0AKKLJCB5E` –
the ID is the segment after `/archives/`), a raw channel ID, or a `#name`. For a name, resolve with
`slack_search_channels` and confirm the match in chat before reading. A pasted URL is authoritative – do not
"verify" it with a search that may return a different channel.

**Company.** If `--customer` is given, resolve it:

```
list_model_records(MODEL: "Company", FILTER: {"name[contains]": "<name>"},
                   SELECT: ["name", "domains", "phase", "owner"])
```

If not given, derive it from the channel's external participants. Every message from the Slack MCP carries the
author's email; take the modal non-`productboard.com` domain across the channel and match it against
`Company.domains`. Confirm the resolved company name in chat before any write – a mis-resolved company writes
a customer's private support history onto the wrong account, which is the worst failure this procedure can
produce. Zero or multiple matches: stop and ask.

**Window.** `--since` filters on the thread's **first** message, not its last reply. Default is the whole
channel.

---

## 1. Pull the channel

`slack_read_channel` returns newest-first and paginates. Read with `limit: 100` and follow `next_cursor`
until `pagination_info` reports no more messages. The response is large – write it to a scratch file and parse
it with a script rather than holding every message in context:

```
Bash: python3 - <<'PY'   # parse the saved tool-result file into structured JSON
PY
```

Each top-level message gives you: author name + email + Slack user ID, an `external: <Org>` marker for guests,
the local timestamp, `Message TS` (the parent ts – this is the thread key), a `Thread: N replies` line when it
has replies, `Files:` and `Reactions:` lines.

---

## 2. Classify every top-level message

| Class | Test | Action |
|---|---|---|
| **Thread** | Has a `Thread: N replies` line | Log |
| **Standalone substantive** | No replies, but carries a real question, decision, status update or session recap | Log |
| **Noise** | Join/leave notices, "X was added to this channel", canvas-update notices, channel-description changes, bare emoji or reaction-only messages, pure logistics one-liners ("booked it for Friday", "thanks!") | **Never log** |

Two judgement rules that matter:

- **A standalone customer question with no in-channel answer is still a touchpoint** – often it was answered in
  a call or by email, and the unanswered thread is exactly the kind of thing worth having on the timeline.
  Log it and say so in `Outcome`.
- **Consecutive messages from the same author within a few minutes are one thread**, not three. Slack users
  press enter mid-thought. Fold them into a single record keyed on the **first** message's ts, and render the
  fragments as consecutive lines under one speaker heading.

Report the counts (`N threads · M standalone · K noise`) before writing anything, and on `--dry-run` stop here.

---

## 3. externalId – the dedup key

**One format, always filled, no exceptions.** This is the only thing standing between a re-run and a duplicated
timeline, so it is written on every create and verified on every read-back.

### Canonical format

```
slack_{channelId}_{parentTs with the dot removed}

e.g.  slack_C0AKKLJCB5E_1786006420396099
      slack_C02N37LS25C_1786373402520939
```

Build it with exactly this, never by hand:

```python
def slack_external_id(channel_id: str, parent_ts: str) -> str:
    # channel_id: "C0AKKLJCB5E" (upper-case, as Slack returns it)
    # parent_ts:  "1786006420.396099" (the THREAD PARENT ts, never a reply ts)
    return f"slack_{channel_id.strip().upper()}_{parent_ts.strip().replace('.', '')}"
```

Reverse it with `ts = digits[:10] + "." + digits[10:]`.

Fixed choices, and why each one is not negotiable:

| Element | Rule | Why |
|---|---|---|
| Prefix | literal `slack_` | Distinguishes these records at a glance from the Notion-page-ID and calendar-event-ID writers already using `externalId` on `Conversation`. |
| Separator | underscore `_`, both positions | One separator only. Hyphens were used in an early record and had to be repaired – see § Legacy repair. |
| Channel ID | Slack's ID, upper-case, never the `#name` | Channel names get renamed; IDs do not. A renamed channel must not orphan its history. |
| Timestamp | thread **parent** ts, dot removed | Digits-only is exactly the form Slack uses in a permalink (`/archives/{channel}/p{digits}`), so the key is both reversible and pasteable. |
| Case | prefix lower, channel upper | Deterministic. Planhat matching is exact. |
| Scope | one per company | Planhat enforces uniqueness per company, which is the level dedup needs. |

Never include the customer name, the date, the subject, a hash, or a run counter. Anything that can change
between runs cannot be part of a dedup key.

### Mandatory pre-create check

```
list_model_records(MODEL: "Conversation",
  FILTER: {"externalId[equal to]": "slack_<channel>_<tsdigits>"},
  SELECT: ["subject", "date", "companyId", "externalId", "description"])
```

A hit is a **backfill candidate** (§ 4), never a create. Zero hits, and only then, create.

### Mandatory post-create read-back

`externalId` is silently droppable, and a record created without one is invisible to every later run – it will
be recreated on the next sweep, and the duplicate will look like a legitimate new thread. So after every
create:

```
get_model_record(MODEL: "Conversation", OBJECT_ID: "<new _id>",
  SELECT: ["externalId", "date", "subject", "companyId"])
```

Assert the returned `externalId` is byte-identical to the string you built. On mismatch or empty, immediately
`update_model_record` to set it, then read back again. If it will not stick after two attempts, stop the run
and report – do not keep creating records that cannot be deduplicated.

### Legacy repair pass

Run this once per company at the start of any invocation, before the backfill pass. Pull every
`💬 Slack Chat` record on the company and check each `externalId` against the canonical shape
`^slack_[A-Z0-9]+_\d{16}$`:

| State found | Repair |
|---|---|
| Canonical | Leave it. |
| Wrong separators or dotted ts (e.g. `slack-C02N37LS25C-1786373402.520939`) | Reparse channel + ts out of it, rebuild canonically, `update_model_record`. |
| Empty or missing | Recover the parent ts from `custom.Slack message Id`; if that is empty, from the `p{digits}` segment of the permalink in the description footer. Recover the channel ID the same way. Rebuild and write. |
| Not recoverable | Report it as `NEEDS EXTERNALID` with the record `_id` and subject. Do not guess, and do not create a replacement record – a wrong key is worse than a missing one, because it can collide with a real thread. |

Repairs touch `externalId` only. Never re-date and never re-subject a record during this pass.

Two live examples of the drift this pass exists for, both found and fixed on 2026-08-25:

- Emplifi `6a7f4ec562ab7a106e3d2919` carried `slack-C02N37LS25C-1786373402.520939` – hyphens plus a dotted ts.
- That same record is also dated on its **last** message (Aug 14) while its parent ts is Aug 10, because it was
  logged as a multi-day channel digest rather than a single thread. Flag that shape when you meet it; a digest
  is not a thread and its `date` needs a human decision, not an automatic re-date.

## 4. Backfill pass – threads that gained replies

Run this **before** the create pass, and run it on every invocation unless `--new-only` is passed. Slack
threads stay alive for months; a record logged in March is routinely wrong by August.

1. Pull existing Slack records on the company:

```
list_model_records(MODEL: "Conversation",
  FILTER: {"companyId[equal to]": "<id>", "type[equal to]": "💬 Slack Chat"},
  SELECT: ["subject", "date", "externalId", "description"], LIMIT: 100)
```

   Page until a request returns zero records (Planhat truncates large responses without an error – see
   `agents/session-log-auditor.md` rule #2). Keep the window to **records dated within the last 365 days**;
   older threads are effectively closed and re-reading them every run is waste.

2. For each record, parse `externalId` → channel + parent ts. Skip any whose `externalId` does not match the
   `slack_*` shape (it came from a different tool).

3. Read the live thread (`slack_read_thread`) and compare its total message count against the record's
   footer watermark:

```
Sync: 4 messages · last message ts 1786366092.921679 · logged 2026-08-25
```

   Count grew, or the last ts moved → rebuild. Unchanged → leave it alone and count it as `unchanged`.

4. Rebuild by **updating the existing record**:

```
update_model_record(MODEL: "Conversation", OBJECT_ID: "<existing _id>",
  PARAMETERS: {"description": "<full re-render>", "subject": "<updated window/outcome if it changed>"})
```

   `date` and `externalId` are never touched. If the new replies changed the outcome, update `subject` and the
   header's `Outcome:` line – a thread that was "open, awaiting customer confirmation" in June and closed in
   August should read as closed.

**Why the watermark lives in the footer.** There is no writable field on `Conversation` for a sync cursor
(`numberOfParts` is read-only), so the footer line is the cursor. It has to be written on every create and
every rebuild, in exactly the format above, or the next run cannot tell a grown thread from a stale one.

---

## 5. Create pass – fields to write

```
create_model_record(MODEL: "Conversation", PARAMETERS: {
  "type": "💬 Slack Chat",
  "companyId": "<planhat company _id>",
  "source": "Slack",
  "date": "<first message, ISO 8601 UTC>",
  "subject": "Slack – #<channel>: <what the thread was about> (<Mon D–D, YYYY>)",
  "externalId": "<slack_external_id(channel, parent_ts) – see § 3, required, never omitted>",
  "description": "<rendered HTML – § 6>",
  "custom": {
    "Slack message Id": "<parent ts, dotted form>",
    "Slack initiated by": "Customer" | "Productboard",
    "First message time": "<YYYY-MM-DD HH:MM <tz>>"
  }
})
```

- **`date`** – the first message, converted to UTC. Slack renders local (CEST/CET); convert, don't copy. The
  offset changes across the DST boundary in the same channel, so convert per message rather than applying one
  offset to the whole sweep.
- **`type`** – exactly `💬 Slack Chat`, including the emoji. Verify against
  `get_model_action_parameters(MODEL: "Conversation")` at the start of a run; the option list drifts.
- **`Slack initiated by`** – `Customer` if the parent author's email is not `@productboard.com`, else
  `Productboard`.
- **`users` / `endusers`** – optional and off by default. `endusers` fails silently on write, so if you do
  populate it, read the record back and confirm.

---

## 6. Description HTML – what Planhat's editor actually accepts

Planhat's rich-text field is not a browser. It sanitizes aggressively and it does not report what it dropped.
These constraints were established by rendering a record and reading it back in the UI:

| Never use | What Planhat does with it |
|---|---|
| `<div>` with `style` | Strips `background`, `border`, `border-left`, `border-radius`, `color`, `padding` – the box disappears and the empty container leaves a large vertical gap |
| `<ol>` / `<ul>` | Mangles into a broken ladder – `1.` / blank / `2.` / blank – with the real text on the even items |
| `<table>` | Renders with visible cell borders and phantom empty rows and columns |
| Literal `\n` between elements | Converted into additional paragraph breaks; stacked newlines produce large blank runs |
| Inline `color` on text | Dropped, so colour-coded speakers all render identical black |

**Safe set:** `<p>` · `<br>` · `<b>` · `<i>` · `<a href>` · `<hr>`. Emit the whole description as a **single
line with no literal newlines**.

### Layout

```
<p><b>Slack thread – #{channel}</b><br>
<b>Started by:</b> {name} ({org}) · {Day Mon D, YYYY, HH:MM tz}<br>
<b>Participants:</b> {name (org), …}<br>
<b>Window:</b> {Mon D – Mon D, YYYY} · {N} messages<br>
<b>Topic:</b> {one or two sentences – what was actually being asked}<br>
<b>Outcome:</b> {resolved / open / superseded, and what the answer was}</p>
<hr>
<p><b>{Speaker}</b> · {Org} · {Day Mon D, HH:MM}<br>
{message text, lines joined with <br>}<br>
<i>📎 {filename} – {what it shows}</i></p>
<hr>
… one <p> per message, <hr> between …
<hr>
<p><b>Follow-ups</b><br>
<b>{Owner}</b> – {action}. <i>{Done – confirmed {date}.}</i><br></p>
<p><i>Source: Slack #{channel} · times in {tz} · <a href="{permalink}">open thread in Slack</a><br>
Sync: {N} messages · last message ts {ts} · logged {YYYY-MM-DD}</i></p>
```

- Speaker heading carries the side (`· Kpler` vs `· Productboard`) since colour is stripped.
- Numbered or bulleted content inside a message: manual `1.` / `2.` or `•` prefixes on `<br>`-separated lines.
- Rewrite Slack mention tokens (`<@U077VT8D2FP|Klara>`) as `<b>@Klara</b>`; resolve bare `<@Uxxxx>` with
  `slack_read_user_profile`. Convert Slack links (`<url|label>`) to `<a href="url">label</a>`.
- Attachments are **noted, not uploaded** – a caption line naming the file and what it shows. Planhat
  attachments are a separate model; do not try to inline images.
- Keep the message text close to verbatim. Fix obvious typos and drop greeting filler, but do not summarize a
  message away – the value of these records is that they are readable transcripts. Summarize only in `Topic`
  and `Outcome`.
- Permalink: `https://<workspace>.slack.com/archives/{channelId}/p{tsdigits}`.
- **No em dashes anywhere in the rendered output.** Use a spaced en dash ( – ) instead, in `subject`, in the
  header block, and in the message text. This is a standing house rule (`context/communication-style-guide.md`)
  and it applies to Planhat records the same as to drafts. Slack messages that contain an em dash get it
  swapped on the way in.

### `subject`

`Slack – #{channel}: {topic} ({Mon D–D, YYYY})`. The topic phrase should be searchable – name the feature or
system in play (`Intercom integration`, `Jira sync`, `team permissions`), not `question from customer`.

---

## 7. Fan-out

The per-thread work (read thread → render → dedup check → write) is independent per thread. Batch it: for more
than ~8 threads, hand generic subagents batches of 5–8 threads each, giving each batch the company `_id`, the
channel ID, the renderer spec from § 6, and the exact create/update call shape. Each returns the list of
`{externalId, action, _id, subject}` it wrote. Reconcile the returned list against the plan from § 2 and report
anything missing – a subagent that silently skipped a thread is the likely failure mode here.

---

## 8. Report

A table: `date · thread topic · action (created / backfilled / unchanged / skipped) · Planhat _id`. Then:

- counts per action,
- any thread held back and why (unresolvable company, malformed `externalId`, thread read failure),
- the record IDs for spot-checking.

---

## Hard-won rules

1. **Render, read it back in the UI, then sweep.** Planhat's sanitizer is the single biggest source of ugly
   output here and it fails silently. Log one record first and look at it before writing fifty.
2. **`date` is the first message.** Dating on the last reply scatters a thread that ran for three weeks into
   the wrong place on the timeline, and makes the backfill pass look like it created a duplicate.
3. **Never re-create on backfill.** Always `update_model_record` on the existing `_id`.
3a. **`externalId` is never optional and never improvised.** One format, built by the § 3 helper, written on
   every create, read back and asserted on every create, repaired to canonical on every legacy record found.
   A record with a missing or off-format key is invisible to the next run and will be silently duplicated.
4. **The footer `Sync:` line is load-bearing.** Omit it and the next run either re-reads every thread or
   misses new replies entirely.
5. **Noise is never logged.** Join notices and bare emoji on a customer's Planhat timeline destroy the value
   of the timeline faster than missing threads do.
6. **Slack is read-only from this procedure.** No posting, no reacting, no thread replies.
7. **`💬 Slack Chat` is uncounted.** Never present logging Slack threads as increasing session delivery.
