# Foundations Architecture — Session Template

**Session ID:** Usually `A1` (first architecting session after discovery)
**Duration:** 90 min
**Attendees:** Program owner, Sr PM(s), Vertical Heads, Exec Sponsor (optional)
**Prerequisites:** Discovery (`S2`) complete; org structure and pain points documented
**Outputs:** Foundations KDDs, configuration backlog, decisions register entries

---

## Purpose

Decide the data model and workspace structure so Productboard can be configured correctly. This is an architecture decision workshop — **not** a feature demo.

---

## Outcomes to drive in-session

By the close, the customer has decided:
- Product hierarchy (levels and definitions in their language)
- Strategic hierarchy (or explicit deferral)
- Teamspace organization + types
- Teams vs teamspaces — what crews/squads map to
- Role assignments (Admin Maker / Maker / Contributor / Viewer)
- Feature statuses aligned to their real PDLC
- Naming conventions
- Custom field governance owner

---

## Pre-read / inputs needed from customer

- Org chart — tribes / BUs / crews / squads (or equivalent)
- Current product taxonomy (even if informal)
- Current lifecycle/status language in their delivery tool
- Named admin(s)
- Stakeholder list with role intent (who needs to edit vs view)

---

## KDDs to facilitate

### 1. Product hierarchy

**Questions to ask:**
- What does a "Product" represent in your business — a customer-facing marketable product, an internal capability area, a team, something else?
- How many levels deep do you actually need? (Default: Product → Component → Feature → Sub-feature.)
- Is Component structural (sub-product area) or organizational (capability grouping)?
- Do you have cross-BU products? If yes, how should they be attributed?

**Key considerations:**
- Products should be stable over 2–3 years. If it changes with every reorg, it's probably a team, not a product.
- Components are usually capability groupings, not a structural sub-layer.
- Avoid sub-components unless there's a clear, durable use case.

**Decision table (fill live):**

| Level | Represents | Example values | Notes |
|---|---|---|---|
| Product | | | |
| Component | | | |
| Feature | | | |
| Sub-feature | | | (often skipped) |

---

### 2. Strategic hierarchy

**Questions to ask:**
- Do you have OKRs today? Active or aspirational?
- At what levels (company / department / team)?
- How do objectives tie to product work today, if at all?
- Who owns each layer?

**Key considerations:**
- If OKRs aren't actively used, defer to Phase 2. Don't build infrastructure for a practice that doesn't exist.
- Single Initiative tier + Strategic Bet custom field is a durable pattern when the OKR layer is immature.

**Decision table:**

| Layer | In scope now? | Owner | Notes |
|---|---|---|---|
| Objective | | | |
| Initiative | | | |
| Key Result | | | |

---

### 3. Teamspaces + folders

**Questions to ask:**
- What's the right teamspace grain — tribe/vertical, BU, crew, functional?
- Will you use Open, Closed, or Private teamspaces? Under what conditions?
- What purpose does the General teamspace serve here?
- Folder structure inside a teamspace — what's the default?

**Key considerations:**
- Crew-level teamspaces create scaling problems (30+ teamspaces at full rollout).
- Tribe/vertical teamspaces + Teams for crew metadata + filtering is the validated pattern.
- Open teamspaces are fine for Phase 1. Revisit at Phase 2.
- Default folder set: Structure / Roadmaps / Planning / Discovery.

**Decision table:**

| Teamspace | Type (Open/Closed/Private) | Purpose | Owner |
|---|---|---|---|
| | | | |

---

### 4. Teams (crews / squads / delivery units)

**Questions to ask:**
- What's the smallest delivery unit in your org? (Crew, squad, pod, feature team.)
- What do you need to use Teams for — ownership, filtering, @mentions, all of the above?
- Naming convention for teams?
- Handle convention for @mentions?

**Key considerations:**
- Teams in PB = metadata, not containers. They drive filtering and ownership.
- Prefix convention (e.g. `[TRIBE] Name`) makes flat lists searchable.
- Handles should be short, lowercase, no hyphens.

**Decision table:**

| Team | Handle | Tribe/vertical | Description |
|---|---|---|---|
| | | | |

---

### 5. User roles

**Questions to ask:**
- Who needs to create and edit features (Maker)?
- Who just comments / contributes / submits feedback (Contributor)?
- Who views roadmaps only (Viewer)?
- Who administers the workspace (Admin Maker)?
- Is there a risk of over-permissioning?

**Key considerations:**
- Admin count should be small and intentional. "Give everyone admin" is a red flag.
- Contributor is often underused — PMs default to Maker even when Contributor fits.

**Decision table:**

| Group / Persona | Role | Count (approx) | Notes |
|---|---|---|---|
| | | | |

---

### 6. Feature statuses & PDLC

**Questions to ask:**
- What are the real stages a feature goes through today, from idea to shipped to deprioritized?
- What's the movement logic between each stage?
- Do different teams need different statuses, or can you standardize?
- How do "Released" and "Won't Do" (or equivalent) language reconcile?

**Key considerations:**
- Default set that usually works: New Idea → Exploration → Planning → In Progress → Released / Won't Do.
- Avoid adding a status per nuance. Every extra status adds friction.
- Don't bring Jira naming into PB. PB-native terms only.

**Decision table:**

| Status | Meaning | Gate criteria (what moves it from previous) | Owner |
|---|---|---|---|
| | | | |

---

### 7. Custom fields (hierarchical vs metadata)

**Questions to ask:**
- Do we need BU/Tribe as a field? At which hierarchy levels?
- Any product-specific classification (e.g. commodity type, geography, tier)?
- Visibility toggles (e.g. GTM / internal-only) — needed?
- Who governs field values?

**Key considerations:**
- Distinguish hierarchical fields (structural) from metadata fields (categorization).
- Watch for duplication (priority vs urgency vs stack rank).
- Assign a single governance owner. Fields sprawl without one.

**Decision table:**

| Field | Type | Scope (which levels) | Governance owner |
|---|---|---|---|
| | | | |

---

### 8. Feature description template

**Questions to ask:**
- Do you have a template for feature specs today (in Jira, Notion, elsewhere)?
- What sections are non-negotiable (problem, benefits, target audience, risks, success metrics)?
- Who's the template owner?

**Decision table:**

| Section | Required? | Notes |
|---|---|---|
| | | |

---

### 9. Naming conventions

**Questions to ask:**
- Products — plain name or prefix?
- Teams — prefix convention?
- Tags — naming rules?
- Any glossary of reserved terms?

**Decision table:**

| Object | Convention | Example |
|---|---|---|
| Product | | |
| Component | | |
| Team | | |
| Tag | | |

---

## Red flags & rebuttals (internal)

| Red flag | Rebuttal |
|---|---|
| "We want every team to do something different" | Start with one template, extend per team only where there's a concrete reason. Variation without rationale = operational debt. |
| "Give everyone admin" | Admin risk: field/status sprawl, accidental deletions. Propose named admin roster + elevated Maker for power users. |
| "We'll define the hierarchy later" | The hierarchy is the scaffolding for everything else. Deferring blocks roadmap design, teamspaces, and reporting. |
| "Let's use tags for everything" | Tags are for recurring categorization, not formal structure. Recurring tags → convert to custom fields. |
| "General teamspace will be our [X] team" | General is a shared space. Repurposing it breaks guardrails for everyone else. |
| "Let's mirror Jira statuses" | PB serves discovery through delivery; Jira covers delivery only. Statuses should reflect the PM lifecycle, not delivery tickets. |

---

## Close — synthesis structure

End the session with:

1. **Decisions summary** — walk through each KDD and confirm the decision out loud
2. **Open items** — anything deferred, with named owner and when it's needed
3. **Configuration backlog** — what SA will build before the next session
4. **Next session objective** — what this unlocks (usually Backlog Architecture)
5. **Customer confirmation** — explicit "does this capture it?" and wait for the "yes"

Log decisions in the numbered register continuing from the last entry (e.g. `D17`, `D18`, `D19`…).

---

## Tweak guidance

When customizing this template for a specific customer:
- Replace generic terms (Product, Tribe, Crew) with the customer's actual terminology
- Pre-populate decision tables with anything already decided in discovery (cite the D-number)
- Remove KDD sections that are genuinely out of scope (e.g. OKR if they have no goal-setting practice)
- Add customer-specific examples in the "Questions to ask" where useful
- Do **not** pre-fill decision values — leave tables blank for live facilitation
