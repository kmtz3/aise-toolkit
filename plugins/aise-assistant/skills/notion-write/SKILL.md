---
name: notion-write
description: Create or update records in the Notion Customer Tracker
---

Notion write for.

Read the procedure in `agents/notion-writer.md` and execute it inline as the main assistant — do not try to spawn `notion-writer` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types). It enforces:

- Schema rules from `context/notion-schema.md` (date triples, `__YES__`/`__NO__`, multi-select JSON arrays, relations as page-URL arrays, `userDefined:` prefix for URL/id fields, JS numbers not strings).
- **Tasks rule**: only create Tasks for PB-side / user-owned actions. Customer-side actions do NOT go in the Tasks DB.
- **Prep rule**: prep content goes inside a toggle heading on the Session page. Standalone prep pages get `[PREP]` prefix and `Do not count = __YES__`.
- **Active Package** per customer is limit 1 — flip old one to `Active? = __NO__` before activating a new one.
- Surface conflicts (contradictions with existing data) before overwriting.

If the user's request is ambiguous about which database or which customer, ask one targeted question. Otherwise proceed and confirm with the Notion URL.
