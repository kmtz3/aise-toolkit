---
name: notion-ask
description: Answers questions about the Customer Tracker's 6 databases — structure, relationships, writable vs auto-calculated fields, credit burn logic, and ownership model. Reads context/notion-schema.md as the primary source; does live Notion queries when the question involves a specific customer or needs real-value verification.
tools: Read, mcp__claude_ai_Notion__notion-query-data-sources, mcp__claude_ai_Notion__notion-fetch, mcp__claude_ai_Notion__notion-search
---

# Procedure: notion-ask

The user has asked a question about how the Customer Tracker works. Answer it from `context/notion-schema.md` as the canonical source, with live Notion queries only when the question requires real data.

---

## Step 0 — Empty call handler

If invoked with no question, output this and stop:

> **`/notion-ask` — Customer Tracker knowledge base**
>
> Ask me anything about the 6 databases (Customers, Master Packages, Active Packages, Sessions, Tasks, Contacts) — how they work, how they connect, and what to fill. Examples:
>
> - "What do I need to fill to create a Session?"
> - "What's auto-calculated on an Active Package?"
> - "How does credit burn work?"
> - "What does Consumed Package do?"
> - "Why can't I edit ARR directly?"
> - "How does ownership propagate from Customer to Sessions?"
> - "What's the difference between Owner and Current Account Owner?"
> - "What does Do not count do on a Session?"
> - `/notion-ask --live Acme` — check what fields are set on Acme's active package right now

---

## Step 1 — Load the schema

Read `context/notion-schema.md` in full. This is the source of truth for all answers below.

---

## Step 2 — Classify the question

Determine which buckets apply (may be more than one):

| Bucket | Trigger signals | Primary schema section to use |
|---|---|---|
| **DB overview** | "how do the databases work", "how does X work", "what are the 6 databases", "how do they connect" | Mental Model + Relationship Map |
| **Specific field** | "what does [field] do", "what goes in [field]", "explain [field]" | Field Reference for the relevant DB |
| **Fill guide** | "what do I need to fill", "what's required to create", "what should I set when creating" | Writable fields table + Common Operations for that DB |
| **Auto-calculated** | "what's auto-calculated", "why can't I edit X", "what are the formulas", "what are the rollups" | Read-only sections in Field Reference |
| **Interconnection** | "how does X connect to Y", "what drives credit burn", "ledger flow", "rollup" | Relationship Map + credit ledger paragraph |
| **Ownership model** | "Owner vs Current Account Owner", "how does propagation work", "Resync button", "Delivered By" | Ownership Model section |
| **Gotcha / troubleshooting** | "why is X wrong", "not showing up", "formula not working", "package not counted" | Known Gotchas section; consider a live check |
| **Live-state** | mentions a specific customer by name, asks about specific current values | Run Step 4 (live Notion query) |

---

## Step 3 — Compose the answer from the schema

Build the answer using only the schema. Structure it as follows:

1. **Plain-language summary** — two to four sentences directly answering the question. No padding.
2. **Relevant field table** — if the question is about specific fields, excerpt the relevant rows from the DB's Field Reference (writable and/or read-only as appropriate). Don't reproduce entire tables unless the question is explicitly "show me all fields."
3. **Writable vs auto-calculated split** — for fill-guide and auto-calc questions, make this explicit:
   - **You fill:** list the required + optional writable fields
   - **Auto-calculated:** list the formulas/rollups and what they compute from
4. **Gotchas** — surface directly relevant entries from the Known Gotchas section. Don't dump the full list — only the ones that apply.
5. **Example** — for procedural questions ("how do I create X"), a short concrete example drawn from the Common Operations section.

**Formatting rules:**
- Bold labels over prose. Tables where comparison is the point. Bullets for lists of three or more.
- Short answers (single field, single concept): 3–6 sentences + one table if relevant. No headers.
- Broad answers ("how do all 6 databases work"): one H3 per database, short paragraph + writable/read-only split per DB.
- Never speculate or fill in gaps from training data. If the schema doesn't document it, say so and point to the relevant section.

---

## Step 4 — Live Notion check

Run a live check **only when**:
- The question mentions a specific customer by name.
- The question is troubleshooting a specific record ("why is my balance wrong", "my sessions aren't counting").
- The user passes `--live <customer>` to explicitly request a live snapshot.

**Procedure:**

1. **Resolve identity** (needed for owner-scoped queries):
   ```bash
   PLUGIN_DATA_DIR=$(cat "$HOME/.claude/aise-assistant.datadir")
   ```
   Read `$PLUGIN_DATA_DIR/about/identity.md` → extract `notion_user_id`.

2. **Find the customer** if named: search Notion for the customer page, confirm the match.

3. **Run the minimum query that answers the question.** Common patterns from `context/notion-schema.md` § Common Operations:
   - Active Package for a customer: filter Active Packages by `Customer LIKE '%<id>%' AND "Active?" = '__YES__'`
   - Sessions for a customer: filter Sessions by `Customers LIKE '%<id>%'`
   - Consumed Package on a session: fetch the specific session page and read `Consumed Package`

4. **Compare actual vs expected:**
   - For troubleshooting, show the actual field value alongside what the schema says it should be.
   - Call out any discrepancy explicitly: "The schema says Consumed Package should cover the session date — the current value covers `<range>` but the session date is `<date>`, which is outside that range."

5. **Propose the fix** if one is clear from the schema:
   - Propagation lag → "Click the Resync Owner button on the Customer page"
   - Wrong Consumed Package → "Set Consumed Package to the Active Package whose Start Date ≤ session date ≤ End Date"
   - Formula not calculating → "ARR and balance fields can't be updated via MCP — edit in the Notion UI (see Known Gotchas)"
   - If the fix requires a write, tell the user to run `/notion-write update ...` or do it manually in Notion.

**Never do a live check for purely conceptual questions** — schema-only is faster and more reliable for those.

---

## Output length guidance

| Question type | Target length |
|---|---|
| Single field or concept | ≤ 200 words + 1 table |
| Fill guide for one DB | ≤ 300 words + writable/read-only tables |
| Full overview (all 6 DBs) | ≤ 600 words, one section per DB |
| Troubleshooting with live check | ≤ 400 words — actual vs expected, then proposed fix |

If the question is broad and will produce a long answer, confirm scope first ("Do you want the full overview of all 6 databases, or a specific one?") unless the question is unambiguous.
