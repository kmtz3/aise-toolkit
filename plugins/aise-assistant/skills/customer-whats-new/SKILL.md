---
name: customer-whats-new
description: Surface what's changed for a customer since the last touch — Gong, Gmail, Slack, Notion comments, Salesforce notes, Jira/Confluence — grouped by source with timestamps. Read-only briefing.
---

Surface deltas for the customer in.

Read the procedure in `agents/whats-new.md` and execute it inline as the main assistant — do not try to spawn `whats-new` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types). The steps:

1. Resolve the customer in Notion (Customer page + Active Package).
2. Determine the **window**:
   - `--since YYYY-MM-DD` if provided.
   - `--last-session` (default if no flag) → last delivered Session's `Call Date` from Notion.
   - If no delivered session exists, fall back to the Active Package `Start Date` or the last 14 days, whichever is more recent.
3. Pull activity inside the window from Glean (Slack, Gong, Salesforce, Confluence, Drive), Gmail, Notion (Sessions, Tasks, comments), and past chats — in parallel.
4. Group by source, ordered newest first inside each group, with a one-line label per item (date + headline + link). Also surface a top **Signals** block: stakeholder changes, new commitments, missed asks, sentiment shifts, anything blocking the next session.
5. Flag stale opens: PB-side Tasks past their due date and customer asks from the last session that haven't been touched.

Output is **inline in chat only** – no Notion writes, no Gmail drafts. Use as a pre-prep scan before `/session-prep`, or before re-engaging after a quiet stretch.

Default to the last-session window when invoked without flags. Don't ask the user what window she wants – pick the sensible default and state the window in the response.
