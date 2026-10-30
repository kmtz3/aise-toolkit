---
name: customer-handover
description: Build the sales-to-AISE handover for a deal that is closing or just closed – pulls the full pre-sales context from Salesforce, Gong, Gmail, Slack, Drive and the Productboard workspace, synthesizes it into the five POPIT pillars (People, Organisation, Process, Information, Technology) with every field sourced, and writes it into Planhat in two steps – first a Sales Handover Conversation for the AE to vouch for (plus Engagement Role + a pending sales read on the customer's End Users), then, after the AE sets Validated – Ready, the Company SH_ fields, Organization Details, Engagement Plan goals, Architecture Details, Customer Toolstack and one Objective per customer goal. Use whenever an AE, FDE or AISE asks to hand a deal over, build or prep a POPIT / AISE handover, "handover for <company>", "POPIT <company>", or check onboarding readiness for a new customer before kickoff.
---

Build the sales handover for: **$ARGUMENTS**

Read the procedure in `agents/sales-handover.md` and execute it inline as the main assistant – do not try to spawn `sales-handover` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types).

## Flags

Canonical syntax uses flags, but recognize natural language too – "hand Acme over to AISE", "POPIT Acme", "build the handover for Acme", "is Acme ready for kickoff?" all run the default.

| Flag | Natural language equivalents | What it does |
|---|---|---|
| *(none)* | "handover for", "POPIT", "hand over", "prep the AISE handover" | Full run: enrichment sweep → POPIT synthesis → Sales Handover Conversation + End User roles and pending reads → readiness summary in chat. No Company fields, no Objectives. |
| `--dry-run` | "just show me", "preview the handover", "don't write anything" | Build everything and show it in chat. No Planhat writes. |
| `--opportunity <SF id or name>` | "for the expansion deal", "the Q4 opportunity" | Pin the handover to one opportunity when the account has more than one open or recent deal. |
| `--force` | "overwrite the validated handover", "re-pull everything" | Full re-run over a Sales Handover already set to `Validated – Ready`. Resets it to `In progress`, so it needs a fresh vouch. |
| `--validated` | "sales validated the handover", "Petr signed off on Acme", "promote the handover", "push the validated handover" | Post-vouch mode. No new research. Builds every Company-level record from the validated Conversation (SH_ fields, Organization Details, Engagement Plan, Architecture Details, Customer Toolstack, Objectives), rewrites End User reads the AE corrected and stamps them validated. Never writes the Conversation. Stops if the status isn't `Validated – Ready`. Safe to re-run. |

## What it writes

| Where | What | When |
|---|---|---|
| Conversation `type: Sales Handover` | The POPIT document. Discovery Quadrant in the four `custom.SH_*` fields, everything else in `description`. `custom.Handover Status` = `In progress`. Linked to the Deal, the AE/FDE/AISE and the key contacts. | Full run |
| End User fields | `custom.Engagement Role`, `custom.AISE Relationship` (blank only), `custom.AISE Read` (sales read, labelled pending), `custom.AISE Read Reviewed`. Never creates a contact. | Full run; stamped validated by `--validated` |
| Company `custom.SH_*` (4) | The Discovery Quadrant, copied from the validated Conversation. | `--validated` |
| Company `custom.Organization Details` | Who they are, org and stakeholders, why they bought, commercial summary, AI strategy. | `--validated` |
| Company `custom.Engagement Plan` | Goals, required capabilities, Day 1 scope, reporting expectations, open items, risks. Phases and sessions are left for `/customer-plan --full`. | `--validated` |
| Company `custom.Architecture Details` | Planned Productboard integration setup: committed integrations and sequence, feedback sources to connect, gaps, technical owner. | `--validated` |
| Company `custom.Customer Toolstack` | Every tool named in the handover under CRM / Delivery / Automation / Feedback collection / Other. | `--validated` |
| `Objective` records | One per customer-stated goal. | `--validated` |

## The vouch step

1. `/customer-handover <customer>` writes the Conversation (`custom.Handover Status = In progress`) and the End User roles with sales reads labelled pending. Nothing touches the Company yet.
2. The AE reviews the Conversation in Planhat, corrects anything directly on the record, and sets it to `Validated – Ready`. That status change is the vouch. The procedure never sets it.
3. `/customer-handover <customer> --validated` builds the Company fields, Toolstack and Objectives from the validated Conversation – including every correction the AE made – and stamps the End User reads validated.

A full re-run stops at a validated record unless `--force` is passed.

## How it differs from neighbors

- `/customer-setup` – AISE's own outside-in research on an assigned account (web, products, use cases), written as a note. `/customer-handover` is the deal team's inside view of what was sold and why.
- `/customer-plan --full` – builds the full program (phases, A/E/S sessions) and runs after the handover, on top of the goals it seeds.
- `/customer-refresh` – maintains the same Company fields on a live account. Run it later in the program, not at handover.
