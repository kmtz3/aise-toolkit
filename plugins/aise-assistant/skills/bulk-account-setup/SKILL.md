---
name: bulk-account-setup
description: Admin reorg task — discovers all Planhat Companies owned by a specified user (or the current user), checks which ones lack an AISE research-note Conversation, and runs the full account-setup procedure sequentially for each. Accepts 'me' (default) or a named teammate (e.g. 'Alex Doe') to run on someone else's portfolio.
---

Run bulk account setup for all accounts owned by the specified user.

Read the procedure in `agents/bulk-account-setup.md` and execute it inline as the main assistant — do not try to spawn `bulk-account-setup` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types). The steps:

1. **Resolve the target user** — blank / "me" = current user, resolved via Planhat (`custom.AISE Identity` on the current user's Planhat User record); a teammate name = resolve via `context/planhat-schema.md` § Planhat User IDs, falling back to a live `list_model_records(MODEL: "User", ...)` lookup. In delegated mode (target ≠ operator), surface a notice that the Gong/Gmail history search will use the target user's involvement, not the operator's.

2. **Query all Planhat Companies** where `owner` equals the target user's Planhat `_id` — this is the closest available Planhat-native proxy for an AISE's book (see `context/planhat-schema.md` § Company; there's no dedicated "AISE owner" field).

3. **Check research-note state per company** — reuse the exact check `account-setup.md` § Step 2 already runs per-account: does a Conversation of `type: "note"` with subject `Account Research — <Company>` exist? No note → needs setup. Note exists → skip by default (`--force <customer>` to include, which runs as a refresh via `account-setup`'s own enrichment logic).

4. **Present the opening run plan**: queue with research-note state, skip-already-set-up list, other skips. `--dry-run` stops here. Wait for one go-ahead — this is the only confirmation gate.

5. **Run the full `account-setup` procedure** (from `agents/account-setup.md`) inline for each queued account, sequentially, passing a bulk-run context flag so `account-setup`'s own Step 5 approval wait auto-proceeds (the queue-level gate already covers it) — the full write-up is still printed in chat per account.

6. **Print a master summary**: accounts set up (Conversation `_id`, fresh vs. refresh, thin/empty headings), skipped (already had a note), skipped (other reasons), and manual follow-up items.

Do NOT start running setups before the step 4 confirmation. Do NOT run setups in parallel. Do NOT write any Company ownership or SF-synced field — `account-setup` only ever writes a Conversation note.
