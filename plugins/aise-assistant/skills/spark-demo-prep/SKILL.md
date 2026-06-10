---
name: spark-demo-prep
description: >
  Generate a fully customized Spark demo playbook for a customer. Pulls the latest
  Spark feature releases from Slack (#releases), researches the customer via Glean /
  Gong / Gmail, detects the customer's brand color scheme, then produces a polished
  HTML playbook as both a Cowork artifact and a downloadable file.
---

Generate a Spark demo playbook for the customer named in the user's message.

## Args

- `customer` (required) — customer name (e.g. "Qlik", "Brandwatch"). Used as the key for
  all research queries and in the playbook title.
- `--scheme orange|teal|purple` (optional) — force a specific color scheme. If omitted,
  the skill auto-detects from the customer's logo (falling back to random).
- `--domain` (optional) — customer's primary domain (e.g. `qlik.com`). Used for logo
  color detection. If not provided, infer it from Glean research results.

## Phase 1 — Parallel Research (run all 4 in parallel)

### 1a. Slack #releases — Spark feature inventory
Search the `#releases` Slack channel for the last 60 days:
```
mcp: slack_search_public_and_private, query: "in:#releases spark", date_range: last 60 days
```
From the results, extract every Spark-related release entry and classify each as:
- **GA** — explicitly marked as generally available, shipped to all customers, or "released to 100%"
- **Internal / Early Access** — marked as internal-only, beta, early access, feature-flagged,
  "not announced yet", or "limited rollout"
- **Roadmap / Coming Soon** — announced but not yet shipped

Build a structured feature list:
```
| Feature name | Status | What it does (1 sentence) | Demo-safe? |
```
Demo-safe = GA only. Internal features appear in the playbook under "Coming Soon" roadmap section
with a ⚠️ internal chip — never demo them as current capabilities.

### 1b. Glean — customer account context
Run three Glean searches in parallel:
1. `glean_search`: `"{customer} productboard"` — general account context, SF notes, support tickets
2. `gmail_search`: `"{customer}"` — recent email threads with customer contacts
3. `meeting_lookup`: `"{customer}"` — Gong call transcripts and summaries

From results, extract:
- **Key contacts**: name, title, team (from email signatures, calendar events, or Gong participants)
- **Use case interests**: anything they've explicitly asked about or flagged (verbatim quotes preferred)
- **Pain points / goals**: what they're trying to solve
- **Account status**: renewal date, ARR (if visible), AI add-on enabled Y/N, Spark enabled Y/N
- **Open items / commitments**: anything promised or outstanding
- **Hot context**: time-sensitive items (merges, migrations, org changes, upcoming deadlines)
- **Customer domain**: infer from email addresses if `--domain` not provided

### 1c. Calendar — session metadata
Search Google Calendar for the next meeting with `{customer}` to extract:
- Date, time, duration
- Attendee names and accept/decline status
- Meeting title (infer session type from it)

If no upcoming meeting is found, use "TBD" for date/time and omit attendee cards.

### 1d. Salesforce (via Glean fallback)
From the Glean results in 1b, also extract:
- Renewal / contract end date
- ARR
- CSM / AE names
- Any open opportunities or risk flags

## Phase 2 — Color Scheme Selection

Priority order: explicit flag → logo detection → random fallback.

### If `--scheme` flag provided:
Use that scheme directly. Map:
- `orange` → scheme "orange-navy" (primary color: #FF5C2B, nav bg: #1F3864)
- `teal` → scheme "teal-dark" (primary color: #0D7A6E, nav bg: #0A3D35)
- `purple` → scheme "purple-dark" (primary color: #6B4FBB, nav bg: #2D1B69)

### Logo detection (when no `--scheme` flag):
Run the logo color extractor script:

```bash
SCRIPT=$(find /sessions -path "*/spark-demo-prep/scripts/extract_logo_color.py" 2>/dev/null | head -1)
# Fallback: try pb-tools directory
[ -z "$SCRIPT" ] && SCRIPT=$(find ~/Projects/pb-tools -path "*/extract_logo_color.py" 2>/dev/null | head -1)
if [ -n "$SCRIPT" ]; then
  pip install Pillow requests --break-system-packages --quiet 2>/dev/null
  python3 "$SCRIPT" "{customer_domain}"
else
  echo "FALLBACK"
fi
```

The script outputs one of: `orange-navy`, `teal-dark`, `purple-dark`, or `FALLBACK`.

### Random fallback:
If logo detection fails (script not found, network error, or outputs `FALLBACK`),
randomly pick from `["orange-navy", "teal-dark"]` using Python:
```bash
python3 -c "import random; print(random.choice(['orange-navy', 'teal-dark']))"
```

## Phase 3 — Content Synthesis

Before generating HTML, produce an internal working outline:

### 3a. Use case angles
From research, identify 2–4 demo angles ranked by relevance to this customer.
Mark each as `primary` (explicitly mentioned by customer or directly maps to a pain point)
or `secondary` (inferred from industry/role/context).

Map each angle to specific Spark capabilities:
- Which GA features best demonstrate it → "demo these"
- Which internal/coming-soon features enhance it → "mention as roadmap"

### 3b. Feature-to-section mapping
For the Use Cases section of the playbook, select 2–3 use cases from the angles above.
For each use case, draft:
- A 1-sentence customer-specific hook (referencing their context)
- A 4–6 step demo flow ("Step 1: Open Spark chat → Step 2: …")
- Which Spark skill or MCP connector to use
- An example prompt (realistic, grounded in their industry/product)
- Credit cost (standard: 1–2 credits per generation)

### 3c. Risks and operational notes
Surface anything from research that should appear as a sidebar alert or operational note
(e.g. a pending migration, a renewal in <90 days, a pending security review).

### 3d. Attendee cards
From calendar + Glean contacts, build an attendee list with:
- Name, title, company
- Accept / Decline / Unknown status (from calendar RSVP data)
- Any known context (e.g. "mentioned feedback analysis in May call")

## Phase 4 — HTML Generation

Generate a single self-contained HTML file following the exact structure and visual design
of the reference playbooks. Read both reference files first to extract the exact CSS, JS,
and component patterns before writing the new file:

**Reference files** (read both at runtime):
- `~/Projects/pb-tools/spark-qlik-demo-playbook.html`
- `~/Projects/pb-tools/spark-brandwatch-demo-playbook.html`

### CSS color variables to parameterize by scheme:

The reference files define scheme colors as named variables in `:root`. Model the variable
naming after the reference files exactly — use semantic names matching the scheme, not
generic `--primary` names. For each scheme, define variables for the main brand color,
its light tint, the nav background, and the active nav state. Examples from reference files:

**orange-navy** (Qlik reference):
```css
--orange: #FF5C2B;
--navy: #1F3864;
--navy-light: #2E4F8A;
--accent-orange: #FEF0E8;
/* nav active: background: rgba(255,92,43,0.2); border-left-color: var(--orange) */
```

**teal-dark** (Brandwatch reference):
```css
--bw-teal: #0D7A6E;
--bw-teal-light: #E6F4F2;
--navy: #1F3864;  /* nav bg stays navy in Brandwatch too */
/* nav active: background: rgba(13,122,110,0.25); border-left-color: var(--bw-teal) */
```

**purple-dark** (new scheme — use analogous naming pattern):
```css
--pb-purple: #6B4FBB;
--pb-purple-light: #F0EBF8;
--pb-purple-mid: #D4C4EF;
--navy: #2D1B69;
/* nav active: background: rgba(107,79,187,0.2); border-left-color: var(--pb-purple) */
```

Always keep `--bg: #F7F8FA`, `--white: #FFFFFF`, `--text: #1A1A2E`, `--text-light: #555`,
`--border: #E2E5EC`, `--sidebar-w: 260px` unchanged across all schemes.

### Required HTML sections (in order):

**Cover / Header**
- Title: "{Customer} — Spark Demo Playbook"
- Meta-card grid: customer name, session date/time, session type, PB team names
- Account status chips (pill badges): AI add-on enabled, Spark enabled, renewal date, any flags

**Section: Overview & Angles** (id="overview")
- Attendee cards grid (`.attendees` / `.attendee-card`): name + title + company + accept/decline status
- Timing bar: visual 60-min distribution across session phases
- Recommended angle cards grid (`.angle-grid` / `.angle-card`): primary (colored border) + secondary (grey border),
  each with a 2-sentence description of why it's relevant to this customer
- Hot context callout (if any): amber/orange background with ⚠️ icon

**Section 1 — Framing Spark** (id="framing")
- "What Spark is" table: 2-col, "What it is" | "What it means for {customer}"
- Opening questions prompt box

**Section 2 — Company Knowledge** (id="company-knowledge")
With 4 sub-sections:
- 2a Templates
- 2b Personas
- 2c Competitors
- 2d Strategic Docs + external connections
  → if the customer has a notable public knowledge base or academy, call it out here specifically

**Section 3 — Integrations & MCP Connectors** (id="integrations")
- Connection methods overview
- MCP connectors grid (GA only)
- File attachment connectors
- Chat-based workspace context table

**Section 4 — Skills** (id="skills")
- 4 skill cards 2×2 grid: Product Brief, Feedback Analysis, Competitor Analysis, Spec
- Custom skills / Prompts library callout

**Section 5 — Use Cases** (id="use-cases")
- 2–3 use case blocks with customer-specific hooks, step flows, prompt boxes
- Coming Soon roadmap block (internal features flagged appropriately)

**Section 6 — Q&A & Next Steps** (id="objections" for Q&A, id="next-steps" for next steps)
- Anticipated Q&A items
- Next steps list split by customer-side vs PB-side
- Links to share row

### Required UI components (use exact class names from reference files):
- Fixed left sidebar nav (260px) with smooth scroll + IntersectionObserver active link tracking
- Section anchors with `id` attributes matching nav `href` targets
- `.pill` status chips for account status
- `.prompt-box` / `.prompt-box-header` / `.prompt-item` for demo prompt blocks
- `.connector-card` / `.connector-grid` for MCP connector display
- `.timing-bar` / `.timing-seg` for the session timing visual
- `.attendees` grid + `.attendee-card` for attendee display
- `.angle-card` / `.angle-grid` for demo angle cards
- `.usecase-block` / `.usecase-header` / `.usecase-body` for use case blocks
- `.next-step` / `.step-circle` / `.step-content` for action items
- `.qa-item` / `.qa-q` / `.qa-a` for Q&A pairs
- `.callout` with modifier classes (`.callout-blue`, `.callout-orange`, `.callout-green`,
  `.callout-yellow`, `.callout-teal` where applicable) for callout boxes
- `.feature-table` for 2-column comparison tables
- `.skills-grid` / `.skill-card` for skills display
- `.roadmap-item` / `.roadmap-dot` / `.roadmap-label` / `.roadmap-text` for roadmap timeline
- `.next-steps` / `.next-step` / `.step-circle` / `.step-content` for action items
- Print CSS: `@media print { nav { display: none } main { margin-left: 0 } }`

Note on IntersectionObserver: use `threshold: 0.25` (matching the Qlik reference).

### Sidebar alert block (render if hot context found):
```html
<div class="nav-alert">
  <div class="alert-title">⚠ Hot context</div>
  {alert_detail}
  <em>Suggested: {one-liner on how to handle}</em>
</div>
```
Use the exact `.nav-alert` / `.alert-title` class names from the Brandwatch reference file.
These are only present in Brandwatch's file; the Qlik file does not have this component.
CSS for `.nav-alert` / `.alert-title` from reference:
```css
.nav-alert {
  margin: 10px 14px; background: rgba(255,92,43,0.15);
  border: 1px solid rgba(255,92,43,0.3); border-radius: 6px;
  padding: 8px 12px; font-size: 11px; color: rgba(255,200,180,0.9); line-height: 1.5;
}
.nav-alert .alert-title {
  font-weight: 700; color: #FF9080; margin-bottom: 3px;
  font-size: 10px; text-transform: uppercase; letter-spacing: 0.5px;
}
```

## Phase 5 — Output

### 5a. Save HTML file
Save to `~/Projects/pb-tools/spark-{customer-slug}-demo-playbook.html`
where `{customer-slug}` = customer name lowercased, spaces → hyphens.

### 5b. Present summary
After generating, print a compact research summary (≤8 lines):
```
📋 Research summary — {Customer}
• Session: {date/time} | {attendee count} attendees
• Scheme: {scheme name} ({detection method: logo-detected | random | flag-override})
• Primary angles: {angle 1}, {angle 2}
• Key context: {most important 1–2 findings from research}
• GA features mapped: {count} | Coming-soon features surfaced: {count}
• ⚠️ {any hot context flag, or "No urgent flags"}
```

## Edge cases

- **No Glean results for customer**: flag in summary, proceed with generic Spark angles,
  ask user to verify customer name spelling or try `--domain` flag.
- **No upcoming calendar event**: omit attendee cards, set session date to "TBD — check calendar".
- **#releases channel returns no Spark content in 60 days**: extend search to 90 days.
  If still empty, note in the playbook that feature inventory was unavailable and use the
  static GA feature list from `context/pb-aise-reference-guide.md`.
- **Logo detection fails**: silent fallback to random — never surface the error to the user
  in the final output (only in the research summary line).
- **Customer domain ambiguous**: use `--domain` flag and ask user once if not provided and
  inference fails.

## Example invocations

```
/spark-demo-prep Snowflake
/spark-demo-prep Zendesk --scheme orange
/spark-demo-prep "Spotify AB" --domain spotify.com
/spark-demo-prep Amplitude --scheme teal
```
