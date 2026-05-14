---
name: assistant-improvement
description: Analyze the previous skill run in this conversation for issues, errors, workarounds, AND user preferences about how the flow should go — then output a single, copyable coding-agent prompt that names the exact plugin, files, and fixes needed. No tools, no writes — output only.
---

The user has just finished a skill run that had problems and wants a fix prompt they can send to a coding agent.

Work entirely from the conversation history in this session — no external tool calls needed.

---

## Step 1 — Identify the skill run

Scan backwards through the conversation to find the most recent slash command invocation (e.g. `/session-prep`, `/session-debrief`, `/customer-setup`, etc.). Note:
- The command name and any arguments passed
- When in the conversation it started
- Whether it completed normally or stalled

---

## Step 2 — Identify failure modes AND preference signals

Look for two categories of signal in the skill run.

### 2a — Failures, errors, workarounds

| Signal | What it indicates |
|---|---|
| Error messages or stack traces | Hard failure in a specific step |
| Agent asked for info the user had to supply manually | Context retrieval gap — wrong search strategy, missing source |
| Agent circled back or re-tried the same step | Ambiguous or missing instruction in skill/agent file |
| Agent produced wrong output format / wrong section structure | Template or output spec mismatch |
| Agent skipped a required step | Missing step in procedure, wrong conditional logic |
| User had to correct the agent mid-run | Agent made a wrong assumption — needs an explicit rule |
| Tool call failed silently and agent didn't recover | Missing fallback in the procedure |
| Agent wrote to the wrong Notion field / DB | Schema misread — points at `context/notion-schema.md` or the agent file |

### 2b — Preference signals (nuances about *how* the flow should go)

These are quieter than failures — the run may have completed fine, but the user expressed a preference about sequencing, depth, format, tool routing, or interaction style that isn't yet encoded in the skill/agent.

| Signal | What it indicates |
|---|---|
| User asked to reorder steps ("do X before Y") | Sequencing preference — bake into the procedure |
| User asked to skip, shorten, or expand a step | Depth / scope preference — adjust default behaviour or add a flag |
| User asked for a different output shape (grouping, headings, level of detail) | Output spec preference — update agent's output section |
| User specified a tool/source preference ("check Gong first, not Glean") | Tool-routing preference — update the agent's search strategy |
| User asked to stop confirming (or start confirming) a class of action | Interaction-style preference — update confirmation gates |
| User validated a non-obvious choice ("yes, bundling these was right") | **Positive signal** — harden the choice into the procedure so it's not re-decided next time |
| User reframed the goal of the skill mid-run | Skill-purpose drift — may need a description/scope update |

### 2c — List each signal

For each signal from 2a or 2b, capture:
- **What happened** (quote or paraphrase from the conversation)
- **What should have happened, or what the user prefers** (infer from context or the command's stated purpose)
- **Category**: `failure` or `preference`

---

## Step 3 — Map each signal to source files

For each signal (failure or preference), identify the file(s) most likely responsible. Use this structure:

```
Plugin root: plugins/aise-leadership/
├── skills/<command-name>/SKILL.md       ← entry point / high-level steps
├── agents/<agent-name>.md               ← procedure detail, tool strategy, output spec
├── context/notion-schema.md             ← DB schema, field formats, ownership rules
├── context/project-instructions.md      ← ground rules, search strategy, ground truth
├── context/pb-aise-reference-guide.md   ← session types, program structure
└── context/communication-style-guide.md ← tone / format rules
```

Match each signal to the right layer:
- **Wrong step sequence / missing step / sequencing or scope preference** → `skills/<name>/SKILL.md`
- **Wrong tool strategy, wrong search, wrong output format / tool-routing or output-shape preference** → `agents/<name>.md`
- **Wrong field, wrong DB, wrong ownership rule** → `context/notion-schema.md`
- **Wrong assumption about the workflow or session type** → `context/project-instructions.md` or `context/pb-aise-reference-guide.md`
- **Tone / format regression or voice preference** → `context/communication-style-guide.md` (or the user's `AISE Leadership Preferences` Notion page if it's personal voice)
- **Interaction-style preference (confirmation gates, default verbosity)** → typically the agent file, sometimes `CLAUDE.md` if it's cross-skill

If the agent file for the failing skill doesn't exist yet (i.e. the skill has no dedicated agent and runs inline), note that.

---

## Step 4 — Draft the output prompt

Format the output as a single, self-contained markdown block the user can copy and paste directly into a new coding session.

The prompt must give the coding agent:
1. **Which plugin** and **which files to edit** (exact relative paths from the plugin root)
2. **What went wrong, or what the user prefers** in each signal (brief, precise — flag whether it's a failure or a preference)
3. **What the fix should be** (concrete instruction — not "improve X", but "add step N after step M that does Y", or "change default in agent to Z")
4. **Enough context** for the coding agent to act without reading the full conversation

Group signals into two sections — **Failures** and **Preferences to encode** — so the coding agent can prioritize. If a category is empty, omit its section.

**Output format:**

````
# Improvement Prompt — /[command-name] — [YYYY-MM-DD]

**Plugin:** `plugins/aise-leadership`

## Failures found in the previous run

### Failure 1: [short label]
**File:** `skills/<name>/SKILL.md` (or `agents/<name>.md`, etc.)
**What happened:** [1–2 sentences from the run]
**Fix:** [specific, actionable instruction — quote or add the exact text if you can]

[repeat for each failure]

## Preferences to encode

### Preference 1: [short label]
**File:** `agents/<name>.md` (or wherever it belongs)
**What the user prefers:** [1–2 sentences — sequencing, depth, format, tool routing, interaction style, or a positive confirmation worth hardening]
**Change:** [specific, actionable instruction — e.g. "in the Discovery step, default to Gong before Glean", or "remove the per-task confirmation gate; confirm once at the batch level"]

[repeat for each preference]

## Context for the coding agent
[Any excerpts, field names, agent names, or background that would otherwise require the coding agent to re-read the whole conversation. Keep it concise — signal only.]
````

---

## Step 5 — Deliver

Output the prompt block in chat, preceded by a one-line summary:

> "Found N signal(s) in the `/[command]` run (X failure(s), Y preference(s)). Here's the improvement prompt — copy it and send to your coding agent:"

Then the prompt block.

Do not apply any fixes yourself. Do not write any files. Output only.
