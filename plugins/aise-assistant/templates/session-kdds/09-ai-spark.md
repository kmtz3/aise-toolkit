# AI + Spark Workshop — Session Template

**Session ID:** Usually `A5` (after Foundations + Backlog + Roadmaps, once content is in PB)
**Duration:** 60–90 min
**Attendees:** Program owner, PMs (pilot), Product Ops, PM leadership (optional)
**Prerequisites:** PB has real content (features, notes, roadmaps); customer has real PM scenarios to work on
**Outputs:** Prioritized Spark use cases, context plan, one usable workflow output, pilot user list, adoption plan

---

## Purpose

Anchor Spark to the customer's highest-value PM workflows. Produce one usable artefact live. This is a **workflow onboarding workshop**, not an AI feature demo.

---

## Outcomes to drive in-session

By the close, the customer has:
- Prioritized Spark use cases (2–3 for the pilot)
- Context strategy + starter context inventory
- Shared skills + prompts (if applicable)
- One usable output from a real scenario
- Review/quality standard for outputs
- Integration into existing rituals
- Pilot user list + adoption next steps

---

## Pre-read / inputs needed from customer

- Top PM pain points Spark could address
- Named pilot users (PMs or Product Ops)
- One real scenario to run live (a real initiative, brief, or feedback batch — not hypothetical)
- Current AI tool landscape (Claude, Gemini, OpenAI, custom agents) — for positioning

---

## KDDs to facilitate

### 1. Use case prioritization

**Questions to ask:**
- What are your biggest PM pain points — feedback overload, PRD/brief creation, competitor research, context fragmentation, stakeholder comms?
- Which Spark use cases fit best — Feedback Analysis, Product Brief, Competitor Analysis, others?
- What's your time-to-value priority — which unlocks fastest?
- What are you explicitly deferring today?

**Key considerations:**
- Start narrow. 2–3 use cases, not 8.
- Use cases with ready inputs (populated notes, existing briefs) produce better first-value moments than greenfield ones.
- Avoid trying to demo every Spark capability.

**Decision table:**

| Use case | Pain point addressed | Priority (P1/P2/defer) | Inputs available? |
|---|---|---|---|
| Feedback Analysis | | | |
| Product Brief | | | |
| Competitor Analysis | | | |
| | | | |

---

### 2. Positioning vs existing AI tools

**Questions to ask:**
- What's your current AI tool landscape — Claude, Gemini, OpenAI, custom agents?
- Where does Spark differentiate (persistent PM context, guided workflows, PB-grounded output)?
- Where does Spark NOT replace existing tools (general research, code, non-PM tasks)?
- What's Spark's beta/limitations framing you want teams to have?

**Key considerations:**
- Overhyping Spark kills credibility. Be honest about current state + beta limitations.
- Spark complements other AI tools — it doesn't replace them for non-PM work.

**Decision table:**

| Workflow | Tool | Rationale |
|---|---|---|
| PM-specific with PB context | Spark | |
| General research / strategy | Other AI | |
| Code / technical | Other AI | |

---

### 3. Context strategy

**Questions to ask:**
- What's evergreen shared context — company strategy, personas, product background, templates, recurring references?
- What's per-job / per-chat context — initiative docs, current research, temporary inputs?
- Which high-signal context sources come first?
- Naming / organization standards for context assets?
- Who owns context upkeep?

**Key considerations:**
- Context quality = output quality. Garbage in, generic out.
- Don't upload everything. Curate.
- Evergreen context should be owned (single owner, review cadence).

**Decision table:**

| Context asset | Type (evergreen / per-job) | Source | Owner |
|---|---|---|---|
| | | | |

---

### 4. Skills + prompts (if applicable)

**Questions to ask:**
- Which repeatable workflows should become custom Skills?
- Are there prompt templates worth standardizing (brief structure, synthesis format, competitive analysis framework)?
- Who owns the skills library + prompt library?
- Quality bar for adding a new skill — avoid one-off clutter?

**Decision table:**

| Skill / Prompt | Purpose | Inputs | Owner |
|---|---|---|---|
| | | | |

---

### 5. Live workflow execution

**Run one real scenario end-to-end.** Not canned, not hypothetical.

**Execution checklist:**
- Real customer scenario chosen (named initiative / note batch / brief)
- Inputs gathered before running (prompts, context assets)
- Customer participates in prompt/input decisions
- Workflow produces a draft output (not partial exploration)
- Discuss what made the output strong or weak (inputs, context, missing data)

**Outputs:**

| Scenario | Workflow used | Output artefact | Usable? |
|---|---|---|---|
| | | | |

---

### 6. Human judgment + review standards

**Questions to ask:**
- How do PMs validate Spark outputs against source context + business reality?
- How do they spot weak assumptions, missing evidence, generic content?
- What level of human review is required before sharing / using outputs?
- How do they iterate (better inputs, more context, refined instructions)?
- Responsible use framing — Spark accelerates PM work, doesn't replace PM judgment.

**Decision table:**

| Output type | Review required | Reviewer | Sign-off? |
|---|---|---|---|
| Internal-only draft | | | |
| Shared with stakeholders | | | |
| Customer-facing | | | |

---

### 7. Workflow integration + team rituals

**Questions to ask:**
- Where does Spark fit in existing PM workflows (discovery, synthesis, brief writing, roadmap prep)?
- Which team rituals benefit (planning, reviews, monthly feedback synthesis)?
- Who uses Spark first (pilot users)?
- What outputs move into other systems (Notion, docs, planning tools)?
- How do we avoid Spark becoming "demo-only"?

**Decision table:**

| Workflow / ritual | Spark step | Owner | Downstream destination |
|---|---|---|---|
| | | | |

---

### 8. Pilot + rollout

**Questions to ask:**
- Named pilot users — who's first?
- Success criteria for the pilot (what "working" looks like)?
- Check-in cadence for the pilot?
- Rollout trigger — what proves it's ready for broader use?

**Decision table:**

| Pilot user | Use case focus | Check-in timing | Success criteria |
|---|---|---|---|
| | | | |

---

### 9. Limitations + realistic expectations

**Questions to ask:**
- What are the current Spark limitations / beta constraints relevant to this customer?
- Where might outputs disappoint (scale of context, specific use cases not yet supported)?
- What's deferred to later product maturity?
- How do we build confidence without overpromising?

**Decision table:**

| Limitation | Impact | Workaround / mitigation |
|---|---|---|
| | | |

---

## Red flags & rebuttals (internal)

| Red flag | Rebuttal |
|---|---|
| "Let's try every Spark feature" | Surface-level coverage = no real adoption. Narrow to 2–3 use cases with strong fit. |
| "Upload everything as context" | Context bloat = generic output. Curate to high-signal sources. |
| "Spark will replace our other AI tools" | Overpromise that kills trust when reality lands. Position as complement, not replacement. |
| "We don't need review standards, just use the output" | Treating outputs as final = bad decisions + reputational risk. Define the review bar. |
| "We'll figure out use cases on our own" | Without anchoring, Spark becomes shelfware. Pilot with defined scenarios. |
| "Demo one canned example, we'll do real work later" | First-value moment = real scenario. Canned demos don't stick. |

---

## Close — synthesis structure

1. **Decisions summary** — prioritized use cases, context plan, pilot users, review standards
2. **Open items** — context assets to gather, pilot check-in timing
3. **Configuration backlog** — context setup, skills/prompts to create, access provisioning
4. **Next activity** — first pilot workflow runs + check-in schedule
5. **Success criteria for next checkpoint** — what progress looks like
6. **Customer confirmation** — pilot user list + first workflow commitment

---

## Tweak guidance

- If the customer has heavy existing AI tooling, spend more time on positioning (when to use Spark vs other tools)
- If their AI maturity is low, anchor on one use case only — don't overwhelm
- If PB content is thin (early in the program), this session should move later — Spark value depends on populated content
- Pick the live scenario before the session. Nothing kills momentum like picking a scenario live and realizing inputs aren't ready.
- If Product Ops is in the room, they often become the natural context + skills owner — call this out as a decision
