# Engagement Program Planning Guide

How to draft a structured, phased onboarding program for a new Productboard AISE engagement. This is the reference for `/customer-plan --full`.

Reference case: **Kpler Holding SA** (Q1 2026) — program plan and session log, reachable via Glean.

---

## Purpose

Use this when a new customer is assigned, or when an existing program needs a full restructure. The output is a decision-ready plan that lands in the customer's Planhat Company `custom.Engagement Plan` field. The user can then work against it for the rest of the engagement.

This is for **program-level planning** only. Individual session prep, debriefs, and facilitator guides are separate workflows (`/session-prep`, `/session-summary`, `/customer-plan --next`).

---

## When to invoke

Trigger phrases:
- "Plan the engagement for [customer]"
- "Draft a program plan for [customer]"
- "Scope the onboarding for [customer]"
- "Restructure the plan for [customer]"
- "Build me a session plan for [customer]"

Do **not** invoke for single-session prep, debriefs, decision register updates, or individual deliverable requests. Route those through `/session-prep`, `/session-summary`, or `/customer-plan --next`.

---

## Inputs to confirm up front

Before drafting, verify you have the following. Pull via Glean / Planhat / Gmail / Salesforce first. If anything is still missing, ask once as a single consolidated question, then proceed with stated assumptions.

1. **Customer name** and industry
2. **Contracted scope** — total Architecting + Training session pool, from `custom.AISE Working Sessions` summed across the Company's active `Line Item` records (`context/planhat-schema.md` § AISE Working Sessions). It's one shared pool, not separate Architecting/Training caps — both session types draw from it.
3. **Program owner** on customer side (primary decision-maker, day-to-day)
4. **Executive sponsor** (sign-off gate)
5. **Target timeline** — e.g. "Q1 live", or a specific milestone date
6. **Pilot team(s)** or starting BU/vertical
7. **Key pain points** driving the purchase (roadmap visibility, feedback sprawl, prioritization chaos, etc.)
8. **Known blockers** — admin bottlenecks, missing stakeholders, tool dependencies
9. **Prior tool usage** — what they're migrating away from, what stays
10. **Org shape** — tribes/BUs/crews, or equivalent hierarchy

---

## Core framework

Every program plan has five layers. Build them in this order.

### 1. Goals

Business outcomes, **not** feature adoption. Format:

| Goal | Success metric | Measurement window |
|---|---|---|
| Unified roadmap visibility across BUs | BU leaders self-serve roadmap view weekly | 30 days post-rollout |

Aim for 3–5 goals. Every goal ties to a customer-stated pain point.

### 2. Milestones

Phase-level checkpoints tied to goals. Outcome-based, never activity-based.

| Milestone | Target date | Gate criteria |
|---|---|---|
| Phase 1 pilot live | End of Q1 | Pilot crews using PB for roadmap + backlog daily |

"A3 delivered" is **not** a milestone. "Roadmap views live for pilot crews" is.

### 3. Phases

Standard Productboard phasing (aligns with `context/pb-aise-reference-guide.md` §1):

- **Phase 0** — Scoping, kickoff, tiger team setup. Usually `S`-sessions.
- **Phase 1** — Foundations → Backlog → Roadmaps. The core architecture block.
- **Phase 2** — Insights, OKRs, rollout to additional tribes/BUs.
- **Phase 3+** — Optimization, expansion, advanced workflows (Spark, integrations, portals).

**Rule:** Keep Phase 1 tight. Defer anything that doesn't block pilot go-live.

### 4. Sessions

The deliverable layer. Each session has a purpose, length, attendees, topics, outputs, and a unique ID following the naming conventions below.

### 5. Parallel streams

Admin/IT work (SCIM, Okta, Jira integration, Salesforce sync) usually runs parallel to the PM-facing architecture stream. Call it out explicitly — it's often owned by a different stakeholder (IT lead) and should not block the architecture stream.

---

## Session naming conventions

Three prefixes. Numbering is sequential **within** each prefix, not across prefixes. Start `S` numbering at `S0` if there's an informal scoping call before kickoff.

### A-sessions — Architecting (counted)

- **Format:** `A1`, `A2`, … `AX`
- **Counts against:** Architecting Sessions allocation on the Active Package
- **Use for:** Any session where Key Design Decisions (KDDs) are made — Foundations, Backlog, Roadmaps, Insights, Prioritization, Spark architecture, OKRs, integration design
- **Must produce:** Numbered entries in the decisions register (`D1`, `D2`, …)
- **Rule:** If a session doesn't drive KDDs, it's not an A-session.

### E-sessions — Enablement (counted)

- **Format:** `E1`, `E2`, … `EX`
- **Counts against:** Training Sessions allocation on the Active Package
- **Use for:** PM training, admin training, contributor/viewer onboarding, rollout enablement for new crews/tribes
- **Must produce:** Enabled team, documented workflow, confirmed adoption path
- **Rule:** Schedule E-sessions **after** the relevant architecture is locked. Don't train on structure that isn't built.

### S-sessions — Syncs & Discovery (uncounted)

- **Format:** `S0`, `S1`, … `SX`
- **Does NOT count:** Excluded from the contracted session pool — see `context/planhat-schema.md` § Line Item. S-sessions don't draw from `custom.AISE Working Sessions`.
- **Use for:**
  - Informal scoping / pre-kickoff calls
  - Kickoffs
  - Discovery sessions (when not contractually counted)
  - Unblocking syncs with a single stakeholder
  - Standing check-ins or async catch-ups
- **Rule:** S-sessions are overhead. They don't produce ledger-counted decisions. If a discovery session produces KDDs, reclassify it as an A-session.

### Quick reference

| Prefix | Name | Counts? | Typical outputs |
|---|---|---|---|
| `S` | Sync / Discovery | No | Notes, alignment, scope confirmation |
| `A` | Architecting | Yes (Architecting) | KDDs, configuration backlog, decisions register entries |
| `E` | Enablement | Yes (Training) | Enabled team, workflow docs, adoption path |

---

## Session design rules (gold standard)

Apply the AISE Score Card principles (`context/score-cards.md`) to every A-session draft:

1. **Frame as a design workshop**, not a feature demo. State outcomes at the top of the session brief.
2. **Let the customer arrive at structure.** Don't pre-build answers. The draft should list topics and outcomes, not prescribe decisions.
3. **Plan for live KDD capture.** Every A-session should produce 5–15 entries in the decisions register.
4. **Plan the synthesis close.** Every A-session brief ends with: decisions summary → open items → named owners → next session objective → customer confirmation. Missing synthesis is the most common score-killer.
5. **Red flags prepped.** Over-engineering, "let's customize later", "give everyone admin", "we'll use tags for everything" — the facilitator guide should list these with rebuttals.
6. **Split customer-facing from internal docs.** The program plan is customer-facing. Internal facilitator guides (opening scripts, red flag tables, contingency plans) are separate artefacts.

---

## Output format

Produce a single markdown artefact with this structure. This is what lands inside the toggle heading on the Active Package page body.

```markdown
# [Customer] – Program Plan
*Updated [date]*
*[One-line priority framing — e.g. "Sequenced around [sponsor's] priority: X first, Y second"]*

> **Program Owner:** [name] | **Technical Lead:** [name] | **Exec Sponsor:** [name]
> **Pilot teams:** [list]
> **Phase 1 target:** [outcome + date]
> **A-sessions: [X/X] remaining | E-sessions: [X/X] remaining**

---

## Status
| Session | Status |
|---|---|

---

## Goals
[Table per §1]

---

## Milestones
[Table per §2]

---

## Phase 1 – [Name]

### Architecture stream (PM-facing)
| # | Session | Length | Attendees | Topics | Outputs |
|---|---|---|---|---|---|
| A1 | ... | ... | ... | ... | ... |

### Admin stream (parallel, IT-owned)
| # | Session | Length | Attendees | Topics | Outputs |
|---|---|---|---|---|---|

### Enablement
| # | Session | Length | Attendees | Scope | Outputs |
|---|---|---|---|---|---|
| E1 | ... | ... | ... | ... | ... |

---

## Phase 2+
*Outline only — detail deferred until Phase 1 is stable.*

---

## Key decisions confirmed
| Decision | Outcome |
|---|---|

---

## Open items
| Item | Owner | Priority |
|---|---|---|

---

## Risk log
| Risk | Severity | Mitigation |
|---|---|---|
```

Keep Phase 2+ intentionally thin. Over-planning downstream phases creates false commitment and invites scope creep.

---

## Quality checks before returning the draft

Verify every one of these:

- [ ] Every session has a unique ID following A / E / S conventions
- [ ] A-session count ≤ contracted Architecting allocation
- [ ] E-session count ≤ contracted Training allocation
- [ ] S-sessions are clearly flagged as uncounted
- [ ] Every milestone is outcome-based, not activity-based
- [ ] Every open item has a **named** owner (not "TBD", not "team")
- [ ] Every risk has a mitigation, not just a severity flag
- [ ] Parallel admin stream is called out if IT/SCIM/integrations are in scope
- [ ] Phase 2+ is outlined but not over-specified
- [ ] Every A-session has an expected KDD yield in its outputs column

---

## Where the plan lands

1. **Primary home — the only home:** the customer's Planhat Company `custom.Engagement Plan` rich-text field (single-line HTML per `context/planhat-schema.md` § Rich Text Field Formatting). Do **not** split the plan across a Drive doc or a Comment — the field is the whole plan, replaced wholesale on each approved revision (not appended to). Prior versions aren't preserved in-field; if history matters, note the change under a dated heading within the field itself rather than relying on Planhat's own record history.
2. **No placeholder Session records.** Unlike the retired Notion workflow, this plan does **not** create forward-looking "Planned" Conversation stubs — Planhat's Conversation model represents things that already happened (`date` = when the session took place), so there's no clean placeholder shape for a future session. The plan's session-by-session table *is* the record of what's planned; an actual Planhat Conversation gets created only when the session is delivered, through the normal `session-prepper`/`post-session-debrief` path.
3. **Do NOT** create Tasks for customer-side action items surfaced during planning — those live in the plan's Open items table. Only PB-side tasks (work the user will do) go into Planhat Tasks.

See `context/planhat-schema.md` for field formats and write rules.

---

## Reference case

**Kpler Holding SA** (Q1 2026) is the canonical example, from the era when this plan lived in Notion. When in doubt about structure, depth, or tone, pull it via Glean (it predates the `custom.Engagement Plan` field) and match that level of specificity, formatting, and decisions density.

---

## Tone & voice

- American English throughout (`customize`, `organize`, `color`)
- Semi-formal, calm, confident, outcome-focused
- Bolded section labels, bulleted structure, table-heavy
- Inline code formatting for field names, statuses, session IDs (`A1`, `Released`, `BU / Tribe`)
- No fluff, no corporate buzzwords, no padding
- Decisions-first; narrative only where it earns its place

Full voice reference: `context/communication-style-guide.md`.

---

## Out of scope for this workflow

Route elsewhere if asked for:
- Individual session prep or facilitator guides → `/session-prep`
- Session debriefs or scoring → `/session-summary`, `/session-score`
- Decisions register updates → `/session-summary`
- Customer comms drafting (Slack, email) → `/draft-followup`
- Stakeholder maps or org diagrams → separate
- Configuration backlogs → separate

Those are separate commands/agents.
