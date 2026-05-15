# Session Naming Convention

## Format

```
[[TYPE][Number]] [TOPIC]
```

**Examples:**
- `[A7] Roadmaps System Design`
- `[E1] Prioritization for PMs`
- `[A1] Foundations Design`
- `[S21] Q&A Roadmaps`
- `[S32] Program sync`

**Do not include the customer name** — it is already captured as the `Customers` relation property on the Session record.

---

## Type codes

| Code | Session type | Notion `Type` value |
|---|---|---|
| `E` | Training or enablement | `🎓 Training` |
| `A` | Architecting | `🏗️ Architecting` |
| `S` | Sync | `🗣️ Sync` |

Other session types (`👟 Kick off`, `🔎 Discovery`, `📦 Other`, `🫥 Internal`) do not use the `[TYPE][N]` prefix. Name them descriptively — e.g. `Kick off`, `Discovery — Tooling Landscape`.

---

## Sequential numbering

The number is **sequential per type within the Active Package** the session consumes from:

1. Query Sessions DB filtered by the customer's Active Package and session type:
   ```sql
   SELECT Name FROM "collection://29397e9c-7d4f-8052-886b-000b9e3479d7"
   WHERE "Consumed Package" LIKE '%<active-package-id>%'
     AND "Type" = '<Notion type value>'
     AND "Do not count" != '__YES__'
     AND "Call Status" != 'Canceled'
   ```
2. Count the results. Next number = count + 1.

If the session does not yet have `Consumed Package` set (new session being created before debrief), fall back to the customer's current Active Package (`Active? = __YES__`) for counting.

---

## Deriving the name on session create or rename

1. Identify the session type (from calendar event, user input, or Notion record).
2. Look up the next sequential number for that type within the Active Package (see above).
3. Derive the topic from the calendar event title, session prep context, or user input. Keep it short: 2–5 words, title case.
4. Assemble: `[<TYPE><N>] <Topic>` — e.g. `[A3] Stakeholder Alignment`, `[E2] Roadmap Prioritization`.

---

## Duplicate detection — name-resilient approach

Session pages created before this convention may have names that don't follow the `[TYPE][N]` format. **Never rely on the `Name` field alone to detect or match sessions.** The canonical dedup key is the triple:

- `Customers` relation = customer page URL
- `date:Call Date:start` = session date
- `Type` = Notion session type value (e.g. `🎓 Training`)

If a record matches all three fields, it IS the same session — treat it as an existing page regardless of its current name.

**On finding an existing session with a non-conforming name:** surface the rename alongside other updates — `"Found [old name] — rename to [new name]?"` — and apply on confirmation. Never silently rename.
