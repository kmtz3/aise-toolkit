# Insights / Feedback Architecture — Session Template

**Session ID:** Usually `A4` (after Foundations and Backlog are locked)
**Duration:** 90 min
**Attendees:** Program owner, PMs, Product Ops, CS lead (if feedback-in-scope), Sales lead (optional)
**Prerequisites:** Product hierarchy from Foundations; known feedback sources; legacy tool list
**Outputs:** Insights pipeline map, note standards, tagging rules, automation backlog, company field + segment requirements

---

## Purpose

Design the feedback pipeline end-to-end — sources, triage, note standards, segmentation, portal. This is a **process design** session, not a feature walkthrough.

---

## Outcomes to drive in-session

By the close, the customer has decided:
- Which sources are in scope for Phase 1 (and which are deferred)
- Triage workflow with named owners + cadence
- "Good feedback" standard
- Tagging strategy + governance
- Custom company fields + segment inputs
- Automation priorities
- Portal decision (yes / no / later)

---

## Pre-read / inputs needed from customer

- Current feedback sources (tools, channels, inflows)
- Volume estimates per source (rough order of magnitude)
- Current triage owner(s) — or confirmation there isn't one
- Current segmentation logic from CRM
- Any portal experience (previous tool or attempts)

---

## KDDs to facilitate

### 1. Stakeholders + sources

**Questions to ask:**
- Who provides feedback today (customers, CS, Support, Sales, Engineering, Exec, UX research)?
- Which tools/channels does that feedback flow through (CRM, Slack, Zendesk, email, portal, interviews)?
- Which sources are high-volume? Which are high-value? They're usually different.
- Which source should become the core structured channel?
- Who owns each source inflow?

**Key considerations:**
- Not every source needs to be integrated on day one. Pick the two or three that deliver the most signal.
- Email is powerful but noisy without forwarding rules.
- Slack integration needs deliberate channel selection + tagging rules upfront.

**Decision table:**

| Source | Volume | Value | Owner | Phase 1? | Integration status |
|---|---|---|---|---|---|
| | | | | | |

---

### 2. Triage workflow

**Questions to ask:**
- Who triages incoming notes, how often, where?
- What does "processed" mean — linked to a feature, tagged, owner assigned, or all three?
- When does a triager @mention a contributor for more context?
- What's the cadence — daily, weekly, per source?
- Who owns which notes (by product area, by source, by team)?

**Key considerations:**
- Daily or weekly cadence. Longer and the backlog becomes unmanageable.
- "Processed" needs a clear definition or the state becomes meaningless.
- Ownership assignment should follow the product hierarchy (note → component owner).

**Decision table:**

| Triage activity | Owner | Cadence | "Processed" criteria |
|---|---|---|---|
| | | | |

---

### 3. "Good feedback" standard

**Questions to ask:**
- What makes feedback actually useful for a PM decision? (Problem, impact, who it affects, context, urgency, use case.)
- Which of those are required vs encouraged?
- Will you use a submission template/form?
- How will you enable Contributors to submit better feedback?

**Decision table:**

| Feedback element | Required? | Notes |
|---|---|---|
| Problem statement | | |
| Impact description | | |
| Who (user/segment) | | |
| Context / use case | | |
| Urgency / timing | | |

---

### 4. Note anatomy + tagging

**Questions to ask:**
- How will tags be used — topic, theme, product area, source, other?
- What tagging conventions prevent sprawl (casing, singular/plural, hierarchy)?
- Topics vs tags — when to use which?
- Who owns the tag library?

**Key considerations:**
- Tags are the most powerful and most abused part of a note.
- Convert recurring tags to formal fields once a pattern is established.
- A governance owner prunes stale/duplicate tags on a cadence.

**Decision table:**

| Tag purpose | Naming convention | Example | Governance owner |
|---|---|---|---|
| | | | |

---

### 5. Insights automations

**Questions to ask:**
- What patterns exist in incoming notes by source (title patterns, submitter type, content keywords)?
- Which automations would deliver the most value first — auto-owner assignment, auto-tagging, routing, source-based handling?
- Which automations are low-risk, high-impact?
- Who monitors automation performance and tunes rules?

**Decision table:**

| Automation | Trigger | Action | Priority (P1/P2/P3) |
|---|---|---|---|
| | | | |

---

### 6. Company data + segments

**Questions to ask:**
- What's the source of company data — CRM, other?
- Sync cadence + ownership?
- Which customer attributes drive product decisions (segment, tier, region, industry, plan, ARR)?
- What segments will PMs use in prioritization?
- Known data quality gaps (stale data, inconsistent values, missing fields)?

**Decision table:**

| Custom company field | Source | Sync cadence | Used in |
|---|---|---|---|
| | | | |

| Segment | Filter logic | Use case |
|---|---|---|
| | | |

---

### 7. Portal strategy

**Questions to ask:**
- Do you want a portal, and for what purpose (feedback, roadmap share, launch comms, validation)?
- How many portals — internal, by product, by segment?
- What structure (tabs, subsections, cards)?
- Sharing settings — hidden, company-only, private link, public link?
- How does feedback submitted via Portal route into insights?
- How do you close the loop with submitters (updates, notifications)?

**Decision table:**

| Portal | Audience | Purpose | Share setting | Feedback loop |
|---|---|---|---|---|
| | | | | |

*If Portal is out of scope: document the explicit decision to defer and the conditions that would unlock it.*

---

### 8. Downstream linkage

**Questions to ask:**
- How will notes drive prioritization (Customer Importance Score, VoC weighting)?
- How will segment-level insight show up in PDLC decisions?
- What does "closing the loop" look like for this customer?
- What adoption ritual reinforces note processing weekly/monthly?

**Decision table:**

| Downstream outcome | Mechanism | Owner |
|---|---|---|
| | | |

---

## Red flags & rebuttals (internal)

| Red flag | Rebuttal |
|---|---|
| "We'll integrate every source on day one" | Integration without triage ownership = backlog graveyard. Start with two sources + a named triage owner. |
| "Tags will organize themselves" | Tags without governance become noise inside 30 days. Assign an owner and a pruning cadence. |
| "We don't need a 'good feedback' standard" | Without it, CS and Sales submit one-line gripes and PMs can't act. The standard is the quality floor. |
| "Everyone gets an auto-owner" | Auto-owner quality depends on tag/source quality. Design the inputs first. |
| "Let's skip segmentation for now" | Without segment data, prioritization becomes opinion-based. Even a rough segment field beats none. |
| "We'll figure out the portal later" | Fine — but document the deferral decision and the condition that unlocks it. Don't leave it vague. |

---

## Close — synthesis structure

1. **Decisions summary** — sources, triage owners, tag strategy, automations, segments, portal decision
2. **Open items** — missing inputs (CRM access, feedback migration scope, portal stakeholder)
3. **Configuration backlog** — what SA will build (insights views, automations, segments, note templates)
4. **Next activity** — usually Harvester/legacy migration scoping or prioritization session
5. **Customer confirmation** — explicit confirmation the pipeline design matches their process

---

## Tweak guidance

- If they have no current feedback tool, simplify — focus on triage + "good feedback" standard first
- If they're replacing a feedback tool, Portal decision should explicitly address whether it replaces the old tool's public surface
- If Sales/CS aren't in the session, flag source ownership as an open item, don't assume
- Match the segment taxonomy to the CRM's actual field list — don't invent
