---
name: slack-thread-logger-internal
description: Procedure for logging internal Productboard `#account-**` Slack channel threads as Planhat Conversations of type "Internal Alignment" on the customer – one Conversation per thread, dated on the last message in the thread, deduplicated on a deterministic Slack externalId, with a reply-backfill pass over the previous 365 days. Resolves the customer↔channel pairing in either direction and, on confirmation, caches it on `Company.custom.Slack ID` (`custom.Slack URL` is a derived formula field, never written directly). Invoked by `/log-slack-threads-internal`.
tools: mcp__Slack__slack_read_channel, mcp__Slack__slack_read_thread, mcp__Slack__slack_search_channels, mcp__Slack__slack_read_user_profile, mcp__Planhat__list_model_records, mcp__Planhat__get_model_record, mcp__Planhat__create_model_record, mcp__Planhat__update_model_record, mcp__Planhat__get_model_action_parameters, Bash, Read, Write
---

# Slack thread logger — internal account comms

Turn an **internal** Productboard `#account-**` Slack channel into a readable Planhat touchpoint history: one
`Internal Alignment` Conversation per thread, dated on the thread's **last** message, matching how Planhat
dates a multi-part email conversation, so the customer's Planhat timeline interleaves internal-alignment
traffic with sessions, emails and shared-channel Slack chat, and so `Company.custom.Last AISE Touch`
(Planhat's native `lastTouch`) reflects the real date of the last touch rather than the date the thread opened.

This is the **sibling** of `agents/slack-thread-logger.md`, not a replacement. That procedure sweeps the
**shared external** channel (`#ext-{customer}`) and logs `💬 Slack Chat`. This one sweeps the **internal**
Productboard-only channel (`#account-{customer}`) and logs `Internal Alignment`. Format, dedup mechanics
(`externalId`, the footer watermark, the backfill/legacy-repair passes) and the fan-out pattern are identical
between the two – only the channel, the field it's cached on, the Planhat `type`, and the participant handling
differ. Where a step is unchanged from the external version it is stated here in full rather than "see the
other file", so this procedure stands alone.

`Internal Alignment` is not in the counted-delivery set (`context/planhat-schema.md` § Which session types
count toward delivery) and must never be used to close a session gap – same rule as `💬 Slack Chat`. It **is**
a valid touchpoint that Planhat's native `lastTouch` picks up like any other Conversation; it just never moves
`custom.Last AISE Session` or a delivered-session count.

---

## 0. Resolve scope

Two entry shapes, resolving in opposite directions. Both end in the same place: a channel ID, a company `_id`,
and – once the user has confirmed the value in chat – `custom.Slack ID` populated on that company so the next
run skips this whole section. (`custom.Slack URL` updates on its own, as a formula derived from `custom.Slack
ID` – there is nothing to write there.)

**The cache field.** `Company.custom.Slack ID` (channel ID, e.g. `C02N37LS25C`) is the internal-account-channel
pairing. Unlike `custom.External_Slack_Channel_ID` on the external skill, it is populated by RevOps/SF sync on
a large share of accounts already, and a write here syncs back toward Salesforce – **write only after the user
has confirmed the specific channel in chat**, never on an unconfirmed guess, even though the API will accept
the write silently.

**`Company.custom.Slack URL` (the same channel as an `/archives/` link) is a locked formula field derived from
`custom.Slack ID` – never write it.** It updates on its own once `custom.Slack ID` is set; a direct write to it
is not just unnecessary, it targets a read-only field.

> **`custom.External_Slack_Channel_ID` is a different thing entirely and must never be used here.** That field
> is the **shared external** channel with the customer in it – the one `/log-slack-threads` sweeps. Reading or
> writing it from this procedure would point an internal-comms sweep at the customer-facing channel or
> vice-versa. The only field this procedure writes is `custom.Slack ID` — `custom.Slack URL` is read-only and
> is never targeted by a write.

### Path A – the user gave a channel

A pasted archive URL, a raw channel ID, or a `#name`.

1. **Extract the channel ID** – identical to the external skill's step: archive-URL segment after `/archives/`,
   raw ID upper-cased, or `#name` resolved via `slack_search_channels` and confirmed before reading.

2. **Resolve the company.** If `--customer` was also given, skip to step 4 and just verify it. Otherwise read
   the first page of channel history (`slack_read_channel`, `limit: 100`) and derive a candidate from the
   channel name: strip a leading `account-` (or `internal-`), turn hyphens into spaces
   (`#account-acme-corp` → `acme corp`), then:

```
list_model_records(MODEL: "Company", FILTER: {"name[contains]": "<candidate>"},
                   SELECT: ["name", "domains", "phase", "owner", "custom.Slack ID"])
```

   Zero or ambiguous matches – retry the candidate as a `domains[contains]` slug (the same parent-company
   pattern as the external skill: `leanix` misses on `name`, resolves to **SAP SE** via `leanix.net`).

3. **Confirm this is actually an internal channel before doing anything else.** Read the first page
   (`slack_read_channel`, `limit: 100`) and check the message authors: an internal `#account-**` channel is
   **all or nearly all `@productboard.com`** authors. A channel with a substantial share of non-`productboard.com`
   authors is a shared/guest channel wearing an `#account-` name by accident – that is the external skill's
   target, not this one. **Stop and ask** rather than logging a customer-visible participant's messages as an
   internal Productboard-only record; see § Non-negotiables.

4. **Confirm the resolved company name in chat before any write.** Same failure mode as the external skill: a
   mis-resolved company writes internal discussion of one customer onto another's Planhat timeline, where –
   unlike the external channel case – there is no expectation the customer will ever see it, but the wrong
   *account* is still wrong. Zero or multiple matches: stop and ask.

5. **Cache write-back** (§ 0.1), then continue to § 1.

### Path B – the user gave a company, no channel

1. **Resolve the company**, pulling the cache field in the same call:

```
list_model_records(MODEL: "Company", FILTER: {"name[contains]": "<name>"},
                   SELECT: ["name", "domains", "phase", "owner", "custom.Slack ID"])
```

   Zero rows on `name` – retry as a `domains[contains]` slug before concluding "no such customer", same as the
   external skill (§ 0, Path B, step 1).

2. **`custom.Slack ID` populated → use it.** This is the fast path, and it is populated on a large share of
   accounts already via RevOps/SF sync – you are very likely not resolving a channel at all, just reading one.
   Validate it with a one-message read (`slack_read_channel`, `limit: 1`) so a stale ID fails loudly here. A
   read failure – archived channel, renamed workspace, ID no longer valid – is **reported to the user**, not
   silently routed into the search fallback below (which would then risk overwriting a RevOps-synced field with
   a guess).

3. **Empty → search, then ask.** Sweep `slack_search_channels` for the `#account-{customer}` convention
   (`account-{customer slug}`; include `private_channel` in `channel_types` – these are usually private), and
   apply the same internal-authorship check as Path A step 3 to any candidate before treating it as a hit. Zero
   or ambiguous results: "I could not find an internal `#account-` channel for {customer} – paste the channel
   URL or ID and I will store it on the account (with your OK, since this syncs toward Salesforce)."

4. **Cache write-back** (§ 0.1), then continue to § 1.

### 0.1 Cache write-back

Once channel and company are both settled:

1. **State the resolved channel and ask for explicit confirmation before writing** – e.g. "This resolves to
   `#account-acme-corp` (`C02N37LS25C`). Since `custom.Slack ID` syncs back toward Salesforce, want me to write
   it to the Acme Corp Company record?" This is a harder gate than the external skill's cache, which writes
   silently once confidently resolved – `custom.Slack ID` is a shared field other teams read, and a write here
   has a longer reach than a Planhat-only cache.
2. On yes, write the channel ID:

```
update_model_record(MODEL: "Company", OBJECT_ID: "<company _id>",
  PARAMETERS: {"custom.Slack ID": "<CHANNEL ID, upper-case>"})

get_model_record(MODEL: "Company", OBJECT_ID: "<company _id>",
  SELECT: ["custom.Slack ID", "custom.Slack URL"])
```

`custom.Slack URL` is never a write target — it is a locked formula field that recomputes on its own once
`custom.Slack ID` changes. Reading it back after the write is only a convenience check that the formula
refreshed, not a second field to populate.

3. **Never overwrite a populated value without asking**, and never overwrite silently even with confirmation
   to write a *different* channel – a value that disagrees with what was just swept is a conflict to surface
   (the account may have more than one internal channel over time), not a value to flip.
4. On `--dry-run`, print the proposed write and skip it, including the confirmation prompt.
5. A rejected write is a one-line note, then business as usual – the cache is an optimization, not a
   prerequisite for logging this run's threads.

**Window.** `--since` filters on the thread's **first** message, not its last reply. Default is the whole
channel. Identical to the external skill.

---

## 1. Pull the channel

Identical mechanics to the external skill § 1: `slack_read_channel` with `limit: 100`, follow `next_cursor`,
write the response to a scratch file and parse it with a script rather than holding every message in context.

---

## 2. Classify every top-level message

Identical classification rules to the external skill § 2 – **thread** / **standalone substantive** / **noise**
/ **broadcast reply** – including the same three judgement rules (unanswered standalone questions still count,
consecutive same-author messages fold into one thread, broadcast replies are matched by ts against a thread's
`latest:` reply time and never logged twice). Read that section for the full test table; nothing about
classification changes for internal channels.

One addition specific to this channel type: **flag, don't silently log, any thread whose author list is not
all-internal.** A single external participant in an otherwise-internal channel is either the misclassification
described in § 0 Path A step 3 (wrong channel entirely – stop the whole sweep and ask) or a one-off guest added
to a specific thread (log the thread, but name the external participant in § 8 rather than resolving them into
`endusers` – see § 5).

Report the counts (`N threads · M standalone · K noise`) before writing anything, and on `--dry-run` stop here.

---

## 3. externalId – the dedup key

**Identical format and mechanics to the external skill § 3** – same helper, same canonical shape, same
mandatory pre-create check, post-create read-back, and legacy-repair pass:

```
slack_{channelId}_{parentTs with the dot removed}
```

```python
def slack_external_id(channel_id: str, parent_ts: str) -> str:
    return f"slack_{channel_id.strip().upper()}_{parent_ts.strip().replace('.', '')}"
```

Using the same `slack_` prefix as the external skill is safe and intentional here: the dedup key is scoped by
Slack channel ID, and an internal `#account-**` channel and its account's external `#ext-**` channel are
always different Slack channels with different IDs, so the two skills' records never collide on `externalId`
even though they share a prefix and, in principle, could land on the same company. Everything else in § 3 of
the external skill – the mandatory pre-create check, the post-create read-back assertion, the legacy-repair
regex and repair table – applies here verbatim; the only thing that changes is which Planhat `type` the repair
pass scopes to (see § 4 below).

---

## 4. Backfill pass – threads that gained replies

Identical mechanics to the external skill § 4, scoped to this skill's type:

```
list_model_records(MODEL: "Conversation",
  FILTER: {"companyId[equal to]": "<id>", "type[equal to]": "Internal Alignment"},
  SELECT: ["subject", "date", "externalId", "description"], LIMIT: 100)
```

Page until a request returns zero records. Keep the window to records dated within the last 365 days. For each
record, parse `externalId` → channel + parent ts, skip any that don't match the `slack_*` shape, use the same
`latest:`-time pre-filter to avoid a thread read when nothing has grown, and rebuild via `update_model_record`
exactly as in the external skill – `date` moves forward, `externalId` never touched, never re-create.

The **legacy-repair pass** (external skill § 3, "Legacy repair pass") also runs here, once per company at the
start of any invocation, before backfill – but pull `Internal Alignment` records instead of `💬 Slack Chat`
ones. Everything else (canonical-shape regex, repair table, "not recoverable → report, don't guess") is
identical.

---

## 5. Create pass – fields to write

```
create_model_record(MODEL: "Conversation", PARAMETERS: {
  "type": "Internal Alignment",
  "companyId": "<planhat company _id>",
  "source": "Slack",
  "date": "<last message in the thread, ISO 8601 UTC>",
  "subject": "Internal – #<channel>: <what the thread was about> (<Mon D–D, YYYY>)",
  "externalId": "<slack_external_id(channel, parent_ts) – see § 3, required, never omitted>",
  "description": "<rendered HTML – § 6>",
  "custom": {
    "Slack message Id": "<parent ts, dotted form>",
    "First message time": "<YYYY-MM-DD HH:MM <tz>>"
  }
})
```

Differences from the external skill's create call (§ 5 there):

- **`type`** is `Internal Alignment`, no emoji. Verify the exact string against
  `get_model_action_parameters(MODEL: "Conversation")` at the start of a run – the option list drifts, and this
  is the value confirmed live 2026-08-28 in `context/planhat-schema.md`.
- **No `Slack initiated by`.** That field's `Customer` / `Productboard` distinction doesn't apply – every
  participant in scope is Productboard by definition of the channel.
- **`users` only, never `endusers`.** Populate `users` from the thread's actual Productboard authors exactly
  as the external skill resolves its side (`list_model_records(MODEL: "User", FILTER: {"email[equal to]":
  "<addr>"})`), read back and asserted the same way. **Never populate `endusers` on an Internal Alignment
  record, even when a non-`productboard.com` author is present in the thread** – this record type is Productboard-
  internal by definition, and an `endusers` link would put a customer-visible-looking association on what is
  meant to be an internal-only note. An external author found mid-thread is reported by name/email in § 8
  ("possible guest in an internal channel – not linked") rather than resolved into `endusers`; if the presence
  is more than a one-off, treat it as the § 0/§ 2 misclassification signal and stop the sweep to ask.
- **`custom.First message time`** carries the same silent-drop caveat documented in the external skill's § 5 –
  note it once per run if it doesn't stick, don't retry past a second attempt, don't fail the run over it. The
  thread start is still recoverable from `custom.Slack message Id` and the `externalId` parent ts.
- **Never edit contact identity data** – not applicable here in the usual sense (no `endusers` are ever
  written), but if a Productboard `User` record looks stale or wrong while resolving `users`, report it rather
  than editing it, same posture as the external skill.

---

## 6. Description HTML – what Planhat's editor actually accepts

**Identical to the external skill § 6** – same safe tag set (`<p>` · `<br>` · `<b>` · `<i>` · `<a href>` ·
`<hr>`), same single-line-no-newlines constraint, same layout template with two adjustments:

- Header line reads `<b>Internal thread – #{channel}</b>` instead of `Slack thread`.
- The `Participants:` line names Productboard people only; if a flagged external author exists in the thread
  (see § 2, § 5), name them in a trailing `<i>` note rather than the `Participants:` line itself, e.g.
  `<i>Also present: {name} ({email}) – not linked, external author in an internal channel.</i>`.

Everything else – speaker headings, mention/link rewriting, attachment captions, the no-em-dash rule, the
`Sync:` footer watermark format, and the permalink line – is the external skill's § 6 verbatim.

### `subject`

`Internal – #{channel}: {topic} ({Mon D–D, YYYY})`. Same searchability rule as the external skill: name the
feature or system in play, not "internal discussion".

---

## 7. Fan-out

Identical to the external skill § 7 – batch remaining creates/rebuilds (after § 3 dedup and § 4 pre-filter) in
groups of 5–8 to generic subagents once the outstanding count exceeds ~8, count the *remaining work* rather
than the raw channel classification count, give every subagent its own scratch directory, and use
`externalId[contains]: "<CHANNEL ID>"` (never `[starts with]`, which is rejected on `Conversation`) for any
bulk existence check.

---

## 8. Report

A table: `date · thread topic · action (created / backfilled / unchanged / skipped) · Planhat _id`. Then:

- counts per action,
- any thread held back and why (unresolvable company, malformed `externalId`, thread read failure, suspected
  channel misclassification),
- any external author spotted in an otherwise-internal thread, named with email, and whether it was a one-off
  (reported, not linked) or looked like a wrong-channel sweep (stopped, asked),
- the record IDs for spot-checking,
- **how the channel was resolved** and what happened to the cache – one line: `channel C02N37LS25C from
  custom.Slack ID (already populated)`, `resolved from #account- search, written to custom.Slack ID on Acme
  Corp with confirmation`, or `resolved, write declined by user` – so a wrong pairing, or a channel that was
  never cached, is visible in the run that made it.

---

## Non-negotiables

- **One Conversation per thread.** Never merge two threads into one record, never split a thread across records.
- **`date` is the last message of the thread, never the run date.** Same rationale as the external skill –
  matches Planhat's own multi-part-conversation convention and keeps native `lastTouch` accurate. Thread start
  preserved in `custom.First message time` and the `externalId` parent ts.
- **`externalId` is the dedup key, always present, same canonical format as the external skill** –
  `slack_{channelId}_{parentTsDigits}`. Built by the § 3 helper, never by hand. Checked before every create,
  read back and asserted after every create, repaired to canonical on any legacy record found.
- **Legacy repair runs before the backfill pass**, scoped to `Internal Alignment` records on the account.
  Repairs touch `externalId` only, never `date` or `subject`.
- **Backfill re-dates forward and never re-creates.** A thread that gained replies is an `update_model_record`
  on the existing `_id`; `date` moves forward, `externalId` and `custom.First message time` stay untouched.
- **`Internal Alignment` does not count toward session delivery**, though it is a valid touchpoint for native
  `lastTouch`. Never use it to fill a session gap, and never retype an uncounted record into a counted session
  type to make a number move.
- **`users` only, never `endusers`.** This record type is Productboard-internal by definition. A non-
  `productboard.com` author is reported, never linked as an `endusers` participant.
- **Never edit contact identity data** encountered while resolving `users`.
- **Never post to Slack.** Read-only against Slack, same as the external skill.
- **Never sweep a channel whose company you have not confirmed**, and **never sweep a channel that is not
  actually internal** – a substantial share of non-`productboard.com` authors means this is the external
  skill's target, not this one. Stop and ask rather than logging a customer-visible participant's messages into
  a record meant to be Productboard-only.
- **Never write `custom.Slack ID` without the user's explicit confirmation in chat**, even though the API
  accepts the write. It syncs back toward Salesforce and is populated by RevOps on many accounts already –
  confirm the specific channel before writing, and never overwrite a populated value that disagrees with what
  was just swept without surfacing the conflict first.
- **Never write `custom.Slack URL` at all.** It is a locked formula field derived from `custom.Slack ID` –
  reading it is fine, writing it targets a read-only field.
- **Never read or write `custom.External_Slack_Channel_ID`.** That is the external skill's cache for the
  shared customer channel – wrong field for this procedure in either direction.

## Related

- `agents/slack-thread-logger.md` – the external-channel sibling this procedure was forked from. Same dedup
  mechanics, renderer, and fan-out pattern; different channel, cache field, Planhat `type`, and participant
  handling.
- `context/planhat-schema.md` § The three Slack fields on Company – field ownership and the internal-vs-
  external distinction this procedure depends on getting right.
- `/log-feedback` – for turning a Slack thread into Productboard product feedback rather than a Planhat
  touchpoint, internal or external.
