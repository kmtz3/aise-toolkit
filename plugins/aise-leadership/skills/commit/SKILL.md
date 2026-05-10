---
name: commit
description: "Commit Skill — aise-leadership version. Syncs context/ from aise-assistant, classifies changes, bumps version in both package.json and .claude-plugin/plugin.json (semver), then commits all modified files."
---

## Steps

1. **Sync context from aise-assistant (always first):**
   Run `bash scripts/sync-context.sh` to pull the latest `context/` from `aise-assistant/main`.
   If context changed, the sync script commits it automatically — note that commit and continue with the remaining changes.

2. Run `git status` and `git diff --stat` to understand what else changed.

3. Stage the relevant changed files. Prefer staging specific files over `git add -A` — avoid accidentally bundling unrelated changes.

4. **Version bump (mandatory when on `main` or `staging`):**
   - Check current branch with `git branch --show-current`.
   - If on `main` or `staging`, read the current version from `package.json`.
   - Determine bump level:
     - **MAJOR** (+1.0.0) — new command/agent/skill added or deleted, significant restructure
     - **MINOR** (+0.1.0) — new feature, functional enhancement to an existing command
     - **PATCH** (+0.0.1) — bug fix, docs update, style tweak, no behaviour change
     - Higher level wins when changes span multiple categories.
   - Update the version in **both** `package.json` and `.claude-plugin/plugin.json` (must match).
   - Stage both version files.

5. **Update CHANGELOG.md** (if one exists at the repo root):
   - Prepend a new entry: `## [version] — YYYY-MM-DD`
   - Group bullets under `### Added`, `### Changed`, `### Fixed`, or `### Removed`
   - Stage `CHANGELOG.md`

6. Write a concise commit message focusing on the main change. Include the version bump if applicable.

7. Commit and push to the current branch.

8. Show the commit hash and summary.
