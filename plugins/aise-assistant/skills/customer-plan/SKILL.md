---
name: customer-plan
description: Plan the customer's program. Two modes via required flag: --next (next 2–4 sessions for an ongoing program) and --full (complete engagement plan — goals, milestones, phases, sessions — for a new or restructured customer, written to Notion).
---

Plan the customer's program. A mode flag is required:

- **`/customer-plan --next <customer>`** — map current program state and propose the next 2–4 sessions
- **`/customer-plan --full <customer>`** — build a full engagement program plan (goals, milestones, phases, sessions) and post it to the Active Package page in Notion

If no mode flag is given, ask whether the user wants a quick next-phase plan (2–4 sessions) or a full program plan.

---

## `--next` — plan the next phase

Plan the next phase for: **$ARGUMENTS**

Read the procedure in `agents/customer-plan-next.md` and execute it inline as the main assistant — do not spawn a subagent.

**What it does:** Pulls Notion state + recent Glean/Gmail/Gong activity, maps the program to the phase model, produces a structured brief (current state, gaps, proposed session sequence, risks, customer asks), then optionally creates Session records (Planned status) and PB-side Tasks in Notion.

### Steps

1. Pull state from Notion: Customer page, Active Package (remaining credit, dates), Session history, open Tasks, Contacts.
2. Pull recent activity from Glean / Gmail / Gong for anything that changed the picture.
3. Map current state to `context/pb-aise-reference-guide.md` phase map: what's done, in flight, not started.
4. Produce a structured brief:
   - **Current state** — phase, last delivered, what's blocked.
   - **Gaps & dependencies** — items that must close before the next session can happen (cross-check against setup checklists).
   - **Proposed sequence** — next 2–4 sessions in order, with rationale and expected output.
   - **Risks** — from the Common Risks table in the reference guide (🔴/🟠/🟡).
   - **What we need from the customer** — explicit asks with owner + timing.
5. Offer to create Session records (Planned status) and PB-side Tasks in Notion to back the plan.

Don't invent stakeholder availability or commitments. Flag assumptions.

**Flags:**
- (no additional flags — customer name is the positional argument)

---

## `--full` — full engagement plan

Build the engagement program plan for: **$ARGUMENTS**

Read the procedure in `agents/engagement-planner.md` and execute it inline as the main assistant — do not spawn a subagent.

**What it does:** Pulls full customer context, drafts a goals/milestones/phases/sessions plan following `context/engagement-planning-guide.md`, iterates in chat, then writes the approved plan to the Active Package page body in Notion under a toggle heading.

### Steps

1. **Locate the customer in Notion.** Customer page + Active Package + Master Package (contracted allocation) + Contacts + any existing Sessions. Pull the Active Package URL — that's where the plan will land.
2. **Pull context in parallel** — Glean (Slack / Salesforce / Gong / Drive / Confluence for this customer), Gmail threads (AE handoff, kickoff coordination), Calendar (upcoming sessions already booked), past chats, the 🧠 Working Notes toggle on the customer's Active Package page in Notion.
3. **Confirm scope inputs** (customer-side program owner, exec sponsor, pilot team, target timeline, key pain points, known blockers). If any can't be retrieved, ask once as a single consolidated question — do not ask for anything retrievable.
4. **Apply `context/engagement-planning-guide.md`** — goals → milestones → phases → sessions → parallel streams. Enforce A / E / S naming conventions and the quality-check list.
5. **Cross-check against standards** — scorecard principles (`context/score-cards.md`) and the phase map + common risks in `context/pb-aise-reference-guide.md`.
6. **Draft the plan in chat** using the output-format template from the guide. Iterate with the user before writing to Notion.
7. **On approval, post to Notion** following the `agents/notion-writer.md` procedure (read and run inline):
   - Append a collapsible toggle heading `🗺️ Program Plan — YYYY-MM-DD` to the **Active Package page body** (not the Customer page).
   - Optionally create `Call Status = Planned` Session records for each session in Phase 1, linked to the Customer and `Consumed Package = [Active Package]`.
   - Only create Tasks for PB-side action items (the user's work), never customer-side.

Do NOT invent stakeholder names, dates, or commitments. Flag gaps. Flag conflicts between sources rather than silently picking.

**Flags:**
- (no additional flags — customer name is the positional argument)
