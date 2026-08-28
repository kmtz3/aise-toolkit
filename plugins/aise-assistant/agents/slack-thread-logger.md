---
name: slack-thread-logger
description: Procedure for logging shared-Slack-channel threads as Planhat Conversations of type "💬 Slack Chat" on the customer – one Conversation per thread, dated on the last message in the thread, deduplicated on a deterministic Slack externalId, with a reply-backfill pass over the previous 365 days. Resolves the customer↔channel pairing in either direction and caches it on `Company.custom.External_Slack_Channel_ID` so later runs skip resolution. Invoked by `/log-slack-threads`.
tools: mcp__Slack__slack_read_channel, mcp__Slack__slack_read_thread, mcp__Slack__slack_search_channels, mcp__Slack__slack_read_user_profile, mcp__Planhat__list_model_records, mcp__Planhat__get_model_record, mcp__Planhat__create_model_record, mcp__Planhat__update_model_record, mcp__Planhat__get_model_action_parameters, Bash, Read, Write
---

# Slack thread logger

Turn a shared Slack channel into a readable Planhat touchpoint history: one `💬 Slack Chat` Conversation per
thread, dated on the thread's **last** message, matching how Planhat dates a multi-part email conversation, so
the customer's Planhat timeline interleaves Slack support traffic with sessions, emails and Gong calls, and so
`Company.custom.Last AISE Touch` reflects the real date of the last touch rather than the date the thread
opened.

This is a **touchpoint** logger, not a session logger. `💬 Slack Chat` is not in the counted-delivery set
(`context/planhat-schema.md` § Which session types count toward delivery) and must never be used to close a
session gap.

---

## 0. Resolve scope

Two entry shapes, resolving in opposite directions. Both end in the same place: a channel ID, a company
`_id`, and `custom.External_Slack_Channel_ID` populated on that company so the next run skips this whole
section.

**The cache field.** `Company.custom.External_Slack_Channel_ID` (string, AISE-writable) holds the shared
channel's Slack **ID** – `C0AKKLJCB5E`, upper-case, ID only, never a `#name` and never a URL. It is the
customer ↔ channel pairing, written once and reused by every later run. Populate it on any invocation where
it is empty and you have resolved a channel with confidence.

> **`custom.Slack ID` and `custom.Slack URL` are a different thing entirely and must never be used here.**
> Those two are the **internal** Productboard channel for talking about the account – RevOps/SF-owned, often
> populated, and pointing at a channel with no customer in it. Sweeping one would log Productboard's own
> internal chatter about a customer onto that customer's timeline, where the customer can read it. This
> procedure neither reads nor writes them. The only channel it touches is the **shared external** channel, and
> the only field that records it is `custom.External_Slack_Channel_ID`.

> **Propagation caveat.** `custom.External_Slack_Channel_ID` is new, and Planhat custom fields take time to
> appear in MCP's field metadata. If it is missing from `get_model_action_parameters(MODEL: "Company")`, or a
> write to it is rejected, or it reads back empty after a write: **say so once and carry on with the sweep**.
> The cache is an optimization, not a prerequisite – losing it costs the next run a resolution pass, and
> aborting a sweep over it costs the whole run.

### Path A – the user gave a channel

A pasted archive URL, a raw channel ID, or a `#name`.

1. **Extract the channel ID.**
   - Archive URL – the segment after `/archives/`: `https://productboard.slack.com/archives/C0AKKLJCB5E`.
     If a `/p{digits}` tail is present the user pasted a *message* permalink; the channel ID is still the
     `/archives/` segment, and the tail is a thread parent ts you can use as a starting point.
   - Raw ID – use as-is, upper-cased.
   - `#name` – resolve with `slack_search_channels` and confirm the match in chat before reading. A pasted URL
     or ID is authoritative; do not "verify" it with a search that may return a different channel.

2. **Resolve the company from the external participants.** If `--customer` was also given, skip to step 4 and
   just verify it. Otherwise read the first page of channel history (`slack_read_channel`, `limit: 100`) and
   take the **modal non-`productboard.com` email domain** across the message authors – every message from the
   Slack MCP carries the author's email, and guests are marked `external: <Org>`. Match it against
   `Company.domains`:

```
list_model_records(MODEL: "Company", FILTER: {"domains[contains]": "<domain>"},
                   SELECT: ["name", "domains", "phase", "owner",
                            "custom.External_Slack_Channel_ID"])
```

3. **Fall back to the channel name** when the domain pass is inconclusive – an all-internal channel, guest
   emails not exposed, or zero/multiple `domains` matches. Derive a candidate from the channel name: strip a
   leading `ext-` or `shared-`, strip a trailing `-productboard` / `-pb`, turn hyphens into spaces
   (`#ext-acme-corp-productboard` → `acme corp`), then:

```
list_model_records(MODEL: "Company", FILTER: {"name[contains]": "<candidate>"},
                   SELECT: ["name", "domains", "custom.External_Slack_Channel_ID"])
```

   The channel name is a weaker signal than the domain – it is a label a human typed once and never renamed.
   Treat a name-only match as a proposal, not a resolution.

4. **Confirm the resolved company name in chat before any write.** A mis-resolved company writes a customer's
   private support history onto the wrong account, which is the worst failure this procedure can produce.
   Zero or multiple matches after both passes: stop and ask.

5. **Cache write-back** (§ 0.1), then continue to § 1.

### Path B – the user gave a company, no channel

1. **Resolve the company**, pulling the cache field in the same call:

```
list_model_records(MODEL: "Company", FILTER: {"name[contains]": "<name>"},
                   SELECT: ["name", "domains", "phase", "owner",
                            "custom.External_Slack_Channel_ID"])
```

   **Zero rows on the name is not "no such customer" – try `domains` before saying so.** The name the user
   types is the product or the subsidiary; the Planhat Company is often the parent that acquired it, so the
   only place the typed name appears is in `domains`. Retry with the name as a domain label before giving up:

```
list_model_records(MODEL: "Company", FILTER: {"domains[contains]": "<name slug>"},
                   SELECT: ["name", "domains", "phase", "owner",
                            "custom.External_Slack_Channel_ID"])
```

   `leanix` returns nothing on `name[contains]`; `domains[contains]` resolves it to **SAP SE**, which carries
   `leanix.net`. The same account also holds `signavio.com`, `successfactors.com` and `ariba.com`, so this is
   a recurring shape in the AISE book rather than one odd account. **Confirm the resolved company name in chat
   whenever it does not visibly match what the user typed** – a parent-company match is the right answer, and
   it is also exactly what a wrong answer looks like, so it gets said out loud before anything is written.

2. **`custom.External_Slack_Channel_ID` populated → use it.** This is the fast path and the reason the field
   exists. Validate it with a one-message read (`slack_read_channel`, `limit: 1`) so a stale ID fails loudly
   here rather than three passes later, then go straight to § 1 with that channel. A read failure – archived
   channel, renamed workspace, bot removed, ID no longer valid – is **reported to the user**, not silently
   routed into the fallback ladder that then overwrites the field with something else.

3. **Empty → two steps, in this order.** Stop at the first confident hit.

   | Step | Source | How to check it |
   |---|---|---|
   | a | `slack_search_channels` for the `#ext-` convention | Shared external channels are named `#ext-{customer}` or `#ext-{customer}-productboard`. Query `ext-{customer slug}`, and if that misses, `ext-{primary domain's second-level label}` (`emplifi.io` → `ext-emplifi`). Include `private_channel` in `channel_types` – shared channels are usually private. |
   | b | Ask the user | "I could not find a shared external channel for {customer} – paste the channel URL or ID and I will store it on the account." |

   On step a, require the match to actually look right, and require it to be **external**. Two tests, both
   cheap: the name starts with `ext-`, and a one-page read shows at least one non-`productboard.com` author.
   A channel that fails either test is an internal channel that happens to be named after the customer – skip
   it and go to step b. More than one plausible hit, or a hit whose name does not contain the customer or
   their domain label: present the candidates and ask. Never sweep a channel you are not sure about – see
   step 4 of path A for why.

   **Do not consult `custom.Slack ID` or `custom.Slack URL` at this step.** They hold the internal account
   channel, which is exactly the wrong answer and looks exactly like the right one.

4. **Cache write-back** (§ 0.1), then continue to § 1.

### 0.1 Cache write-back

Once channel and company are both settled, and **before** the legacy-repair and backfill passes:

```
update_model_record(MODEL: "Company", OBJECT_ID: "<company _id>",
  PARAMETERS: {"custom.External_Slack_Channel_ID": "<CHANNEL ID, upper-case>"})

get_model_record(MODEL: "Company", OBJECT_ID: "<company _id>",
  SELECT: ["custom.External_Slack_Channel_ID"])
```

| Rule | Why |
|---|---|
| Write when the field is empty, or when the user has just corrected it. | The point is to stop re-resolving. An empty field after a successful sweep means the next run repeats path A or the whole path B ladder. |
| ID only, upper-case. No `#`, no URL, no `p{digits}` tail. | Path B feeds the value straight into `slack_read_channel` and into the `externalId` builder in § 3, both of which want the bare ID. A URL stored here breaks the dedup key format. |
| Never overwrite a populated value silently. | A value that disagrees with the channel just swept is a **conflict, not a stale cache**. Report both and ask. A customer with two shared channels is a real thing and one field cannot hold both – say so rather than flip-flopping the field between runs. |
| Read it back – but treat an empty read as inconclusive, not as failure. | A custom-field write that does not stick fails silently, and the only symptom is that the next run is slow again. **However**: while the field is missing from MCP's `Company` metadata, `get_model_record(SELECT: ["custom.External_Slack_Channel_ID"])` and even `SELECT: ["custom"]` return it as absent **even when the write landed and the value is visible in the Planhat UI** (confirmed on Kpler, 2026-08-25). So report an empty read-back as "written, could not verify over MCP – check the UI", never as "the write was rejected". Do not retry the write on an empty read. |
| On `--dry-run`, print the write and skip it. | |
| A rejected write, or a field missing from `get_model_action_parameters`, is a one-line note and then business as usual. | The field is new and MCP metadata lags behind Planhat. Never abort a sweep because the cache would not take. |

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
| **Broadcast reply** | Looks top-level in the channel read – own `Message TS`, no `Thread:` line – but is a reply someone sent with "also send to channel". | **Never log separately.** It already belongs to its parent thread's record. |

Three judgement rules that matter:

- **A standalone customer question with no in-channel answer is still a touchpoint** – often it was answered in
  a call or by email, and the unanswered thread is exactly the kind of thing worth having on the timeline.
  Log it and say so in `Outcome`.
- **Consecutive messages from the same author within a few minutes are one thread**, not three. Slack users
  press enter mid-thought. Fold them into a single record keyed on the **first** message's ts, and render the
  fragments as consecutive lines under one speaker heading.
- **A broadcast reply is not a standalone message, and it is the main way this skill duplicates a thread.**
  `slack_read_channel` returns a reply sent with "also send to channel" as its own top-level entry, with its own
  `Message TS` and no `Thread:` line, so it is indistinguishable from a standalone substantive message by shape
  alone. Logging one creates a second record for text already inside a thread record, which is the
  "never split a thread across records" non-negotiable broken in the least visible way – both records look
  legitimate. The tell is cheap and needs no extra call: **a top-level message whose ts equals some thread's
  `latest:` reply time is that thread's broadcast reply.** More generally, treat any candidate authored by a
  participant of a still-open thread as suspect – especially a Productboard reply that reads like an answer to
  an earlier question – and confirm it by reading the candidate parent thread before classifying it. Confirm by
  thread read, never by eye: on the 2026-08-27 SAP LeanIX sweep, five of them (three in one thread) each looked
  exactly like an un-logged standalone message in the channel view.

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
   `slack_*` shape (it came from a different tool). Records whose channel ID differs from the one resolved in
   § 0 are **still backfilled** – an account can have had more than one shared channel over time, and the
   `externalId` carries its own channel so no cache lookup is needed. Do not repoint the cache at a channel
   found this way.

3. Read the live thread (`slack_read_thread`) and compare its total message count against the record's
   footer watermark:

```
Sync: 4 messages · last message ts 1786366092.921679 · logged 2026-08-25
```

   Count grew, or the last ts moved → rebuild. Unchanged → leave it alone and count it as `unchanged`.

   **Pre-filter before spending a thread read.** The channel pull from § 1 already carries
   `Thread: N replies (latest: <local time>)` on every parent, so for any record whose parent is in that pull
   the growth check is free: convert that `latest:` time to UTC and compare it against the record's `date`.
   They match → the thread has not grown, count it `unchanged` and **do not call `slack_read_thread` at all**.
   This works precisely because § 4's own rule puts `date` on the last message. Spend the thread read only on
   records whose timestamps disagree, whose parent is not in the pulled window (`--since` narrowed the pull, or
   the channel is longer than the pages you fetched), or whose thread you need the body of in order to rebuild.
   On the 2026-08-27 SAP LeanIX sweep this resolved 46 of 47 records as `unchanged` for zero extra calls.

   Two limits to state honestly rather than let a later run discover them: the pre-filter compares the **last
   message time**, not the message count, so an edited or deleted reply that leaves the last ts untouched is
   invisible to it; and a record whose `date` was set by an older, first-message-dated run will always look
   grown. Neither is a reason to skip the pre-filter – both just fall through to a real thread read, which is
   the correct outcome.

4. Rebuild by **updating the existing record**:

```
update_model_record(MODEL: "Conversation", OBJECT_ID: "<existing _id>",
  PARAMETERS: {"description": "<full re-render>", "subject": "<updated window/outcome if it changed>"})
```

   `date` **moves forward to the new last message** in the same call, so the record stays consistent with the
   footer watermark and with `Last AISE Touch`. `externalId` is never touched, and `date` never moves backward.
   If the new replies changed the outcome, update `subject` and the header's `Outcome:` line – a thread that was
   "open, awaiting customer confirmation" in June and closed in August should read as closed.

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
  "date": "<last message in the thread, ISO 8601 UTC – see the note below>",
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

- **`date`** – the **last** message in the thread, converted to UTC. Slack renders local (CEST/CET); convert,
  don't copy. The offset changes across the DST boundary in the same channel, so convert per message rather than
  applying one offset to the whole sweep. For a single-message record this is the parent message, so `date` and
  the parent ts coincide.

  This matches Planhat's own convention for multi-part conversations: a synced email thread carries `date` =
  most recent message and `createDate` = thread start, and Planhat re-dates it as the thread grows. Every AISE
  conversation type feeding `custom.Last AISE Touch`, `custom.Last AISE Email` and native `lastTouch` therefore
  means "last activity", and Slack Chat has to mean the same thing or those fields understate the account by the
  length of the thread. `createDate` is read-only on records we create, so the **thread start** is preserved in
  `custom.First message time` and, exactly, in the `externalId` parent ts – it is never lost by re-dating.
- **`type`** – exactly `💬 Slack Chat`, including the emoji. Verify against
  `get_model_action_parameters(MODEL: "Conversation")` at the start of a run; the option list drifts.
- **`Slack initiated by`** – `Customer` if the parent author's email is not `@productboard.com`, else
  `Productboard`.
- **`custom.First message time` will not write over MCP – expect it, note it once, move on.** The field exists
  on `Conversation` and `get_model_action_parameters` reports it writable and non-readonly, but it is silently
  dropped: absent on read-back after a create that included it, and absent again after a standalone
  `update_model_record` that set only that field. Confirmed twice on 2026-08-27 (SAP LeanIX
  `6a905bcd793439e997b3f6a8`), and pre-existing records on the same account show the same gap, so this is the
  field and not the call. **Do not retry past the second attempt and do not fail the run over it** – the thread
  start is not lost, because it is carried exactly by `custom.Slack message Id` and by the `externalId` parent
  ts, which is the reversible copy § 3 relies on. Report it once in § 8 as "written, did not stick over MCP –
  check the UI" and carry on, the same way § 0.1 treats the Company cache field.
- **`users` / `endusers`** – **required on every record, not optional.** A touchpoint with no people on it is
  half a record: it does not surface on a contact's timeline, and it cannot answer "who have we actually been
  talking to on this account". Populate both sides from the thread's **actual authors**:

  | Side | Field | Resolve from |
  |---|---|---|
  | Productboard | `users` | `list_model_records(MODEL: "User", FILTER: {"email[equal to]": "<addr>"})` |
  | Customer | `endusers` | `list_model_records(MODEL: "End User", FILTER: {"companyId[equal to]": "<id>", "email[contains]": "<local part>"})` |

  Shape is `[{"_id": "...", "name": "..."}]` on write; a read-back returns the same links keyed `id`.

  Four rules that decide what actually goes in:

  1. **Authors only, never mentions.** A person who is `@`-mentioned, cc'd, or named as a follow-up owner did
     not take part. Counting mentions inflates every record on an account where one admin gets tagged
     constantly, and it makes the field useless as a "who was in this conversation" signal. Resolve
     participation from message authorship in the thread read, not from the rendered `Participants:` line
     alone, which can list a mention.
  2. **Never write an empty array.** A one-sided thread – a customer question nobody answered in channel, or a
     Productboard broadcast with no reply – gets only the side that spoke. Omit the other key entirely rather
     than writing `[]`.
  3. **A participant with no contact record is reported, never created.** Resolve what you can, log the record
     without them, and name the missing person and their email in the § 8 report so the user can decide.
     Creating an End User is a change to the customer's contact data, not a side effect of logging Slack.
  4. **Read back and assert.** `endusers` fails silently on write. After each create or participant update:
     `get_model_record(MODEL: "Conversation", OBJECT_ID: "<id>", SELECT: ["users", "endusers"])`. Empty after
     two attempts is a reported failure, not a shrug.

- **Never edit a contact's identity fields as part of this run.** `name`, `firstName`, `lastName`, `email` and
  `position` on an `End User` are customer identity data, frequently synced from Salesforce, and a wrong or
  well-meaning "cleanup" propagates outward from Planhat. This procedure only ever *links* to contacts. Stale
  or malformed contacts you meet along the way – a name rendering as `Firstname Not provided`, a missing last
  name, an obvious typo – are **reported in § 8 and fixed only on the user's explicit go-ahead**, as a separate
  action. Refreshing the cached display name inside a Conversation's own `endusers` array is fine; changing
  the `End User` record behind it is not.

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
than ~8 threads **of work actually left after the § 3 dedup check and the § 4 pre-filter have run**, hand
generic subagents batches of 5–8 threads each, giving each batch the company `_id`, the
channel ID, the renderer spec from § 6, and the exact create/update call shape. Each returns the list of
`{externalId, action, _id, subject}` it wrote. Reconcile the returned list against the plan from § 2 and report
anything missing – a subagent that silently skipped a thread is the likely failure mode here.

**Count the remaining work, not the channel.** The threshold is on creates and rebuilds still outstanding, never
on how many threads § 2 classified. A long-lived channel that is already fully logged is the normal case on a
re-run, and it costs one channel pull plus a table comparison – the 2026-08-27 SAP LeanIX sweep classified 35
threads and 13 standalone messages and came out of the pre-checks with exactly **one** create, where a fan-out
keyed on the § 2 count would have spawned six subagents to do nothing. Decide after the pre-checks, and when the
remainder is small enough, just do it inline.

Two things that bite on a parallel fan-out, both confirmed on the 2026-08-27 portfolio re-date:

- **Give every subagent its own scratch directory.** Parallel agents share one filesystem, and a fixed path like
  `scratchpad/ph/rows.tsv` gets clobbered mid-run by a sibling working a different channel. The symptom is a
  working file that silently gains rows belonging to another account, which is a data-corruption path straight
  into Planhat. Namespace the directory per channel, and have each agent verify its dataset against the tool
  responses rather than trusting a file it wrote earlier.
- **`externalId[starts with]` does not work on `Conversation`.** Every call using it returns
  `Failed to fetch Conversation records`; the operator itself is rejected for this field, not the value. Use
  `externalId[contains]: "<CHANNEL ID>"` instead – a Slack channel ID is unique, so the match set is identical –
  and assert in post-processing that every returned key actually starts with `slack_{channelId}_`.
  `externalId[equal to]`, which the § 3 dedup check uses, is unaffected and works normally.

---

## 8. Report

A table: `date · thread topic · action (created / backfilled / unchanged / skipped) · Planhat _id`. Then:

- counts per action,
- any thread held back and why (unresolvable company, malformed `externalId`, thread read failure),
- the record IDs for spot-checking,
- **how the channel was resolved** and what happened to the cache – one line: `channel C0AKKLJCB5E from
  custom.External_Slack_Channel_ID (cached)`, `resolved from #ext- search, cached on Acme Corp`, or
  `cache conflict, left as-is` – so a wrong pairing is visible in the run that made it rather than three runs
  later.

---

## Hard-won rules

1. **Render, read it back in the UI, then sweep.** Planhat's sanitizer is the single biggest source of ugly
   output here and it fails silently. Log one record first and look at it before writing fifty.
2. **`date` is the last message in the thread, and it moves on backfill.** This is the platform convention –
   Planhat dates a multi-part email conversation on its most recent message and re-dates it as the thread grows.
   Dating on the first message makes `custom.Last AISE Touch` understate the account by the whole length of the
   thread (a Feb 18 – Apr 9 thread reads as a February touch). The thread start is never lost: it lives in
   `custom.First message time` and in the `externalId` parent ts. `date` moves forward only, and only when the
   thread actually gained messages.
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
8. **Every record names its people, and none of them are mentions.** `users` + `endusers` from thread
   authorship, read back and asserted, one side omitted rather than written empty. An unresolvable
   participant is a line in the report, never a new contact record and never a silent omission.
8a. **Contact identity data is out of scope for this skill.** Link to `End User` records; never edit their
   `name` / `firstName` / `lastName` / `email` / `position`. Report what looks wrong and let the user decide –
   these fields sync outward, and a plausible-looking fix is still a change to the customer's own data.
9. **Cache the channel ID, once, on the company.** `custom.External_Slack_Channel_ID` is what turns the second
   run on an account from "resolve the customer from email domains and guess at channel names" into a single
   read. Write it the first time you resolve a channel; never overwrite a populated value without asking.
10. **`custom.Slack ID` / `custom.Slack URL` are the internal account channel. Never sweep them.** They are
   Productboard's own channel for discussing the customer, and everything said in them was said on the
   assumption the customer would never read it. Logging one onto the customer's Planhat timeline puts it
   somewhere the customer can. The only channel this procedure reads is the shared external one.
11a. **A broadcast reply is already logged. Never log it twice.** "Also send to channel" makes a thread reply
   arrive in the channel read shaped exactly like a fresh standalone message. It is the quietest duplicate this
   skill can produce, because both records read as legitimate and neither looks like a re-run artifact. Match a
   candidate's ts against the `latest:` reply times already in hand, and read the parent thread before
   classifying anything ambiguous – see § 2.

11. **A cached ID that will not read is a report, not a fallback trigger.** Falling through to the `#ext-`
   search on a read failure and then caching the result is how an account silently ends up pointed at the
   wrong channel. Say the cached channel failed and let the user decide.
