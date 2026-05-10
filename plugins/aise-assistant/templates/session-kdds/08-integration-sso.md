# SSO / Okta / SCIM — Session Template

**Session ID:** Usually `A7` (admin stream, runs parallel to PM-facing architecture)
**Duration:** 60–90 min
**Attendees:** IT admin / Technical lead, Security (optional), Program owner (brief)
**Prerequisites:** Foundations roles decisions (Admin Maker / Maker / Contributor / Viewer); customer IdP access
**Outputs:** SCIM design live, Okta group → PB role mapping, offboarding process, provisioning rules

---

## Purpose

Design end-to-end identity management so users get the right role and teamspace access automatically via the customer's IdP. This is an **identity architecture + provisioning** session.

---

## Outcomes to drive in-session

By the close, the customer has decided:
- SSO approach (SAML, specifics)
- Okta (or other IdP) group model → PB role mapping
- SCIM scope + attributes
- Provisioning rules (auto-assign on domain, default role, teamspace membership)
- Offboarding workflow
- Testing / rollout plan

---

## Pre-read / inputs needed from customer

- IdP tenant (Okta / Azure AD / OneLogin / Google Workspace)
- Current Okta group list relevant to PB
- Named IT owner with IdP admin access
- Role decisions from Foundations
- User count baseline + expected growth

---

## KDDs to facilitate

### 1. SSO approach

**Questions to ask:**
- Which IdP — Okta, Azure AD, OneLogin, Google Workspace, other?
- SAML or OIDC? (PB supports SAML; confirm the customer's IdP supports this.)
- Single or multi-domain setup?
- Any SSO-specific compliance requirements (MFA enforcement, session length, IP restrictions)?
- Is SSO already configured on the workspace, or setting up from scratch?

**Key considerations:**
- SSO already live on a trial workspace is a strong argument for keeping that workspace.
- MFA is enforced by the IdP, not PB.
- Session length + IP restrictions live at the IdP layer.

**Decision table:**

| SSO element | Decision | Notes |
|---|---|---|
| IdP | | |
| Protocol | | |
| MFA | | |
| Session length | | |
| IP restrictions | | |

---

### 2. Okta / IdP group model

**Questions to ask:**
- Which Okta groups are relevant to PB users — PM, Engineering, CS, Exec, IT, Contributors?
- How do groups map to the four PB roles?
- Do groups map to teamspace membership as well, or just roles?
- Is there a sensible default group for new hires?
- Any groups explicitly excluded from PB access?

**Key considerations:**
- Group-based role assignment is far cleaner than individual user assignment.
- Default group for new hires should be Contributor or Viewer unless PM Ops manually promotes.
- Admin role should be tightly scoped — ideally named individuals, not a group.

**Decision table:**

| Okta group | PB role | Teamspace membership | Auto-provisioned? |
|---|---|---|---|
| | | | |

---

### 3. SCIM scope

**Questions to ask:**
- Which Okta groups are SCIM-managed (full lifecycle) vs manually managed?
- Which user attributes sync via SCIM (name, email, title, department)?
- How are role changes handled — group membership change in Okta propagates to PB?
- What happens when a user is deactivated in Okta — immediate PB deactivation or grace period?

**Key considerations:**
- SCIM-managed = scalable. Manual = tech debt. Prefer SCIM for all groups.
- Title / department attributes are often useful for reporting but optional.
- Immediate offboarding is the security-preferred default.

**Decision table:**

| Attribute | SCIM-synced? | Source of truth |
|---|---|---|
| Name | | |
| Email | | |
| Title | | |
| Department | | |
| Group membership | | |

---

### 4. Provisioning rules

**Questions to ask:**
- What happens on first login — auto-assign to a default role/teamspace?
- Domain-based auto-assignment (e.g. @customer.com → Contributor)?
- How are guest / external users handled (contractors, agencies)?
- Any approval workflow for role upgrades (Contributor → Maker)?

**Decision table:**

| Scenario | Provisioning action | Approval required? |
|---|---|---|
| New hire in known group | | |
| Domain match, no group | | |
| External / contractor | | |
| Role upgrade request | | |

---

### 5. Offboarding workflow

**Questions to ask:**
- When a user leaves, what's the PB action — immediate deactivate, deactivate after X days, archive?
- What happens to their owned features / notes — reassign, leave unassigned, archive?
- Who handles the reassignment (manager, PM lead, admin)?
- Is there an audit requirement (log of who had access when)?

**Decision table:**

| Offboarding scenario | PB action | Owner |
|---|---|---|
| | | |

---

### 6. Admin roster

**Questions to ask:**
- Named admins post-go-live (1–3 people, not a group)?
- IT admin vs PM admin vs both?
- Escalation path for urgent changes?
- Break-glass access if the primary admin is unavailable?

**Decision table:**

| Admin | Role type | Break-glass |
|---|---|---|
| | | |

---

### 7. Testing + rollout plan

**Questions to ask:**
- Test users / groups before going live?
- Rollout sequence — IT first, pilot PMs, then wider?
- Rollback plan if SCIM behaves unexpectedly?
- Validation checklist — can we provision, role-change, deprovision cleanly?

**Decision table:**

| Test / rollout step | Owner | Success criteria |
|---|---|---|
| | | |

---

### 8. Documentation + runbook

**Questions to ask:**
- Who documents the final config (groups, mappings, SCIM rules)?
- Where does the runbook live (IT wiki, PB admin docs)?
- Review cadence for the runbook?

**Decision table:**

| Artefact | Owner | Location |
|---|---|---|
| Config doc | | |
| Runbook | | |

---

## Red flags & rebuttals (internal)

| Red flag | Rebuttal |
|---|---|
| "Let's do SCIM later, manual provisioning is fine" | Manual provisioning at scale = onboarding delays + orphan accounts. SCIM pays back quickly. |
| "Give all PMs Admin" | Admin is a governance role, not a PM role. Makers cover normal PM work. |
| "Make SSO optional for some users" | Inconsistent access model creates audit gaps. SSO for all or none. |
| "Don't sync group membership, just roles" | Then teamspace access drifts out of sync from role. Do both. |
| "We'll figure out offboarding case-by-case" | Inconsistent offboarding = security risk + leftover content owners. Define the default now. |
| "Test in production" | IdP misconfigurations lock out real users. Use a test group first. |

---

## Close — synthesis structure

1. **Decisions summary** — SSO protocol, group → role mapping, SCIM scope, provisioning + offboarding rules
2. **Open items** — missing IdP access, pending security approvals
3. **Configuration backlog** — IT configures SCIM; SA validates in PB
4. **Testing plan** — pilot group, validation checklist, rollback
5. **Customer confirmation** — IT lead confirms they can execute the config

---

## Tweak guidance

- For customers on Azure AD or Google Workspace, replace Okta-specific terms but keep the structural KDDs
- If SCIM isn't supported on the customer's PB plan, flag this early and propose the manual provisioning alternative
- For smaller customers (<50 users), SCIM may be overkill — offer a simpler SAML-only SSO
- If Security team is in the session, add a section on audit logging + data residency requirements
