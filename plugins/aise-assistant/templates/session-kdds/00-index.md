# Session Templates — System Index

Reusable session architecture templates for Productboard SA engagements. Each template mirrors a FigJam page and drives a specific set of Key Design Decisions (KDDs).

Companion to [`context/engagement-planning-guide.md`](../../context/engagement-planning-guide.md). Use that to scope the program. Use these templates to prep and run the individual A-sessions.

---

## Template library

| File | Session | Scorecard mapped | Typical ID |
|---|---|---|---|
| `01-foundations.md` | Foundations Architecture | 🏗️ Foundations | `A1` |
| `02-feedback.md` | Insights / Feedback Architecture | 👀 Insights | Usually `A4` |
| `03-prioritization.md` | Backlog Architecture / PDLC / Prioritization | 🧮 Prioritization | Usually `A2` |
| `04-roadmaps.md` | Roadmap System Design | 🗺️ Roadmaps | Usually `A3` |
| `05-workspace-settings.md` | Workspace & Governance | (part of Foundations) | Often `S0` or admin stream |
| `06-integration-jira.md` | Jira Integration | (admin stream) | Usually `A8` |
| `07-integration-salesforce.md` | Salesforce Integration | (admin stream) | Usually bundled with feedback integrations |
| `08-integration-sso.md` | SSO / Okta / SCIM | (admin stream) | Usually `A7` |
| `09-ai-spark.md` | AI + Spark Workshop | ⚡ Spark | Usually `A5` |

---

## How the agent should use these templates

**Trigger phrases:**
- "Prep the [session type] session for [customer]"
- "Build me the [session type] brief"
- "Give me the KDDs for [session type]"
- "Tweak the [session type] template for [customer]"

**Workflow:**

1. **Identify the right template** from the library above. If the session is genuinely a new type, say so rather than forcing a fit.
2. **Read the customer's program context** from project knowledge — stakeholders, prior decisions (decisions register), open items, risks.
3. **Tweak the template** by:
   - Customizing the KDD questions to reference the customer's actual terminology (e.g. "tribes/crews" for Kpler, not generic "teams")
   - Pre-populating decision tables with anything already decided in prior sessions (cite D-numbers)
   - Flagging KDDs that are blocked by missing inputs or absent stakeholders
   - Removing red flag sections that don't apply to this customer's maturity level
4. **Don't pre-fill decision values.** Decision tables arrive blank or with one illustrative row. The customer arrives at the decision live; the template is a facilitation scaffold, not a pre-built answer. This is the #1 scoring principle from the PSP/SA Score Cards.
5. **Output format:** a single markdown artefact ready to drop into a FigJam page or customer-facing deck. Keep the internal-only sections (red flags, rebuttals, tactical notes) in a separate "Facilitator notes" section clearly demarcated so they don't leak into the customer view.

---

## Template structure (every file follows this shape)

```
# [Session Name] — Template

Session ID | Duration | Attendees

## Purpose
## Outcomes to drive in-session
## Pre-read / inputs needed from customer
## KDDs to facilitate
  ### Topic 1
    - Questions to ask
    - Key considerations
    - Decision table (blank)
  ### Topic 2
  ...
## Red flags & rebuttals (internal)
## Close — synthesis structure
## Tweak guidance
```

The consistency is deliberate — an agent can reliably extract any section programmatically.

---

## Customer-facing KDD doc (copy-paste output)

For every **A-session** (architecting), the user runs the call off a **customer-facing KDD doc** — a cleaned-up derivative of the internal template above. The internal template stays internal. The customer-facing doc is what gets shared / copy-pasted into the customer's space (Notion, Confluence, shared doc) to anchor the session and capture decisions live.

**Storage in the user's tracker:** the doc lives as a **sub-page of the Notion Session page** (child page, parent = Session page). Title: `KDDs — [Session ID] [Session Name]`. Created automatically by `session-prepper` during `/session-prep` for A-sessions, or on demand via `/session-kdds` → `kdd-builder`.

### Required structure

```markdown
# [Session ID] [Session Name]
*[Customer] · [Date] · [Duration]*

## Agenda
1. Framing and outcomes
2. [KDD topic 1]
3. [KDD topic 2]
…
N. Synthesis and next steps

## Outcome
By the end of this session, we will have:
- Decided: …
- Aligned: …
- Documented: …

## Action items
| # | Owner | Action | Due |
|---|---|---|---|

## Key Design Decisions

### D#. [Topic]
**Question:** [one-line framing from the internal template's "Questions to ask"]

**Starter example — react to this, not decide from it:**
| column | column | … |
|---|---|---|
| [seeded row 1] | | |
| [seeded row 2 — optional] | | |

**Decision (captured live):**
| column | column | … |
|---|---|---|
| | | |

…repeat per KDD in the session…
```

### Transform rules (internal template → customer-facing doc)

| Internal section | Maps to | Notes |
|---|---|---|
| Session metadata header | Title block + subtitle | Pull Session ID, Name, Customer, Date, Duration from the Notion Session record |
| Purpose + Outcomes to drive | **Outcome** section | Rewrite in customer voice: "we will have decided/aligned/documented…" |
| KDDs → Questions to ask | **Agenda** (numbered) + per-KDD Question line | Agenda collapses each KDD to one agenda item |
| KDDs → Key considerations | **Starter example** rows (1–2, visibly labeled) | Never framed as pre-decided; always "here's a starting point to react to" |
| KDDs → Decision table | Two side-by-side tables: a Starter example (seeded) and a Decision (blank) | Starter = illustration; Decision = live capture |
| Close → synthesis | **Action items** table | Translate to Owner + Action + Due format |
| Red flags & rebuttals | **EXCLUDED** | Internal facilitator use only; never in the customer doc |
| Pre-read / inputs | **EXCLUDED** (or surfaced in the follow-up email) | |
| Tweak guidance | **EXCLUDED** | |

### Starter examples — sourcing rules

Fill Starter-example rows from (in priority order):

1. **Customer-specific context from discovery / prior sessions** — decisions already captured on the customer's Active Package decisions register, terminology they use (tribes vs BUs vs crews), org chart, pilot team. Cite inline: `from discovery (D7): tribes = Energy, Agri, Freight`.
2. **Anchoring defaults** drawn from the `Key considerations` block of the internal template — labeled `Typical starting point` or `Example — not a recommendation`.
3. **Never** fabricate customer-specific stakeholders, names, or structural choices. If nothing sources, leave only the header row and a note: `No starter example — we'll fill live.`

Starter examples must be visibly tagged and never mixed into the live Decision table.

### What the customer-facing doc is NOT

- Not a facilitator script. No opening lines, no time checks, no rebuttal language.
- Not a slide deck. Flat markdown, rendered as a Notion page.
- Not a prep brief. The internal prep (agenda framing, scorecard hits, risks, questions to ask) stays in the `📋 Prep` toggle on the Session page body.
- Not a follow-up. Post-session recaps are handled by `/session-summary`.

---

## Core principles to preserve on every tweak

These come from the PSP/SA Score Cards. Don't lose them when customizing.

1. **Frame as a design workshop**, not a feature demo. Every session opens with time check → frame → outcomes → participation → what happens next.
2. **Facilitate KDDs; don't present answers.** Questions drive the conversation. Pre-built answers undermine the architecture process.
3. **Capture decisions live** with numbered register entries (`D27`, `D28`, …) that continue from the customer's existing decisions register.
4. **Synthesize at the close.** Decisions → open items → named owners → next session objective → customer confirmation. Missing synthesis is the most common score-killer.
5. **Ground in workspace data.** Never fabricate capability names, team names, or structure. If a decision is blocked by missing customer input, call it out as an open item, don't invent.
6. **Separate customer-facing from internal.** Facilitator notes, red flag rebuttals, and time-pressure contingencies stay in internal sections.

---

## Scoring dimensions (quick reference)

Every A-session scorecard has ~9–10 dimensions. Common across all:

1. Framing and outcome setting
2. Domain-specific KDD facilitation (the bulk — varies by session type)
3. Customer-specific definitions vs generic concepts
4. Prerequisites and dependency mapping
5. Red flags surfaced and addressed
6. Decisions captured with owners
7. Configuration readiness close

The templates are structured so that if the agent fills every section, the session will hit ≥4 on every dimension by default.

---

## Out of scope for these templates

Route elsewhere for:
- Program-level planning → [`context/engagement-planning-guide.md`](../../context/engagement-planning-guide.md) / `/customer-plan --full`
- Session debriefs / Gong-driven recaps → separate debrief workflow
- Decisions register updates → separate tracker workflow
- Customer comms drafting (Slack, email) → separate comms workflow
- Discovery sessions → these are `S`-sessions with a different scorecard (Technical Discovery)
