---
name: notion-ask
description: Answer questions about how the 6 Customer Tracker databases work — structure, interconnections, what to fill manually, and what is auto-calculated. Does live Notion checks when the question involves a specific customer or needs real-value verification.
---

Answer this question about the Customer Tracker: $ARGUMENTS

Read the procedure in `agents/notion-ask.md` and execute it inline as the main assistant — do not try to spawn it as a subagent (custom agents in this plugin are procedure documents, not registered subagent types).

If `$ARGUMENTS` is empty, output a short welcome message listing the kinds of questions this command answers (see Step 0 of the agent procedure), then stop.
