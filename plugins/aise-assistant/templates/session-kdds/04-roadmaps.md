# Roadmap System Design — Session Template

**Session ID:** Usually `A3` (after Foundations + Backlog)
**Duration:** 60–90 min
**Attendees:** Program owner, Sr PM(s), PMM / GTM (optional), Exec sponsor (optional), CS lead (optional)
**Prerequisites:** Foundations locked; PDLC + prioritization in progress; Timeframe/Release field decisions available
**Outputs:** Roadmap portfolio (2–4 views), schemas, configuration tasks, metadata prerequisites

---

## Purpose

Design a small, persona-based portfolio of roadmap views — one per audience job. This is a **communication design** session, not a roadmap feature demo.

---

## Outcomes to drive in-session

By the close, the customer has decided:
- Roadmap audiences/personas + the job each roadmap does
- Board type (Grid vs Timeline vs Column) per persona
- Schema (main item, swimlanes/grouping, milestones) per roadmap
- Metadata / card attributes per persona
- Roadmap placement + access per teamspace
- Minimum viable roadmap set for launch + future additions
- Configuration prerequisites + data dependencies

---

## Pre-read / inputs needed from customer

- Named audiences that need roadmap visibility today
- Current roadmap artefacts (often in Miro, slides, spreadsheets)
- Release/timeframe discipline status (are dates/releases populated?)
- Named roadmap owner(s)

---

## KDDs to facilitate

### 1. Audiences + jobs

**Questions to ask:**
- Who actually needs a roadmap (C-suite/leadership, PMs, PMM/Marketing, Engineering, Sales/CS, customers)?
- What job does each roadmap do — strategic alignment, delivery tracking, GTM prep, release comms, customer-facing?
- What level of detail does each audience need (strategy vs granular delivery)?
- What questions does each audience need the roadmap to answer (why, what, when, status)?
- Which audiences share a roadmap vs need their own view?

**Key considerations:**
- One roadmap cannot serve all audiences. Force persona-specific views.
- "Leadership wants to see everything" usually means "leadership wants strategic alignment." Don't build a delivery roadmap for execs.
- Customer-facing roadmaps typically belong in Portal, not a teamspace view.

**Decision table:**

| Persona / Audience | Job of the roadmap | Detail level | Key questions answered |
|---|---|---|---|
| | | | |

---

### 2. Board type selection

**Questions to ask:**
- For each persona, which board type fits — Grid (inputs/decisions), Timeline (when/time), or Column (status/release bucket)?
- Where does the decision happen — are they looking at options (Grid) or communicating a plan (Timeline/Column)?
- Is "when" a hard date or a bucket (now/next/later)?

**Key considerations:**
- Grid Boards = "the what and why" (inputs, decision-making).
- Timeline Roadmaps = "the what and when" (date-based communication).
- Column Roadmaps = status or time-bucket communication (now/next/later, quarterly, release groups).
- One-size-fits-all = the monolithic-roadmap antipattern.

**Decision table:**

| Persona | Board type | Rationale |
|---|---|---|
| | | |

---

### 3. Schema design (per roadmap)

**Questions to ask (per roadmap):**
- What's the main item — Objectives, Initiatives, Features, Sub-features, Releases?
- What's the grouping / swimlane — Strategic Pillar, Team, Product, Owner, Component?
- Are milestones/events needed (launches, conferences, funding, releases)?
- Structural convention — release groups, quarterly columns, now/next/later, timeline granularity?

**Key considerations:**
- Main item ≠ automatically Features. Exec roadmaps often work better with Initiatives.
- Swimlane should align to how the audience thinks (Strategic Pillar for exec, Team for delivery, Product for GTM).
- Milestones only matter if they're actually tracked.

**Decision table:**

| Roadmap | Main item | Swimlane/grouping | Milestones? | Structural convention |
|---|---|---|---|---|
| | | | | |

---

### 4. Metadata + card attributes

**Questions to ask:**
- Which card attributes does each audience need (owner, team, progress, health, effort, dependencies, business impact, key result, GTM contact)?
- Which attributes exist today vs need to be added in the PDLC?
- What data prerequisites do each board type require (timeframes for Timeline, Releases for Column)?
- Who owns keeping metadata populated?
- What's the risk if metadata is incomplete (roadmaps become unreliable)?

**Decision table:**

| Persona | Critical card attributes | Already exist? | Owner for population |
|---|---|---|---|
| | | | |

**Prerequisite matrix:**

| Roadmap type | Data requirement | Status |
|---|---|---|
| Timeline | Timeframe populated on features | |
| Column | Releases populated + release groups defined | |
| Any | Hierarchy + status set | |

---

### 5. Alignment to strategy + prioritization

**Questions to ask:**
- How do roadmaps reflect decisions from prioritization (VoC, drivers, scoring)?
- How do roadmaps tie to strategic hierarchy (Objectives, Initiatives)?
- Is the roadmap a dynamic artefact (populated from PDLC data) or a static one (manually curated)?
- Where are decisions backed by VoC + VoB?

**Key considerations:**
- Roadmaps are outputs of prioritization. If they're disconnected from the backlog, they become manual storytelling.
- Dynamic roadmaps require metadata discipline. Static ones require manual update rituals.

---

### 6. Placement + access

**Questions to ask:**
- Where does each roadmap view live (General teamspace, Executive, Marketing, per-tribe)?
- Which roadmap types should be in which teamspace?
- Access considerations per audience (teamspace type, member access, sharing)?
- Internal-only vs shareable broadly — including external via Portal?
- Who governs roadmap maintenance per view?

**Decision table:**

| Roadmap | Placement (teamspace) | Access | Owner |
|---|---|---|---|
| | | | |

---

### 7. Portfolio design (minimum viable set)

**Questions to ask:**
- What's the smallest set of roadmaps that covers the priority audiences at launch?
- What roadmaps are deferred to Phase 2 / later?
- Is there a monolithic master roadmap risk to pre-empt?

**Decision table:**

| Roadmap | Launch phase (P1 / P2 / later) | Priority rationale |
|---|---|---|
| | | |

---

### 8. Configuration prerequisites

**Questions to ask:**
- What config must exist first (release groups, timeframe discipline, metadata fields)?
- Any blocking gaps from prior sessions (Foundations, Prioritization)?
- Sequencing — what must be built before roadmap views can work?
- How do roadmap views stay updated automatically (process inputs vs manual)?

**Decision table:**

| Prerequisite | Source session | Status |
|---|---|---|
| | | |

---

## Red flags & rebuttals (internal)

| Red flag | Rebuttal |
|---|---|
| "One master roadmap for everyone" | No roadmap serves all audiences. Persona-specific views are non-negotiable. |
| "We'll add timeframes later" | Timeline boards need timeframes. Without them, the view is empty. Sequence prereqs first. |
| "Just show everything on the roadmap" | Noise kills communication. Filter to what the audience needs to answer their question. |
| "We'll keep the slides roadmap for now" | Fine as a transition, but define the cutover point or the slides version will outlive the PB view. |
| "Engineering wants the full backlog on the roadmap" | That's a Grid board, not a roadmap. Route them to the right view. |
| "We'll figure out metadata as we go" | Incomplete metadata = unreliable roadmap = loss of trust. Define the minimum set now. |

---

## Close — synthesis structure

1. **Decisions summary** — personas, board types per persona, schemas, placement, portfolio
2. **Open items** — missing metadata, named roadmap owners, release discipline
3. **Configuration backlog** — roadmap views to build, release groups to create, sharing settings
4. **Prerequisites flagged** — data dependencies that block launch
5. **Next session objective** — usually Insights (`A4`) or integrations work
6. **Customer confirmation** — each persona's roadmap answers their key question

---

## Tweak guidance

- If release discipline is weak, lead with the Timeline vs Column decision — it often surfaces the prereq gap
- If the customer has a strong existing tool (Miro, slides), treat the cutover plan as a named decision
- If execs aren't in the session, flag the executive roadmap as requiring a follow-up validation
- Don't pre-fill personas with generic lists — pull from the customer's actual stakeholder map
