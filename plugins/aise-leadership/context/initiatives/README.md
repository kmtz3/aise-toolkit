# Initiatives

Time-boxed GTM and adoption motions that change how we run sessions **for a defined window**, then end.

An initiative is not a session type and not a permanent workflow. It is a temporary overlay: while it is active, it can override the normal agenda, naming, reporting target, and follow-up cadence for the accounts in its scope. When it ends, the overlay comes off and the standard workflow in `context/project-instructions.md` resumes.

## Why these live in their own folder

Motions arrive with their own account list, gates, meeting shape, and success measure, and they contradict the defaults on purpose. Folding that into the permanent context files means the contradictions outlive the motion. Keeping each one as a self-contained file means it can be archived in one move.

## How agents should use this folder

1. On any customer-session work, check whether the account appears in the scope of an initiative file whose **Status** is `Active`.
2. If it does, the initiative file wins over the general workflow **for the parts it explicitly covers**. Everything else falls back to the defaults.
3. Where an initiative contradicts a permanent context file, the initiative file must say so out loud in its § Assistant rules. Never resolve a conflict silently.
4. If an account is not in scope, the initiative changes nothing. Do not apply its meeting shape to accounts it does not cover.

## File contract

Every initiative file starts with a status block:

```
**Status:** Active | Ended | Paused
**Window:** start date – end date (or "end date TBD")
**Internal owner:** who runs the motion
**Source of truth:** link to the authoritative doc
**Last synced from source:** YYYY-MM-DD
```

The file summarizes the motion, names the scoped accounts, and ends with an **Assistant rules** section – the concrete behavior changes for this plugin's agents. Without that section the file is reference reading, not operating context.

## Keeping these honest

The source doc moves faster than this folder. Treat `Last synced from source` as an expiry date: if it is more than two weeks old and the motion is still active, re-read the source before relying on the details. Scoped account lists go stale fastest, since accounts graduate in and out as enablement and consent change.

## Archiving

When a motion ends, set `Status: Ended`, add the end date to the window, and leave the file in place. Ended initiatives are how we answer "what did we actually run last quarter". Do not delete them.

## Current

| File | Status | Window |
|---|---|---|
| `spark-in-practice.md` | Active | 2026-08-11 – TBD (expected ≤ 3 months) |
