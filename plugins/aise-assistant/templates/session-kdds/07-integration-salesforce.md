# Salesforce Integration — Session Template

**Session ID:** Usually part of admin stream or bundled with feedback integrations
**Duration:** 45–60 min
**Attendees:** Technical lead / IT admin, Program owner (brief), Salesforce admin, Product Ops (if segmentation-heavy)
**Prerequisites:** Feedback session defined company field + segment requirements; Salesforce admin access available
**Outputs:** Salesforce company field sync configured, segment definitions live, sync cadence documented

---

## Purpose

Configure Salesforce → Productboard company data sync to support VoC weighting, Customer Importance Score, and segment-based prioritization. This is a **data pipeline configuration** session.

---

## Outcomes to drive in-session

By the close, the customer has decided:
- Sync direction + scope (typically one-way SFDC → PB)
- Which SFDC fields map to which PB custom company fields
- Sync cadence + trigger
- Segment definitions backed by synced fields
- Data quality handling (stale records, missing values, duplicates)
- Cutover / initial data load plan

---

## Pre-read / inputs needed from customer

- Salesforce field list for Account object (or equivalent)
- Named SFDC admin with integration permissions
- CIS / segmentation requirements from the Insights session
- Data quality baseline — which accounts are stale, how many have missing fields

---

## KDDs to facilitate

### 1. Sync direction + scope

**Questions to ask:**
- Is the integration one-way (SFDC → PB) or bidirectional?
- Which SFDC object(s) are in scope — Account, Opportunity, Contact?
- Do we sync all accounts or filtered (active, paying, non-churned)?
- Any records explicitly excluded (internal test accounts, churned)?

**Key considerations:**
- One-way SFDC → PB is the standard. Bidirectional is rare and usually unnecessary.
- Account object is primary. Contacts sync is usually overkill for Phase 1.
- Filter to active/live accounts — stale records pollute CIS.

**Decision table:**

| Direction / Scope | In scope | Rationale |
|---|---|---|
| SFDC → PB, Account object | | |
| Filter rules | | |

---

### 2. Field mapping

**Questions to ask:**
- Which SFDC fields map to PB custom company fields?
- What attributes matter for prioritization (ARR, tier, region, industry, plan, CS health score, renewal date)?
- Are any SFDC fields calculated/formula — do they sync cleanly?
- Any fields that should transform on sync (e.g. concatenate, lookup)?

**Key considerations:**
- Less is more. Sync only fields that drive decisions.
- Renewal date is often high-value for prioritization windows.
- Custom formula fields can break silently. Test each one.

**Decision table:**

| SFDC field | PB custom company field | Type | Used in |
|---|---|---|---|
| | | | |

---

### 3. Sync cadence + triggers

**Questions to ask:**
- How often should data refresh — real-time, daily, weekly?
- Event-triggered (e.g. opportunity closed) or scheduled?
- Who monitors sync health?
- What happens if a sync fails — alert where, to whom?

**Key considerations:**
- Daily is the standard sweet spot. Real-time adds API cost and isn't usually needed.
- Alerting should go to the IT admin, not just PB.

**Decision table:**

| Sync | Cadence | Trigger | Monitored by |
|---|---|---|---|
| | | | |

---

### 4. Segment definitions

**Questions to ask:**
- Which segments do PMs actually use in prioritization (Enterprise, Mid-market, by region, by industry, by tier)?
- Are segments derived from single fields or multi-field rules?
- Dynamic segments (update as data changes) or static lists?
- Who owns segment definitions post-go-live?

**Key considerations:**
- Dynamic segments are almost always the right choice — they self-maintain.
- Segment sprawl is a real risk. Cap at 5–8 segments for Phase 1.

**Decision table:**

| Segment | Filter logic | Use case | Owner |
|---|---|---|---|
| | | | |

---

### 5. Data quality handling

**Questions to ask:**
- What's the baseline data quality in SFDC — missing fields per record, duplicates?
- Do we block sync for records missing required fields, or sync with gaps?
- How are duplicate accounts handled?
- What's the cleanup plan if data quality is poor?

**Key considerations:**
- Data quality issues become CIS weaknesses. Address at source in SFDC, not downstream in PB.
- Don't block sync on data quality — it becomes blameable on the integration.

**Decision table:**

| Quality issue | Handling | Source-side action |
|---|---|---|
| Missing required field | | |
| Duplicate account | | |
| Stale record (no activity >X months) | | |

---

### 6. Cutover + initial load

**Questions to ask:**
- Initial historical load — all records or filtered?
- Timing of cutover vs pilot activity?
- Post-load validation — spot checks, counts, CIS calculations?
- Rollback if initial load looks wrong?

**Decision table:**

| Cutover activity | Owner | Timing |
|---|---|---|
| Initial load | | |
| Validation | | |
| Go-live | | |

---

### 7. Governance post-go-live

**Questions to ask:**
- Who approves new field mappings after go-live?
- Who owns segment definition changes?
- Review cadence for sync health + data quality?

**Decision table:**

| Area | Owner | Cadence |
|---|---|---|
| Field mappings | | |
| Segment definitions | | |
| Health review | | |

---

## Red flags & rebuttals (internal)

| Red flag | Rebuttal |
|---|---|
| "Sync every SFDC field, just in case" | Field bloat = slow syncs, unclear UX. Sync only what drives decisions. |
| "We'll build the segments later" | Segments drive CIS and prioritization. Without them, the integration adds little value. |
| "Our SFDC data is messy, but it'll be fine" | Messy source = messy destination = weak CIS. Flag as open item, don't paper over. |
| "Let's make the integration bidirectional" | Rare real need. Adds conflict resolution complexity. Ask what problem it solves. |
| "Real-time sync is a must-have" | Almost never true. Daily is fine for CIS and segment use cases. |

---

## Close — synthesis structure

1. **Decisions summary** — direction, field mappings, cadence, segments, data quality handling
2. **Open items** — missing SFDC admin access, data cleanup before go-live
3. **Configuration backlog** — SA builds integration + segments; customer provides SFDC access + cleanup commitment
4. **Validation plan** — spot-check after initial load
5. **Customer confirmation** — SFDC admin confirms the field list and sync plan are workable

---

## Tweak guidance

- If segments were already defined in the Insights session, pre-populate segment rows citing the source session — customer just validates
- For customers not using Salesforce, swap terms (HubSpot, Dynamics, custom CRM) — structural KDDs are the same
- If the customer has no dedicated SFDC admin, flag field mapping as conditional and offer a follow-up working session
- If CIS isn't going to be active in Phase 1, keep this session lighter — sync is there for future use, not immediate value
