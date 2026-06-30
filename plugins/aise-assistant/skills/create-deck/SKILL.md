---
name: create-deck
description: >
  Generate a customer-facing HTML presentation deck for any meeting type. Pulls context
  from Notion, Glean, and Gmail, plans slide structure by meeting type, and produces a
  styled single-file deck using the Productboard brand template. Invoke with
  /create-deck [customer] [meeting type].
---

Generate a presentation deck for the customer and meeting type named in the user's message.

## Args

- `customer` (required) — customer name used as the key for all research queries and in the deck title.
- `meeting-type` (required) — one of: `kickoff`, `qbr`, `strategy`, `product-demo`, `onboarding`, `checkin`.
  Infer from context if not stated (e.g. "make a kickoff deck for Acme" → kickoff).
- `topics` (optional) — specific agenda items to cover. If not provided, infer from context.
- `--output <path>` (optional) — output directory. Default: `~/Desktop/aise-assistant/decks/`.

**Trigger phrases:** "create a deck for [customer]", "build slides for [meeting]",
"make a presentation for [topic]", "/create-deck [customer] [meeting type]"

---

## Phase 1 — Pull Context

Run all three in parallel:

### 1a. Glean — account context

```
glean_search:    "{customer} productboard"
gmail_search:    "{customer}"
meeting_lookup:  "{customer}"
```

Extract: program stage, use case interests, open asks, hot context (mergers, migrations, renewals),
key contacts (name + title), pain points and goals.

### 1b. Notion — customer tracker

**Resolve PLUGIN_DATA_DIR first:** use the Read tool on `~/.claude/aise-assistant.datadir`
— the file content is the absolute path. Use it to resolve `{PLUGIN_DATA_DIR}/about/identity.md`
and get the user's Notion UUID for owner-filtered queries.

Then:
1. `notion-search("{customer}")` → `notion-fetch` the Customer page and its linked Active Package.
2. `notion-search("{customer} session")` → fetch the 3 most recent Session pages.

Extract: current program stage, session themes, open tasks, outstanding commitments, known gaps.

### 1c. Gmail — recent thread context

Search Gmail for `{customer}` — extract subject lines and any outstanding asks from the last 3 threads.

### 1d. Synthesize into a working context block

```
Customer:        {name}
Program stage:   {stage}
Key contacts:    {names + titles}
Recent themes:   - {theme 1}
                 - {theme 2}
Open asks:       - {ask 1}
                 - {ask 2}
Hot context:     {urgent flags, or "none"}
```

If no Notion or Glean data is found: flag it inline, continue with whatever is available,
and mark those slides as "needs review" in the confirmation message.

---

## Phase 2 — Plan Deck Structure

Based on `meeting-type` and the context block, decide which slides to include and in what order.

**Required slides for every deck (non-negotiable):**
- 1 × `layout-title` — must be first
- 1 × `layout-agenda` — must be second
- 1 × `layout-next-steps` — must be last

**Slide count target:** 10–14 slides. Ask the user if they want more.

**Meeting type → suggested middle slides:**

| Meeting type | Middle slide sequence |
|---|---|
| kickoff | layout-split (intro/partnership context), layout-cards (platform overview), layout-cards (what we'll work through) |
| strategy / qbr | layout-divider + layout-cards per topic (2–3 topics), layout-split (gaps and asks) |
| product-demo | layout-split (customer context), layout-cards (demo capabilities), layout-split (what's next) |
| onboarding | layout-cards (program goals), layout-split (session arc), layout-cards (topic 1), layout-cards (topic 2) |
| checkin | layout-cards (topics 1–2), layout-kpi (if metrics are available) |

Add `layout-divider` slides as section breaks whenever there are 2+ thematic groups of content.
Add `layout-kpi` only when you have real metric data (ARR, sessions delivered, adoption %, etc.).

Produce a slide plan as a numbered list before generating HTML:

```
1.  [layout-title]      {Customer} — {Meeting Type Title}
2.  [layout-agenda]     Today's agenda
3.  [layout-divider]    01 — {Section name}
4.  [layout-cards]      {Slide heading}
...
N.  [layout-next-steps] Next steps
```

Show the plan inline and proceed. If the plan looks wrong for the context found, adjust it first.

---

## Phase 3 — Generate HTML

Read `skills/create-deck/deck-template.html` as the base. Use its CSS, JS, component structure,
and layout class names exactly. Do not rewrite or simplify the CSS.

Generate a single self-contained `.html` file:

**File name:** `{customer-slug}-{meeting-type}-{YYYY-MM-DD}.html`
- `{customer-slug}` = customer name lowercased, spaces and special characters → hyphens
- `{YYYY-MM-DD}` = today's date

**Replacements to make from the template:**
- `<title>` → `{Customer} · {Meeting Type}`
- Footer year → current year
- All `[PLACEHOLDER: ...]` text → real content
- `data-label` attributes on slides → actual slide titles
- Slide count in `data-label` / counter → total number of generated slides

**Logo block — protected, static markup.** Every slide must contain this exact SVG block,
verbatim. Never modify, simplify, or remove it. Find-and-replace for placeholder content
must skip any block matching `<svg class="logo"`:

```html
<svg class="logo" viewBox="0 0 28 28" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M18.6666 4.66666L28 14L18.6666 23.3334L9.33325 14L18.6666 4.66666Z" fill="#0071E1"/>
  <path d="M18.6667 4.66666L9.33335 14L0 4.66666H18.6667Z" fill="#FFC600"/>
  <path d="M9.33335 14L18.6667 23.3333H0L9.33335 14Z" fill="#F84136"/>
</svg>
```

### Slide copy rules

Write like a well-prepared SA, not a marketing deck. Sharp, direct, outcome-focused.

- **Eyebrow headings** — small all-caps labels above main headings give slide context.
  "PROGRAM STAGE · Q3" is better than repeating the customer name.
- **Card headings** — name the thing, not describe it. "What you raised" not "Customer feedback items".
- **Bullets** — 1 short sentence max. No semicolons chaining clauses. No trailing periods.
- **Discovery questions** — frame as prompts Klara will ask live, not rhetorical. End with "?"
- **Avoid:** "honestly", "straightforward", "leverage", "synergy", "touch base", "circle back",
  "deep dive", "move the needle", "bandwidth"
- **Status badges (use sparingly):** inline `<span class="badge badge-[color]">LABEL</span>` chips only.
  - `badge-red` = Urgent · `badge-yellow` = In Progress · `badge-purple` = BETA
- **Slide backgrounds:** `bg-dark` for Title, Agenda, and Section Dividers only.
  All content slides use `bg-light`.
- **Footer** on every slide: `© {year} Productboard, Inc. proprietary & confidential`

### Layout class specifications

Use these exact layout classes from the template. Do not invent new ones.

**`layout-title` (bg-dark):**
Structure: `.eyebrow` → `.main-title` → `.subtitle` → `.meta` (name · role, company · date)

**`layout-agenda` (bg-dark):**
Structure: `.slide-heading` ("Today") → `<ol class="agenda-list">` with 4–6 items

**`layout-divider` (bg-dark):**
Structure: `.section-number` (e.g. "01") → `.section-title` → `.section-sub` (optional tagline)

**`layout-cards` (bg-light):**
Structure: `.slide-eyebrow` → `.slide-heading` → `<div class="cards">` with 2–3 `.card` elements.
Each `.card`: `<div class="card-bar" style="background: {color}">` + `.card-inner` containing
`.card-title` and `<ul class="card-list">`.
Card bar colors: use `var(--blue)`, `var(--teal)`, `var(--yellow)`, `var(--purple)` to vary.

**`layout-split` (bg-light):**
Structure: `.slide-eyebrow` → `.slide-heading` → `.split-left` (bullets via `.split-list`) +
`.split-right` (`.question-box` elements or secondary content).

**`layout-next-steps` (bg-light):**
Structure: `.slide-eyebrow` → `.slide-heading` → `<ol class="steps-list">`.
Each `<li>`: `.step-content` containing `.step-action` + `.step-meta` with
`<span class="step-owner">` and `<span class="step-timing">`.

**`layout-kpi` (bg-light):**
Structure: `.slide-eyebrow` → `.slide-heading` → `<div class="kpi-grid">` with 2–4 `.kpi-card`
elements, each with `.kpi-value` (big number) + `.kpi-label` + `.kpi-sub` (context line).

---

## Phase 4 — Save and Confirm

1. Resolve output directory: `--output` flag if provided, else `~/Desktop/aise-assistant/decks/`.
   Create the directory if it does not exist (`mkdir -p`).
2. Write the file to `{output_dir}/{customer-slug}-{meeting-type}-{YYYY-MM-DD}.html`.
3. Confirm to the user:

```
✅ Deck saved: ~/Desktop/aise-assistant/decks/{filename}
   {slide-count} slides · {meeting-type} · {customer}
   Open in any browser to present. Arrow keys or swipe to navigate.
```

---

## Edge cases

- **Customer not found in Notion:** flag it, continue with Glean + Gmail context only.
- **No Glean results:** note it in the confirmation summary, fall back to meeting-type defaults for slide copy.
- **Ambiguous meeting type:** ask the user once before proceeding.
- **Date not available:** use today's date for the file name; set the title-slide date to "TBD — confirm before presenting".
- **No real metric data for layout-kpi:** substitute the kpi slide with a second layout-cards slide.

---

## Example invocations

```
/create-deck Acme kickoff
/create-deck Zendesk qbr
/create-deck "Spotify AB" strategy
create a deck for Snowflake onboarding
build slides for the Amplitude product demo
make a presentation for Figma check-in
```
