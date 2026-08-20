---
name: customer-setup
description: Research a newly assigned or inherited customer — company overview, products they bring to market, their use cases with Productboard, org/toolstack, stakeholders — and write the findings as a Planhat Conversation note on the Company record.
---

Set up account for.

Read the procedure in `agents/account-setup.md` and execute it inline as the main assistant — do not try to spawn `account-setup` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types).

## Flags

Canonical syntax uses `--force-new`, but also recognize natural language variations — e.g. "research Acme", "set up Acme", "refresh the research for Acme" all run the default (research, enrich if a note already exists); "redo the research from scratch for Acme", "start fresh" map to `--force-new`.

| Flag | Natural language equivalents | What it does |
|---|---|---|
| *(none)* | "set up", "research", "onboard" | Research the customer. If a Planhat research note already exists on the Company record, enrich it (prepend new findings, keep prior content). Otherwise create a fresh one. |
| `--force-new` | "start fresh", "redo the research", "ignore the old note" | Skip enrichment — write a brand-new research note even if one already exists. |

## The procedure

1. **Resolves the Planhat Company** for the customer (name search → SF `sourceId` fallback → `domains` fallback — see `context/planhat-schema.md`). If no Company record exists yet, stops and flags it — nothing to attach research to until Salesforce sync creates one.
2. **Checks for an existing research note** — a Planhat Conversation (`type: "note"`, subject `Account Research — <Company>`) on the Company record. If found (and `--force-new` wasn't passed), this run enriches it rather than replacing it.
3. **Researches in parallel** — web search (company overview, industry, tech stack), Planhat Sales Handoff fields (auto-populated at deal close), Gong via Glean (goals, product areas, use cases, org structure), Gmail/Glean (stakeholders, handoff context).
4. **Synthesizes** a write-up: company overview, products they bring to market, customer's use cases with Productboard, org/toolstack, key stakeholders, open items — citing sources, never fabricating gaps.
5. **Proposes in chat (always — never writes without confirmation)** the full write-up, flagging any thin sections.
6. **Writes on approval** — creates a fresh Planhat Conversation note, or prepends a dated enrichment block to the existing one.

## After setup

Once the research note is in place, run `/customer-plan --full [customer]` to build the program plan.
