---
name: notion-check
description: Walk Notion looking for ownership / data drift across the user's records — null Owners, customers with no Active Package, multiple active packages flagged Active, contradictions between Customer.Owner and descendants' Current Account Owner. Surfaces issues in chat for cleanup. No writes.
---

Check Notion data integrity for the user's records.

Read the procedure in `agents/notion-integrity-check.md` and execute it inline as the main assistant — do not try to spawn `notion-integrity-check` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types). The steps:

1. Query all records where the user is Owner (Customers) or Current Account Owner (Active Packages, Sessions, Tasks).
2. Check for drift cases:
   - Customer with `Owner` containing the user but no Active Package
   - Customer with multiple `Active? = __YES__` packages
   - Active Package / Session / Task where `Current Account Owner` doesn't match `Customer.Owner` (propagation drift — Resync button needed)
   - Tasks with null `Customers` relation (should always be set, even for internal tasks → Productboard customer record)
   - Sessions with `Call Status = Delivered` but no `Delivered By` set
   - Sessions with `Call Status = Planned` but `Call Date` in the past (likely missed or not yet flipped to Delivered)
   - Orphan Active Packages (no Customer relation)
3. Group findings by drift category. Surface in chat with the affected page links.
4. **Read-only by default.** Pass `--fix` to apply low-risk fixes automatically (e.g. running the Resync button propagation, setting null `Current Account Owner` from `Customer.Owner`). Higher-risk drift (orphan packages, contradictory ownership) always requires explicit confirmation.

**Flags:**
- `--customer <name>` – check a single customer's record tree only
- `--fix` – auto-apply low-risk corrections (default is read-only)

Do NOT touch teammate records. The default Owner-filter scopes everything to the user's portfolio.
