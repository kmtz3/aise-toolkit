---
name: slack-thread-logger
description: Procedure for logging shared-Slack-channel threads as Planhat Conversations of type "💬 Slack Chat" on the customer – one Conversation per thread, dated on the last message in the thread, deduplicated on a deterministic Slack externalId, with a reply-backfill pass over the previous 365 days. Resolves the customer↔channel pairing in either direction and caches it on `Company.custom.External_Slack_Channel_ID` so later runs skip resolution. Invoked by `/log-slack-threads`.
tools: mcp__Slack__slack_read_channel, mcp__Slack__slack_read_thread, mcp__Slack__slack_search_channels, mcp__Slack__slack_read_user_profile, mcp__Planhat__list_model_records, mcp__Planhat__get_model_record, mcp__Planhat__create_model_record, mcp__Planhat__update_model_record, mcp__Planhat__delete_model_record, mcp__Planhat__get_model_action_parameters, Bash, Read, Write
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
   | a | `slack_search_channels` for the `#ext-` convention | Shared external channels are named `#ext-{customer}` or `#ext-{customer}-productboard`. Query `ext-{customer slug}`, and if that misses, `ext-{primary domain's second-level label}` (`acme.io` → `ext-acme`). Include `private_channel` in `channel_types` – shared channels are usually private – and pass `include_archived: true`. |
   | b | Ask the user | "I could not find a shared external channel for {customer} – paste the channel URL or ID and I will store it on the account." |

   On step a, require the match to actually look right, and require it to be **external**. Two tests, both
   cheap: the name starts with `ext-`, and a one-page read shows at least one non-`productboard.com` author.
   A channel that fails either test is an internal channel that happens to be named after the customer – skip
   it and go to step b. More than one plausible hit, or a hit whose name does not contain the customer or
   their domain label: present the candidates and ask. Never sweep a channel you are not sure about – see
   step 4 of path A for why.

   **Archived channels are candidates too.** On some accounts the only `#ext-` channel left is archived – the
   customer moved to email, or the channel was retired after a renewal. Show an archived hit like any other
   candidate, with its archive date (`#ext-acme-productboard – archived 2025-03-14`), and let the user confirm.
   A confirmed archived channel is cached and swept exactly like a live one, with one difference: **skip the § 4
   backfill pass**, because an archived channel cannot gain replies. Legacy repair (§ 3) and duplicate resolution
   (§ 3.1) still run.

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

### 0.2 Portfolio mode (`--mine` / `--owner <name>`)

Sweeps every Company a user owns in one invocation instead of one account at a time. `--mine` targets the
current user; `--owner <name>` targets a named teammate.

1. **Resolve the Planhat User by email**: `list_model_records(MODEL: "User", FILTER: {"email[equal to]": "<addr>"})`.
   For `--owner <name>`, resolve the name to an email first and confirm the match in chat.
2. **Pull the book:**

```
list_model_records(MODEL: "Company", FILTER: {"owner[equal to]": "<user _id>"},
                   SELECT: ["name", "domains", "phase", "custom.External_Slack_Channel_ID"], LIMIT: 100)
```

   Page with `OFFSET` until a page returns zero rows. Split the result into **cached** (channel ID populated) and
   **uncached** accounts.
3. **Resolve every uncached account in one batched, read-only pass.** Hand all of them to a single
   general-purpose subagent that runs § 0 Path B step 3a (with `include_archived: true`) for each one and
   returns candidates only. It writes nothing.
4. **One confirmation table for every new pairing:** `account · candidate channel · ID · live/archived (date) ·
   external authors seen`. The user confirms, corrects or drops each row. Only confirmed rows are cached
   (§ 0.1) and added to the sweep. Never cache or sweep a pairing that was not confirmed in this table.
5. **Sweep every cached and newly confirmed account.** Use **one general-purpose subagent per account**, run in
   parallel. Give each one the full text of this procedure, the company `_id`, the channel ID, the flags for this
   run, and its own scratch directory named by channel ID (`<scratch>/<CHANNEL_ID>/`). Each subagent runs §§ 1–8
   for its account and returns its § 8 report plus its duplicate-resolution batch (§ 3.1) **without deleting
   anything**. Validated with 10 accounts in parallel and no cross-contamination, as long as each subagent stays
   in its own scratch directory (§ 7).
6. **Portfolio report:** one row per account (`account · channel · created · backfilled · unchanged · repaired ·
   duplicates found · issues`), then the **combined** duplicate-resolution decision list across all accounts
   (§ 3.1), then one consolidated § 8 Hygiene block. Deletes happen only after the user approves that combined
   list.

**Checkpoint & resumability.** A portfolio run is long enough to be compacted mid-run. Write
`/tmp/slack-thread-logger-portfolio-<owner-id>.json` after step 4 and after each account's subagent returns:
`{"scope": "<owner _id>", "flags": {"since": ..., "new_only": ..., "backfill_only": ..., "dry_run": ...},
"items_completed": ["<company _id>", ...], "items_pending": [...], "confirmed_pairings": {"<company _id>":
"<CHANNEL_ID>"}, "unresolved": [...]}`. IDs and status only, never thread content. On start-up, resume from an
existing checkpoint only if its `scope` and every flag match this invocation exactly; otherwise discard it and
start fresh. Delete it when the run completes, and leave it in place after an error or partial run.

---

## 1. Pull the channel

`slack_read_channel` returns newest-first and paginates. Read with `limit: 100` and follow `next_cursor`
until `pagination_info` reports no more messages.

**Where the response ends up decides how you parse it.** Two cases, and you do not choose between them:

| Case | What happens | What you do |
|---|---|---|
| Result over the tool-output token cap (usually page 1 of `slack_read_channel`) | The harness saves it to `tool-results/<id>.txt` and returns the path | **Copy that file into your own scratch directory right away**, then parse the copy with the reference parser below. Identify the file by its `Channel:` header line, **never by "latest file in the folder"**. `tool-results/` is shared by every agent in the session, so in a parallel fan-out the newest file is often another account's channel. |
| Result under the cap (later pages, every Planhat `list_model_records` response) | Returned inline | Compare it in context. Do **not** retype rows into a script by hand: hand-copying 100+ IDs and timestamps into Python is a copy-error path straight into the dedup logic. |

Keep the inline Planhat side small enough to compare by eye: when listing existing records for a dedup or
backfill comparison, `SELECT` only `externalId`, `date` and `custom.Slack message Id`, **never `description`**.
Pull `description` only for the specific records you are about to rebuild.

**Reference parser for saved channel reads.** Message headers have more shapes than they look like, and a naive
pattern drops messages silently. Guest headers carry an `external:` marker inside the parentheses, and Slackbot
and app headers have no email at all:

```
=== Message from Jane Doe <jane@productboard.com> (U01ABCDEF) at 2026-03-04 10:12 CET ===
=== Message from Sam Lee <sam@acme.io> (U02GHIJKL, external: Acme Corp) at 2026-03-04 10:15 CET ===
=== Message from Slackbot (USLACKBOT) at 2026-03-04 10:20 CET ===
```

A pattern like `\((\w+)\)` matches only the first shape, and on one guest-heavy channel it dropped 77 of 100
messages without an error. Use this parser, which asserts that it found every message:

```python
import re, json, sys

HEADER = re.compile(
    r"^=== Message from (?P<name>.+?)"
    r"(?: <(?P<email>[^>]+)>)?"
    r" \((?P<uid>[A-Z0-9]+)(?:, external: (?P<org>[^)]+))?\)"
    r" at (?P<local>.+?) ===\s*$",
    re.M,
)
TS = re.compile(r"^Message TS: (?P<ts>\d+\.\d+)", re.M)
THREAD = re.compile(r"^Thread: (?P<n>\d+) repl(?:y|ies)(?: \(latest: (?P<latest>[^)]+)\))?", re.M)

def parse(text: str) -> list[dict]:
    heads = list(HEADER.finditer(text))
    raw_headers = len(re.findall(r"^=== Message from ", text, re.M))
    if len(heads) != raw_headers:
        sys.exit(f"parser matched {len(heads)} of {raw_headers} message headers – fix the pattern, do not continue")
    out = []
    for i, h in enumerate(heads):
        body = text[h.end(): heads[i + 1].start() if i + 1 < len(heads) else len(text)]
        ts, th = TS.search(body), THREAD.search(body)
        if not ts:
            sys.exit(f"no Message TS for header at offset {h.start()}")
        out.append({**h.groupdict(), "ts": ts["ts"],
                    "replies": int(th["n"]) if th else 0,
                    "latest": th["latest"] if th else None})
    return out

print(json.dumps(parse(open(sys.argv[1]).read()), indent=1))
```

If the assertion fires, look at the unmatched header, widen the pattern and re-run. Never carry on with a
partial parse. Confirm the printed labels (`Message TS:`, `Thread:`) against the first page you read, since
the MCP output format can change.

Each top-level message gives you: author name + email + Slack user ID, an `external: <Org>` marker for guests,
the local timestamp, `Message TS` (the parent ts – this is the thread key), a `Thread: N replies` line when it
has replies, `Files:` and `Reactions:` lines.

---

## 2. Classify every top-level message

| Class | Test | Action |
|---|---|---|
| **Thread** | Has a `Thread: N replies` line **and** at least one message in it (parent or reply) carries substance | Log |
| **Standalone substantive** | No replies, but carries a real question, decision, status update or session recap | Log |
| **Noise** | Join/leave notices, "X was added to this channel", canvas-update notices, channel-description changes, bare emoji or reaction-only messages, pure logistics one-liners ("booked it for Friday", "thanks!"). **Also a thread whose parent and every reply are logistics, pleasantries or acks**: having replies does not make it a thread worth logging. | **Never log** |
| **Broadcast reply** | Looks top-level in the channel read – own `Message TS`, no `Thread:` line – but is a reply someone sent with "also send to channel". | **Never log separately.** It already belongs to its parent thread's record. |

**Where the logistics line falls.** Decide on content, not shape, and apply the same test on every run so a
record logged by one run is not reclassified as noise by the next:

| Noise (never log) | Log |
|---|---|
| "Will book time with you next week" / "Sounds good, see you then" | "Can we book time next week? We want to walk through why the Jira sync is creating duplicates" (states the problem) |
| A thread where the only exchange is picking a meeting slot and confirming the invite | A scheduling thread where someone also states the agenda, a blocker, a decision, or who needs to attend and why |
| "Thanks!" / "👍" / "Got it, will check" with nothing after it | "Got it – we have decided to roll it out to the EMEA team first" (a decision, however short) |

When a thread is mostly logistics but carries one substantive line, log it and make that line the `Topic`.
When you are unsure, log it: a thin record costs less than a lost touchpoint. Count logistics-only threads in
the § 2 report as `noise (logistics)` so the user can see what was skipped.

Judgement rules that matter:

- **A standalone customer question with no in-channel answer is still a touchpoint** – often it was answered in
  a call or by email, and the unanswered thread is exactly the kind of thing worth having on the timeline.
  Log it and say so in `Outcome`.
- **Consecutive messages from the same author within 5 minutes are one record**, not three. Slack users press
  enter mid-thought. Measure each gap from the previous fragment, not from the first. Fold them into a single
  record and render the fragments as consecutive lines under one speaker heading. **Key the record on the
  earliest fragment, unless a later fragment is the one that carries the thread** (has the `Thread:` line): then
  key on that fragment's ts, because it is the thread parent and the backfill pass (§ 4) reads the thread from
  it. List every folded fragment's ts in the footer `Sync:` line (§ 4 step 3) so the backfill pre-filter can
  account for them.
- **Unthreaded back-and-forth between different authors is folded under a 15-minute rule.** People often answer
  each other with new top-level messages instead of replying in a thread. Apply this test, the same way on every
  run:
  - A top-level message on the same topic, posted within **15 minutes** of the previous message in the exchange,
    is folded into the earlier record. Key on the **first** message, date on the **last** (§ 5), and render all
    messages in order under their own speaker headings.
  - Beyond 15 minutes it is its own record, **unless it directly fulfils a promise made in the earlier message**
    ("I'll check with the team and come back" → the answer, two hours later). Fold that one in too and say so in
    `Outcome` ("answered 2 h later in channel").
  - A different topic is never folded, however close in time.
  Folding happens **before** dedup: if an earlier run split an exchange that this rule would fold, report the
  extra records in § 3.1 rather than creating more.
- **A broadcast reply is not a standalone message, and it is the main way this skill duplicates a thread.**
  `slack_read_channel` returns a reply sent with "also send to channel" as its own top-level entry, with its own
  `Message TS` and no `Thread:` line, so it is indistinguishable from a standalone substantive message by shape
  alone. Logging one creates a second record for text already inside a thread record, which is the
  "never split a thread across records" non-negotiable broken in the least visible way – both records look
  legitimate.

  **Test every unthreaded candidate with the window test before classifying it:**
  1. **Zero-cost subset:** its ts equals some thread's `latest:` reply time → it is that thread's broadcast
     reply. No call needed. This only catches a broadcast reply that is the **last** reply in its thread, which
     in practice is a small minority of them, so it is never the whole check.
  2. **Window test:** its ts falls inside some thread's `[parent ts, latest]` window **and** its author took part
     in that thread (posted the parent, or appears in its reply authors) → **broadcast suspect**.
  3. **Confirm each suspect by reading that thread with `response_format: "detailed"`** and matching the
     candidate's ts against the reply `Message TS` values. Match → broadcast reply, never logged. No match →
     classify it normally. Several candidate threads → read each until one matches.

  Confirm by ts match, never by eye or by text: a broadcast reply looks exactly like an un-logged standalone
  message in the channel view, and text matching fails on edited or truncated messages.
- **Read threads with `response_format: "detailed"` whenever you need reply timestamps** – the broadcast check
  above and the footer watermark (§ 4). `"concise"` omits each reply's `Message TS`, which forces text matching.
  `"concise"` is fine only when you need the text alone.
- **Forwarded messages arrive truncated.** The Slack MCP cuts the body of a forwarded message short. If the
  original message is in the same channel, take its full text from there. Otherwise render what you have and
  add `<i>(forwarded text truncated)</i>` after it, so the record does not pass off a fragment as the whole
  message.

Report the counts (`N threads · M standalone · B broadcast · K noise (L logistics)`) before writing anything, and on `--dry-run` stop here.

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

**Date check (report-only).** In the same pass, compare each record's `date` with the footer `Sync:` line's
`last message ts`, converted to UTC. They should be equal to the second. A record whose `date` disagrees – most
often a local wall-clock time (CEST/CET) stored as if it were UTC, which leaves it 1–2 hours late – is reported
as `DATE MISMATCH` with its `_id`, its stored `date` and the UTC value from the watermark. **Do not auto-fix
it.** Correcting it usually means moving `date` backward, which § 4 never does on its own, so it needs a human.
Skip the check on records with no footer watermark, and say how many were skipped.

Two live examples of the drift this pass exists for, both found and fixed on 2026-08-25:

- Emplifi `6a7f4ec562ab7a106e3d2919` carried `slack-C02N37LS25C-1786373402.520939` – hyphens plus a dotted ts.
- That same record is also dated on its **last** message (Aug 14) while its parent ts is Aug 10, because it was
  logged as a multi-day channel digest rather than a single thread. Flag that shape when you meet it; a digest
  is not a thread and its `date` needs a human decision, not an automatic re-date.

### 3.1 Duplicate resolution

Deduplication is part of every run, not something only a flag turns on. Detecting a duplicate and listing it is
not the end of the job: the user expects duplicates resolved. After the legacy repair pass, find existing
records whose content is already inside another record:

| Duplicate shape | How to detect it |
|---|---|
| **Confirmed broadcast reply logged on its own** | An existing record whose parent ts (from `externalId`) is a broadcast reply confirmed by the § 2 window test – its ts matches a reply `Message TS` in another record's thread. |
| **Two records for one parent ts** | Two records on the company whose `externalId` or `custom.Slack message Id` resolve to the same parent ts. |
| **Split unthreaded exchange** | Two or more records that the § 2 folding rules (5-minute same-author, 15-minute cross-author) would have made one. |

Present them as **one batch per account**: `duplicate _id · subject · date · duplicates which record (_id) ·
why`, with a recommended action (keep / delete) for each record. For a split exchange, recommend keeping the
record keyed on the first message, rebuilding it to include the folded messages (§ 4 step 4), and deleting the
rest.

**Delete only on explicit approval, record by record.** For each approved delete:

```
delete_model_record(MODEL: "Conversation", OBJECT_ID: "<_id>")
get_model_record(MODEL: "Conversation", OBJECT_ID: "<_id>", SELECT: ["_id"])   # must fail or return nothing
```

A record that still reads back after the delete is reported as `DELETE FAILED`. Never delete as a side effect
of a sweep, never delete the record you are keeping, and on `--dry-run` list the batch without asking for
approval. In portfolio mode (§ 0.2) the batches from every account are combined into one decision list at the
end; subagents report duplicates and never delete.

## 4. Backfill pass – threads that gained replies

Run this **before** the create pass, and run it on every invocation unless `--new-only` is passed. Slack
threads stay alive for months; a record logged in March is routinely wrong by August.

1. Pull existing Slack records on the company:

```
list_model_records(MODEL: "Conversation",
  FILTER: {"companyId[equal to]": "<id>", "type[equal to]": "💬 Slack Chat"},
  SELECT: ["externalId", "date", "custom.Slack message Id"], LIMIT: 100)
```

   Leave `description` out of this list call (§ 1). Fetch it with `get_model_record` only for the records the
   pre-filter in step 3 sends to a thread read, since those are the only ones whose footer you need. The list cap
   is 100 per page: page with `OFFSET` until a request returns zero records (Planhat truncates large responses without an error – see
   `agents/session-log-auditor.md` rule #2). Keep the window to **records dated within the last 365 days**;
   older threads are effectively closed and re-reading them every run is waste.

2. For each record, parse `externalId` → channel + parent ts. Skip any whose `externalId` does not match the
   `slack_*` shape (it came from a different tool). Records whose channel ID differs from the one resolved in
   § 0 are **still backfilled** – an account can have had more than one shared channel over time, and the
   `externalId` carries its own channel so no cache lookup is needed. Do not repoint the cache at a channel
   found this way.

3. Read the live thread (`slack_read_thread`, `response_format: "detailed"`, so each reply carries its
   `Message TS`) and compare its total message count against the record's footer watermark:

```
Sync: 4 messages · last message ts 1786366092.921679 · logged 2026-08-25
Sync: 6 messages · last message ts 1786366092.921679 · fragments 1786365001.100200, 1786365130.200300 · logged 2026-08-25
```

   **`{N} messages` counts the parent plus all replies (parent + replies).** `slack_read_thread` reports
   **replies only** (`N total`), so add 1 for the parent. Folded fragments and folded cross-author messages
   (§ 2) count too: N is every message rendered in the record. The `fragments` segment is present only on
   records that folded extra top-level messages, and lists each one's ts in dotted form.

   Count grew, or the last ts moved → rebuild. Unchanged → leave it alone and count it as `unchanged`.

   **Pre-filter before spending a thread read.** The channel pull from § 1 already carries
   `Thread: N replies (latest: <local time>)` on every parent, so for any record whose parent is in that pull
   the growth check is free: take the **latest** of the parent's `latest:` time and the ts of every fragment
   listed in the footer `fragments` segment, convert it to UTC, and compare it against the record's `date`.
   They match → nothing has grown, count it `unchanged` and **do not call `slack_read_thread` at all**. A record
   with folded fragments must use this max: comparing against the parent's `latest:` alone never matches when the
   last folded message came after the thread's last reply, so the record falls through to a thread read on every
   run. A record keyed on a fragment that is not the thread parent cannot be checked this way, and a thread read
   from that fragment can look like the thread shrank. Report it as `KEYED ON FRAGMENT` with its `_id` instead of
   rebuilding it, so the user can re-key it under § 2's fragment-keying rule.
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
     than writing `[]`. **Known read-back behavior:** Planhat returns `users: []` / `endusers: []` on read-back
     even when the key was omitted on write, so a read-back cannot tell an omitted key from a written empty
     array. The rule is about what you send. Do not try to verify it from the read-back.
  3. **A participant with no contact record is reported, never created.** Resolve what you can, log the record
     without them, and name the missing person and their email in the § 8 report so the user can decide.
     Creating an End User is a change to the customer's contact data, not a side effect of logging Slack.
  4. **Read back and assert that the side that spoke is non-empty.** `endusers` fails silently on write. After
     each create or participant update:
     `get_model_record(MODEL: "Conversation", OBJECT_ID: "<id>", SELECT: ["users", "endusers"])`. Assert that
     every side that authored messages reads back non-empty and contains the people you wrote. An empty array
     on the side that did not speak is expected (rule 2) and is not a failure. A speaking side that is empty
     after two attempts is a reported failure, not a shrug.

- **`update_model_record` on `Conversation` returns only `{_id, type}`.** It never echoes the fields you set,
  so it proves nothing about whether they stuck. Every update in this procedure (rebuilds, `externalId`
  repairs, participant fixes) is followed by a separate `get_model_record` read-back of the fields it changed.

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
<b>Window:</b> {Mon D – Mon D, YYYY} · {N} messages (parent + replies, same N as the Sync line)<br>
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
Sync: {N} messages · last message ts {ts}[ · fragments {ts}, {ts}] · logged {YYYY-MM-DD}</i></p>
```

- `{N} messages` counts the parent plus all replies, plus any folded fragments or folded cross-author messages
  (§ 2). `slack_read_thread` reports replies only, so add 1 for the parent. The `fragments` segment appears only
  when the record folded extra top-level messages.

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
  responses rather than trusting a file it wrote earlier. The harness's own `tool-results/` folder is shared as
  well: copy a saved result into your scratch directory and identify it by its `Channel:` header, never as "the
  newest file" (§ 1).
- **`externalId[starts with]` does not work on `Conversation`; `[contains]` and `[does not contain]` do.** Every call using it returns
  `Failed to fetch Conversation records`; the operator itself is rejected for this field, not the value. Use
  `externalId[contains]: "<CHANNEL ID>"` instead – a Slack channel ID is unique, so the match set is identical –
  and assert in post-processing that every returned key actually starts with `slack_{channelId}_`.
  `externalId[equal to]`, which the § 3 dedup check uses, is unaffected and works normally. Use
  `externalId[does not contain]: "slack_"` to find Slack Chat records with a missing or off-format key.

---

## 8. Report

A table: `date · thread topic · action (created / backfilled / unchanged / skipped) · Planhat _id`. Then:

- counts per action,
- any thread held back and why (unresolvable company, malformed `externalId`, thread read failure),
- the record IDs for spot-checking,
- **how the channel was resolved** and what happened to the cache – one line: `channel C0AKKLJCB5E from
  custom.External_Slack_Channel_ID (cached)`, `resolved from #ext- search, cached on Acme Corp`, or
  `cache conflict, left as-is` – so a wrong pairing is visible in the run that made it rather than three runs
  later,
- every `DATE MISMATCH` and `KEYED ON FRAGMENT` record (§ 3, § 4) with its `_id` and both values,
- the duplicate-resolution batch (§ 3.1) and what was deleted on approval.

### Hygiene

One consolidated block at the end, not findings scattered through the report. Report-only: this procedure
never fixes any of it (§ 5 contact-identity rule). Each item lists the record IDs involved.

| Category | What to list |
|---|---|
| **Duplicate Companies** | Companies that share a name or a domain with the swept account (two `Acme Corp` rows, or `Acme Corp` and `Acme Corp Ratings` on one domain), with each `_id`. |
| **Duplicate End Users** | Several `End User` records on the company for one person (same email, or same name with different emails), with each `_id`. |
| **End Users named with an email** | Contacts whose `name` is an email address. |
| **Productboard authors with no Planhat User** | Usually former staff. Name and email, plus how many records were logged without them on `users` because of it. |

In portfolio mode (§ 0.2), combine every account's Hygiene findings into one block.

### Close-out

If the run surfaced any tool quirk, rule gap or duplicate, end by offering to run `/assistant-improvement`. If
the user asked for it in the invocation, run it directly.

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
   skill can produce, because both records read as legitimate and neither looks like a re-run artifact. The
   "ts equals `latest:`" match alone is not enough: it catches a broadcast reply only when it is the last reply
   in its thread. On one sweep it caught 1 of 17, on another 2 of 15, and an earlier run on a third account that
   relied on it alone created 7 duplicate standalone records. Run the § 2 window test on every unthreaded
   candidate and confirm each suspect by a `detailed` thread read and a ts match. Existing duplicates of this
   kind go through § 3.1.

11. **A cached ID that will not read is a report, not a fallback trigger.** Falling through to the `#ext-`
   search on a read failure and then caching the result is how an account silently ends up pointed at the
   wrong channel. Say the cached channel failed and let the user decide.
