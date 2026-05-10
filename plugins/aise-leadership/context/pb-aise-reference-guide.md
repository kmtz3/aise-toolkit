# Productboard AISE Reference Guide
*Generalized knowledge base — session methodology, scorecards, data model, architecture rules, onboarding patterns*
*No customer-specific content.*

---

## Table of Contents

0. [Account Team Model](#0-account-team-model)
1. [Program Structure & Session Types](#1-program-structure--session-types)
2. [What Good Looks Like — Session-by-Session (Scorecard Standards)](#2-what-good-looks-like--session-by-session-scorecard-standards)
3. [Productboard Data Model & Architecture](#3-productboard-data-model--architecture)
4. [Seat Licensing Model](#4-seat-licensing-model)
5. [Integrations Landscape](#5-integrations-landscape)
6. [New Project Setup Checklist](#6-new-project-setup-checklist)
7. [Common Risks & Mitigation Patterns](#7-common-risks--mitigation-patterns)
8. [Internal Communication Conventions](#8-internal-communication-conventions)

---

## 0. Account Team Model

Three roles cover every account. Each is assigned per account independently — there are no dedicated fixed combos.

| Role | Abbrev. | Responsibility |
|---|---|---|
| Account Executive | AE | Commercial owner, upsell, contract negotiations |
| Renewal Manager | RM | Renewal and contract health |
| AI Success Engineer | AISE | Onboarding program, adoption, technical guidance |

**"CSM" is not a Productboard role.** Never use this term. The AISE is the post-sales success role.

---

## 1. Program Structure & Session Types

### Phase map (typical sequence)

| Phase | Focus | Sessions |
|---|---|---|
| **0 — Scoping / Tiger Team** | Confirm program ownership, align on goals, gather artefacts | Informal scoping call |
| **1 — Discovery & Success Planning** | Technical discovery, current state, stakeholder mapping, success plan | Technical Discovery, Success Planning |
| **2 — Foundations** | Data model, workspace structure, identity | Foundations Architecture, Okta/SCIM/Workspace |
| **3 — Insights** | Feedback pipeline design, Harvester/legacy replacement | Insights Architecture |
| **4 — Prioritization & PDLC** | Backlog structure, scoring model, lifecycle stages | Prioritization Architecture |
| **5 — Roadmaps** | Persona-based roadmap portfolio | Roadmap System Design |
| **6 — Spark** | AI for PM workflows | Spark Workshop |
| **7 — Integrations & Rollout** | Jira, SFDC, Slack integrations, pilot training, comms cadence | Integrations Working Session, Enablement & Rollout |

### Session types
- **Architecting sessions** — design and decision workshops. Not feature demos. Output = KDDs and configuration backlog.
- **Admin / parallel stream** — Okta/SCIM, Jira integration. Run in parallel with PM sessions. Attendee = IT/admin only.
- **Training / enablement** — after architecture is locked. Target = pilot users and then broader rollout cohorts.

### Typical attendee split
- **Core PM group** — all architecting sessions (A1–A6)
- **IT/Admin** — separate parallel stream (Okta, SCIM, Jira)
- **Exec sponsor** — kickoff, review checkpoints, QBR
- **Strategy/OKR lead** — strategic planning session only
- **CS/Marketing** — insights and roadmap sessions where relevant

---

## 2. What Good Looks Like — Session-by-Session (Scorecard Standards)

> **Summary only** — see `context/score-cards.md` for full rubrics and 0–5 scoring definitions.

Each session is scored 0–5 per dimension. The overall framing principle across all sessions: **you are running a design/decision workshop, not a feature demo.** That distinction is the foundation of every high score.

---

### Universal session opener (applies to ALL sessions)
Every session must explicitly include all five of these to score 4–5:

- **A** — Time check and session structure
- **B** — Frame the session type clearly (discovery / architecture / workshop — not "a tour of the product")
- **C** — State the outcomes: what must be decided or produced by end of session
- **D** — Participation expectations: who contributes to which decisions
- **E** — Next-step logic: how today's outputs feed the next session or configuration work

**Score 5** = all five explicit AND customer confirms alignment.
**Score 3** = three to four elements present but some missing.
**Score 0–1** = generic intro with no real framing.

---

### Technical Discovery

| Dimension | What a 5 looks like |
|---|---|
| Upfront contract + framing | All five opener elements explicit. Customer agrees. |
| Org structure + stakeholder mapping | Uncovers: org structure, products/domains, core PM roles, cross-functional stakeholders, *and* variation across teams (not assuming one team = universal) |
| Strategic alignment | OKRs at multiple levels, cadence, responsible stakeholders, how strategy maps to product work, *and* known disconnects between strategy and execution — with at least one real objective or KR as an example |
| Feedback intake | Covers providers, channels/tools, consolidation point, triage owner + cadence, how feedback influences decisions, *and* pain points. Not just "what tools do you use." |
| Backlog management | Hierarchy/structure, tool-role distinctions, PDLC phases, how requirements evolve, team rituals, *and* pain points at handoffs |
| Prioritization | Framework/methodology, data attributes, segmentation logic, CRM representation, readiness definition, *and* pain points or inconsistency |
| Roadmap communication | Roadmap types, audiences, information needs by audience, cadence, tools in use, *and* pain points in maintenance |
| Gap synthesis | Explicitly summarizes: setup priorities, team/process differences, gaps/risks, open assumptions — *and gets customer to confirm the summary* |
| Close + next steps | Named next step, explicit timing, customer homework with owners, objective for next session tied to this session's gaps, customer confirms |

**Key failure mode:** Spending 80% of the session on current state tooling and never synthesizing implications. A discovery that ends with "we got lots of good info" and no synthesis scores a 2–3 at best.

---

### Foundations Session

| Dimension | What a 5 looks like |
|---|---|
| Session framing | Architecture/design decision workshop — not feature training. All five opener elements. |
| Data model + hierarchy | Product hierarchy defined with *customer-specific* level definitions (not just "features and sub-features"). Strategic hierarchy defined. JTBD vs product-area tradeoffs explored. |
| Teamspace architecture | Organization approach, folder logic, teamspace *types* (Open/Closed/Private) with rationale, product permission strategy, filtering criteria |
| Teams + roles | What "Teams" represent, how used for ownership/filtering, full role mapping (Admin Maker / Maker / Contributor / Viewer) to real personas, access risk discussion |
| Feature status design | Customer's actual PDLC stages mapped to PB statuses, movement criteria defined, team variation addressed (standardize vs allow flexibility) |
| Feature description templates | Required fields defined, template ownership agreed, consistency/handoff rationale, customer-specific sections (compliance, GTM, etc.) |
| Custom fields governance | Hierarchical vs metadata fields distinguished, naming standards, anti-duplication principle, governance owner and pruning cadence |
| KDD facilitation | AISE *drives* decisions — doesn't just present options. Captures: hierarchy, teamspaces, folder logic, statuses, templates, field governance, open items with owners |
| Close | Decisions summarized, open items with owners, next session objective, realistic sequencing, customer confirms |

**Red flags to address explicitly (don't let these slide):**
- "We want every team to do something different" → surface implications, offer standardization guidance
- "Give everyone admin" → explain admin scope and risk
- "We'll define hierarchy later" → block this — hierarchy must be decided before anything can be configured
- "Let's use tags for everything" → tags have a role; they don't replace fields or statuses
- "General Teamspace will be [our small team's space]" → General has a specific purpose; explain it

---

### Insights Session

| Dimension | What a 5 looks like |
|---|---|
| Session framing | Feedback *process design* session — not a notes feature walkthrough. All five opener elements. |
| Stakeholder + source mapping | Internal + external feedback providers, all current channels, high-volume vs high-value distinction, source ownership, gap/noise risks |
| Triage workflow design | Who reviews, how often, steps to process a note, @mention criteria, ownership assignment, what "processed" means, cadence sustainability |
| "Good feedback" definition | What makes feedback valuable (problem, impact, who, context), required vs encouraged fields, template/form approach, contributor enablement per source type |
| Note anatomy + tagging | Key note components, tagging strategy and conventions, topics/sentiment usage, owner and status standards, anti-sprawl governance |
| Automations | Pattern-based automation identification per source, prioritized list, dependencies/requirements, governance/review cadence |
| Company data + segmentation | Source (typically CRM), sync cadence, required attributes/divisions, custom company field design, dynamic segment strategy, data quality risks |
| Portal strategy | Whether to use portals, audience design, structure, share settings, feedback submission routing, loop closure |
| Downstream linkage | Explicitly connects insights setup to: VOC-informed prioritization, feature linkage, segment visibility, stakeholder communication, adoption reinforcement |
| Close | All KDDs captured, AISE action items separated from customer action items, next session objective, customer confirms |

---

### Prioritization Session

| Dimension | What a 5 looks like |
|---|---|
| Session framing | Prioritization *process and system design* — not a scoring tool demo. All five opener elements. |
| PDLC mapping | Customer's lifecycle stages → PB statuses, stage movement criteria, where prioritization actually happens (multiple stages, not one), artifact/system action distinction |
| Methodology + criteria | Framework(s) chosen (RICE/value-effort/custom), core criteria, which criteria apply at which stage, team variation + standardization question, *movement logic* per stage |
| Drivers, formulas, scoring | Which drivers tracked, scoring/codification logic, formula design, required custom number fields, model scope (all teams vs specific boards), limitations/assumptions |
| Fields design | Default + custom fields, stage-specific field mapping, field purpose clarity, anti-duplication |
| Company data + segments | CRM source + cadence, required customer attributes, dynamic segment design, how segments support Customer Importance Score and prioritization decisions, data quality risks |
| Grid board architecture | Board directory by stage (backlog, evaluation, planning, release), purpose per board, filters + status scope, key columns per board, ownership/audience |
| Task usage | Whether tasks are used, which tasks tracked, ownership, status workflow, linkage to release management boards |
| Close | All KDDs captured with owners, AISE action items explicit (create segments, drivers, formulas, boards), next session tied to outputs |

---

### Roadmaps Session

| Dimension | What a 5 looks like |
|---|---|
| Session framing | Roadmap *communication system design* — not a roadmap feature demo. All five opener elements. |
| Persona + audience discovery | Named audiences, *job/purpose* per roadmap (not just "who sees it"), detail level per audience, questions each audience needs answered, explicit acknowledgment that one roadmap doesn't serve all audiences |
| Board type selection | Grid vs roadmap distinction (inputs/decisions vs communication/output), timeline vs column distinction (time-based vs status/bucket), selection rationale per use case, no one-size-fits-all |
| Roadmap schema design | Main item per roadmap, grouping/swimlane logic, milestone/event needs, structural conventions per type, rationale tied to audience and purpose |
| Metadata + card attributes | Per-persona card attribute requirements, which exist vs need building in PDLC, prerequisites (timeframes for timeline, releases for column), ownership + process for keeping populated, risks if empty |
| Strategy + prioritization alignment | Roadmaps as *outputs* of prioritization/strategy, not manual decks. VOC + VOB decision backing. Dynamic roadmap concept (living artifact, not a snapshot). |
| Placement + access | Where each roadmap lives (which teamspaces), access by audience, internal vs shareable, governance/ownership per view |
| Portfolio design | Small set of persona-specific roadmaps (one per job/persona), purpose + board type + main item + metadata per roadmap, minimum viable launch set vs future additions, explicit rejection of monolithic master roadmap |
| Configuration prerequisites | Data dependencies (timeframes, releases, fields), missing setup from prior sessions that blocks implementation, sequencing, automatic upkeep via process |
| Close | Decisions per roadmap, open items, AISE action items (create column/timeline views, release groups, sharing settings), customer confirms |

---

### Spark Workshop

| Dimension | What a 5 looks like |
|---|---|
| Session framing | Spark *workflow onboarding* — not an AI feature demo. Outcomes include: align on use cases, run one real workflow end to end, define context approach, set adoption next steps. |
| Use case prioritization | Customer's top PM pain points identified, specific use cases prioritized with rationale (why these first, what's deferred), aligned to team maturity and process readiness |
| Positioning + differentiation | Spark as purpose-built PM workflow tool (not generic chat), persistent/shared context value, guided workflows for quality + repeatability, realistic positioning including *current limitations* |
| Context strategy | Shared/evergreen context vs session-specific inputs, high-signal sources first (not "upload everything"), naming/organization standards, explicit linkage between context quality and output quality |
| Workflow execution | Real customer scenario (not a canned demo), one core job run collaboratively (Feedback Analysis, Product Brief, Competitor Analysis, etc.), customer inputs prompts/decisions, *usable draft produced*, quality analysis at end |
| Human judgment + review | How to validate outputs vs source context, identifying weak assumptions/generic content, required review before sharing, how to iterate, responsible expectation setting (Spark accelerates PM work, doesn't replace PM judgment) |
| Workflow integration | Where Spark fits in existing PM rituals, which cadences it supports, who uses it first (pilot PMs), what outputs move downstream, anti-demo-only adoption strategy |
| Usage economics | Usage focused on high-value workflows, usage planning guidance, credit/monitoring visibility, avoiding over-promising throughput before habits are set |
| Limitations + risk handling | Current constraints transparent, how they affect use case sequencing, workarounds where applicable, what to defer, confidence-building without overpromising |
| Close + adoption plan | Use cases summarized, context assets needed, pilot users/owners named, immediate next actions, success criteria for next checkpoint, customer confirms |

---

### Success Planning

| Dimension | What a 5 looks like |
|---|---|
| Session framing | *Joint* success planning — not a status update or renewal pitch. Outcomes = objectives, metrics, scope, owners, milestones, risks, cadence. |
| Business objectives + context | Top business priorities, why now, which product org challenges PB addresses, how PB supports (not just "adoption goals"), stakeholder alignment or divergence |
| Success outcomes + KPIs | Specific measurable outcomes, metric per outcome, baseline or plan to establish one, target state + timeframe, how success will be evidenced |
| Scope definition | In-scope priorities, teams/products in first phase, explicitly deferred items, sequencing rationale, linkage to desired outcomes |
| Roles + ownership | Named owners on both sides (customer + PB), who owns which deliverables, decision authority and escalation path, shared accountability language |
| Milestones + timeline | Phases, target windows, dependencies, checkpoints for validating progress, linkage to KPIs |
| Communication cadence | Meeting types, purpose per cadence, visibility mechanism (tracker, dashboard, scorecard), what gets reviewed regularly, escalation norms |
| Risk planning | Named risks (capacity, alignment, data quality, competing priorities, adoption resistance), dependencies, early warning signs, mitigations with owners, review/escalation model |
| Continuous improvement | How metrics drive plan adjustments, what "continuous improvement" means practically, decision triggers for re-scoping, incentives for sustained engagement, success plan as a living document |
| Close + commitment | Full summary: objectives/KPIs/scope/owners/milestones/cadence, open items, immediate next actions, timing for next checkpoint, customer confirms plan reflects shared expectations |

---

### QBR

| Dimension | What a 5 looks like |
|---|---|
| Framing | Business *review* — not a project status update. Outcomes: progress vs success plan, adoption assessment, risk identification, decisions + next actions. |
| Success plan progress | Objective-by-objective review with evidence, clear status (on/at risk/off track/achieved), what changed since last review, objective drift or reprioritization addressed |
| Adoption metrics interpretation | Key metrics, trend direction (not point-in-time), segmentation cuts, distinction between activity and outcome indicators, *AISE explains why metrics look this way*, not just reads charts |
| Data quality + confidence | Known gaps/limitations acknowledged, confidence level in conclusions, what additional data is needed, facts vs interpretation vs hypotheses clearly distinguished, follow-up actions for reporting quality |
| Adoption → business value | Adoption patterns connected to success plan outcomes, process behavior changes as value signals, areas where adoption ≠ value explained, customer-specific "what does progress mean" narrative |
| Wins + proof points | Specific examples by team/workflow/decision, who benefited, why it matters to stated objectives, evidence or observable indicators, balanced (celebrate without ignoring gaps) |
| Risks + blockers | Current risks to objectives, adoption gaps by team/role, root cause diagnosis (not just symptom listing), impact/severity, prioritization of which blockers matter most now |
| Recommendations | Tied to objectives and diagnosed gaps, prioritized actions, customer + PB responsibilities, expected impact, timing/checkpoints |
| Executive alignment | AISE tests agreement on interpretation/recommendations, invites perspectives from multiple roles, confirms priorities for next period, secures commitment on actions, handles disagreement constructively |
| Close | Progress summary + key adoption insights + agreed actions + named owners + next QBR timing + customer confirms |

---

## 3. Productboard Data Model & Architecture

### Product hierarchy

```
Product (top level — typically a vertical, business unit, or product line)
  └── Component (team/crew/squad level)
        └── Sub-component (optional — use for structurally distinct sub-areas)
              └── Feature
                    └── Sub-feature
```

**Design rules:**
- Products and components define the *structural* navigation of the workspace. Every feature must sit somewhere in this tree.
- Hierarchy depth should reflect *how the org actually thinks about ownership*, not how Jira is currently structured.
- Two common organizing logics: **product area** (what the team owns) vs **JTBD** (the customer job being served). These have different downstream implications for roadmap views and prioritization — decide explicitly.
- Sub-components are optional. Use them when a component genuinely has structurally distinct sub-areas that PMs think about separately. Don't add depth for the sake of it.
- Don't mirror Jira hierarchy directly — PB is the discovery/strategy layer; Jira is the delivery layer. They complement, not duplicate.

### Strategic hierarchy

```
Parent Objective
  └── Child Objective
        └── Initiative / Key Result
```

**Design rules:**
- Objectives sit at company or BU level; child objectives sit at tribe or team level.
- Key Results tie to objectives and represent measurable outcomes.
- Initiatives are the bets — the "what we're doing" to achieve objectives. Features link up to initiatives.
- This layer is typically phase 2 after foundations are stable — don't try to build it simultaneously with the product hierarchy.

### Teamspaces

Teamspaces organize *who sees what* and provide a scoped working context for each group.

| Type | When to use |
|---|---|
| **Open** | Default for most product teams. Anyone in the workspace can see and join. |
| **Closed** | Visible in the directory but requires join request or admin invite. Use for teams with sensitive or exec-level content. |
| **Private** | Not visible to others. Use sparingly — for C-suite, confidential roadmaps, or pre-announcement work. |

**Design rules:**
- General Teamspace is not a team's personal workspace. It's the shared cross-org view — roadmaps and boards that span all teams live here. Protect this use case.
- One teamspace per vertical/BU/tribe is the typical pattern for a multi-tribe org.
- Folders within teamspaces organize board views (not more features). Don't nest teamspaces.
- Teamspace-scoped product permissions: Open / View-only / Restricted — controls which teamspaces can edit vs view product areas.
- Custom fields can be scoped to a teamspace — useful when a specific tribe/vertical needs fields that would create noise for others.

### User roles

| Role | What they can do | Seat cost |
|---|---|---|
| **Admin Maker** | Full access + workspace configuration | Paid seat |
| **Maker** | Create/edit features, boards, roadmaps, insights, Spark | Paid seat |
| **Contributor** | Add notes and feedback, limited feature editing | **Free** |
| **Viewer** | Read-only access to specific teamspaces | **Free** |

**Design rules:**
- Only one admin (typically IT/Product Ops). More admins = governance risk. Scott's rule at one account: "only IT gets admin" is the right instinct.
- Engineering leads, CS, Sales, Marketing → Contributor or Viewer in almost all cases.
- Executive sponsors → Viewer on relevant teamspaces.
- PMs and Product Ops → Maker.
- If BU leads are expected to *edit* roadmaps or initiatives (not just view), they need Maker seats — factor into seat budget.
- 50 seats for ~50 PMs is tight if BU leads need Maker access. Validate before designing the role model.

### Feature statuses (PDLC)

Statuses are fully customizable. A typical recommended set:

```
New Idea → Candidate → In Discovery → Planned → Ready for Dev → In Progress → Released → Won't Implement
```

**Design rules:**
- Statuses define *stage gates*, not just labels. Define what it means to move a feature from one status to the next.
- Align statuses to the customer's actual PDLC language — don't force PB defaults if the org already has established terms.
- Decide whether statuses are standardized across all teams or whether teams can have variations. Standardization is almost always better for cross-team reporting.
- "Won't Implement" and "Paused" are important — they're how you manage backlog hygiene.

### Custom fields

Two categories:

| Category | Purpose | Examples |
|---|---|---|
| **Hierarchical / structural fields** | Define the structure of the product hierarchy | Teams, Components, Products |
| **Metadata fields** | Categorize, contextualize, and score items | Priority tier, commodity type, compliance flag, GTM status, release quarter |

**Field types available:**
- Single select, Multi-select
- Text, Long description
- Number
- Date
- Member (user assignment)
- Tasks
- Tags
- Formula (combines other number fields)
- Drivers (structured scoring inputs)
- Integration fields (from Jira, SFDC, etc.)

**Governance rules:**
- Establish a field owner and a pruning cadence before creating fields.
- Recurring tags → promote to a formal select field once they're used consistently.
- Avoid duplicate fields (e.g., "priority" and "urgency" and "importance" all doing the same thing).
- Multi-select fields can be teamspace-scoped — use this to prevent tribal custom fields from polluting other teams' views.

### Boards: Grid vs Roadmap

**Critical distinction:**

| Board type | Purpose | Mental model |
|---|---|---|
| **Grid board** | Input / decision-making | "The what and why" — where prioritization happens |
| **Roadmap** | Output / communication | "The what and when" — what you share with stakeholders |

Never use a roadmap view as a prioritization workspace, and don't try to replace a roadmap with a grid board.

**Within Roadmaps:**

| Type | When to use |
|---|---|
| **Timeline** | Time-based planning — features/initiatives on a date or timeframe axis. Requires features to have *timeframes* populated. |
| **Column** | Status-based or time-bucket communication — now/next/later, quarterly buckets, release-based. Requires features to have *releases* assigned. |

**Design rule:** One roadmap per persona/audience. Don't build one "master roadmap" and try to serve all audiences with it. Build a small portfolio of 2–5 views, each designed for a specific audience's question.

### Insights (Notes)

Key concepts:
- **Notes** = the primary unit of customer feedback. Each note has: title, content, company/user linkage, linked features, owner, status (processed/unprocessed), tags, topics, sentiment.
- **Topics** = AI-generated thematic groupings across notes.
- **Sentiment** = AI-detected signal on note content.
- **Tags** = manually applied metadata. The most powerful organizational tool in insights — but prone to sprawl without governance.

**Automation:** Notes can be auto-tagged, auto-assigned to owners, or auto-routed based on source, content patterns, or title keywords. Design automations based on source patterns — don't automate until tagging standards are set.

**Processed state:** A note marked "processed" means it's been reviewed, linked to relevant features, and had importance assigned. Unprocessed ≠ unread — it's an operational queue state.

### Drivers and Formulas (Prioritization)

- **Drivers** = structured scoring inputs (e.g., Strategic Alignment, Customer Impact, Implementation Effort). Each driver has a value set you define.
- **Formulas** = combine number fields and drivers into a calculated score (e.g., Value / Effort, RICE variant, custom weighted formula).
- Drivers and formulas are used in grid boards to support data-driven prioritization.
- Codify driver scoring logic explicitly — e.g., "Strategic Alignment = 3 means this initiative directly maps to a named company OKR."

### Company data and Segments

- **Company records** in PB = your customer accounts. Linked to notes so you can see which companies are requesting which features.
- **Custom company fields** = extend company records with attributes from CRM (e.g., segment tier, ARR, region, plan type).
- **Segments** = dynamic filters on company records (e.g., "Enterprise customers in EMEA"). Used in grid boards to understand feature demand by customer type.
- **Customer Importance Score (CIS)** = PB's built-in signal aggregating customer demand on a feature — powered by how many and which companies have linked notes requesting it.
- Source of company data is almost always the CRM (Salesforce). Define sync cadence and ownership — stale data breaks CIS.

### Portal

- Portals are customer-facing (or internal-audience-facing) spaces hosted by PB.
- Use cases: feedback collection, roadmap sharing, launch communication, idea validation.
- Multiple portals possible — design one per audience if needs differ.
- Sharing settings: hidden / company (logged-in users only) / private link / public link.
- Feedback submitted via portal routes back into PB notes — connects the feedback loop.
- Portal is often phase 2 or later for most customers — don't default to including it in phase 1 scope without validating the use case.

---

## 4. Seat Licensing Model

| Role type | Typical PB role | Seat cost |
|---|---|---|
| Product Managers | Maker | Paid |
| Product Ops | Maker | Paid |
| IT/Admin | Admin Maker | Paid (1 only) |
| BU leads (if editing roadmaps/initiatives) | Maker | Paid — watch budget |
| Engineering leads | Contributor | Free |
| CS, Sales, Marketing | Contributor | Free |
| Executives (read-only) | Viewer | Free |
| BU leads (read-only) | Viewer | Free |

**Budget watch:** The main risk is BU leads or engineering managers who *want* to edit features/roadmaps — they need Maker seats and can blow a 50-seat contract quickly. Validate this during Discovery before designing the role model.

**Phased rollout pattern:**
- Phase 1: ~15 Maker seats for pilot tribe (1 PM per team × pilot teams + BU leads)
- Phase 2–3: remaining Maker seats allocated to additional tribes as they onboard

---

## 5. Integrations Landscape

### Jira

- **Purpose:** PB handles discovery and planning; Jira handles execution. PB → Jira is the primary direction.
- **Integration type:** Feature ↔ Jira issue linkage, bidirectional status sync once linked, Fix Version → PB release mapping.
- **Critical design decision:** Forward-looking sync only. Don't mass-import Jira backlog into PB — you inherit all the mess. "Fix forward" (create clean PB items, link to Jira epics manually) is almost always the right call.
- **SQL import option:** Available for targeted bulk import of specific Jira items — use surgically, not as a shortcut.
- **Common confusion:** Customers often assume PB replaces Jira or that Jira stories should all live in PB. Clarify the layer distinction early and often.
- No single Jira workflow per team is common in larger orgs — designing a standard recommended Jira workflow is often worth the conversation.

### Okta (SSO/SCIM)

- **SSO/SAML:** Usually already configured by the time you're running architecture sessions — customers often set this up during trial.
- **SCIM:** Rarely pre-configured. This is a dedicated design stream. Okta groups → PB roles + Teamspace membership.
- **Design decisions needed:** Which Okta groups map to which PB roles, SCIM scope (which groups are SCIM-managed), offboarding handling (user deprovisioning), attribute sync.
- **Admin rule:** Only IT (one person) should have admin rights. SCIM misconfiguration can affect everyone instantly.
- Run SCIM design in parallel with PM architecture sessions, not sequentially — it doesn't block PM work.

### Salesforce

- **Purpose:** Source of truth for company/account data and segmentation.
- **Integration direction:** One-way SFDC → PB. Company fields sync on a cadence.
- **What to sync:** ARR, segment/tier, region, plan type, renewal date — whatever the team needs for prioritization by customer type.
- **Data quality risk:** If SFDC data is stale, CIS and segment-based prioritization become unreliable.

### Slack

- **Purpose:** Feedback ingestion from internal channels (sales, CS, support, internal product feedback).
- **Setup:** Select channels → PB insights. Define tagging and owner rules per channel.
- **Governance:** Be selective — not every Slack channel should flow into PB. Noise will kill adoption of the insights pipeline.

### Harvester / legacy feedback tools

- Standard pattern: replace with PB insights pipeline, not migrate everything wholesale.
- Scope the migration to recent, high-value notes (last 12–18 months typically).
- "Fix forward" applies here too — start fresh in PB for new feedback, do one-time historical import for key data.
- If the legacy tool license has months of runway, deprioritize migration. Get the process right first.

---

## 6. New Project Setup Checklist

### Before first customer session

- [ ] Salesforce account reviewed — deal size, segment, ICP, key contacts
- [ ] Gong reviewed — why they bought, what they said about pain points, AI maturity, key stakeholders' stated priorities
- [ ] AE/AISE handoff complete — open expectations, risks flagged, anything unusual in the deal
- [ ] Account channel confirmed in Slack
- [ ] Workspace status confirmed — trial workspace exists? SSO configured? Admin assigned?
- [ ] Program stakeholders mapped: exec sponsor, day-to-day lead, technical contact (IT), PM leads, any strategy/OKR owners
- [ ] Session plan drafted and ready to walk through at kickoff

### Project files to create at start of engagement

| File | Purpose |
|---|---|
| **Company Profile** | Who they are, what they sell, competitive landscape, segment, key context for the PB engagement |
| **Stakeholder Map** | Name, title, function, PB role, goal/interest — updated after each session |
| **Program Context / Living Reference** | Program status, key decisions, tooling, open items, risks — updated after every session |
| **Onboarding Deep Dive + Plan** | Detailed session plan, goals/metrics, current vs future state, integration/migration plan |
| **Session Summaries & Decisions Log** | Running log of what happened in each session + cumulative decisions register |
| **Org Structure, Licensing & Rollout** | Seat budget, role mapping, Q1/phased rollout plan, what we know vs don't know |
| **Crew/Team → Product Mapping** | How the customer's org maps to PB concepts (teamspace, product, component) |
| **Workspace Standards (Teams)** | Naming convention, team structure, handles — AISE-authored, admin-managed |

### Key questions to answer before A1 Foundations

These are blockers — you can't design the workspace without them:

1. What is the product org structure? (teams, verticals, reporting lines)
2. Which teams are in scope for phase 1?
3. Who is the sole admin?
4. What hierarchy depth makes sense? (2 levels? 3? JTBD or product area?)
5. What are the PDLC stages they actually use today?
6. What does the BU/leadership hierarchy look like, and who owns roadmap-facing decisions?
7. What's the Jira setup? (projects, workflow states) — needed before A8
8. What Okta groups exist that map to PB access model? — needed before A7

---

## 7. Common Risks & Mitigation Patterns

| Risk | Severity | Mitigation |
|---|---|---|
| **Aggressive go-live timeline** | 🔴 | Trim phase 1 scope to foundations + backlog + roadmaps only. Don't let insights, OKR layer, and full integrations all land in phase 1. |
| **Org change not fully socialized with the team** | 🟠 | Identify it in discovery. Don't surface it unplanned in a group architecture session — handle 1:1 with the AISE first. |
| **Scope creep into phase 1 from phase 2 items** | 🟠 | Delineate phase gates clearly in kickoff. When an item gets raised that belongs in phase 2, name it explicitly and park it. |
| **Too many admins** | 🟠 | Name the admin constraint explicitly in session 0. One admin (IT). Zero exceptions. |
| **"Give us everything in Jira in PB"** | 🟠 | Fix forward. Explain why historical import creates more problems than it solves. If they push, scoped SQL import only for specific items. |
| **"Let's define hierarchy later"** | 🔴 | Hard block. Hierarchy is a prerequisite for every other session. Don't schedule A1 without a hierarchy draft ready to validate. |
| **BU leads need Maker access (unplanned)** | 🟠 | Surface in discovery before role model is designed. 50-seat contracts get tight fast if 5–10 BU leads need paid seats. |
| **Solo IT/admin as sole technical resource** | 🟡 | Run admin stream in parallel — don't serialize it behind PM sessions. Florian-type figures always have competing priorities. |
| **Poor context quality → Spark adoption failure** | 🟠 | Context strategy is its own session topic. Don't assume customers will figure it out. Bad context = generic output = "Spark doesn't work." |
| **Legacy feedback tool renewal reduces urgency** | 🟡 | Deprioritize migration. Focus on building the right process in PB first; migration can follow. Don't let this become a blocker or a distraction. |
| **Roadmap as single monolithic view** | 🟠 | Surface the persona problem early in the roadmap session. "One roadmap for everyone" always disappoints everyone. Push toward a portfolio of 2–5 views from the start. |
| **Discovery ends without synthesis** | 🔴 | Score killer. Build synthesis + gap identification + setup implications into the session agenda — not as an afterthought. Get customer confirmation before closing. |
| **Artefacts not gathered before discovery** | 🟠 | Chase artefacts at kickoff with explicit named owners and due dates. Don't run discovery blind. |

---

## 8. Internal Communication Conventions

### Customer Slack channels

Productboard uses a standard two-channel pattern per customer. These names are org-wide conventions — never user-specific.

| Channel | Purpose |
|---|---|
| `#accounts-{customer}` | Internal-only. Post-session debrief notes, internal coordination, deal signals, AE alignment. |
| `#ext-{customer}` | External shared channel with the customer. Client-facing communications only. |

**Coverage caveat:** Not every customer has dedicated Slack channels. When channels are absent, default to follow-up emails per the communication style guide.

Before posting, search Slack for `accounts-{customer}` and `ext-{customer}` to confirm the channels exist. If neither exists, route all follow-up through Gmail.