# Session KDD Templates

Customer-facing templates for anchoring architecting sessions and capturing Key Design Decisions (KDDs) live during the call.

Each template is a **dual-purpose** document:
- **Anchor** — sets the agenda, frames the outcomes, lists the decisions to drive.
- **Capture** — numbered slots for KDDs to be recorded as they're made (`D1`, `D2`, …), producing the session's contribution to the decisions register on the customer's Active Package page.

The user (account owner) maintains the templates in this folder. Agents should read them, adapt them to the specific customer, and never overwrite them.

---

## Naming convention

One file per A-session type, prefixed with a two-digit sort key, kebab-case. Current set:

- `01-foundations.md` — Foundations Architecture
- `02-feedback.md` — Insights / Feedback Architecture
- `03-prioritization.md` — Backlog Architecture / PDLC / Prioritization
- `04-roadmaps.md` — Roadmap System Design
- `05-workspace-settings.md` — Workspace & Governance
- `06-integration-jira.md` — Jira Integration
- `07-integration-salesforce.md` — Salesforce Integration
- `08-integration-sso.md` — SSO / Okta / SCIM
- `09-ai-spark.md` — AI + Spark Workshop

Add / rename as the session taxonomy evolves. Use `00-index.md` as the authoritative mapping of session type → filename — agents should resolve templates from there, not from this list.

---

## How agents should use these

When a future `/plan-session` (or `/session-prep`) flow runs for an A-session:

1. **Resolve the template** — match the session sub-type (Foundations, Insights, etc.) to the filename in this folder.
2. **Read the template** — do not modify the source file.
3. **Adapt to the customer** — fill in stakeholders, pilot team, prior decisions, open items from the customer's Active Package page and prior session logs.
4. **Post the adapted copy** to the Notion Session page body (not here). It becomes the anchor doc for the call and the container for live KDD capture.
5. **After the session**, the captured decisions are extracted by `session-summarizer` into the Active Package decisions register.

If a template is missing for a given session type, flag it to the user — do not invent one.

---

## Format notes

- American English, semi-formal voice — see [`context/communication-style-guide.md`](../../context/communication-style-guide.md).
- Customer-facing: no internal jargon, no facilitator scripts, no red-flag tables (those belong in internal prep, not the anchor doc).
- Structured with bolded labels, tables where they help, and numbered KDD slots. Match the tone of [`context/engagement-planning-guide.md`](../../context/engagement-planning-guide.md) output.
