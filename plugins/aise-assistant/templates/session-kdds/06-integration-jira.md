# Jira Integration — Session Template

**Session ID:** Usually `A8` (admin stream)
**Duration:** 60 min
**Attendees:** Technical lead / IT admin, Program owner (brief), Engineering lead (optional)
**Prerequisites:** Foundations locked (statuses, hierarchy); Jira project list + current workflows available
**Outputs:** Jira integration live + validated for pilot crews, project mapping doc, sync rules

---

## Purpose

Design and validate the Jira integration so Productboard features sync cleanly with delivery tickets. This is a **configuration design** session with live validation.

---

## Outcomes to drive in-session

By the close, the customer has decided:
- Sync direction (forward-only vs bidirectional)
- Project mappings (which Jira projects → which PB products/teams)
- Status mapping (Jira workflow → PB statuses)
- Fix Version / Release handling
- Linking convention (manual vs auto-push on stage transition)
- Validation approach for pilot crews

---

## Pre-read / inputs needed from customer

- Jira project list (all projects in scope)
- Current Jira workflow diagrams (per project type)
- Fix Version usage pattern (if any)
- Named Jira admin with API / integration permissions
- Pilot crews identified for first integration validation

---

## KDDs to facilitate

### 1. Sync direction

**Questions to ask:**
- Do you want bidirectional sync (status updates flow both ways) or forward-only (PB → Jira push)?
- Which tool is the source of truth for feature status?
- Which is the source of truth for delivery / completion?
- Do Jira status changes need to update PB, or only the reverse?

**Key considerations:**
- Bidirectional feels clean but creates conflict resolution complexity.
- Forward-only is simpler and often sufficient: PB owns idea → planning, Jira owns delivery execution.
- If bidirectional, define which tool "wins" on conflicting updates.

**Decision table:**

| Direction | In scope | Rationale |
|---|---|---|
| Forward-only (PB → Jira) | | |
| Bidirectional | | |

---

### 2. Project mappings

**Questions to ask:**
- Which Jira projects are in scope for Phase 1?
- How does each Jira project map to PB (product, team, component)?
- Are any projects shared across multiple PB products (e.g. a platform project serving several verticals)?
- Any projects explicitly out of scope?

**Decision table:**

| Jira project | PB mapping (product / team / component) | In scope Phase 1? |
|---|---|---|
| | | |

---

### 3. Status mapping

**Questions to ask:**
- For each Jira workflow, how do statuses map to PB's status set?
- Are any Jira statuses without a PB equivalent (e.g. "Awaiting QA")?
- How do we handle Jira states with no PB parallel — ignore, collapse, or block sync?
- Who owns alignment when Jira workflows differ between projects?

**Key considerations:**
- Jira workflows often differ per project. Either standardize the workflow or accept per-project mapping.
- Don't mirror Jira statuses in PB — keep PB-native terms (ref. Foundations D25 equivalent).
- Edge cases like "Reopened" or "Blocked" need explicit handling rules.

**Decision table:**

| Jira status | PB status | Action on sync |
|---|---|---|
| | | |

---

### 4. Fix Version / Release handling

**Questions to ask:**
- Do you use Fix Version in Jira today?
- Should PB Releases sync to Jira Fix Version?
- Direction of sync (PB creates in Jira, or Jira owns)?
- Naming convention alignment (release groups in PB, version naming in Jira)?

**Decision table:**

| Approach | In scope | Notes |
|---|---|---|
| Jira Fix Version → PB Release | | |
| PB Release → Jira Fix Version | | |
| Independent | | |

---

### 5. Linking convention

**Questions to ask:**
- When does a PB feature get linked to a Jira issue — on creation, on stage transition, manually?
- Auto-push on a specific status change (e.g. moves to Planning = pushes to Jira)?
- What happens when a PB feature has no matching Jira issue yet — blocker, warning, ignore?
- How are legacy Jira epics linked to existing PB features retroactively?

**Key considerations:**
- Auto-push on stage transition is powerful but only works if stages are clean.
- Manual linking for legacy items is almost always the right call for migration — no bulk import.

**Decision table:**

| Trigger | Action | Notes |
|---|---|---|
| | | |

---

### 6. User / ownership alignment

**Questions to ask:**
- Does PB feature owner sync to Jira assignee?
- If users don't match across tools (different emails, missing accounts), how is that handled?
- Does a PB team map to a Jira team/component field?

**Decision table:**

| Field | Sync behavior | Fallback |
|---|---|---|
| Owner / Assignee | | |
| Team / Component | | |

---

### 7. Validation approach

**Questions to ask:**
- Which pilot crew(s) validate the integration first?
- Validation checklist — can you create a PB feature, push to Jira, update status in Jira, see it reflect in PB?
- Failure modes to test (missing fields, user mismatch, deleted Jira issue)?
- Rollback plan if the integration misbehaves?

**Decision table:**

| Validation scenario | Owner | Status |
|---|---|---|
| End-to-end push | | |
| Status sync | | |
| Fix Version | | |
| Edge case | | |

---

### 8. Governance post-go-live

**Questions to ask:**
- Who monitors integration health (sync failures, rate limits)?
- Who approves changes to mapping / sync rules after go-live?
- Escalation path if the integration breaks?

**Decision table:**

| Responsibility | Owner | Cadence |
|---|---|---|
| Health monitoring | | |
| Mapping changes | | |
| Break/fix | | |

---

## Red flags & rebuttals (internal)

| Red flag | Rebuttal |
|---|---|
| "Bulk import all Jira tickets into PB" | Migrating noise creates unmaintainable chaos. Fix forward — create clean PB items, link to Jira manually. |
| "Mirror Jira statuses in PB" | PB serves idea → handoff; Jira serves delivery. Status sets should reflect each tool's purpose. |
| "Auto-push everything to Jira" | Low-quality features get pushed to engineering before they're ready. Gate the push. |
| "Each Jira project has a different workflow, fine" | Sync mapping becomes per-project maintenance. Propose standardizing workflows first (Scott at Kpler was open to this). |
| "We'll handle user mismatches later" | Mismatch = sync failures from day one. Resolve before pilot. |

---

## Close — synthesis structure

1. **Decisions summary** — sync direction, project mappings, status mapping, Fix Version, linking convention
2. **Open items** — missing data (project list, workflow diagrams), user mismatches
3. **Configuration backlog** — SA builds integration config; customer provides Jira admin access
4. **Validation plan** — which pilot crew, success criteria, timing
5. **Customer confirmation** — tech lead confirms the rules match their Jira reality

---

## Tweak guidance

- If Jira admin isn't in the session, flag mapping decisions as conditional on validation
- For customers with many (>5) Jira projects, split this into two sessions: design + validation
- If Jira workflows are wildly inconsistent, offer to run a workflow-standardization conversation first
- If the customer uses a non-Atlassian issue tracker (Azure DevOps, Linear), adapt field/status terms but keep the structural KDDs — they apply to any delivery integration
