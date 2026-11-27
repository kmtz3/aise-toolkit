---
name: planhat-automations
description: Build, debug, and extend Planhat automations — Execute Functions, Branch routing, Update steps, Get steps, and Association field patterns. For formula field syntax (FIND / COUNT / SUM, the filters-sort-limit-through options object, date math), use planhat-formula-builder instead.
---

# Planhat Automations Skill

Use this skill whenever the user wants to build, debug, or extend a Planhat automation — including Execute Functions, Branch routing, Update steps, and Get steps.

> **Writing a formula field?** Use the `planhat-formula-builder` skill — it covers `FIND` / `COUNT` / `SUM` / `MAX` / `MIN`, the `filters` / `sort` / `limit` / `through` options object, operator and date-function reference, and a debugging checklist. Come back here when the logic can't be expressed as a formula and needs real automation steps.

**When syntax is uncertain, check the source, not Fin.** Search help.planhat.com first – "Get steps" (11162604), "Webhooks in Automations" (11432236) and "Workflow permissions" (10398687) are authoritative – and check a real Run log for payload shapes. Offer a Fin prompt only as a last resort.

---

## Design order: native first, simplest wins

Before proposing a design, work down this list and stop at the first option that does the job:

1. **Formula fields + a single per-record trigger** (the self-triggering record pattern below)
2. **Native steps with a small Execute Function**
3. **The bulk webhook pattern**

Use the fewest new fields and automations possible. **Present one recommended design**, not several stacked alternatives – mention a fallback in one line only if the recommendation depends on something unverified.

---

## Core Limitations to Know Upfront

Before building anything, understand these hard constraints:

| Limitation | Detail |
|---|---|
| Cross-model formula direction (implicit) | Plain `FIND`/`COUNT` filters only work **Company → child models** (Conversations, Licenses, etc.). A Conversation formula **cannot** read Company fields this way. See the `through` escape hatch below for lateral (non-hierarchy) relations. |
| Typed field inputs in Update steps | Date fields show a date picker; boolean fields show a toggle. Neither accepts variable/replacement code input — only static values. |
| Date fields in Branch conditions | Same as above — date comparison operators show a calendar picker, not a variable input. |
| Execute Function return | Must use a **top-level `return`** statement. No `function main()` wrapper. |
| No loops, no bulk update | There is **no Loop / For each step** and **no Update multiple step**. The Update step takes **one `_id`** – an array or comma-separated list fails with `id must be the Planhat _id or "<keyable>-<value>"`. `<<step[0]._id>>` is only the first record. To act on many records use the self-triggering record pattern, or the bulk webhook pattern. |

---

## Automation Step Reference

### Trigger
Standard Planhat triggers: `Conversation created or updated`, `Conversation manual action`, `Company created or updated`, etc.

The triggering object is accessible via `<<object>>` or field-level as `<<object.fieldName>>` – **but the payload shape depends on the trigger, so check a Run log's event details before writing references, rather than guessing.**

**`<Model> updated` payload has no top-level `_id`.** Its keys are `companyId`, `entityId`, `update` (only the changed fields), `oldDoc` (the full prior record), `operation`, `actor` and `model`. On a Company updated trigger, `<<object._id>>` resolves empty – reference the company as `<<object.companyId>>` or `<<object.entityId>>`.

**Formula recalculation fires `<Model> updated` triggers.** The Run log shows `actor: System`; recalculation runs roughly hourly. This is useful (see the self-triggering record pattern) but also means a formula change can set off any automation listening on that model.

**Scheduled trigger** lives under **Other → Scheduled** in the trigger picker. It needs the **Automation Events – Scheduled** workflow permission (Settings → Users & Roles → Roles → Workflow tab). A scheduled run fires **once per run with no trigger record**, so acting on many records from it requires the bulk webhook pattern.

### Get Step
Fetches a related record. The step's output is referenced downstream using the **step ID** (e.g. `get-object-y80`) or the **step name** if renamed.

```
<<get-object-y80.customerFrom>>     // specific field
<<get-object-y80>>                  // whole object
```

Always rename steps to readable names (e.g. `Get Company`) to keep references legible.

### Execute Function
Runs JavaScript. Key rules:

- **No function wrapper** — top-level code only
- **Return an object** for downstream property access
- Replacement codes are substituted inline before JS executes — wrap in quotes when used inside `new Date()`

**Correct pattern:**
```javascript
const convDate = new Date("<<object.date>>");
const start   = new Date("<<get-object-y80.customerFrom>>");
const end     = new Date("<<get-object-y80.renewalDate>>");

return { inContract: convDate >= start && convDate <= end };
```

**Wrong patterns:**
```javascript
// ❌ function wrapper — return value won't propagate
function main() {
  return { inContract: true };
}

// ❌ planhat.update() — Execute Function cannot write records
await planhat.update('Conversation', object._id, { ... });

// ❌ steps['step-id'] — not valid syntax
const company = steps['get-object-y80'];
```

Rename the Execute Function step to something meaningful (e.g. `Check Contract`) — the step name is used to reference its output downstream.

### Branch Step
Routes execution based on conditions. References Execute Function output using replacement codes with dot notation — **must be typed manually**, not selected from dropdown.

```
Field:    <<Check Contract.inContract>>
Operator: Equal To
Value:    true
```

- The step name in `<<StepName.property>>` must exactly match the Execute Function's step name
- If the function returns a plain value (not an object), reference as `<<StepName>>` directly
- `executionResult: {}` in run logs does **not** mean the value is empty — it's a display issue; the value does flow to downstream steps

### Update Step
Writes fields on a record. Boolean and date fields only accept **static values** — no variable input.

**Workaround for boolean fields:** Use a Branch before the Update step. Each branch path has a hardcoded toggle value:
- Condition 1 (`inContract = true`) → Update with toggle **ON**
- Condition 2 (`inContract = false`) → Update with toggle **OFF**

**Workaround for date fields:** There is no clean workaround in the Update UI. Use Execute Function to perform any date logic and output a derived value instead.

---

## Common Automation Patterns

### Pattern: Self-triggering record (preferred way to act per record)
**Use case:** Change many records of one model when a condition becomes true, with no loop, flag field or webhook.

1. **Toggle formula** on the model – on when the record needs action. It switches off by itself once the automation changes the record (e.g. `planhat-formula-builder` Pattern H).
2. **Counter formula** on the same model – a Number that changes on a schedule while the toggle is on (e.g. days since a date, `planhat-formula-builder` Pattern I). Because formula recalculation fires `updated` triggers, this re-fires the automation daily until the record is resolved.
3. **Trigger:** `<Model> updated`, conditions:
   ```
   Match all
     <toggle> is true
     Group – Match any
       <toggle> is true
       <counter> more than -1
   ```
4. **Steps:** native Branch / Update. With this trigger, `<<object._id>>` works in Update steps.

Name the two fields as a pair (e.g. `Needs Status Review` + `Needs Status Review Days`).

---

### Pattern: Bulk update via webhook (when per-record triggering isn't possible)
**Use case:** A scheduled or one-off run that must update many records at once.

```
Get multiple (step: Get Records)
  ↓
Execute Function (step: Build Body)
  ↓
Call a webhook
  Method:  PUT
  URL:     https://api.planhat.com/<model>        // e.g. lineitems
  Header:  Content-Type: application/json
  Body:    <<Build Body.body>>
```

**Build Body:**

```javascript
let recs = <<Get Records>>;
if (typeof recs === "string") recs = JSON.parse(recs);
if (!Array.isArray(recs)) recs = recs ? [recs] : [];
const body = recs.filter(r => r._id).map(r => ({ _id: r._id, custom: { "Field Name": true } }));
return { count: body.length, body: JSON.stringify(body) };
```

- The PUT is Planhat's bulk upsert: matched on `_id`, **max 5,000 items** per call.
- Calls to `api.planhat.com` from an Automation are **authenticated automatically – no token needed** (confirmed by Planhat Support).

---

### Pattern: Dynamic "In Active Contract" flag on Conversation (preferred)
**Use case:** Flag a conversation as occurring within its linked deal's contract period. Fully dynamic — recalculates automatically, renewal-proof.

**Setup (no automation needed):**

1. Add an **Association** custom field on Conversation → target model: **Deal**. Name: `Linked Contract`.
2. Add two **Association pull** custom fields on Conversation, both pulling from `Linked Contract`:
   - `Start Date` → Deal.`startDate`
   - `End Date` → Deal.`endDate`
3. Add a **Formula** custom field of type **Toggle** on Conversation, named `In Active Contract`:
   ```
   IF(IS_EMPTY(<<custom.Start Date>>) || IS_EMPTY(<<custom.End Date>>), false, IF(DAYS_DIFF(<<date>>, <<custom.Start Date>>) >= 0 && DAYS_DIFF(<<custom.End Date>>, <<date>>) >= 0, true, false))
   ```
   `AND()` is not a supported function – use `&&`. `DAYS_DIFF(a, b)` is `a − b`, so both diffs are ≥ 0 only when the date falls inside the window. `true` / `false` are unquoted. Built from functions verified in `planhat-formula-builder`, but this exact formula hasn't been tested yet – check it on one record inside and one outside the window before relying on it.

**Why this is better than the automation approach:**
- Recalculates live — no stamping, no staleness
- Renewal-proof: create a new Deal for the new contract period; old conversations stay linked to the old Deal and correctly return false; new conversations link to the new Deal
- No automation re-trigger needed on renewal

**Operational requirement:** When logging AISE conversations, the `Linked Contract` association field must be filled in — otherwise Start Date and End Date are null and the formula returns false. Consider making it required or defaulting it via an automation on conversation create.

---

### Pattern: Stamp a boolean field based on date range (automation fallback)
**Use case:** Use this only if the Association field approach above is not available or if Deal records are not maintained. Flag a conversation as occurring within the company's active contract period via a stamped toggle.

> ⚠️ Limitation: this approach stamps a value at create/update time. On contract renewal, old conversations are not re-evaluated unless the automation is manually re-triggered on them.

```
Trigger: Conversation created or updated
  ↓
Get Company (step: Get Company)
  ↓
Execute Function (step: Check Contract)
  const convDate = new Date("<<object.date>>");
  const start   = new Date("<<Get Company.customerFrom>>");
  const end     = new Date("<<Get Company.renewalDate>>");
  return { inContract: convDate >= start && convDate <= end };
  ↓
Branch
  Condition 1: <<Check Contract.inContract>> Equal To true
    → Update Conversation: toggle In Active Contract ON
  Condition 2: <<Check Contract.inContract>> Equal To false
    → Update Conversation: toggle In Active Contract OFF
```

### Pattern: Count conversations by type within contract period (Company metric)
**Use case:** Dashboard showing sessions consumed in the current contract.

Create numeric formula fields on the **Company** model (not Conversation) — one per conversation type:

```
COUNT(Conversation & {"filters": [
  {"field": {"id": "type"}, "op": "equal to", "value": "🏗️ Architecting"},
  {"field": {"id": "date"}, "op": "more than", "value": "<<customerFrom>>"},
  {"field": {"id": "date"}, "op": "less than", "value": "<<renewalDate>>"}
]})
```

Date `<<field>>` values in a filter must be quoted – unquoted, the formula fails to save with a JSON syntax error (`planhat-formula-builder` gotcha #13).

Repeat for each type: Kick off, Sync, Discovery, Audit/Setup Review, Enablement, etc.

---

### Pattern: Pull a field from a laterally-related model via `FIND` + `through` (formula field)
> Full formula syntax reference lives in `planhat-formula-builder`. This section is kept here because the `through` escape hatch is what makes the Association-vs-formula decision below.

**Use case:** A model needs to show a field from a record it references via a `manyToOne` relation that is **not** a Company → child relationship — e.g. a Line Item pulling a custom field from its linked Product via `productId`. Plain `FIND`/`COUNT` filters can't reach across this kind of lateral reference (see the Core Limitations table), but an explicit `through` clause does.

**Confirmed working example** (Line Item formula field pulling a Product custom field):

```
FIND(Product.custom.Default Project Plan – SF & {
  "through": {
    "basePath": "LineItem.productId",
    "targetPath": "Product._id"
  },
  "limit": 1
})
```

- `basePath` — `"<ModelTheFormulaLivesOn>.<relationField>"`. The relation field is the one on the current model that stores the linked record's ID (e.g. `LineItem.productId`).
- `targetPath` — `"<TargetModel>._id"`. Almost always `_id` on the target side.
- `limit: 1` — expected for a single-record lookup; omit or raise it for a list.
- Field names with spaces, en dashes, or other special characters (common on Salesforce-synced custom fields, e.g. `Default Project Plan – SF`) do **not** need quoting — write them exactly as they appear in Manage Fields, unquoted, same as any other `Model.custom.Field Name` reference.
- This `through`/`basePath`/`targetPath` structure is **not** in Planhat's public formula docs (as of Aug 2026) — treat it as a confirmed-working but unofficial capability, not something to assume is documented or stable across a Planhat platform update. Re-verify on a test record if it stops working after a Planhat release.

**When to prefer an Association Pull field instead:** If the relation is (or can be) modeled as a proper **Association** custom field rather than a plain system relation like `productId`, an **Association pull** field (see the "In Active Contract" pattern above) is the simpler, fully-documented way to surface a linked record's field — no formula needed at all. Reach for `FIND` + `through` when the relation is a native `manyToOne` system field (like `productId` → Product) rather than a custom Association field, or when the value needs to be computed inline as part of a larger formula rather than pulled as its own field.

---

## Field Reference: Company Model (Key Date Fields)

| Display name | Internal field ID | Notes |
|---|---|---|
| Customer Since | `customerFrom` | Contract start — earliest license start date |
| Renewal Date | `renewalDate` | Next renewal date |
| Customer To | `customerTo` | Latest license end date |

## Field Reference: Conversation Model (Key Fields)

| Display name | Internal field ID | Notes |
|---|---|---|
| Date | `date` | When the interaction took place (datetime) |
| Type | `type` | Conversation type (e.g. `👟 Kick off`, `🏗️ Architecting`) |
| Company | `companyId` | Parent company ID |

## Field Reference: Line Item ↔ Product Models (Key Fields)

| Model | Display name | Internal field ID | Notes |
|---|---|---|---|
| LineItem | Product | `productId` | `manyToOne` relation to Product — native system field, not a custom Association |
| LineItem | Deal | `dealId` | `manyToOne` relation to Deal (required) |
| Product | Default Project Plan | `custom.Default Project Plan – SF` | Boolean/checkbox, Salesforce-synced, readonly |
| Product | SKU | `custom.SKU – SF` | Text, Salesforce-synced, readonly |
| Product | Plan Name | `custom.Plan Name – SF` | Text, Salesforce-synced, readonly |

**Line Item status and Salesforce import:**

- `status` values: `ongoing`, `renewed`, `lost`.
- Planhat imports Closed Won opportunities and all their line items. Keep the Line Item import limited to Closed Won (planned import filter: `PH_Opportunity_Import__c = true`).
- Line Item start/end dates come from the Salesforce formulas `PH_Service_Start_Date__c` / `PH_Service_End_Date__c`, which inherit the **opportunity's** service dates because line-level dates weren't consistently filled.
- Salesforce Customer Status and `Churning__c` follow live workspace subscription and provisioned-order ARR, not opportunities – an account can show `5.0 Churn` while a Closed Won term is still running. Don't use them to decide a Line Item's status.

Several LineItem custom fields mirror the same-named Product fields (`SKU – SF`, `Plan Name – SF`, `Plan Version – SF`, `Duration – SF`, `Product Type – SF`, `Unit Price – SF`, `Default Project Plan – SF`) and are all marked readonly — these are intended to be formula/pull fields sourced from the linked Product via `productId`, not manually-entered values. If one is blank on a Line Item that has `productId` set, check whether its formula uses the `FIND` + `through` pattern above (or an Association pull field) before assuming the underlying Product data is missing.

---

## Debugging Workflow

When an automation isn't behaving as expected, work through this sequence:

### Step 1 — Check the Run log
Go to **Runs** tab → click the specific run → expand each step.

| What you see | What it means |
|---|---|
| Step shows `Skipped` | A Branch condition didn't match — check what value the Branch is actually seeing |
| Step shows `Completed` but field unchanged | The Update step ran but the value was wrong or the field reference failed |
| `executionResult: {}` on Execute Function | Normal — doesn't mean empty. Check the Branch log instead to see what value flowed through |
| Both Branch conditions `resultCondition: false` | The property reference is wrong — check step name spelling and dot notation path |
| `"property": {}` in Branch log | The replacement code resolved to empty — step name mismatch or the function didn't return the expected key |

**Auditing what an automation changed:** use the automation's **Runs** tab or the record's **Logs** (`···` menu on the record). Never use `updatedAt` – every record's `updatedAt` moves when formulas recalculate.

### Step 2 — Verify replacement code resolution
In the Run log, click the Execute Function step and check **Code** — the replacement codes should be fully substituted with real values. If you see `<<object.date>>` still unresolved, the replacement code syntax is wrong.

### Step 3 — Isolate the function logic
If the function logic is suspect, paste the substituted code (from the Run log) into a browser console or Node REPL to verify the return value independently.

### Step 4 — Check step naming
The most common cause of `property: {}` in the Branch is a step name mismatch. Confirm:
- The Execute Function step name matches exactly what's in `<<StepName.property>>`
- No spaces vs underscores, no capitalisation differences

### Step 5 — Trigger a manual test run
Use **Conversation manual action** as the trigger so you can test against a specific known record (e.g. an ACME Solutions conversation with a known date inside the contract window).

---

## Writing New Automation Mechanics

When asked to design or extend an automation, follow this sequence:

1. **Identify the data sources** — What model is the trigger? What related models need to be fetched? Check field IDs against the Company and Conversation field references above.

2. **Check for cross-model constraints** — If the logic needs data from a parent model (e.g. Company dates from a Conversation trigger), it must go through a **Get** step. Plain formulas cannot do this. For lateral relations (e.g. LineItem → Product), consider the `FIND` + `through` pattern or an Association pull field before reaching for an automation.

3. **Design the Execute Function first** — Write the transformation logic as a plain JS snippet (no wrapper), verify it manually with hardcoded values, then add replacement codes.

4. **Handle typed field outputs via Branch** — If the final output is a boolean or date field, plan for a Branch → hardcoded Update pattern. Never try to pipe a variable into a boolean toggle or date picker.

5. **Name steps clearly** — Step names become part of replacement code references. Use descriptive names like `Get Company`, `Check Contract`, `Calculate Score` from the start.

6. **Test on a known record first** – Use a customer where you know the expected outcome (e.g. ACME Solutions: `customerFrom` 30 Jun 2026, `renewalDate` 30 Jun 2027 – any conversation dated July 2026 should return `inContract: true`).

7. **Pre-flight downstream side effects** – For any automation that changes revenue records (Line Items, Deals, Licenses), list the other automations and derived fields that react to Company `renewalDate`, `phase`, `status` or `mrr`/`arr`, and tell the user which side effects to expect **before** running in bulk. Example: resolving expired Line Items moves Company `renewalDate`, which fires the Company phase automation (`3. Renewal` when days till renewal < 90; `0. Preparation` when > 179 and phase is Renewal) on every affected company.

8. **Verify against live data after each change** – After a field is created or an automation runs, query 2–3 known records through the Planhat MCP and confirm the values before moving on. New formula fields can lag in the API; if the API shows nothing, ask the user to check the UI.

---

## Large data changes (more than ~50 records)

1. **Size the job** and split it into buckets by outcome (e.g. renewed / lost / leave as is).
2. **Have the user export a backup** of the affected records first.
3. **Test on 1–3 records per bucket.**
4. **Run batches of 100–200**, grouped by company so no company is left half-done.
5. **Keep the automation disabled while testing.** Run batches from a **Manual action** copy: Data Explorer → select records → Run automation.

---

## Auto-Update Pattern for Iterative Debugging

When debugging a failing automation, follow this loop:

```
1. Run the automation manually on a known test record
2. Open Runs → expand each step → read the log
3. Identify the first step that fails or produces unexpected output
4. Make ONE targeted change (step name, return value, condition)
5. Re-run on the same test record
6. Compare the new log against the previous — confirm the change had the expected effect
7. Repeat until all steps show the correct output and the final field updates correctly
```

**Do not make multiple changes between runs** — it makes it impossible to know which change fixed the issue.

When the automation works on the test record, run it against 2-3 additional records with different expected outcomes (one inside contract, one outside) to confirm both branches behave correctly.
