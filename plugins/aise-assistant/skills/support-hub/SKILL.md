---
name: support-hub
description: Search support.productboard.com (product/feature questions) or developer.productboard.com (API/integration questions) for official answers — returns sourced doc excerpts and links, flags gaps.
---

Search the official Productboard docs for an answer to: $ARGUMENTS

Read the procedure in `agents/support-hub.md` and execute it inline as the main assistant — do not try to spawn `support-hub` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types). The steps:

1. Route to the right source: `support.productboard.com` for product/feature questions, `developer.productboard.com` for API, webhook, or integration questions, or both for ambiguous queries.
2. Run `site:` searches for the query, varying phrasing if needed.
3. Fetch the top 2–3 matching articles or API docs and extract the relevant answer.
4. Flag any gaps where no official doc covers the question.
5. Return a structured block with a plain-language answer, source links, and any caveats.

Do NOT answer from memory or speculate about feature behavior. Source it or flag it.
