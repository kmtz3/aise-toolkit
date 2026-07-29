---
name: session-facilitation
description: >
  Generate a self-contained interactive HTML facilitation guide for a customer session — live
  timer, sidebar nav, decision capture panels (one per KDD for A-sessions), open items check-in,
  attendee presence, watch-fors, and action items. Saves to ~/Desktop/aise-assistant/facilitation/
  and adds a file-path callout to the Notion Session page. For A-sessions this runs automatically
  after KDD sub-page creation in /session-prep. Also standalone via /session-facilitation.
---

Generate an interactive HTML facilitation guide for the session named in the user's message.

## Triggers

Invoke when the user says any of:
- `/session-facilitation <customer> [session-id]`
- "facilitation guide for [customer]"
- "make me a facilitation html for [session]"
- "facilitation artifact for [customer]"
- "run sheet for [customer]"

Also invoked automatically by `session-prepper` (step 6.5) for every `🏗️ Architecting` session,
and offered (not auto-run) for `🔎 Discovery` and `👟 Kick off` sessions.

## Inputs

- `customer` (required) — customer name used for Notion lookup and file naming.
- `session-id` (optional) — e.g. `A5`. If omitted, use the next upcoming session for this customer.
- `--output <path>` (optional) — output directory. Default: `~/Desktop/aise-assistant/facilitation/`.

---

## Step 1 — Resolve the session

Pull all context needed before generating HTML. Run in parallel where possible.

**a) Session identity** — from Notion Sessions DB or Calendar:
- Session ID (e.g. `A5`), Name, Type, Date, Duration (h), Call Status.
- For A-sessions: the KDD template match (from `templates/session-kdds/00-index.md`).

**b) Open items** — from the prior session page (last delivered session for this customer):
- Extract the action items table from the Notion session body (`## Action items` block or equivalent).
- Include: Item text, Owner, current status if captured.

**c) Attendees** — from the Calendar event for this session or Notion session page.
- Include: Name, Role, any facilitation notes (e.g. "decisive — will push fast", "absent from last session").

**d) Session outcomes** — from the prep brief (`📋 Prep` toggle on the Session page) or session KDD template:
- The 3–5 "by the end of this session we will have" outcome bullets.

**e) Watch-fors + scorecard criteria** — from:
- `context/score-cards.md` — the rows matching this session type.
- `context/pb-aise-reference-guide.md` — "watch-fors" section for this session flavor.
- The `📋 Prep` toggle on the Session page (Risks/watch-outs section).

**f) KDD decisions list (A-sessions only)** — read the matching KDD template from
`templates/session-kdds/{template}.md`. Extract:
- Each KDD (D-number, question, why-it-matters, options/frameworks, decision capture fields).
- The next D-number continues from the customer's existing decisions register (read from Active Package
  or prior sessions).

**g) Agenda** — derive from:
- KDD working doc / KDD sub-page if already created.
- Prep brief if available.
- Fallback: standard agenda for the session type from `context/pb-aise-reference-guide.md`.

**h) Pre-read documents** — check for any documents the user or customer has shared that should be
referenced live during the session:
- User-uploaded files in the current conversation (governance docs, agenda proposals, survey results, org charts).
- Links inside the `📋 Prep` toggle on the Session page (look for "📎" markers or explicit pre-read callouts).
- Gmail/Drive search for customer-sent attachments in the 7 days before the session.

For each pre-read document found: read its contents, extract key principles/rules/agenda items,
and plan a dedicated **reference panel** in the HTML (sidebar link, not in main agenda sequence).
See Panel structure → Pre-read reference panels below.

---

## Step 2 — Generate the HTML file

Produce a single self-contained `.html` file. No external dependencies except the font stack.

### File name

```
{customer-slug}-{session-id-or-type}-facilitation-{YYYY-MM-DD}.html
```
- `{customer-slug}` = customer name lowercased, spaces/special chars → hyphens.
- `{session-id-or-type}` = session ID if known (e.g. `a5`), else session type slug (e.g. `discovery`).
- `{YYYY-MM-DD}` = session date.

### Design rules (mandatory — do not deviate)

**Colors** (inline CSS variables at `:root`):
```css
--purple: #534AB7;
--purple-light: #EEEDFE;
--purple-mid: #7F77DD;
--teal: #0F6E56;
--teal-light: #E1F5EE;
--teal-mid: #1D9E75;
--amber: #BA7517;
--amber-light: #FAEEDA;
--coral: #993C1D;
--coral-light: #FAECE7;
--gray-100: #F1EFE8;
--gray-300: #D3D1C7;
--gray-500: #888780;
--gray-700: #444441;
--gray-900: #2C2C2A;
--white: #ffffff;
--text: #2C2C2A;
--text-muted: #5F5E5A;
--border: #D3D1C7;
--radius: 10px;
```

**Layout**: sticky header (57px) + two-column body (`display: flex; height: calc(100vh - 57px); overflow: hidden`):
- Left: sidebar nav (`width: 230px; min-width: 230px; overflow-y: auto`).
- Right: main content area (`flex: 1; overflow-y: auto; padding: 24px 28px`).

**Header** — purple background (`#534AB7`), white text:
- Left: `<h1>` with `{Customer} × Productboard — {Session Name}`, subtitle with date + facilitator name,
  3px progress bar (teal fill, updates via JS as user navigates panels).
- Right: "Session N of M" badge, timer display (click to start/pause, shows `00:00`), Reset button.
- Timer turns teal when running; turns amber at `{session_minutes - 5}` minutes elapsed.

**Sidebar nav items** — one per agenda panel (numbered), then a divider, then Watch-fors and Action Items links:
- Default state: gray circle number, 12.5px text, nav-time below.
- Active state: `border-left: 3px solid var(--purple)`, purple circle, `background: var(--purple-light)`.
- Done state: teal circle (user clicks to mark done — optional JS toggle).
- Clicking any nav item scrolls `.main` to top and activates the target panel.

**Panels** — `display: none` by default, `display: block` when `.active`. Use `animation: fadeIn 0.2s ease`.
- Each panel has: `.panel-header` (title 22px + subtitle 13px muted), card(s), nav buttons (Back / Next).
- Cards: `background: white; border-radius: 10px; border: 1px solid var(--border); padding: 18px 20px; margin-bottom: 16px`.
- Card title: 13px, 600 weight, uppercase, letter-spacing 0.5px, muted.

**Tables** (options, capture, open items):
- Option tables: th `background: var(--gray-100)`, td with hover state, first-col labels bold purple for option labels (A/B/C).
- Capture tables: input/select cells with `border: none; padding: 8px; font-family: inherit; outline: none`. Focus state: `background: #FAFAFA`.
- Row label cells: plain text, medium weight.

**Info/warning boxes**:
- Info (teal): `background: var(--teal-light); border: 1px solid #9FE1CB; color: #085041; border-radius: 7px; padding: 12px 14px`.
- Warning (amber): `background: var(--amber-light); border: 1px solid #FAC775; color: #633806`.

**Textareas**: `width: 100%; border: 1px solid var(--border); border-radius: 6px; padding: 10px; font-size: 13.5px; font-family: inherit; resize: vertical; min-height: 80px`. Focus: `border-color: var(--purple-mid); box-shadow: 0 0 0 2px rgba(83,74,183,0.1)`.

### Panel structure (in order)

#### Panel 0 — Framing & outcomes
Always first. Contains:
1. **Outcome card** — checklist of `<input type="checkbox">` + outcome text (3–5 items from Step 1d).
2. **Opening questions card** — numbered list of 3–5 questions to ask at session start (grounded in context pulled in Step 1, not generic).
3. **Attendees card** — `border-left: 3px solid var(--purple)`, table with columns: Name / Role / Facilitation note / Present checkbox. Populate from Step 1c.

#### Panel 1 — Open items check-in
Always second. Contains:
1. **Open items card** — list of `<div class="open-item">` rows, each with:
   - Checkbox, Item label (bold owner name inline), status badge.
   - Status badge colors: `badge-done` (teal), `badge-outstanding` (amber), `badge-unknown` (gray).
   - Populate from Step 1b. If no prior action items found, show placeholder row.
2. **Notes card** — textarea for check-in updates.

#### Panels 2 through N — One panel per KDD (A-sessions only)

For each KDD from the template (Step 1f), generate a panel with:

1. **Options/framing card**:
   - `<div class="decision-header">`: `<span class="decision-badge">D{N}</span>` + `"React to this, then decide"` label.
   - `<div class="decision-question">`: the KDD question text.
   - `<div class="decision-why">`: the "why this matters" explanation (muted, 13px).
   - Any info boxes for current state (e.g. "✅ TM is live — use as reference").
   - Options table (columns: Option / Approach / Trade-off). Use KDD template's framework options.
     For options that are recommended, add a note in the trade-off cell.

2. **Live capture card** (`border-left: 3px solid var(--purple)`):
   - Card title: `Decision capture — D{N}`.
   - Capture table: rows = entities being decided (e.g. one row per audience, one row per portfolio).
     Columns = decision fields for this KDD (e.g. "In scope now?" select, "Format" input, "Owner" input).
     Use `<select>` for bounded choices, `<input type="text">` for open fields.
   - Notes textarea labeled "Additional notes".

For non-A-sessions: replace decision panels with agenda topic panels — a card per agenda item with:
- Topic description, key questions to drive, notes textarea for live capture.

#### Panel N+1 — Live build (for sessions with hands-on workspace work)

Include this panel when the session template includes hands-on configuration (Roadmaps, Jira setup, Lifecycle):
1. **Build sequence card** — numbered watchfor-style steps for what to build.
2. **Warning box** (amber) — data readiness condition (e.g. "If backlog not populated, focus on decisions not live build").
3. **What was built card** — checklist of expected configuration outputs with checkboxes.
4. **Build notes card** — textarea.

Omit this panel if the session template doesn't include hands-on work (Foundations, Feedback, SSO).

#### Panel N+2 — Synthesis & next steps
Always second-to-last (before Watch-fors and Action Items in the sidebar — those are modal-style panels).

1. **Decisions register card** — table:
   - Columns: D# (purple bold) / Decision / Outcome (text input) / Locked? (checkbox).
   - Pre-populate with this session's D-numbers and decision labels.
2. **Parking lot card** — pre-populated from session template's parking lot items + textarea for new items.
3. **Next session card** — two inputs: Date + Focus confirmed? (select Yes/Adjusted/TBD).

#### Pre-read reference panels (sidebar link — one per pre-read document)

Generated only when Step 1h found one or more pre-read documents. Each panel is a sidebar link (not in the numbered agenda sequence) and follows this structure:

1. **Source info box** (teal) — doc title, author, link, and a note: "Review and react live during [relevant D# panel]."
2. **Skimmable summary table** — columns: `#` / `Principle or rule` / `One-line summary`. Max 10 rows. Pull the key rules/items from the document, distil each to a single clear sentence.
3. **Open questions card** (amber accent) — 3–7 questions surfaced by reading the doc that need to be resolved live. Format: `<div class="watchfor-item"><span class="watchfor-icon">❓</span><span>...</span></div>`.
4. **Live capture card** (teal accent) — capture table with rows for the governance/agenda decisions that need to come out of the session. Use `<select>` for bounded choices (e.g. "Adopted as-is / With amendments / Not yet"), `<input type="text">` for open fields (e.g. named owner, open amendments). Include a notes textarea.

**Sidebar link icon:** `📋`
**Sidebar link label:** short doc name (e.g. "Governance Principles", "Customer Agenda")
**Panel header:** doc title + author attribution
**Panel subtitle:** "Pre-read — quick reference for [session / D# context]"

This is the confirmed good format from the IBO A12 run — do not deviate.

#### Watch-fors panel (sidebar link — not in main sequence)

Accessible anytime from sidebar. Contains:
1. **Watch-fors card** (`border-left: 3px solid var(--amber)`) — facilitation watch-fors from Step 1e.
   Format: `<div class="watchfor-item"><span class="watchfor-icon">⚡</span><span>...</span></div>`.
   Pull real, session-specific watch-fors — not generic bullets.
2. **Scorecard card** — outcome checkboxes from session scorecard (Step 1e). Include a "bonus" item (gray, 60% opacity) for optional stretch objectives.
3. **Post-session actions card** — fixed bullets (mark Delivered in Notion, draft follow-up email, fill KDD sub-page, confirm next session date).

#### Action items panel (sidebar link — last)

Always accessible from sidebar. Contains:
1. **Action items table** — columns: # / Owner (text input) / Action (text input) / Due (text input).
   Pre-populate 5 empty rows. JS `addRow()` function appends additional rows.
2. **Add row button** — dashed border, full width.
3. **Print/export button** — calls `window.print()`. Style as `btn btn-teal`.

### JavaScript (minimal, inline at end of `<body>`)

```javascript
// Panel navigation
let currentPanel = 0;
const totalPanels = {N};  // total sidebar-nav panels (agenda panels only, not watch-fors/actions)

function goTo(idx) {
  document.querySelectorAll('.panel').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
  document.getElementById('panel-' + idx).classList.add('active');
  document.getElementById('nav-' + idx).classList.add('active');
  currentPanel = idx;
  document.querySelector('.main').scrollTop = 0;
  const pct = Math.max(12.5, Math.round((idx / totalPanels) * 100));
  document.getElementById('progressFill').style.width = pct + '%';
}

// Timer
let timerInterval = null, timerSeconds = 0, timerRunning = false;
const timerDisplay = document.getElementById('timerDisplay');
const warningMinutes = {session_length_minutes - 5};  // from Step 1a session duration

timerDisplay.addEventListener('click', function() {
  if (timerRunning) {
    clearInterval(timerInterval); timerRunning = false;
    timerDisplay.classList.remove('running');
  } else {
    timerInterval = setInterval(tick, 1000); timerRunning = true;
    timerDisplay.classList.add('running');
  }
});

function tick() {
  timerSeconds++;
  const m = Math.floor(timerSeconds / 60), s = timerSeconds % 60;
  timerDisplay.textContent = String(m).padStart(2,'0') + ':' + String(s).padStart(2,'0');
  if (timerSeconds >= warningMinutes * 60) timerDisplay.classList.add('warning');
}

function resetTimer() {
  clearInterval(timerInterval); timerRunning = false; timerSeconds = 0;
  timerDisplay.textContent = '00:00';
  timerDisplay.classList.remove('running', 'warning');
}

// Add action item row
let rowCount = 5;
function addRow() {
  rowCount++;
  const tbody = document.getElementById('actionTable');
  const tr = document.createElement('tr');
  tr.innerHTML = `<td style="padding:8px;border:1px solid var(--border);text-align:center;color:var(--text-muted);font-size:12px;">${rowCount}</td><td><input type="text" placeholder="Owner…"></td><td><input type="text" placeholder="Action…"></td><td><input type="text" placeholder="Due…"></td>`;
  tbody.appendChild(tr);
}
```

### Print styles (append at end of `<style>`)

```css
@media print {
  .header, .sidebar { display: none; }
  .layout { height: auto; }
  .main { overflow: visible; }
  .panel { display: block !important; page-break-after: always; }
}
```

---

## Step 3 — Save the file

**Context detection (mandatory — do this before writing):**

- **Cowork context** (detected by: `$CLAUDE_PLUGIN_DATA` is set and `$CLAUDE_PLUGIN_DATA/about/identity.md` exists):
  - Use the `Write` tool to write the file to the Cowork outputs folder. Do **not** use Bash for file creation — `~` in the Linux sandbox resolves to the VM home, not the Mac home.
  - After writing, call `mcp__cowork__present_files` to surface the file to the user.
  - The Desktop path is inaccessible from the Cowork sandbox. Do not attempt `mkdir ~/Desktop/...`.

- **CLI (Claude Code) context** (all other cases):
  ```bash
  mkdir -p ~/Desktop/aise-assistant/facilitation/
  ```
  Write the file to: `~/Desktop/aise-assistant/facilitation/{filename}`.
  Use the `Write` tool with the absolute path (expand `~` to the actual home directory) or Bash.

---

## Step 4 — Add reference to Notion Session page

**This step is mandatory — do not skip even if the Notion session page ID was not pre-resolved.**

After the file is saved, add a single paragraph block to the Notion Session page body
(outside the `📋 Prep` toggle — append below all existing content):

- **CLI context:** `💻 **Facilitation guide:** \`~/Desktop/aise-assistant/facilitation/{filename}\` — open in browser before the call.`
- **Cowork context:** `💻 **Facilitation guide generated** — open \`{filename}\` from the Cowork outputs folder before the call.`

Use `notion-update-page` with `command: append_content`.  Do not modify the `📋 Prep` toggle or KDD sub-page.

If the Notion session page ID is not already in context, look it up from the Sessions DB (customer + date + type) before attempting the write.

If the Notion write fails, surface the failure explicitly in the Step 5 report — do not silently skip.
The file is still usable, but the failure must be visible.

---

## Step 5 — Report in chat

```
✅ Facilitation guide saved:
   {filename}
   {N} panels · {session-type} · {customer}
   Open in any browser. Timer in header — click to start/pause.
```

If Notion write succeeded: add `   📌 File path added to Notion session page.`
If Notion write failed: add `   ⚠️ Notion callout write failed — add manually to the session page.`

---

## Edge cases

- **Session not found in Notion:** generate from KDD template + Calendar context only. Flag missing data in the file (gray placeholder text in affected cells).
- **No prior session action items:** show empty Open Items panel with 3 placeholder rows and a note: "No action items found from prior session — add manually."
- **Non-A-session invoked directly:** generate a simplified facilitation guide with agenda topic panels instead of decision panels. Still include framing, open items, synthesis, watch-fors, action items.
- **KDD template mismatch:** flag in chat, fall back to a generic decision panel structure (D# / Question / Options / Capture). Don't block file generation.
- **`warningMinutes` unknown (session duration not set in Notion):** default to 85 minutes.
