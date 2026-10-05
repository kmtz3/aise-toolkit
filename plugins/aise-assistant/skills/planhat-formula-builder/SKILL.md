---
name: planhat-formula-builder
description: Build, debug, and validate Planhat formula fields — cross-model lookups (FIND / COUNT / SUM / MAX / MIN / AVERAGE), the filters / sort / limit / through options object, date math, and same-model logic. Use when writing or troubleshooting a Planhat formula field, a connection lookup + filter, when a formula returns blank or picks the wrong record, or when deciding whether logic belongs in a formula vs an automation.
---

# Planhat Formula Builder

For automation *steps* (Execute Function, Branch, Get, Update), use the `planhat-automations` skill instead. This skill covers formula fields only.

---

## Decide these two things before writing a character

| Decision | Why it matters |
|---|---|
| **Which model does the field live on?** | Cross-model formulas only traverse **parent → child** (Company → Conversation / License / Line Item / Deal). A Conversation formula **cannot** read Company fields. If you need that direction, it's an automation with a Get step, not a formula. |
| **What data type is the field?** | The formula field's declared type must match what the expression returns. A `FIND()` on a text field must land in a **Text** field; a date lookup needs **Date**; a `COUNT()` needs **Number**. Type mismatch is the single most common cause of a silently blank field. |

**Prefer one formula field per value.** If you need Plan Name and Plan Version separately, write two fields each with a single clean `FIND()`. Do not build one concatenated field and try to parse it back apart — Planhat has no variables, so every extra value you cram in multiplies the length of the formula.

---

## Same-model syntax

Reference fields on the record the formula lives on with `<<>>`:

- System fields: `<<nps>>`, `<<h>>`, `<<customerFrom>>`, `<<renewalDate>>`
- Custom fields: `<<custom.Go-Live Date>>`, `<<custom.Segment>>`

Do **not** use aggregate functions (`SUM`, `COUNT`, `MAX`) on same-model fields — those are cross-model only. Use plain math.

```
(<<custom.ARR – SF>> - <<custom.Target ARR>>) / <<custom.Target ARR>>
```

### Operators and logic

| Category | Available |
|---|---|
| Math | `+` `-` `*` `/` |
| Comparison | `==` `!=` `>` `<` `>=` `<=` |
| Boolean | `&&` `\|\|` |
| Conditional | `IF(condition, value_if_true, value_if_false)` |
| Text / array | `IS_EMPTY(<<field>>)`, `LENGTH(<<array>>)`, `INCLUDES(<<field>>, "text")`, `INCLUDES_ALL()`, `INCLUDES_SOME()` |

### Date functions

| Function | Notes |
|---|---|
| `DAYS_DIFF(date1, date2)` | Whole days between two dates |
| `PERIOD_DIFF(date1, date2, unit)` | `unit` = `day` \| `month` \| `quarter` \| `year` |
| `DATE_ADD_DAYS(date, n)` / `DATE_SUBTRACT_DAYS(date, n)` | |
| `DATES_MAXOF(d1, d2)` / `DATES_MINOF(d1, d2)` | |
| `@today` | Dynamic current date — re-evaluates, safe in live formulas |

---

## Cross-model syntax

```
OPERATION(Model.field & { options })
```

**Target field:**

- System model: `LineItem.status`, `Conversation.date`, `License.renewalDate`
- Custom field on a system model: `LineItem.custom.Plan Name – SF`
- Custom model: `subscription_line_item.fieldName` — custom models use a **bare root key**, no `custom.` prefix

**Filter field IDs drop the model name.** Inside `"filters"`, write `{"id": "status"}` and `{"id": "custom.Plan Name – SF"}` — never `{"id": "LineItem.status"}`.

### Which functions accept what

| Function | `filters` | `sort` | `limit` | Returns |
|---|:--:|:--:|:--:|---|
| `FIND()` | ✅ | ✅ | ✅ | Field value(s) from matching records |
| `COUNT()` | ✅ | ❌ | ❌ | Count of all matches |
| `SUM()` | ✅ | ❌ | ❌ | Sum over all matches |
| `AVERAGE()` | ✅ | ❌ | ❌ | Mean over all matches |
| `MAX()` / `MIN()` | ✅ | ❌ | ❌ | Extreme value over all matches |
| `IS_EMPTY()` | — | — | — | Wraps a single field **or** a `FIND()`; not a cross-model query itself |

`COUNT`, `SUM`, `AVERAGE`, `MAX` and `MIN` tally or aggregate **every** match — `sort` and `limit` are meaningless there and are ignored.

### The options object

```json
{
  "filters": [
    {"op": "equal to", "field": {"id": "status"}, "value": "ongoing"},
    {"op": "more than", "field": {"id": "custom.ARR"}, "value": 1000}
  ],
  "sort": {"fromDate": -1},
  "limit": 1
}
```

**Filter operators:** `equal to`, `not equal to`, `more than`, `less than`, `has value`, `has no value`, `any of`, `none of`, `after (days ago)`, `period_diff`

**Sort:** `-1` = descending (newest / highest first), `1` = ascending.

**Traversal (`through`)** — when there's no direct parent → child relationship, or when querying a custom model, declare the join explicitly. This is the escape hatch for *lateral* relations that plain filters can't reach (e.g. Line Item → Product via `productId`).

Two forms are in circulation. Both have been seen working; they are not interchangeable in every case, so if one returns nothing, try the other before concluding the relation can't be traversed.

```json
// Array form — matches Planhat's documented syntax
"through": {
  "basePath": ["Deal._id"],
  "targetPath": ["subscription_line_item.dealId"]
}

// String form — confirmed working for LineItem → Product
"through": {
  "basePath": "LineItem.productId",
  "targetPath": "Product._id"
}
```

- `basePath` — `<ModelTheFormulaLivesOn>.<relationField>`, the field on the current model holding the linked record's ID.
- `targetPath` — `<TargetModel>._id` in most cases.
- Field names containing spaces or en dashes (common on Salesforce-synced fields like `Default Project Plan – SF`) are written **unquoted**, exactly as they appear in Manage Fields.
- `through` is thinly documented. Treat it as confirmed-working-but-unofficial and re-verify on a test record after any Planhat platform update.

See `planhat-automations` for the full worked Line Item → Product example and for when an **Association pull** field is the simpler answer than a `through` formula.

---

## Hard limits and gotchas

**1. `"limit": 1` without `"sort"` is non-deterministic.** Order falls back to internal database response order (roughly `createdAt`), which is not a business rule. Any time more than one record can match, you will silently get an arbitrary one — and it can change. **Always pair `limit` with `sort`.**

**2. `"sort"` accepts exactly one key.** There is no secondary tiebreaker:

```json
"sort": {"fromDate": -1}              // ✅
"sort": {"fromDate": -1, "arr": -1}   // ❌ second key is not parsed
```

If two records tie on your sort field, you're back to arbitrary. Either pick a field that can't tie, or resolve the tiebreak upstream in the source system.

**3. There are no variables — every lookup is written out in full.** A formula needing the same lookup in four places contains it four times. Keep the options block **byte-identical** across repeats; a filter that drifts in one branch produces a formula whose branches disagree with each other and is nearly impossible to debug by reading.

**4. `IS_EMPTY(FIND(...))` conflates two different failures.** It returns true both when *no record matched the filters* and when *a record matched but the target field is blank*. If you need to tell them apart, add a `COUNT()` field with the same filters — `COUNT = 0` means no match; `COUNT > 0` with an empty `FIND` means the field is blank on the matched record.

**5. Direction is parent → child only.** Company can read Line Item, Conversation, License, Deal. None of those can read Company. No workaround inside a formula.

**6. Synced fields are read-only but filterable.** Fields pushed in from Salesforce or another source (often suffixed `– SF`) can be filtered and read, never written. Check the model's field metadata for `readonly: true` before assuming you can build on a field.

**7. String concatenation with `+` produces orphan separators.** `name + " Plan " + version` yields `" Plan 13"` when `name` is blank. Guard every operand, or split into separate fields.

**8. The custom-field prefix is `custom.`, not `custom_fields.`.** Planhat's REST API and some exports use `custom_fields`; the formula engine does not. `{"id": "custom_fields.My Field"}` matches nothing and throws no error.

**9. A field that doesn't exist fails silently.** Filtering on a custom field that was never created on that model returns an empty result identical to "no records matched". Before debugging logic, confirm the field actually exists on the target model in **Manage Fields** — and confirm it exists on *that* model specifically, since same-named fields are often defined on a neighbouring model instead.

**10. `filters` entries are AND-ed. There is no OR.** To match any of several values you must use the `any of` operator on a single filter — but `any of` is not accepted on every field. Array subfields (e.g. `users.id` on Conversation) accept only `equal to`, one value at a time, which means "any of these N people" cannot be expressed in a single formula at all. When you hit this, the answer is an automation that stamps a real stored field, not a cleverer formula.

**11. Embedded arrays are not relations.** `Conversation.users` is an array of `{isOwner, id, name}` objects, not a `manyToOne` foreign key. `through` needs a single relation field pointing at a target `_id`, so array-valued fields can't be traversed — you cannot hop Conversation → User to read `User.teams`. Check the model's `relationships` block before assuming a link is traversable; if the field isn't listed there, it isn't a relation.

**12. Filter values must match the stored type.** Booleans are `true` / `false` unquoted; picklist and text values are quoted strings and are case-sensitive. `"value": "true"` on a boolean field matches nothing.

**13. `<<field>>` substituted into a filter `value` needs quotes unless it's numeric or boolean.** The `<<>>` token is replaced with raw text *before* the surrounding JSON is parsed. A number (`<<custom.ARR – SF>>` → `150000`) or boolean (`<<custom.Is NRR>>` → `true`) is already a valid bare JSON token, so leave those unquoted. A string, date, or ObjectId field (`<<owner>>`, `<<customerFrom>>`, `<<custom.Segment>>`) substitutes as raw unquoted characters — `<<owner>>` becomes `6a44ef76c9aade50502936d5`, and `<<customerFrom>>` becomes something like `2026-01-01T00:00:00.000Z` — neither of which is a valid bare JSON literal. Left unquoted, saving the formula throws `SyntaxError: Unexpected token '<' ... is not valid JSON` (you'll see the literal `<<` in the error snippet, meaning substitution never even ran before the parser choked). Fix: wrap it — `"value": "<<owner>>"`, `"value": "<<customerFrom>>"`. Pattern D below was corrected for this; treat any older copy of that example (or anything hand-written before this note existed) as needing the same fix.

**14. The field's declared data type is separate from the formula text, and mismatches fail 100% silently — confirmed in production.** A field built with a `FIND(Conversation.date & {...})` formula but created as fieldType **Text** instead of **Date** returned blank on every single record, even ones with a confirmed matching Conversation. `get_model_action_parameters` on the model will show the mismatch directly (e.g. `{"id": "custom.Last AISE Email", "fieldType": "text"}` when the formula clearly returns a date) — check this before re-debugging the formula logic itself. Changing the formula text does nothing; the field's type has to be edited in Manage Fields.

**15. `DATES_MAXOF` (and likely `MIN`/`MAX` generally) does not treat a missing side as "ignore it" — confirmed in production.** If either input is empty, the whole function returns blank instead of falling back to the populated one. When either side can legitimately be empty (e.g. an account with sessions logged but no AISE-involved email yet, or vice versa), guard it:

```
IF(
  IS_EMPTY(<<custom.Field A>>),
  <<custom.Field B>>,
  IF(
    IS_EMPTY(<<custom.Field B>>),
    <<custom.Field A>>,
    DATES_MAXOF(<<custom.Field A>>, <<custom.Field B>>)
  )
)
```

Returns whichever side is populated when the other is empty, and the true max only when both have values. Same-model `IS_EMPTY()` works on custom fields exactly as it does on `FIND()` results (see gotcha #4).

**16. String literals in the formula body are UNQUOTED. Quotes render literally — confirmed in production 2026-09-12.** This contradicts the conventional `IF(cond, "value", "other")` shape and is the single fastest way to ship a field full of visible quote marks.

```
IF(<<custom.Flag>> == true, Everyone, Admins only)      ✅ renders: Everyone
IF(<<custom.Flag>> == true, "Everyone", "Admins only")  ❌ renders: "Everyone"
```

Multi-word literals are fine unquoted (`Spark not enabled` works). **An empty return is an empty position** — write nothing between the commas:

```
IF(IS_EMPTY(<<custom.Some Text Field>>), , Something)
```

**The exception, and it matters: values inside a cross-model options object keep their JSON quoting.** That block is parsed as JSON, so the rules there are unchanged — `{"op": "equal to", "field": {"id": "custom.X"}, "value": "ongoing"}` stays exactly as documented, with booleans and numbers bare per gotcha #12. Unquoting applies only to literals in the formula body: `IF` branches, string concatenation operands, and comparison values.

Patterns C above still shows the quoted form; treat it as needing the same correction.

**17. `IS_EMPTY()` returns true for a boolean field regardless of its value — confirmed in production 2026-09-12.** A formula guarded with `IF(IS_EMPTY(<<custom.Some Boolean – SNF>>), ...)` sends **every** record down the true branch, so the whole field renders as the empty case with no error and no clue why. This was diagnosed by putting `<<custom.Some Boolean – SNF>>` alone in a Text field, confirming it rendered `true`, and therefore isolating `IS_EMPTY` rather than the field reference as the fault.

**Do not use `IS_EMPTY()` on a boolean.** Two ways round it:

- **Test the value directly.** `== true` and `== false` both behave correctly. Order the branches so the fall-through is the answer you want for a null.
- **Use a co-populated string field as the presence sentinel.** `IS_EMPTY()` works correctly on strings. On Asset, `custom.Spark State – SNF` and `custom.Spark Enabled – SNF` are exactly co-populated — zero records carry one without the other — so the string can carry the "is this record in the feed at all" check that the boolean cannot. Verify co-population with a pair of `has value` / `has no value` filter queries before relying on any such sentinel.

**18. Arithmetic on `<<field>>` references inside a comparison does not evaluate — confirmed in production 2026-09-12.** A Mixed-state check written as

```
IF(<<custom.Count A>> + <<custom.Count B>> > 0, Mixed, ...)
```

returned **false** on a record where `Count A` was 1 and `Count B` was 0. Both fields rendered their values correctly on their own, so the references resolved — the `+` is the fault. Either it binds as `<<A>> + (<<B>> > 0)`, or it is being treated as the string-concatenation operator (see gotcha #7). The engine gives no error either way; the branch just silently never fires.

**Do not sum field references inside a condition.** Use boolean operators, which are in the documented set and behave correctly:

```
IF(<<custom.Count A>> > 0 || <<custom.Count B>> > 0, Mixed, ...)     ✅
```

Same applies to any `<<A>> - <<B>> > n` or `<<A>> * <<B>> == n` shape in a condition. If you genuinely need the arithmetic result, put it in its own Number formula field and compare **that** field — one value per field, per the guidance at the top of this skill.

Plain math on field references in the formula *body* (not inside a condition) is documented as working — e.g. `(<<custom.ARR – SF>> - <<custom.Target ARR>>) / <<custom.Target ARR>>`. The failure is specific to arithmetic being compared.

---

## Worked patterns

### A. Most recent matching child record (the deterministic default)

```
FIND(LineItem.custom.Plan Name – SF & {
  "filters": [
    {"op": "equal to", "field": {"id": "status"}, "value": "ongoing"},
    {"op": "equal to", "field": {"id": "custom.Default Project Plan – SF"}, "value": true}
  ],
  "sort": {"fromDate": -1},
  "limit": 1
})
```

Field type: **Text**. The `sort` is what makes this safe on accounts with overlapping active terms — early renewals, mid-term expansions, and multi-workspace accounts all produce several simultaneously-live child records.

### B. Same lookup, second value — a separate field

```
FIND(LineItem.custom.Plan Version – SF & {
  "filters": [
    {"op": "equal to", "field": {"id": "status"}, "value": "ongoing"},
    {"op": "equal to", "field": {"id": "custom.Default Project Plan – SF"}, "value": true}
  ],
  "sort": {"fromDate": -1},
  "limit": 1
})
```

Field type: **Text** (version identifiers like `12` / `13` are labels, not quantities — keep them Text so they don't get formatted as numbers).

Two fields with identical filters and sort are guaranteed to resolve to the *same* record, which is exactly what a concatenated single field was trying to achieve — without the nested `IF` tree.

### C. Only if you genuinely need one combined label

```
IF(
  IS_EMPTY(FIND(LineItem.custom.Plan Name – SF & { ...same block... })),
  "",
  FIND(LineItem.custom.Plan Name – SF & { ...same block... })
    + " v"
    + FIND(LineItem.custom.Plan Version – SF & { ...same block... })
)
```

**Note:** the quoted literals above predate gotcha #16 and are wrong as written — the empty return is an empty position and `" v"` would render its quotes. Return an empty result rather than a partial label when the name is missing — a bare version string with no plan name reads as corrupt data downstream.

### D. Count within the contract window

```
COUNT(Conversation & {
  "filters": [
    {"op": "equal to", "field": {"id": "type"}, "value": "🏗️ Architecting"},
    {"op": "more than", "field": {"id": "date"}, "value": "<<customerFrom>>"},
    {"op": "less than", "field": {"id": "date"}, "value": "<<renewalDate>>"}
  ]
})
```

Field type: **Number**. Same-model `<<>>` references can be used as filter *values* inside a cross-model query — but quote them (see gotcha #13). Unquoted, this exact formula throws a JSON syntax error the moment `customerFrom` or `renewalDate` has a real date in it.

### E. Most recent completed renewal date

```
FIND(License.renewalDate & {
  "filters": [
    {"op": "equal to", "field": {"id": "renewalStatus"}, "value": "renewed"}
  ],
  "sort": {"renewalDate": -1},
  "limit": 1
})
```

Field type: **Date**.

### F. Filtering on a same-model field that identifies "who owns this record" (e.g. the assigned rep)

```
FIND(Conversation.date & {
  "filters": [
    {"op": "equal to", "field": {"id": "type"}, "value": "email"},
    {"op": "equal to", "field": {"id": "users.id"}, "value": "<<owner>>"}
  ],
  "sort": {"date": -1},
  "limit": 1
})
```

Field type: **Date**. `owner` is an ObjectId field on the base model (e.g. Company) — quoted per gotcha #13. Note the limitation this doesn't solve: `Conversation.users` does not distinguish To/CC/BCC (confirmed against raw Gmail headers — a cc'd participant appears in `users` identically to a To recipient). This filter tells you "the assigned rep was somewhere on the thread," not "was directly addressed." True To/CC precision requires an automation reading the raw `parts[].toAddresses` / `ccAddresses` array, which formula filters can't reach (see gotcha #11 and `planhat-automations`).

---

## Debugging checklist

Work this in order — the causes are roughly ordered by how often they're the culprit.

1. **Every record blank, and the field type is right?** Check for `IS_EMPTY()` on a boolean (gotcha #17) — it is true for every record, so the whole field collapses to the empty branch. Isolate by putting the bare `<<field>>` in a Text field: if it renders a value, the reference is fine and `IS_EMPTY` is the fault.
2. **Values rendering with visible quote marks around them?** String literals in the formula body are unquoted — gotcha #16.
3. **A condition that should fire never fires, and the fields it reads look correct?** Check for `+` or other arithmetic between `<<field>>` refs inside the condition — gotcha #18. Rewrite with `||` / `&&`.
4. **Field data type matches the return value?** Text formula in a Number field renders blank with no error — check `fieldType` in `get_model_action_parameters` against what the formula actually returns (see gotcha #14). This has been the root cause more than once; check it before re-reading the formula text.
2. **Direction legal?** Confirm the formula lives on the parent model, not the child.
3. **Does the field exist on this model at all?** Check Manage Fields. A non-existent field returns empty with no error — this is the single fastest thing to rule out.
4. **Prefix is `custom.`?** Not `custom_fields.` (REST API form) and not `customFields.`.
5. **Filter field IDs stripped of the model name?** `{"id": "status"}`, not `{"id": "LineItem.status"}`.
6. **Filter values the right type and case?** Unquoted booleans, exact-case picklist strings.
7. **`SyntaxError: Unexpected token '<' ... is not valid JSON` on save?** A `<<field>>` replacement code in a filter `value` needs quotes — see gotcha #13. This is a save-time JSON parse failure, not a runtime formula bug.
8. **Blank result — no match, or blank field?** Add a temporary `COUNT()` with identical filters to tell them apart.
9. **Wrong record returned?** You have `"limit": 1` without `"sort"`, or your sort field ties. Check whether the account has overlapping active child records.
10. **Repeated lookups drifted?** Diff the options blocks character by character — a stray filter in one branch is the classic cause of a formula that works on most records and fails on a few.
11. **Custom model root key bare?** `subscription_line_item.field`, not `custom.subscription_line_item.field`.
12. **Still stuck?** Narrow to a single `FIND()` with one filter, confirm it returns anything at all on a record you know should match, then add filters back one at a time.
13. **Combining two formula fields with `MAX`/`MIN`/`DATES_MAXOF` and it's blank whenever one input is empty?** That's expected behavior, not a bug — see gotcha #15 for the `IF(IS_EMPTY(...))` guard.

---

## When a formula is the wrong tool

Move to an automation (see `planhat-automations`) when you need:

- Data flowing **child → parent**, or any hop a formula can't traverse
- A **written, stamped value** rather than a live computed one
- Multi-key sorting or tiebreaker logic the `sort` object can't express
- Any transformation needing real procedural logic — string parsing, loops, conditionals more than a couple of levels deep
- To/CC/BCC-precise participant matching on emails (see Pattern F) — the raw header split lives in `Conversation.parts`, which formula filters cannot reach

Formulas recalculate live and never go stale; that's their advantage. Reach for an automation only when the formula engine genuinely can't express the thing.
