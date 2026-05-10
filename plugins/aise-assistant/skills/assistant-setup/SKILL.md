---
name: assistant-setup
description: Onboard a new user (or re-onboard yourself) to this assistant. Resolves Notion identity, asks short HITL questions about voice + workspace preferences, optionally scrapes recent Gmail and Slack to draft your voice profile, and writes the about/ folder. Run on first install of the plugin or when handing the assistant off to a teammate.
---

Set up the assistant for the current user.

Read the procedure in `agents/assistant-onboarding.md` and execute it inline as the main assistant — do not try to spawn `assistant-onboarding` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types). The steps:

0. **Run the connection check first.** Before anything else, run `./scripts/setup-connections.sh --check` via `mcp__Control_your_Mac__osascript` (file and bash tools are sandboxed in Cowork and cannot reach the plugin directory). Surface the full output in chat. If the Salesforce CLI (`sf`) is missing, tell the user to install it (`npm install -g @salesforce/cli`, then `sf org login web`, then `claude mcp add salesforce -- npx -y @salesforce/mcp`). Do not skip this step.
1. **Resolve the persistent data directory.** Run the following via `mcp__Control_your_Mac__osascript` (Cowork) or the Bash tool (Claude Code CLI):
   ```bash
   PLUGIN_DATA_DIR=$(cat "$HOME/.claude/aise-assistant.datadir" 2>/dev/null)
   if [ -z "$PLUGIN_DATA_DIR" ]; then
     PLUGIN_DATA_DIR=$(ls -d "$HOME/.claude/plugins/data/aise-assistant"* 2>/dev/null | head -1)
     PLUGIN_DATA_DIR="${PLUGIN_DATA_DIR:-$HOME/.claude/plugins/data/aise-assistant}"
   fi
   echo "PLUGIN_DATA_DIR=$PLUGIN_DATA_DIR"
   ls "$PLUGIN_DATA_DIR/about/" 2>/dev/null || echo "(empty — fresh install)"
   ```
   Capture the printed `PLUGIN_DATA_DIR` value. Use it as the literal path for **all** file reads and writes in this session. **Never use `$CLAUDE_PLUGIN_DATA` for writing** — it resolves to a volatile temp path, not the persistent directory.
2. Detect the Notion connection and resolve the current user via `notion-get-users self` → auto-fills `identity.md` with the Notion user ID.
3. Ask HITL questions covering identity, voice, and workspace preferences in **one combined elicitation form** (call `read_me` with `modules: ["elicitation"]` first, then render a single card — no sequential question-by-question flow). Reserve `AskUserQuestion` only for a single ad-hoc clarification that arises after the form is submitted.
4. Optionally (`--scrape-voice` or when the user opts in via the form): read 5–10 recent sent emails from Gmail and 5–10 recent Slack messages, distinguishing **internal** vs **client-facing** tone, and draft a `voice.md` from the user's actual writing style. For Slack, read the `slack_search_public_and_private` tool description to find the `Current logged in user's user_id is <ID>` line — use `from:<@USER_ID>` as the query (not the email address).
5. **Write files to `<PLUGIN_DATA_DIR>/about/`** (the literal path from step 1) — `identity.md`, `voice.md`, `workspace.md`. Create the directory if it doesn't exist. Present `computer://` links to each written file so the user can open them.
6. Confirm setup in chat. These files live at `<PLUGIN_DATA_DIR>/about/` and persist across plugin updates. They are **deleted on uninstall** and are machine-specific — re-run `/assistant-setup` after a full reinstall or on a new machine.

**Modes (mutually exclusive):**
- **Default** (no flag) — fill gaps only. Preserves existing values in `<PLUGIN_DATA_DIR>/about/`; asks only about fields still set to `<TBD>`. Safe to re-run whenever.
- **`--update`** — drift check. Re-resolves Notion identity (catches user ID changes, role changes), then walks each section asking the user to confirm or update values that may have drifted. Useful after a role change, team move, or workflow shift.
- **`--reset`** — wipe everything. Deletes the three files from `<PLUGIN_DATA_DIR>/about/` and runs the full onboarding flow from scratch. Use when handing the assistant off to a teammate, or starting clean after a major shift.

**Modifier flag (combinable with any mode):**
- **`--scrape-voice`** — skip the opt-in question and go straight to Gmail+Slack scraping for the voice draft. Distinguishes internal vs client-facing tone.

**Don't ask the user for values that are retrievable.** Notion user ID, primary email, time zone — pull from the connected account, don't ask. Reserve HITL questions for genuine preferences (sign-offs, em-dash rule, Slack register, etc.).

Save scraped raw email/Slack samples to a temp file the user can reference if they want to tweak the inferred voice.md by hand.

## Cowork: reading about/ files

In Cowork, `Read` is sandboxed to session outputs. Use `mcp__Control_your_Mac__osascript` to read files. Always derive the path from the pointer file — **not** from `$CLAUDE_PLUGIN_DATA` which is a volatile runtime var.

**Pattern:**
```applescript
do shell script "PLUGIN_DATA_DIR=$(cat \"$HOME/.claude/aise-assistant.datadir\" 2>/dev/null || ls -d \"$HOME/.claude/plugins/data/aise-assistant\"* 2>/dev/null | head -1); cat \"$PLUGIN_DATA_DIR/about/identity.md\" 2>/dev/null || echo NOT_FOUND"
```

Run one call per file (`identity.md`, `voice.md`, `workspace.md`). If a file returns `NOT_FOUND`, the user hasn't run `/assistant-setup` yet — prompt them to do so before continuing.

## Cowork: writing about/ files

In Cowork, `Write`, `Edit`, and `mcp__workspace__bash` are sandboxed. Use `mcp__Control_your_Mac__osascript` to write to `<PLUGIN_DATA_DIR>/about/`. Always derive the path from the pointer file — **not** from `$CLAUDE_PLUGIN_DATA`.

**Pattern: Python script via heredoc**

1. **Destination path** — read from the pointer file inside the Python script:
   ```python
   import os, pathlib, glob, subprocess
   result = subprocess.run(['sh', '-c', 'cat "$HOME/.claude/aise-assistant.datadir" 2>/dev/null'],
                          capture_output=True, text=True)
   data_dir = result.stdout.strip()
   if not data_dir:
       matches = glob.glob(os.path.expanduser('~/.claude/plugins/data/aise-assistant*'))
       data_dir = matches[0] if matches else os.path.expanduser('~/.claude/plugins/data/aise-assistant')
   about_dir = pathlib.Path(data_dir) / 'about'
   about_dir.mkdir(parents=True, exist_ok=True)
   ```

2. **Write all three files in one osascript call.** The pattern:
   - `do shell script` wraps a bash heredoc using `<< 'PYEOF'` (single-quoted delimiter — passes content through literally with no substitution)
   - Python creates the directory then writes each file using `.write_text(content, encoding='utf-8')`
   - File content goes in Python triple-single-quoted strings, which handle apostrophes and backticks without restriction

3. **Critical constraint:** The outer `do shell script` command is an AppleScript string delimited by double quotes. Any double-quote character anywhere inside the heredoc content will terminate this outer string early and cause a syntax error. Keep all file content free of double-quote characters. If a double-quote is unavoidable, use the Python hex escape `\x22` in the Python source.

4. **Verify after writing.** In Cowork, `Read` is sandboxed — use osascript `cat` calls (same pattern as the read section above) to confirm content landed correctly before reporting success.
