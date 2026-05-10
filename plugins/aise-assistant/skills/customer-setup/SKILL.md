---
name: customer-setup
description: Set up a newly assigned or inherited customer account. Three modes via flags — baseline (creates Customer page + Active Package + session backfill, no research), --research (baseline plus deep company research to populate Customer page sections), --refresh (deep research on existing page, enriches content without silently overwriting manually-added info).
---

Set up account for.

Read the procedure in `agents/account-setup.md` and execute it inline as the main assistant — do not try to spawn `account-setup` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types).

## Flags

Canonical syntax uses flags (`--research`, `--refresh`), but also recognize natural language variations and map to the same modes — e.g. "research Acme", "set up Acme with research", "deep research setup", "refresh the page for Acme", "update the company info for Acme" all resolve to the right mode. When the intent is ambiguous, default to baseline and offer the other modes.

| Flag | Natural language equivalents | What it does |
|---|---|---|
| *(none)* | "set up", "create", "onboard" | **Baseline** — creates/verifies Customer page (template applied), Active Package, session backfill. Sections left as placeholders. |
| `--research` | "research", "with research", "deep research", "populate the page" | **Deep research** — everything in baseline, plus runs company research to populate all discovered Customer page sections from web, Salesforce, and Gong. |
| `--refresh` | "refresh", "update the company page", "re-research", "update company info" | **Refresh** — assumes Customer + Active Package already exist. Runs company research against the existing page; enriches content, but confirms with the user before overwriting anything that can't be verified from an external source (may be manually added by the AISE). |

## The procedure

1. **Locates or creates the Customer page** in the Notion Customers DB.
   - If found: captures the URL and fetches current content.
   - If not found (baseline or `--research`): creates it via Notion API, applies the **New Customer template** (`29397e9c7d4f8005b04bef3858ece3e0`), then fetches the resulting page to discover section headings dynamically.
   - If not found (`--refresh`): stops and asks the user to run baseline or `--research` first.

2. **Detects customer mode** after pulling Gong and Notion history (baseline and `--research` only):
   - **New customer** — no relevant post-sales sessions found. Creates the foundation only (Customer page + Active Package). No session backfill.
   - **Existing customer** — post-sales sessions found. Creates the foundation AND backfills all relevant sessions as Session records. Always backfills all — no partial backfills.

3. **Researches in parallel** (baseline: Salesforce + Gong for history only; `--research`/`--refresh`: full research):
   - Web search — company overview, industry, scale, tech stack, product areas
   - Salesforce — plan, AE, AISE, renewal manager, health, billing cycle, stated PB objectives from opp notes
   - Gong — sales and post-sales calls for goals, product areas, org structure, toolstack signals
   - Gmail history — threads from previous AEs / predecessor AISEs
   - Notion — any existing sessions, tasks, or contacts already in the tracker

4. **Filters sessions** (baseline/`--research` only) — only post-sales sessions are backfilled. Excluded: sales demos, discovery calls, pricing/negotiation calls, AE-only calls, internal PB syncs. When ambiguous, flags for the user to decide.

5. **Maps the Master Package** from the Salesforce `servicesplan` field to the Master Packages DB (baseline/`--research` only).

6. **Populates Customer page sections** (`--research`/`--refresh` only):
   - Sections are discovered from the live page fetch — never hardcoded.
   - Content is mapped to sections by heading name/emoji heuristic (see `agents/account-setup.md` § Company Research sub-procedure).
   - In `--refresh` mode: confirms with the user before overwriting any section content that can't be matched to a current external source.

7. **Proposes in chat (always — never writes without confirmation):**
   - Mode and customer type (new vs. existing)
   - Customer page: sections to populate (research modes) or "template applied, sections left as placeholders" (baseline)
   - Active Package record: name, Master Package, dates, ARR, Status
   - Active Package page body: structured account history summary
   - Session records to backfill (existing customer mode): date, inferred type, 2–3 sentence brief

8. **Writes on approval** in order: Customer page → Active Package → Session records. Reports all Notion URLs and flags remaining gaps.

## After setup

Once the Active Package is in place, run `/customer-plan --full [customer]` to build the program plan on top of it.
