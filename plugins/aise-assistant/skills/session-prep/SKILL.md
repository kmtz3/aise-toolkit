---
name: session-prep
description: Prep for a customer session — pulls context, drafts a brief, writes it to the session's Planhat Task/Conversation (custom.Prep Notes), and generates an interactive HTML facilitation guide (auto for A/Discovery/Kickoff sessions)
---

Prep the user for the customer session identified in the user's message (customer name, session type, and/or date).

Read the procedure in `agents/session-prepper.md` and execute it inline as the main assistant — do not try to spawn `session-prepper` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types). The steps:

1. Confirm date, attendees, and session type (Google Calendar lookup).
2. Pull context from Planhat (Company record, contracted session pool, recent Conversations), Glean (including Slack channel search), Gmail, Salesforce (fallback for missing snapshot fields), and past chats — in parallel.
3. Consult `context/pb-aise-reference-guide.md` (what-good-looks-like) and `context/score-cards.md` for the session type.
4. Draft a prep brief: customer context, goals, KDDs to drive, open items, risks, suggested agenda, questions to ask.
5. Resolve the session's Planhat Task or Conversation (GCal-event-id ladder, never a title search first — see `agents/session-prepper.md` § 5) and write the brief to `custom.Prep Notes`, single-line HTML per `context/planhat-schema.md` § Rich Text Field Formatting.
6. **If the session is `🏗️ Architecting`**, also build the customer-facing KDD doc (title, agenda, outcome, action items, per-KDD starter examples + blank decision tables) per `templates/session-kdds/00-index.md`, publish it to Google Drive, and prepend the artifact link to `custom.Prep Notes` on the same record. Also update Company `custom.Architecture Details` if the session's decisions changed the customer's workspace configuration.
7. **Generate facilitation HTML guide** — execute `skills/session-facilitation/SKILL.md` inline after the KDD doc (when applicable) is written. Auto-generates for `🏗️ Architecting`, `🔎 Discovery`, and `👟 Kick off` sessions. Offers (does not auto-run) for Sync and Training. Saves to `~/Desktop/aise-assistant/facilitation/`.
8. **Publish the artifacts to Drive and link them back into Planhat** — follow `context/session-artifact-convention.md` end to end. Resolve (or create) the `Customer Session Artifacts` folder, resolve and verify the Salesforce Account Id via the Planhat Company `sourceId`, upload each generated file as `{CustomerName}_{YYYY-MM-DD}_{SalesforceAccountId}_{ArtifactType}.ext` (`SessionPrep` for the prep brief, `KDD` for the KDD doc, `Facilitation` for the facilitation guide), and prepend the artifact link block to `custom.Prep Notes` on the session's Planhat calendar-event Task — falling back to the session Conversation when no event Task exists. A file with the same name already in the folder is updated in place, not duplicated.
9. Report back with links (Planhat Task/Conversation URL, KDD Drive link when created, facilitation guide file path, **Drive link per artifact and which Planhat record each link landed on**) and any gaps or contradictions surfaced. Call out explicitly if the Drive folder had to be created or a Planhat write failed.

Do NOT ask the user for context that's retrievable. Search first, ask once if something is genuinely missing.

## Compound requests

Users often bundle related asks with `/session-prep`. Recognize these add-ons and route each to its handler in the same run — do not ask the user to invoke them separately.

| Phrase pattern | Handler |
|---|---|
| _"make me a task to [X]"_, _"add a task for [X]"_ | Create a Planhat Task (PB-side, `ownerId` = current user, `companyId` required) — see `context/planhat-schema.md` § Task priority & description defaults for priority/due-date/scaffold logic. Slot in after Step 5. |
| _"read the gmail [agenda]"_, _"check what [stakeholder] sent"_ | In Step 2, specifically search Gmail for customer-proposed agendas sent in the last 7 days. In Step 4, give the customer's proposed agenda **priority weight** — it's the backbone of the suggested agenda, adapted with scorecard criteria, not replaced. |
| _"what should I do before"_, _"pre-call checklist"_ | In Step 9, include a **Pre-call checklist** section listing concrete actions for the user before the session (overdue tasks, space prep, pre-reads to send, Slack pings to make). |
| _"full session plan"_, _"minute-by-minute"_, _"run sheet"_ | In Step 9, include a **Session plan** — time blocks with what to say/do/decide in each block, plus contingencies (e.g. _"if Kate is absent, defer D7.2"_). |
| _"draft diagram"_, _"diagram in figma"_, _"visualize the integration"_ | After the primary Planhat write lands, spawn `diagram-builder` (per the context-management ordering in `agents/session-prepper.md`). If the sub-agent reports Figma MCP unavailable, finish the Drive upload + Planhat Attachment in the main conversation. |
| _"facilitation guide"_, _"facilitation html"_, _"run sheet"_, _"no facilitation guide"_ / _"skip the facilitation"_ | The facilitation HTML is auto-generated for A/Discovery/Kickoff sessions — explicit mention overrides the default. "no facilitation guide" or "skip the facilitation" suppresses it. Explicit request forces it even for Sync/Training sessions. |

**Context-management ordering for compound requests.** Write the primary deliverable (`custom.Prep Notes` on the resolved Task/Conversation) first, then create secondary deliverables (Task, KDD doc), and only then spawn expensive sub-agents (diagram-builder). This prevents context-window compaction mid-run. See `agents/session-prepper.md` § Context management.
