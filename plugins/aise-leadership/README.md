# aise-leadership

Portfolio visibility and account health co-pilot for Productboard AISE leadership.

Install this plugin if you're a **manager, Head of AISE, or VP CS** — not an individual AISE. For the individual AISE co-pilot (session prep, debrief, follow-ups), install [aise-assistant](https://github.com/kmtz3/aise-toolkit) instead.

---

## What it does

- **`/report --aise`** — portfolio summary across all accounts owned by an AISE: attention queue (gaps, renewals, credits exhausted), per-account health table, velocity. Renders inline in chat and publishes as an Artifact.
- **`/report --customer`** — single-account snapshot: program health, credit burn trajectory, recent sessions, open items, risks, next step. Same dual output.
- **`/session-audit`** — reconcile logged Planhat session history against Calendar + Gong, and audit open Tasks for completion drift (`--tasks`); whole-workspace by default, `--owner <aise-name>` narrows to one AISE

Planhat is the sole system of record — nothing in this plugin reads or writes Notion.

---

## Install

1. Open **Claude Code (Cowork)** → Settings → Extensions → Add Plugin
2. Enter the GitHub repo: `kmtz3/aise-toolkit`
3. Install and restart Cowork
4. Run `/aise-leadership:assistant-setup` to complete onboarding (Planhat identity + preferences)

---

## First run

After install, run:

```
/aise-leadership:assistant-setup
```

This auto-resolves your Planhat User identity and asks a short series of questions about your preferences. Takes about 2 minutes.

Then try:

```
/aise-leadership:report --aise me
```

---

## Shared knowledge base

The `context/` directory (schema, reference guide, style guide) is shared with `plugins/aise-assistant/` in this monorepo and synced via `scripts/sync-context.sh`. Changes to the knowledge base happen in `plugins/aise-assistant/context/` and are pulled here — never edit `context/` files directly in this repo.

---

## Commands

| Command | Purpose |
|---|---|
| `/report --aise [me \| <name>] [--chat-only]` | Portfolio summary for an AISE |
| `/report --customer <name> [--chat-only]` | Single-account snapshot |
| `/session-audit [--owner <aise-name>] [--tasks] [--fix]` | Reconcile session history / audit task completion drift, whole workspace by default |
| `/assistant-setup` | Onboard / re-onboard |
| `/assistant-help` | Full command reference |
| `/assistant-remember <correction>` | Capture a correction or new rule into context files and memory |
| `/assistant-improvement` | After a run with issues, output a copyable fix prompt for the plugin admin |
| `/aise-context` | Load operating context (use at session start if context seems stale) |

---

## License

MIT — Klara Martinez
