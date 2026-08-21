# Initiative – Spark in Practice (Ignition Meetings)

**Status:** Active
**Window:** 2026-08-11 – TBD (Boge: "should not be more than 3 months")
**Internal owner:** Boge Sotirovski. David owns the data/flags, Jordan owns the reporting-scope decision.
**Source of truth:** [Ignition Meetings - Spark in Practice](https://pb.productboard.com/document/MTpQcm9kdWN0RG9jdW1lbnRCb2FyZDozZWUzMjZjMi1jMjI4LTRjOGMtYmY0OS01ZGU5M2QxYmJiNzE=) (Productboard doc). Slack: [#init-ignition-meetings](https://productboard.slack.com/archives/C0BNZ9JVDDM)
**Last synced from source:** 2026-08-21

This file is the AISE-facing operating summary plus the assistant rules derived from it. The PB doc is authoritative and has sections for AEs that are not reproduced here.

---

## 1. What the motion is

Take one job the customer already does, do it with them in Spark on their own data, and leave a skill and a scheduled task running in their workspace. Fourteen days later, check whether it held.

The problem it addresses is not dislike of Spark. It is that people try Spark once and do not come back:

- Nearly half of all Spark conversations are a single message
- 87% happen in one sitting
- About 5% are ever returned to
- Nine in ten makers who activate never return

Usage is rising because more people have access, not because anyone changed how they work. The Ignition Meeting is the intervention meant to change that.

This is a time-boxed experiment, not a standing motion.

---

## 2. Not the same thing as the Ignite conversion push

Two different motions, two different account lists. Do not mix them.

|  | Ignite conversion (Sept 1) | Spark in Practice (this) |
|---|---|---|
| The customer | Has **not** enabled Spark | Has **already** enabled Spark |
| The ask | Enable it, or tell us you are leaving | Use it |
| The conversation | Demo and conviction | Real work on their data |
| Account list | The conversion list (~86 accounts) | Tiered list, see § 3 |
| Ends | September 1 cutover | TBD |

If an account is on the conversion list, nothing in this file applies to it.

---

## 3. Scope

**The rule:** Spark enabled, not engaged, and an AISE assigned. No ARR floor. No V13 gate. Admin-only accounts are in scope – opening Spark to all makers is a good outcome to pursue in the room, but it is not a precondition and not what is measured. Accounts with no AISE assigned are out of scope entirely; there is no unassigned pile.

Tiering (source: Ignition prioritization, 12 August 2026 – 255 accounts, $20.00M, with 21 PM AI Index pilot accounts removed and excluded from outreach):

| Tier | Accounts | ARR | What it means |
|---|---|---|---|
| T1 – Priority outreach | 64 | $5.28M | Enabled and visible to makers, nobody ignited yet. **Book here first.** |
| T2 – Second wave | 29 | $2.51M | Ignited but not adopted. Same meeting, aimed at first-use → habit. |
| T3 – Adopted / transitioned | 9 | $1.18M | Already working this way. Sustain via normal adoption work, **not** this motion. |
| T4 – Open visibility first | 74 | $4.67M | Admin-only. Get Spark opened to makers before driving adoption. |
| T5 – Enablement motion | 66 | $4.64M | Spark not enabled. AI terms + enablement is the job. **Do not book an Ignition Meeting.** |
| T6 – No outreach | 13 | $1.71M | Churned or churning. Out of scope. |

Focus order is T1 then T2. **Tiers are guidance for prioritizing outreach, not strict sequencing** – layer in account context (a live exec conversation, a stalled renewal, a champion who just left) and say so in the account channel.

### Klara's book (30 accounts, $2.56M – T1 9 / T2 5 / T3 1 / T4 9 / T5 5 / T6 1)

**T1 – book these first**

| Rank | Account | AE | ARR | Health | Spark makers/wk |
|---|---|---|---|---|---|
| 3 | Kpler | Noah Isibor | $76.0k | Healthy | 0 |
| 6 | Mirakl | George Egerton | $42.9k | Healthy | 7 |
| 8 | Camunda | Mathieu Govoni | $33.0k | Contraction risk | 2 |
| 18 | EcoVadis | George Egerton | $120.0k | Contraction risk | 4 |
| 28 | Dr.Max Pharmacy Chain | George Egerton | $44.8k | Healthy | 1 |
| 36 | Configura | Mathieu Govoni | $47.6k | Contraction risk | 3 |
| 40 | SAP SE | Daniel Slavin | $644.1k | Contraction risk | 0 |
| 49 | SymphonyAI | George Egerton | $40.0k | Contraction risk | 1 |
| 61 | Emplifi | George Egerton | $55.0k | Contraction risk | 7 |

Emplifi already has an Ignition Meeting booked under the naming convention (one of only two across the whole motion, alongside Investorflow).

**T2 – second wave**

| Rank | Account | AE | ARR | Health | Spark makers/wk |
|---|---|---|---|---|---|
| 1 | S&P Global | Daniel Slavin | $159.7k | Healthy | 20 |
| 2 | Talend | George Egerton | $122.0k | Healthy | 9 |
| 6 | OutSystems | George Egerton | $173.0k | Healthy | 14 |
| 8 | Onfido | Mathieu Govoni | $72.0k | Healthy | 7 |
| 14 | CFC Underwriting | George Egerton | $36.0k | Healthy | 0 |

**T3 – sustain, no Ignition Meeting:** LumApps ($42.0k, Mathieu Govoni, healthy, 20 Spark makers/wk).

T4/T5/T6 accounts are not listed account-by-account in the source appendix. Ask Boge or David for the slice if needed.

### Accounts graduate into scope

The tier list is a snapshot from 12 August. A T5 account that enables Spark now meets the in-scope rule and should move. When that happens: flag it in the account channel so it lands in the funnel, and do not treat it as T5 any more.

- **weclapp GmbH** – Dominik Billing enabled Spark on 2026-08-20 after their IT Governance Board review. Was T5 (not enabled), now in scope. AE: Mathieu Govoni. Not yet in the appendix.

---

## 4. The three gates – the meeting is not booked until all three are met

| Gate | Owner | Why |
|---|---|---|
| AI terms signed and Spark enabled | AE + AISE | Without consent we cannot use their real data in the room and cannot measure afterwards |
| Discovery call completed | AE by default; AISE where they are running it | No discovery means no agreed job, which means a generic demo. That will not land |
| Enough in the workspace to work on | AISE, pre-work | The whole hour runs on their data. No fuel, no meeting |

**A meeting booked without these three is worse than no meeting. Push the date.**

Booking is two calls: call one is discovery and qualification, call two is the Ignition Meeting.

---

## 5. Meeting naming convention (mandatory)

Every qualifying meeting on the calendar:

```
Spark in Practice — [Account] × Productboard
```

This is the only way these meetings are identified. The title flows from the calendar invite into Gong and Salesforce, and the weekly forecast report reads it. **A meeting without this title does not exist in reporting.**

Two notes:

- The string contains an em dash and a multiplication sign. This is a **reporting key, not prose** – copy it verbatim. The em dash ban in `context/communication-style-guide.md` does not apply to it.
- Booking through Calendly will not produce this title. Rename the calendar event once the booking lands.

---

## 6. AISE pre-work – five things before the meeting

1. Run the workspace assessment skill ([Spark Skills Library](https://app.notion.com/p/productboard/Spark-Skills-Library-FDE-AISE-Copy-Paste-Reference-37997e9c7d4f814eaae6ce469fed712e)) to see what state their Productboard is in.
2. Get their data connections working. The meeting runs on their data, not a demo tenant.
3. Load their company knowledge into Spark. It sets the quality bar.
4. Build one skill against a job this customer actually does, using what discovery surfaced.
5. Confirm the product operations owner will be on the call, and that terms and access are in place.

Item 1 needs access to their workspace. The customer-side path is **Settings** (bottom of the main menu) → scroll to **"Allow access to your space for remote support"** → pick a **Duration** → **Allow access**. Admin makers only, 1 hour to 90 days, revocable at any time from the same place, off by default. It is impersonation-based – the representative logs in as a specific user at that user's permission level. [Support article](https://support.productboard.com/hc/en-us/articles/6610735397651-Allow-access-to-your-Productboard-workspace-for-remote-support). The article documents no restrictions, no read-only mode, and no audit logging or login notification, so **never claim read-only or auditable access** to a security-sensitive customer – check with Support or Security instead. Fallback if access is refused: run the assessment live at the top of the session on a shared screen, at the cost of hands-on time.

---

## 7. The meeting – 60 minutes

| Segment | Minutes | What happens |
|---|---|---|
| Open | 5 | Agenda. One question that makes them say what today's way of working costs them |
| Where you stand | 5 | Present the assessment result |
| Questions | 5 | Only the four below. Everything factual was answered in discovery |
| The moment | 35 | **They type. You coach.** Their workspace, the skill you built. Handle objections when raised |
| Close | 10 | Say the two-week goal out loud, name who owns it, book the day-14 check-in before anyone leaves |

**The meeting closes with two artifacts in their workspace: a customer-built skill, and a scheduled task that runs it on their cadence.** Whichever job you ran. Not a preference – it is the behavior separating power users from casual ones, and half of how the account is scored.

**Do not open on the five use cases they originally bought.** That is the sale we already made; reopening it burns the hour.

**Do not demo.** If you find yourself demoing Spark in an Ignition Meeting, you are in the wrong motion and the meeting should not have been booked.

### The four questions asked in the room

These constitute "value qualification answered" as a meeting output.

1. Confirm the product operations owner is here and will own the two-week goal.
2. On a scale of one to ten, is what you use AI for today making the whole organization faster, or just individuals faster on their own? Ask it against the job you are running, not in general.
3. Who maintains the skill or connection you built, and what happens when they leave? Ask whenever they already use an LLM for anything.
4. If this works, what does the team do with the time it gets back? **Write down their exact words – that becomes the goal.**

Skip size, seats and budget. It is in Salesforce and asking costs meeting time.

### The four objections

1. **"We already pay for Claude, why pay twice?"** Spark runs the same frontier models at the same cost and speed, and which model ran is inspectable. You are not buying the model, you are buying the workspace it runs in – feedback, customers, revenue, features and strategy joined up, every answer cited to real data.
2. **"We already built our own setup."** Keep it. The repo connects as a source, skills import, MCPs keep working. Leaving a DIY setup costs nothing.
3. **"Isn't this a wrapper on Claude?"** Do not assert. Point at the published head-to-heads and offer to run the same comparison on their data.
4. **"My PMs are already faster with generic AI."** Individually, yes. Use their own answer to question 2. Private prompts mean each PM prioritizes in isolation and judgment leaves when a person leaves – velocity up, institutional intelligence flat.

---

## 8. The fourteen days after

You own the outcome, not just the meeting. If the account shows no activity in the first week, reach out at **day 7** rather than waiting. Keep the day-14 check-in regardless.

---

## 9. How an account is scored

Measured 14 days after the meeting. An account passes when **both** are true.

| # | Condition | Passes when | Source |
|---|---|---|---|
| 1 | **Habit moment reached** | Someone in the account has created a custom skill and invoked it, **and** has either used a skill on 3+ separate days or set up a scheduled task | Amplitude: skill created, skill invoked, scheduled task created |
| 2 | **Repeat usage by the people in the room** | The makers who attended do real AI work (own prompt in chat, skill run, or skill completed) on 2+ separate days inside the 14 days, counted by distinct person × distinct day. Expressed as a **share of attendees**, not a headcount | Amplitude, filtered to meeting attendees |

Condition 1 is the existing habit-moment definition, unchanged – the same measure Product uses for a habitual space. Condition 2 is a share so it scales with meeting size: one enthusiastic person is not a healthy account.

**Also recorded, not scored:** the customer's own words on what makes Spark different, logged at the meeting and again at day 14. If we said it and they nodded, it does not count.

**Not measured here:** sustained Spark adoption (50% of makers at L2, or 25% at L3, in three of the last four weeks). Longer window, separate gate, normal book reporting. Do not conflate the two.

**Meeting volume is not a performance measure.** Activity is measured against the scoped list only, never against total capacity. Where the customer relationship is weak or non-existent, lean on AEs and FDEs to book and qualify.

---

## 10. What every meeting must produce

Three outputs, one record. If these are not logged, the meeting did not happen as far as reporting is concerned.

1. **Value qualification answered** – the four in-room questions, plus which job you ran and whether they already use an LLM for it.
2. **In-product goals set** – the two-week goal in the customer's own words, verbatim, with a named owner and the day-14 check-in on the calendar.
3. **A customer quote** – what they said that proves it landed.

**Where:** Salesforce **account** notes (not opportunity level – we are not creating opportunities for these, and doing so would distort win rates) for the duration of this motion. Moving to Planhat once implementation completes; you will be told when.

---

## 11. Assistant rules

Behavior changes for this plugin's agents while the initiative is `Active`. Applies only to accounts in scope (§ 3).

**Session prep (`/session-prep`, `session-prepper`)**
- Check the three gates in § 4 first. If any is unmet, say which one and recommend pushing the date rather than producing a prep brief.
- The agenda is the 5 / 5 / 5 / 35 / 10 shape in § 7. Never draft a demo or overview agenda for an in-scope account.
- Prep notes must carry the five pre-work items (§ 6) as a checklist, the specific job being run, and the four questions.

**Naming (conflicts with `context/session-naming-convention.md`)**
- Calendar event titles use `Spark in Practice — [Account] × Productboard` verbatim. The `[TYPE][N]` convention does **not** apply, and neither does the em dash ban. Flag the rename if the event was booked via Calendly.
- The Planhat/Notion session record still follows the normal naming convention. Only the calendar title is the reporting key.

**Session debrief (`/session-debrief`, `post-session-debrief`)**
- Capture all three required outputs (§ 10) and write them to Salesforce account notes for now, not Planhat, until told otherwise.
- Record the two-week goal **verbatim** with a named owner. Paraphrasing it defeats the measure.
- Create the day-14 check-in and a day-7 activity check as tasks.
- Verify the two closing artifacts exist (customer-built skill + scheduled task). If they do not, the meeting did not meet its own bar – say so plainly in the debrief.

**Email and message drafting (`/draft-email`, `/draft-followup`)**
- Never propose a Spark demo, overview, or walkthrough session to an in-scope account. Propose scoping → Spark in Practice session → day-14 check-in.
- Never ask the customer to run the workspace assessment skill. That is AISE pre-work and the result is presented in the "Where you stand" slot.
- When workspace access is needed, use the exact path and caveats in § 6.

**Reporting**
- Keep this motion's funnel (meetings booked / conducted / passing at day 14) separate from portfolio Spark adoption. Never present one as the other.

---

## 12. Open items (none of them blocks starting)

| Open item | Owner |
|---|---|
| Accuracy of the Spark-enabled flag, and whether gaps are workspace or account level. The scoped list moves when this is clean | David |
| The AI consent picture across the list | David |
| Whether reporting on an account stops at ignition or follows continued engagement, given the consumption element in pricing | Jordan |
| How this sits against the PM AI Index initiative – both score the same customer on similar things | Boge, with Chase, Branca & Danielle |
| Conversation-type modeling in Planhat. Boge proposed a session type; Klara proposed a **Conversation Initiatives** field instead (reportable, avoids a permanent type for a ≤3-month motion) and Boge agreed it works if reporting holds up. Not built yet | Klara |

---

## 13. Links

- [Ignition Meetings - Spark in Practice](https://pb.productboard.com/document/MTpQcm9kdWN0RG9jdW1lbnRCb2FyZDozZWUzMjZjMi1jMjI4LTRjOGMtYmY0OS01ZGU5M2QxYmJiNzE=) – the operating doc, authoritative
- [#init-ignition-meetings](https://productboard.slack.com/archives/C0BNZ9JVDDM) – motion channel
- [Boge's kickoff post in #org-gtm](https://productboard.slack.com/archives/C05TLRL8SEL/p1786448110996579)
- [Spark Skills Library (FDE/AISE copy-paste reference)](https://app.notion.com/p/productboard/Spark-Skills-Library-FDE-AISE-Copy-Paste-Reference-37997e9c7d4f814eaae6ce469fed712e)
- [Allow access to your workspace for remote support](https://support.productboard.com/hc/en-us/articles/6610735397651-Allow-access-to-your-Productboard-workspace-for-remote-support)
