# Workspace Settings & Governance — Session Template

**Session ID:** Often `S0` (informal scoping) or part of admin stream
**Duration:** 45–60 min
**Attendees:** Technical lead / IT owner, Program owner (brief overlap), Exec sponsor (sign-off)
**Prerequisites:** Contract signed; workspace(s) provisioned
**Outputs:** Workspace decision, admin model, naming conventions baseline, governance ownership map

---

## Purpose

Decide workspace-level configuration, governance, and admin model before deep architecture work begins. This is a **governance + setup** session, separate from Foundations.

---

## Outcomes to drive in-session

By the close, the customer has decided:
- Which workspace to use (trial, fresh, migrate)
- Admin roster + escalation model
- Governance ownership per config area
- Naming conventions (workspace-wide)
- General teamspace purpose + guardrails
- Migration scope (what carries over, what's left behind)

---

## Pre-read / inputs needed from customer

- List of existing PB workspaces (trial, contract, any legacy)
- Current workspace contents inventory (if migrating from a trial)
- Named IT / workspace admin
- SSO/SCIM status (often a parallel stream)

---

## KDDs to facilitate

### 1. Workspace decision

**Questions to ask:**
- Which workspace do we use — trial (clean and keep), fresh (new setup), or migrate (selective carryover)?
- If trial: what's worth keeping vs starting fresh?
- If fresh: what content do we need to migrate from trial/legacy?
- What's the cutover plan?

**Key considerations:**
- SSO already configured on a workspace is a strong argument for keeping it, even if content is messy.
- "Burn down and rebuild" is often faster than cleaning a cluttered workspace — but only with a disciplined migration scope.
- Multiple workspaces create licensing + governance complexity. Consolidate to one.

**Decision table:**

| Option | In scope | Rationale |
|---|---|---|
| Keep trial (clean) | | |
| New workspace | | |
| Migrate selectively | | |

---

### 2. Admin model

**Questions to ask:**
- Who are the named admins (and how many)?
- What's the escalation path for config changes (e.g. new field, new teamspace)?
- Is there an IT admin vs a PM admin vs both?
- What governance exists for contentious changes (status edits, field deletions, workspace-wide settings)?

**Key considerations:**
- Admin count should be tight. 1–3 named admins is usually right.
- "Give everyone admin" creates sprawl + accidental destruction risk.
- Separate admin roles: IT owns identity/integrations; PM Ops owns taxonomy/workflow.

**Decision table:**

| Admin | Role | Scope | Escalation path |
|---|---|---|---|
| | | | |

---

### 3. Governance ownership per area

**Questions to ask:**
- Who owns the custom field library (adds, removes, prunes)?
- Who owns the tag library?
- Who owns teamspaces + folders (can create, rename, archive)?
- Who owns status definitions?
- Who owns the product hierarchy (adds new products/components)?
- Who reviews + approves integration configs?
- How often is each area reviewed?

**Decision table:**

| Area | Owner | Review cadence | Approval for changes |
|---|---|---|---|
| Custom fields | | | |
| Tags | | | |
| Teamspaces / folders | | | |
| Statuses | | | |
| Product hierarchy | | | |
| Integrations | | | |

---

### 4. Naming conventions (workspace-wide)

**Questions to ask:**
- Naming rules for Products (prefix / plain / custom)?
- Naming rules for Components?
- Naming rules for Teams + handles?
- Tag naming rules (case, singular/plural, hierarchy)?
- Feature naming guidance?

**Key considerations:**
- BU/tribe prefix on Products often creates more confusion than value — cross-BU products break the convention. Use a BU/Tribe custom field instead.
- Team prefixes (e.g. `[CM]`, `[PL]`) are useful because flat team lists need a single search axis.
- Tag naming rules prevent the biggest long-term maintenance problem (tag sprawl).

**Decision table:**

| Object | Convention | Example | Rationale |
|---|---|---|---|
| Product | | | |
| Component | | | |
| Team | | | |
| Team handle | | | |
| Tag | | | |
| Custom field | | | |

---

### 5. General teamspace purpose

**Questions to ask:**
- What's General for in this workspace — shared views, cross-team roadmaps, exec visibility?
- What belongs in General vs a specific teamspace?
- Who can add to General?
- Any guardrails to prevent misuse (e.g. using General as a team's workspace)?

**Decision table:**

| Content type | In General? | Owner |
|---|---|---|
| | | |

---

### 6. Migration scope

**Questions to ask:**
- If migrating: what artefacts are worth carrying over (features, notes, roadmaps, integrations, users)?
- What's the quality bar — migrate everything, or curated subset?
- Who executes the migration (SA + customer lead)?
- Cutover date?

**Key considerations:**
- Migrating garbage = cleaning garbage later. Curate aggressively.
- Integrations should usually stay attached to the production workspace from day one.

**Decision table:**

| Artefact | Migrate? | Curated how? | Owner | Cutover |
|---|---|---|---|---|
| | | | | |

---

### 7. Workspace-wide settings

**Questions to ask:**
- Default roles for new users — Maker, Contributor, Viewer?
- Auto-assignment on domain (if applicable)?
- Feedback portal defaults?
- Notification defaults?
- Any compliance/privacy settings needed (data residency, export restrictions)?

**Decision table:**

| Setting | Current | Target | Owner |
|---|---|---|---|
| | | | |

---

## Red flags & rebuttals (internal)

| Red flag | Rebuttal |
|---|---|
| "Give everyone admin so they can self-serve" | Admin sprawl = field/status/teamspace chaos inside a month. Tight admin roster + responsive request flow works better. |
| "We don't need naming conventions, people will figure it out" | Without conventions, workspace becomes unsearchable inside 6 months. Define them now. |
| "Let's use two workspaces" | Doubles licensing + governance. Collapse to one unless there's a hard reason (separate regulated entity, etc.). |
| "Migrate everything from the trial" | Migrating mess = maintaining mess. Curate. |
| "General teamspace is for our [small team]" | Breaks guardrails for everyone else. General is shared by design. |
| "We'll assign governance later" | Unowned config drifts. Name an owner today, even if provisional. |

---

## Close — synthesis structure

1. **Decisions summary** — workspace decision, admin roster, governance ownership, naming, General purpose, migration scope
2. **Open items** — SSO/SCIM status, missing admin, migration details
3. **Configuration backlog** — workspace provisioning, admin assignments, governance doc
4. **Parallel streams flagged** — SSO/SCIM timeline, integration prereqs
5. **Customer confirmation** — tech lead confirms they can execute the admin model

---

## Tweak guidance

- For smaller customers, most governance sits with one person — don't force multi-owner tables
- If SSO/SCIM is already live, this session is lighter (admin model is mostly confirmation, not design)
- If migrating from a legacy tool (not a trial workspace), migration scope needs its own dedicated working session — don't try to close it here
- For regulated industries, add a compliance section — data residency, audit log, export controls
