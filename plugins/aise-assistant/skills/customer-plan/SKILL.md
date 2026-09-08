---
name: customer-plan
description: Plan the customer's program. Two modes via required flag: --next (next 2–4 sessions for an ongoing program) and --full (complete engagement plan — goals, milestones, phases, sessions — for a new or restructured customer, written to Planhat).
---

Plan the customer's program. A mode flag is required:

- **`/customer-plan --next <customer>`** — map current program state and propose the next 2–4 sessions
- **`/customer-plan --full <customer>`** — build a full engagement program plan (goals, milestones, phases, sessions) and write it to the Company `custom.Engagement Plan` field in Planhat

If no mode flag is given, ask whether the user wants a quick next-phase plan (2–4 sessions) or a full program plan.

---

## `--next` — plan the next phase

Plan the next phase for: **$ARGUMENTS**

Read the procedure in `agents/customer-plan-next.md` and execute it inline as the main assistant — do not spawn a subagent.

**What it does:** Pulls Planhat state (Company, Line Items, Conversations, open Tasks, `custom.Engagement Plan`) + recent Glean/Gmail/Gong activity, maps the program to the phase model, produces a structured brief (current state, gaps, proposed session sequence, risks, customer asks), then optionally creates PB-side Tasks and — only if the proposal genuinely changes what's already sequenced — updates `custom.Engagement Plan`.

### Steps

1. Pull state from Planhat: Company + contracted session pool (sum `custom.AISE Working Sessions` across `ongoing` Line Items), recent Conversations (session history), open Tasks, EndUsers (contacts), current `custom.Engagement Plan` value.
2. Pull recent activity from Glean / Gmail / Gong / Calendar for anything that changed the picture, and read recent Company Comments for the latest logged program state.
3. Map current state to `context/pb-aise-reference-guide.md` phase map: what's done, in flight, not started.
4. Produce a structured brief:
   - **Current state** — phase, last delivered, what's blocked.
   - **Gaps & dependencies** — items that must close before the next session can happen (cross-check against setup checklists).
   - **Proposed sequence** — next 2–4 sessions in order, with rationale and expected output.
   - **Risks** — from the Common Risks table in the reference guide (🔴/🟠/🟡).
   - **What we need from the customer** — explicit asks with owner + timing.
5. Offer to create PB-side Tasks to back the plan, and — only if the sequence changes what `custom.Engagement Plan` currently says is next — offer to fold it into that field (replace-wholesale write, merge rather than drop the rest of the plan). No placeholder Conversation records: Planhat's Conversation model has no clean shape for a forward "Planned" session.

Don't invent stakeholder availability or commitments. Flag assumptions.

**Flags:**
- (no additional flags — customer name is the positional argument)

---

## `--full` — full engagement plan

Build the engagement program plan for: **$ARGUMENTS**

Read the procedure in `agents/engagement-planner.md` and execute it inline as the main assistant — do not spawn a subagent.

**What it does:** Pulls full customer context, drafts a goals/milestones/phases/sessions plan following `context/engagement-planning-guide.md`, iterates in chat, then writes the approved plan to the customer's Planhat Company `custom.Engagement Plan` field.

### Steps

1. **Locate the customer in Planhat.** Company record + contracted session pool (sum `custom.AISE Working Sessions` across active Line Items) + Contacts (EndUsers) + recent Conversations + any existing plan already on `custom.Engagement Plan`.
2. **Pull context in parallel** — Glean (Slack / Salesforce / Gong / Drive / Confluence for this customer), Gmail threads (AE handoff, kickoff coordination), Calendar (upcoming sessions already booked), past chats, recent Company Comments (running account working notes).
3. **Confirm scope inputs** (customer-side program owner, exec sponsor, pilot team, target timeline, key pain points, known blockers). If any can't be retrieved, ask once as a single consolidated question — do not ask for anything retrievable.
4. **Apply `context/engagement-planning-guide.md`** — goals → milestones → phases → sessions → parallel streams. Enforce A / E / S naming conventions and the quality-check list.
5. **Cross-check against standards** — scorecard principles (`context/score-cards.md`) and the phase map + common risks in `context/pb-aise-reference-guide.md`.
6. **Draft the plan in chat** using the output-format template from the guide. Iterate with the user before writing to Planhat.
7. **On approval, write to Planhat:**
   - `update_model_record(MODEL: "Company", ...)` to set `custom.Engagement Plan` — replaces the field wholesale, not an append.
   - Post the starting program state as a Company Comment (first Working Notes entry for this program).
   - No placeholder Session records — Planhat has no clean shape for a "planned" future session; the plan's own table is the record of what's scheduled.

Do NOT invent stakeholder names, dates, or commitments. Flag gaps. Flag conflicts between sources rather than silently picking.

**Flags:**
- (no additional flags — customer name is the positional argument)
