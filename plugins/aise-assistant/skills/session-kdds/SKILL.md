---
name: session-kdds
description: Generate a customer-facing KDD doc for an architecting session — lands as a sub-page of the Notion Session page, ready to copy-paste into the customer's space
---

Build the customer-facing KDD doc for.

Read the procedure in `agents/kdd-builder.md` and execute it inline as the main assistant — do not try to spawn `kdd-builder` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types). The steps:

1. Resolve the target architecting session (Sessions DB → customer + `Type = 🏗️ Architecting` + `Planned`). If a session-id (e.g. `A1`) is passed, use that. If multiple candidates, ask once.
2. Match the session to the right template in [`templates/session-kdds/`](../templates/session-kdds/) per the library in `00-index.md`. Stop if not an A-session or no clean template match.
3. Pull customer context — Active Package page body, prior Session decisions (`D#`), discovery notes, terminology — so starter examples are real, not fabricated.
4. Build the doc per the **Customer-facing KDD doc** spec in `templates/session-kdds/00-index.md`: Title · Subtitle · Agenda · Outcome · Action items · per-KDD (Question + Starter example + blank Decision table). D-numbering continues from the customer's register.
5. Create a Notion **sub-page** of the Session page titled `KDDs — [Session ID] [Session Name]` with the full doc in the body. Leaves the `📋 Prep` toggle on the parent Session page untouched.
6. Report back with the sub-page link, which KDDs were seeded from real data vs left blank, and any source conflicts.

**Use for A-sessions only.** Sync / Training / Discovery / Kickoff sessions don't get this doc — the agent will stop and say so.

Don't invent stakeholders, team names, or prior decisions. Cite sources or leave blank.
