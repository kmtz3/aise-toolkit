---
name: draft-diagram
description: Build a customer-facing integration-flow or architecture diagram in a polished grid/card visual style (phases/systems as rows, time periods/stages as columns, color-coded activity cards with pill tags — never mermaid-style arrows). Primary output is a Figma design file built via the Plugin API; fallback is an editable SVG; secondary fallback is HTML. Saves artifacts to ~/Desktop/aise-assistant/diagrams/{customer}/ and attaches to the relevant Notion session page.
---

Build a diagram for.

Read the procedure in `agents/diagram-builder.md` and execute it inline as the main assistant — do not try to spawn `diagram-builder` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types).

**Diagram types:** `integration-flow` · `architecture`

The procedure:
1. Pull customer context from Notion and Glean to seed diagram content (system names, integration details, stakeholders).
2. Plan and confirm the diagram structure if the description is ambiguous (one question max).
3. Detect Figma connectivity via `mcp__claude_ai_Figma__whoami`, then generate using the highest available output path:
   - **Figma design file** (primary — if Figma connected): `create_new_file` (editorType: "design") then `use_figma` with Plugin API JS to build the grid/card layout; attach Figma URL to Notion
   - **SVG** (fallback): Python generator script → editable SVG with grid/card layout → upload to Google Drive → attach Drive link to Notion
   - **HTML** (secondary fallback): same grid/card layout as CSS Grid — local only
4. Save artifacts to `~/Desktop/aise-assistant/diagrams/<customer-slug>/` at project root.
5. Attach the diagram to the relevant Notion session page (searches for the most recent session if not specified).

**Examples:**
- `/draft-diagram Eltropy integration-flow Zendesk and Gong to Productboard`
- `/draft-diagram Acme architecture PB workspace structure — teamspaces, hierarchy, and Jira integration`
