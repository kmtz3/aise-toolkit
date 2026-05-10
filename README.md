# AISE Toolkit

Personal Claude Code marketplace bundling the Productboard AISE plugin suite.

## Plugins

| Plugin | Description |
|---|---|
| [aise-assistant](plugins/aise-assistant/) | End-to-end customer onboarding co-pilot — prep, summarize, follow up, plan, Notion sync |
| [aise-leadership](plugins/aise-leadership/) | Portfolio visibility and account health — reports, notion-check, notion-sync, sf-backfill |

## Installation

Add this marketplace in Claude Code / Cowork:

```
/plugin marketplace add kmtz3/aise-toolkit
```

Then install individual plugins:

```
/plugin install aise-assistant@aise-toolkit
/plugin install aise-leadership@aise-toolkit
```

After installing, run `/aise-assistant:assistant-setup` (or `/aise-leadership:assistant-setup`) to personalise your install.

## Development

Open this directory as your project root. The `.claude/` folder contains dev-only commands (not shipped in the plugins):

| Command | Purpose |
|---|---|
| `/commit` | Version-bump, context sync, CHANGELOG update, commit + push |
| `/update-docs` | Sync all documentation to current state |
| `/port-to-leadership <skill>` | Copy a skill from aise-assistant into aise-leadership |

**context/ is canonical in `plugins/aise-assistant/context/`.** The `/commit` command syncs it to aise-leadership automatically.

## Maintainer

Klara Martinez · Productboard AI Success Engineering
