# Session Artifact Convention — Google Drive + Planhat

> Applies to **every file artifact generated for a customer session** by this plugin: session prep HTML, facilitation guides, KDD docs, decks, diagrams, debrief exports. If a workflow produces a file a customer or a colleague could plausibly open later, it follows this convention.
>
> This is distinct from [`context/session-naming-convention.md`](session-naming-convention.md), which governs **session record names** (`[A7] Roadmaps System Design`). This file governs **artifact file names and where they live**.

---

## 1. The home folder

All session artifacts live in a single flat Drive folder owned by the user:

| | |
|---|---|
| Name | `Customer Session Artifacts` |
| Folder ID | `1jqk8QqRqOJczneOCIjm0-uslf6D5bOJt` |
| URL | https://drive.google.com/drive/folders/1jqk8QqRqOJczneOCIjm0-uslf6D5bOJt |

Flat by design — the file name carries customer, date, account and type, so no per-customer subfolders. Do not create them.

### Resolve-or-create (run this before every upload — never assume the folder exists)

The folder ID above is the ID **for the user this plugin was configured against**. A teammate installing the plugin, or a user whose folder was moved, renamed, or trashed, will not have it. The per-user source of truth is the `Artifacts folder: <id>` line in `custom.AISE Workspace` on the user's Planhat User record (`context/planhat-user-profile.md`). Always resolve before writing, in this order:

1. **Persisted ID first.** Read `custom.AISE Workspace` on the user's Planhat User record, strip tags, and parse the `Artifacts folder: <id>` line. If present, `get_file_metadata(fileId: "<id>")`.
   - Returns a non-trashed folder titled `Customer Session Artifacts` → use this ID. Done.
   - Line absent, or the ID errors, is trashed, or is not a folder → continue to step 2.
2. **Search by exact title, owned by the user.** `search_files(query: "title = 'Customer Session Artifacts' and mimeType = 'application/vnd.google-apps.folder' and 'me' in owners and trashed = false")`.
   - Exactly one hit → use its ID.
   - Several hits → use the **oldest** (earliest `createdTime`) and flag every other one in the run report as `⚠️ Duplicate artifacts folder: <id> (<file count> files)` so the user can merge them. Never pick the most recently modified: that is how a second folder became the default (2026-10, two folders in use at once).
   - No hits → continue to step 3.
3. **Create only when the search returned nothing.** `create_file(title: "Customer Session Artifacts", contentMimeType: "application/vnd.google-apps.folder")` at Drive root. Report the new folder URL in the run summary.
4. **Persist.** If the ID that steps 2–3 resolved differs from the `Artifacts folder:` line (or the line is missing), write it back to `custom.AISE Workspace`: read the current value, replace the `<p>Artifacts folder: …</p>` paragraph or append one, keep every other line exactly as it was, and send the whole field in one `update_model_record(MODEL: "User", …)` call. Read it back to verify. A failed write is reported, never silently dropped.
5. Once resolved in a run, **cache the folder ID in working context and reuse it** for every artifact in that run — bulk runs must not re-resolve per session.

Never silently fail an artifact because the folder was missing. Creating it is part of the job. Never create one while a search hit exists.

---

## 2. File naming

```
{CustomerName}_{YYYY-MM-DD}_{SalesforceAccountId}_{ArtifactType}.{ext}
```

**Example:** `Emplifi_2026-08-27_001f400000FwmeqAAB_SessionPrep.html`

| Segment | Rule |
|---|---|
| `CustomerName` | Exactly as it appears in Salesforce / Planhat `Company.name`. **No spaces** — strip them (`Acme Corp` → `AcmeCorp`). Keep the casing Salesforce uses. Drop `.`, `,`, `/`, `&` and any character Drive or a shell would fight over; keep `-`. |
| `YYYY-MM-DD` | The **session date** (ISO), not the date the file was generated. For an artifact that isn't tied to one session (rare), use the generation date and say so in the Planhat link line. |
| `SalesforceAccountId` | The 18-char SF Account Id — see §3. |
| `ArtifactType` | One value from the registry in §4. PascalCase, no separators. |
| `.ext` | Real extension of the file (`.html`, `.pdf`, `.svg`, `.pptx`). |

Underscores separate segments; nothing else in the name may contain an underscore.

---

## 3. Salesforce Account Id — resolve and verify

**Duplicate and churned accounts under the same customer name are common.** Never take the first SOQL hit.

1. Preferred path — read it off the Planhat Company: `list_model_records(MODEL: "Company", FILTER: {"name[equal to]": "<customer>"})` and use `sourceId`. Planhat syncs natively from Salesforce, so `sourceId` is by definition the **active, synced** account.
2. Verify against Salesforce: `SELECT Id, Name, Type, IsDeleted FROM Account WHERE Name LIKE '%<customer>%'`. Confirm the Planhat `sourceId` appears in the results and is the record with `Type = 'Customer'` / not deleted.
3. If SOQL returns several accounts and the Planhat `sourceId` is **not** among them, or matches a churned/deleted record — stop, don't guess. Surface both IDs to the user and ask which one is live.

Record the resolved ID once per run and reuse it across every artifact for that customer.

---

## 4. `ArtifactType` registry

| Value | Produced by | Notes |
|---|---|---|
| `SessionPrep` | `/session-prep`, `/bulk --prep`, `/daily-brief` (same-day prep, `--auto-prep`) | The prep brief rendered as a file. |
| `Facilitation` | `/session-facilitation` | Interactive HTML run sheet. |
| `KDD` | `/session-kdds`, `/session-prep` (A-sessions) | Customer-facing key design decisions doc. |
| `Deck` | `/create-deck` | Single-file HTML deck. |
| `Diagram` | `/draft-diagram` | SVG path only — a Figma file has no Drive artifact. |
| `Debrief` | `/session-debrief`, `/bulk --debrief` | Only when the debrief produces a file; the written summary itself belongs on the Planhat Conversation, not in Drive. |
| `Brief` | `/daily-brief` | Only when the user asks for the daily brief to be filed in Drive. Uses the brief date and the user's own name in place of a customer. |
| `Onepager` | `/spark-onepager` | |
| `Playbook` | `/spark-demo-prep` | |

Need a type that isn't listed? Add it here via `context-keeper` in the same run — don't improvise a one-off suffix.

---

## 5. Upload

`create_file` with:

- `title` — the name from §2
- `parentId` — the folder ID resolved in §1
- `contentMimeType` — the real type (`text/html`, `image/svg+xml`, …)
- `disableConversionToGoogleType: true` — **required** for HTML and SVG, otherwise Drive silently converts the artifact into a Google Doc and the styling is destroyed
- content via `textContent` for UTF-8 text, `base64Content` otherwise

Local copies still go to their usual `~/Desktop/aise-assistant/...` path. Drive is the shareable copy, not a replacement.

Re-running a workflow for the same session produces the same file name. Search the folder by title first; if a file with that exact name exists, **update it in place rather than creating a second copy**, and say so in the report.

---

## 6. Link it back into Planhat

An artifact that isn't linked from the session record doesn't exist. After a successful upload, write the link onto the session's Planhat record.

**Target, in order of preference:**

1. The **calendar-event Task** for the session (`MODEL: "Task"`, `mainType: "event"`, GCal-synced, matching company + date) — this is where `daily-brief` and `session-prepper` already read prep status from.
2. The session **Conversation** on the Company (matching company + date + type) when no event Task exists.

**Field, per artifact type:**

| Artifact | Field(s) written |
|---|---|
| `Facilitation` | Task `custom.Facilitation Playbook URL` (the bare Drive `webViewLink`) **plus** the `custom.Prep Notes` block below |
| `SessionPrep`, `KDD`, and every other type | `custom.Prep Notes` only (KDD attachments also follow the Attachment path in `context/planhat-schema.md`) |

`custom.Facilitation Playbook URL` exists on the **Task model only** (string, writable). It is the canonical facilitation link: the daily brief, the debrief and every orchestrator read it first, and it holds the bare `webViewLink`.

**Playbook URL write rules** (any procedure that publishes or finds a `Facilitation` artifact):

1. Only when the target is the event Task. On a Conversation-only session, skip the field (the Conversation model has no such field), link into `custom.Prep Notes` as usual, and report `Playbook URL field not available on Conversations`.
2. One call: `update_model_record(MODEL: "Task", OBJECT_ID: "{_id}", PARAMETERS: {"custom": {"Facilitation Playbook URL": "<webViewLink>"}})`, then select the field back to verify.
3. Read the field first. Same URL already there: skip the write. Different URL: overwrite (the Drive file is updated in place by filename, so the URL should normally be identical) and note the change in the report.
4. The write is additive. It never replaces or removes the `custom.Prep Notes` block, and it is independent of whether that block was already present: if the guide is already published and linked but the field is empty, backfill the field.

**Format — one canonical shape, used by every writer.** The link lives in the **Session artifact** section of the prep brief: right after the `<hr>`, before Account snapshot (`context/planhat-schema.md` § Canonical prep-brief structure, row 5). One `<li>` per artifact, then a `Folder` item, then the Salesforce Account Id as plain text. Links are anchors, en dashes only, single-line `ph-editor` HTML:

```html
<p><strong>Session artifact</strong></p><ul class="ph-editor__bullet-list"><li class="ph-editor__list-item"><p><strong>{ArtifactType}</strong> – <a href="{webViewLink}">{filename}</a></p></li><li class="ph-editor__list-item"><p><strong>Folder</strong> – <a href="{folderUrl}">Customer Session Artifacts</a></p></li><li class="ph-editor__list-item"><p><strong>Salesforce Account</strong> – {SalesforceAccountId}</p></li></ul>
```

`{ArtifactType}` is the registry value from §4 (`SessionPrep`, `KDD`, `Facilitation`, `Deck`, …). Never write a bare URL, a `SESSION PREP ARTIFACT — …` / `FACILITATION ARTIFACT — …` paragraph run, `&ndash;`, or an em dash.

**Upsert, never prepend.** Every writer (session-prepper § 6.8, `session-facilitation` step 4, `kdd-builder`, `create-deck`, `diagram-builder`, `post-session-debrief`) follows the same rule:

1. Read the record's current `custom.Prep Notes`.
2. **Section exists** → inside it, find the `<li>` whose anchor text is this artifact's filename (or, failing that, whose `<strong>` label is this `{ArtifactType}`) and replace it; if none matches, insert a new `<li>` before the `Folder` item. Leave every other item untouched.
3. **Section absent, `<hr>` present** → insert the full section immediately after the first `<hr>`.
4. **Notes empty, or no `<hr>`** → write the section, preceded by `<hr>` when there is other content above it, so the shape stays header → `<hr>` → Session artifact → body.
5. **Legacy shapes** (a `… ARTIFACT — …` paragraph run before the header, or a bulleted list with a bare `Drive file` URL) → on any write, remove them and carry their links into the canonical section. A re-run never leaves two artifact sections.

Write the whole field back in one `update_model_record` call and read it back to confirm exactly one `Session artifact` label and every pre-existing section is intact.

> **Link rendering.** `<a href>` is stored unchanged and clickable in the Planhat UI (verified 2026-10-08). `custom.Facilitation Playbook URL` remains the canonical facilitation link.

### Facilitation gate

For `🏗️ Architecting`, `🔎 Discovery` and `👟 Kick off` sessions, a prep run is **not done** until both are true:

1. A `Facilitation` artifact for the session is in the `Customer Session Artifacts` folder (exact filename per §2), and
2. `custom.Facilitation Playbook URL` on the session's event Task has been **read back non-empty and equal to that file's `webViewLink`**.

If either fails, the run reports `🔴 Facilitation missing – <reason>` (same visibility as `🔴 KDD missing`) and never finishes silently. On a Conversation-only session the gate is satisfied by condition 1 plus the `Facilitation` `<li>` in the Session artifact section, reported as `Playbook URL field not available on Conversations`. For `🗣️ Sync` and `🎓 Training` the guide stays an offer; once the user accepts it, the same field write and read-back apply.

### Known failure mode — `externalId: Not valid type`

Planhat rejects updates to Conversation records that have **no `externalId`** with `{"el":"externalId","error":"Not valid type"}`, and the error cannot be cleared by supplying one in the same call. When this happens:

- Fall back to the sibling GCal-synced record for the same session (it has an `externalId` and accepts writes).
- Note in the run report which record actually received the link and which one is stuck, so the user can reconcile the duplicate.
- Don't retry the same PUT more than once.

---

## 7. Reporting

Every run that produces an artifact reports, per artifact:

- the file name,
- the Drive link,
- which Planhat record the link landed on,
- and — if the folder had to be created, a duplicate name was updated, or a Planhat write failed — that fact, explicitly.
- for `Facilitation`, the Artifacts block also carries `Playbook URL field: set on Task {_id}` (or `already current on Task {_id}`, `changed on Task {_id}` when an old URL was overwritten, `not available on Conversations`, or `write failed on Task {_id}`). This line is **mandatory** for `🏗️ Architecting`, `🔎 Discovery` and `👟 Kick off` sessions, failures included (§ Facilitation gate).
- if more than one `Customer Session Artifacts` folder was found (§1 step 2), each extra folder ID, and whether the `Artifacts folder:` line on the User record was written this run.
