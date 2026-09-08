---
name: session-kdds
description: Generate a customer-facing KDD doc for an architecting session — publishes to Google Drive and attaches to the session's Planhat Conversation, ready to copy-paste into the customer's space
---

Build the customer-facing KDD doc for.

Read the procedure in `agents/kdd-builder.md` and execute it inline as the main assistant — do not try to spawn `kdd-builder` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types). The steps:

1. Resolve the target architecting session (Planhat Conversation/Task, `type = 🏗️ Architecting`) for the named customer. If a session-id (e.g. `A1`) is passed, use that. If multiple candidates, ask once.
2. Match the session to the right template in [`templates/session-kdds/`](../templates/session-kdds/) per the library in `00-index.md`. Stop if not an A-session or no clean template match.
3. Pull customer context — Company `custom.Engagement Plan` and `custom.Architecture Details`, prior Conversation decisions (`D#`), discovery notes, terminology — so starter examples are real, not fabricated.
4. Build the doc per the **Customer-facing KDD doc** spec in `templates/session-kdds/00-index.md`: Title · Subtitle · Agenda · Outcome · Action items · per-KDD (Question + Starter example + blank Decision table). D-numbering continues from the customer's register.
5. Publish to Google Drive (shared, direct-download link) and attach it to the session's Planhat Conversation as an Attachment record. Also update Company `custom.Architecture Details` if this session's decisions changed the customer's workspace configuration.
6. Report back with the Drive link, which KDDs were seeded from real data vs left blank, and any source conflicts.

**Use for A-sessions only.** Sync / Training / Discovery / Kickoff sessions don't get this doc — the agent will stop and say so.

Don't invent stakeholders, team names, or prior decisions. Cite sources or leave blank.
