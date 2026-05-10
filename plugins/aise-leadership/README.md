# aise-leadership

Portfolio visibility and account health co-pilot for Productboard AISE leadership.

Install this plugin if you're a **manager, Head of AISE, or VP CS** — not an individual AISE. For the individual AISE co-pilot (session prep, debrief, follow-ups), install [aise-assistant](https://github.com/kmtz3/aise-assistant) instead.

---

## What it does

- **`/report --aise`** — portfolio summary across all accounts owned by an AISE: attention queue (gaps, renewals, credits exhausted), per-account health table, velocity
- **`/report --customer`** — single-account snapshot: program health, credit burn trajectory, recent sessions, open items, risks, next step
- **`/notion-check`** — audit the Customer Tracker for ownership drift, missing packages, stale data
- **`/notion-sync --sf`** — sync Salesforce ARR and contract end dates into Active Packages
- **`/notion-ask`** — answer questions about how the 6 Customer Tracker databases work

---

## Install

1. Open **Claude Code (Cowork)** → Settings → Extensions → Add Plugin
2. Enter the GitHub repo: `kmtz3/aise-leadership`
3. Install and restart Cowork
4. Run `/aise-leadership:assistant-setup` to complete onboarding (Notion identity + preferences)

---

## First run

After install, run:

```
/aise-leadership:assistant-setup
```

This auto-resolves your Notion user ID and asks a short series of questions about your preferences. Takes about 2 minutes.

Then try:

```
/aise-leadership:report --aise me
```

---

## Shared knowledge base

The `context/` directory (schema, reference guide, style guide) is shared with [aise-assistant](https://github.com/kmtz3/aise-assistant) and synced via `git checkout`. Changes to the knowledge base happen in aise-assistant and are pulled here — never edit `context/` files directly in this repo.

---

## Commands

| Command | Purpose |
|---|---|
| `/report --aise [me \| <name>]` | Portfolio summary for an AISE |
| `/report --customer <name>` | Single-account snapshot |
| `/notion-check [--fix]` | Audit Customer Tracker for data drift |
| `/notion-sync --sf [--apply]` | Sync Salesforce ARR + end dates |
| `/notion-sync --renewals [--dry-run]` | Flag upcoming renewals |
| `/notion-ask <question>` | Q&A on Customer Tracker schema |
| `/assistant-setup` | Onboard / re-onboard |
| `/assistant-help` | Full command reference |

---

## License

MIT — Klara Martinez
