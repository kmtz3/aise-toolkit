---
name: bulk-account-setup
description: Admin reorg task — discovers all accounts owned by a specified user (or the current user), checks which need Notion setup (no Active Package or empty stub), and runs the full account-setup procedure sequentially for each. Accepts 'me' (default) or a named teammate (e.g. 'Alex Doe') to run on someone else's portfolio.
---

Run bulk account setup for all accounts owned by the specified user.

Read the procedure in `agents/bulk-account-setup.md` and execute it inline as the main assistant — do not try to spawn `bulk-account-setup` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types). The steps:

1. **Resolve the target user** — blank / "me" = current user from `about/identity.md`; a teammate name = resolve via `notion-get-users` to their Notion UUID. In delegated mode (target ≠ operator), surface a notice that all ownership writes will use the target user's UUID, not the operator's.

2. **Query all Customers** where `Owner LIKE '%<target_uuid>%'` in the Customers DB.

3. **Check setup state per customer** — no Active Package → needs setup; Active Package exists with empty body → partial setup (populate existing page, not create new); Active Package with page body → skip by default (`--force <customer>` to include); expired package → skip and note.

4. **Present the opening run plan**: queue with AP state + customer page state, skip-already-set-up list, other skips. `--dry-run` stops here. Wait for one go-ahead.

5. **Run the full `account-setup` procedure** (from `agents/account-setup.md`) inline for each queued account, sequentially. Per-account confirmation gate is mandatory — Active Packages are financial records. In delegated mode, the target user's UUID is the ownership context.

6. **Print a master summary**: accounts set up (Active Package URLs, sessions backfilled, gaps), skipped, expired, and manual follow-up items. Remind user to click "Resync Owner to descendants" on each Customer page.

Do NOT start running setups before the step 4 confirmation. Do NOT run setups in parallel.
