---
name: assistant-improvement
description: Analyze the previous skill run in this conversation for issues, errors, or workarounds — then output a single, copyable coding-agent prompt that names the exact plugin, files, and fixes needed. No tools, no writes — output only.
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

## Step 2 — Identify failure modes

Look for the following signals in the skill run:

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

List each failure mode with:
- **What happened** (quote or paraphrase from the conversation)
- **What should have happened** (infer from context or the command's stated purpose)

---

## Step 3 — Map each issue to source files

For each issue, identify the file(s) most likely responsible. Use this structure:

```
Plugin root: plugins/aise-leadership/
├── skills/<command-name>/SKILL.md       ← entry point / high-level steps
├── agents/<agent-name>.md               ← procedure detail, tool strategy, output spec
├── context/notion-schema.md             ← DB schema, field formats, ownership rules
├── context/project-instructions.md      ← ground rules, search strategy, ground truth
├── context/pb-aise-reference-guide.md   ← session types, program structure
└── context/communication-style-guide.md ← tone / format rules
```

Match each issue to the right layer:
- **Wrong step sequence / missing step** → `skills/<name>/SKILL.md`
- **Wrong tool strategy, wrong search, wrong output format** → `agents/<name>.md`
- **Wrong field, wrong DB, wrong ownership rule** → `context/notion-schema.md`
- **Wrong assumption about the workflow or session type** → `context/project-instructions.md` or `context/pb-aise-reference-guide.md`
- **Tone / format regression** → `context/communication-style-guide.md`

If the agent file for the failing skill doesn't exist yet (i.e. the skill has no dedicated agent and runs inline), note that.

---

## Step 4 — Draft the output prompt

Format the output as a single, self-contained markdown block the user can copy and paste directly into a new coding session.

The prompt must give the coding agent:
1. **Which plugin** and **which files to edit** (exact relative paths from the plugin root)
2. **What went wrong** in each issue (brief, precise)
3. **What the fix should be** (concrete instruction — not "improve X", but "add step N after step M that does Y")
4. **Enough context** for the coding agent to act without reading the full conversation

**Output format:**

````
# Fix Prompt — /[command-name] — [YYYY-MM-DD]

**Plugin:** `plugins/aise-leadership`

## Issues found in the previous run

### Issue 1: [short label]
**File:** `skills/<name>/SKILL.md` (or `agents/<name>.md`, etc.)
**What happened:** [1–2 sentences from the run]
**Fix:** [specific, actionable instruction — quote or add the exact text if you can]

### Issue 2: [short label]
**File:** `...`
**What happened:** ...
**Fix:** ...

[repeat for each issue]

## Context for the coding agent
[Any excerpts, field names, agent names, or background that would otherwise require the coding agent to re-read the whole conversation. Keep it concise — signal only.]
````

---

## Step 5 — Deliver

Output the prompt block in chat, preceded by a one-line summary:

> "Found N issue(s) in the `/[command]` run. Here's the fix prompt — copy it and send to your coding agent:"

Then the prompt block.

Do not apply any fixes yourself. Do not write any files. Output only.
