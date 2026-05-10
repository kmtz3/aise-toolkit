# Prioritization / Backlog / PDLC — Session Template

**Session ID:** Usually `A2` (directly after Foundations)
**Duration:** 60–90 min
**Attendees:** Program owner, Sr PM(s), Vertical Head(s), Exec Sponsor (optional)
**Prerequisites:** Foundations locked (hierarchy, statuses, teams); Jira workflow list from IT
**Outputs:** PDLC stage definitions, lifecycle gates, scoring model, prioritization fields, grid board inventory, tasks usage decision

---

## Purpose

Define how the customer makes prioritization decisions and encode it into Productboard. This is a **process design + configuration** session.

---

## Outcomes to drive in-session

By the close, the customer has decided:
- PDLC stages + transition criteria
- Lifecycle gates (what moves a feature between statuses)
- Prioritization methodology + formula
- Drivers + scoring logic
- Prioritization fields (default + custom)
- Segments + Customer Importance logic
- Grid board inventory by stage
- Tasks usage (if any)

---

## Pre-read / inputs needed from customer

- Foundations status set (from `A1`)
- Current scoring approach (qualitative, RICE, custom — even if informal)
- CRM sync status (Customer Importance depends on it)
- Named prioritization owner(s) per product/tribe

---

## KDDs to facilitate

### 1. PDLC mapping

**Questions to ask:**
- What are your real lifecycle stages from intake to shipped?
- Which PB status maps to which stage?
- What decision/criteria moves a feature from one stage to the next?
- Where does prioritization actually happen — at one stage or across multiple?
- Any stages where the decision is system-driven (e.g. auto-moves on CIS threshold) vs business-driven?

**Key considerations:**
- PDLC ≠ Jira workflow. PB covers idea → delivery handoff; Jira covers delivery.
- Prioritization typically happens twice: intake triage + planning.
- Don't over-stage. Every extra status adds friction without value.

**Decision table:**

| Stage | PB status | Transition criteria (from previous) | Owner |
|---|---|---|---|
| | | | |

---

### 2. Lifecycle gates

**Questions to ask:**
- What fields must be populated before a feature moves from idea → exploration?
- From exploration → planning?
- From planning → in progress?
- What's a soft consideration vs a hard gate?
- Who owns enforcement of each gate?

**Key considerations:**
- Gate 1 (idea → exploration) is the highest-leverage: forces PM ownership + intent before work starts.
- Objective/Initiative linkage is usually a soft consideration at gate 1, hard gate at gate 2.
- Too many hard gates and the workflow stalls.

**Decision table:**

| Gate (from → to) | Required fields | Soft/Hard | Approver |
|---|---|---|---|
| | | | |

---

### 3. Prioritization methodology

**Questions to ask:**
- How do you prioritize today — value/effort, RICE, weighted scoring, gut?
- What criteria matter most — business value, customer impact, effort, confidence, strategic alignment, dependencies?
- Do criteria differ by stage (triage vs evaluation vs planning)?
- Should the model be standard across all teams, or per-tribe variation?

**Key considerations:**
- Start simpler than RICE unless the org has data maturity. Impact × Effort is often enough for Phase 1.
- Confidence drops out of many customer scoring models because it's hard to calibrate consistently.
- Don't standardize prematurely — some variation per tribe is fine for Phase 1, harmonize later.

**Decision table:**

| Methodology | In scope | Stage applied | Notes |
|---|---|---|---|
| | | | |

---

### 4. Drivers, formulas, scoring

**Questions to ask:**
- Which drivers will you track (business drivers, themes, generic criteria)?
- How do you score each driver (scale, rubric)?
- Which formula does the math — Value/Effort, RICE, custom?
- What custom number fields do you need to power it?
- Is the scoring model global or board-specific?
- What limitations/assumptions should be explicit (data quality, manual updates, CIS integrity)?

**Key considerations:**
- Drivers without a scoring rubric are subjective. Codify the rubric.
- Customer Importance Score (CIS) integrity depends on note-to-feature linkage. Don't allow manual editing if accuracy matters.
- Formula complexity trades off against adoption. Start simple.

**Decision table:**

| Driver | Scoring rubric | Weight | Used in formula |
|---|---|---|---|
| | | | |

**Formula decision:**

| Formula | Components | Scope |
|---|---|---|
| | | |

---

### 5. Prioritization fields (default + custom)

**Questions to ask:**
- Which default fields matter for your workflow — Customer Importance, Health, Owner, Dependencies, Timeframe, Teams, Tags, Value/Effort?
- What additional custom fields — date, text, select, multi-select, member?
- Which fields matter at which stage (evaluation vs planning vs release management)?
- Risk of duplicate/overlapping fields?

**Decision table:**

| Field | Type | Stage(s) used | Maintainer |
|---|---|---|---|
| | | | |

---

### 6. Company data + Customer Importance

**Questions to ask:**
- Is CRM sync configured? (If not, CIS will be weak.)
- Which customer attributes matter for prioritization (segment, tier, region, ARR, industry)?
- Which segments drive decisions?
- Known data quality gaps that would weaken CIS?

**Decision table:**

| Customer attribute | Used in | Source | Known gaps |
|---|---|---|---|
| | | | |

---

### 7. Grid board architecture

**Questions to ask:**
- Which boards do you need — New Ideas / Full Backlog, Evaluation, Planning, Release Management, Monitoring?
- What's the purpose of each (which decisions happen there)?
- Filters + status scope for each?
- Key columns (fields shown) for each?
- Who owns each board (audience + editor)?

**Key considerations:**
- One board per PDLC stage is usually overkill. Aim for 3–5 boards total.
- Release Management board only matters if release planning is a real practice.

**Decision table:**

| Board | Stage/status filter | Key columns | Audience | Owner |
|---|---|---|---|---|
| | | | | |

---

### 8. Tasks usage

**Questions to ask:**
- Do you want to track tasks in PB, or is delivery fully in Jira?
- If yes — which tasks (pre-dev, release readiness, cross-functional)?
- Task statuses + workflow?
- How do tasks link to release management visibility?

**Key considerations:**
- Default to No for Phase 1. Tasks in PB without a clear purpose = maintenance overhead.
- Good use cases: pre-development checklist, GTM readiness, cross-functional launch tasks.

**Decision table:**

| Task type | In scope | Owner | Status workflow |
|---|---|---|---|
| | | | |

---

## Red flags & rebuttals (internal)

| Red flag | Rebuttal |
|---|---|
| "Let's use RICE for everything" | RICE needs clean reach + confidence data. Start simpler (Impact × Effort) and add complexity once data maturity is there. |
| "Every team will have its own scoring" | Creates pricing comparisons impossible across portfolio. Standardize the formula; allow per-tribe drivers. |
| "We'll track everything as tasks in PB" | PB tasks aren't a delivery system. If it belongs in Jira, keep it there. |
| "Customer Importance Score is manual" | Manual CIS gets gamed within a quarter. Lock it to insights linkage. |
| "We need gates on every transition" | Over-gating stalls workflow. Pick the two highest-leverage gates. |
| "One giant backlog board" | Filterable by everyone = useful to no one. Boards per purpose. |

---

## Close — synthesis structure

1. **Decisions summary** — PDLC stages, gates, formula, drivers, fields, boards, tasks decision
2. **Open items** — missing data (CRM, named owners), deferred model refinement
3. **Configuration backlog** — fields, drivers, formula, segments, boards to build
4. **Next session objective** — usually Roadmaps (`A3`) or Insights (`A4`)
5. **Customer confirmation** — explicit confirmation the scoring model matches their decision reality

---

## Tweak guidance

- If Foundations isn't fully locked, flag which prior decisions are assumed before proceeding
- If the customer has no prioritization practice today, anchor on "what's a realistic starting scoring model" rather than methodology theory
- If CIS / CRM integration isn't ready, defer CIS-dependent fields and flag as open item
- Don't pre-fill driver names — the customer's drivers must reflect their business, not generic templates
