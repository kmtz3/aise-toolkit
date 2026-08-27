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

The folder ID above is the ID **for the user this plugin was configured against**. A teammate installing the plugin, or a user whose folder was moved, renamed, or trashed, will not have it. Always resolve before writing:

1. `get_file_metadata(fileId: "1jqk8QqRqOJczneOCIjm0-uslf6D5bOJt")`.
   - Returns a folder titled `Customer Session Artifacts`, not trashed → use this ID. Done.
   - Errors, is trashed, or is not a folder → continue to step 2.
2. `search_files(query: "title = 'Customer Session Artifacts' and mimeType = 'application/vnd.google-apps.folder'")`.
   - Exactly one non-trashed hit → use its ID. Done.
   - Several hits → prefer the one the user owns (`owner = <user email>`) and, among those, the most recently modified. Mention the ambiguity in the run report.
   - No hits → continue to step 3.
3. `create_file(title: "Customer Session Artifacts", contentMimeType: "application/vnd.google-apps.folder")` at Drive root. Report the new folder URL to the user in the run summary.
4. Once resolved in a run, **cache the folder ID in working context and reuse it** for every artifact in that run — bulk runs must not re-resolve per session.

Never silently fail an artifact because the folder was missing. Creating it is part of the job.

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
| `SessionPrep` | `/session-prep`, `/bulk --prep`, `/daily-brief --auto-prep` | The prep brief rendered as a file. |
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

**Field:** `custom.Prep Notes` on whichever record, unless a more specific field exists for that artifact type (KDD attachments follow the Attachment path in `context/planhat-schema.md`).

**Format** — prepend this block above any existing prep content, never overwrite it:

```
SESSION PREP ARTIFACT — {filename}
Drive file: {webViewLink}
Folder: Customer Session Artifacts — {folder URL}
Salesforce Account: {SalesforceAccountId}
```

Swap the first line's label to match the artifact type (`SESSION DECK ARTIFACT`, `KDD ARTIFACT`, …).

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
