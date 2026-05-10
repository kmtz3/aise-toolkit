# Communication Style Guide — universal AISE-comms

> **Universal layer.** This guide covers PB-AISE comms patterns that apply to any user in this role (structure, tone-by-context, transformation rules, action/ownership conventions). Personal preferences (sign-offs, em-dash rules, language quirks, name-spelling) live in [`about/voice.md`](../about/voice.md) and **override** anything here.

Use this guide alongside `about/voice.md` to rewrite drafts, braindumps, or raw notes into clear, send-ready messages for **customers** and **internal colleagues**, primarily via **email** and **Slack**.

---

## 1. Voice & Tone

**Overall persona**

- Sound like a **friendly, organized, action-oriented technical expert**.
- Balance **warmth** and **clarity** – polite but direct, no fluff.
- Default to **semi-formal** with customers and broader internal audiences; more **casual** in 1:1 or small internal Slack chats.

**Tone by context**

- **Customer / senior stakeholder (email or Slack)**
  - Semi-formal, friendly, calm, and confident.
  - Focus on clarity, outcomes, and next steps.
  - Avoid slang and strong abbreviations; mild shorthand like "e.g." is fine.
- **Internal cross-functional / leadership**
  - Similar to customer tone, but slightly more candid and technical.
- **Close colleagues in Slack DMs**
  - Casual and conversational.
  - Light humor and mild slang/abbreviations are OK (e.g. "lol", "tbh", "qq", "TY").
  - Still be clear and respectful; don't overdo jokes or profanity.

---

## 2. Structure & Formatting

**General structure**

For anything non-trivial, structure the message clearly:

- Start with a short **greeting**: `Hi team,` / `Hi all,` / `Hi <Name>,`
- Then 1–3 short paragraphs for **context** and **main point**.
- Use **headings and bold labels** to break up complex information:
  - `**Context**`
  - `**What we did**`
  - `**Findings**`
  - `**Recommendations**`
  - `**Next steps**`
- Prefer **bulleted lists** and **numbered steps** over long paragraphs.

**Action / ownership clarity**

When there are follow-ups or decisions:

- Explicitly state **Owner** (who is responsible) and **Timing** (when it should happen).
- Example pattern:
  - `**Next steps**`
    - `Owner: <Name>`
    - `Timing: <When>`
    - `Action: <Clear description>`

**Technical content**

- Use **inline code formatting** for technical terms, endpoints, fields, and code-ish things: e.g. `v2 endpoint`, `companyId`, `/notes/export`.
- For more complex examples (API calls, payloads), use **code blocks**.

---

## 3. Email Guidelines

**Style**

- Professional, clear, and concise; avoid corporate buzzwords.
- Short intro, then quickly move into the substance.
- Close with a short, warm sign-off — see `about/voice.md` for the user's specific sign-off preferences per audience.

**Recommended email layout**

1. **Greeting**
2. **Context** – 1–2 sentences explaining why you're writing and tying back to previous conversations or sessions.
3. **What we did / Where we are** – clear summary of actions taken, status, or findings.
4. **Details (if needed)** – bullets for key points; include links to resources, boards, recordings, docs as needed.
5. **Next steps** – explicit bullets with owner and timing.
6. **Questions / Call for input** – invite clarifications or choices if needed, but stay focused.
7. **Sign-off**

**Level of detail**

- Default to **high signal, medium detail** – enough that a busy PM or stakeholder can understand quickly, without over-explaining basics they already know.
- For technical topics (API, migrations, workspace configuration): be precise and explicit, explain the "why" in 1–2 sentences, and briefly describe what any linked docs are for.

---

## 4. Slack / Messaging Guidelines

**Team channels & cross-functional discussions**

- Keep messages **short and scannable**.
- Use a brief opener when needed (e.g. `Hi team, quick update on X:`).
- Use bullets for updates, decisions, and action items; bold labels to highlight structure.
- If asking for help or a decision, clearly state what you need and by when. Example:
  `**Request** – Could you confirm if we can switch the feedback email by Friday? That will unblock the final migration run.`

**1:1 or small group DMs**

- More relaxed, but still purposeful.
- OK to use shorthand (`qq`, `tbh`, `lol`) and light humor.
- When discussing complex work, still organize: `**Context**` / `**My take**` / `**What I'm proposing**`.

---

## 5. Handling Uncertainty & Questions

When the input draft is unclear or missing information:

- **Make reasonable assumptions** and state them briefly: `I'm assuming X; if that's wrong, adjust wording accordingly.`
- Suggest clear options rather than being vague: "We can either A (faster, less precise) or B (slower, more robust)."

Avoid:

- Long hedging blocks.
- Overly apologetic language.
- Overly strong or absolute claims when there isn't enough evidence.

---

## 6. Transforming Drafts & Raw Thoughts

When given rough notes, partial sentences, or a messy brain dump:

1. **Clarify intent (internally)** – infer whether this is a customer email, internal email, Slack channel post, or Slack DM. Choose tone accordingly.
2. **Identify key points** – what was decided, what was done, what is being proposed, what is needed from others.
3. **Restructure** – add greeting (unless it's a short DM reply); organize into: Context → Main point → Details → Next steps / Ask.
4. **Tighten wording** – remove repetition and filler; keep sentences concise; prefer plain language over jargon.
5. **Make it send-ready** – ensure the message answers **why** you're writing, states **what** has been done/decided, and clarifies **what's needed next**, by whom, and by when.

**Do NOT:**

- Change the underlying decisions or commitments.
- Over-polish into something stiff or generic; keep it sounding like a real person.
- Invent new promises, dates, or scope that weren't implied.

---

## 7. Quick Style Checklist

Before finalizing, ensure the rewritten message:

- Uses the **right tone** for the audience (customer vs internal; channel vs DM).
- Has a **clear structure** with bolded labels and/or bullets for multi-part content.
- States **context** in 1–3 sentences max.
- Clearly calls out **next steps**, **owners**, and **timelines** where relevant.
- Uses **plain, direct language** with enough but not excessive detail.
- Uses **inline code** or code blocks for technical references where appropriate.
- Ends with a sign-off appropriate to the audience (per `about/voice.md`).
- Punctuation conforms to the user's preferences in `about/voice.md` (em-dashes, semicolons, etc.).

---

## 8. User-specific overrides

Personal preferences (sign-offs, em-dash rules, semicolons, casual register, English variant, name-spelling, forbidden phrases) live in [`about/voice.md`](../about/voice.md). Always cross-reference both files before producing any draft on the user's behalf — `voice.md` wins where they differ.
