---
name: assistant-remember
description: Capture a correction, new rule, or changed fact into context files and memory
---

the user wants to persist.

Read the procedure in `agents/context-keeper.md` and execute it inline as the main assistant — do not try to spawn `context-keeper` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types). The steps:

1. Classify the input (style rule / workflow rule / scorecard change / customer fact / Notion schema / user preference).
2. Find the right context file in `context/` — read it, check for existing related content.
3. Draft a diff and show it in chat with the proposed memory entry alongside.
4. Wait for the user's approval (unless she's previously authorized auto-write for this type).
5. Write to **both** the project context file and cross-conversation memory (`~/.claude/projects/<this-project-slug>/memory/` — Claude Code derives the slug from this project's absolute path, same as `context-keeper.md`).
6. Confirm what was written.

Note: the `context-keeper` should also trigger automatically whenever the user gives a correction in normal conversation. `/assistant-remember` is the explicit override.
