# Deck Guidelines

> Applies to **any request for a deck, slides or a presentation**, whether it comes from a skill, an agent or a conversational ask. Replaces the retired `/create-deck` skill (single-file HTML on a hand-rolled template), which ignored the org design system.

---

## 1. Routing

Every deck is a Claude **Slides artifact** built on the org's default design system.

1. Find the Slides type with `Artifact` `action:"list"`, `scope:"types"` (known URL: `https://claude.ai/artifact/8jTsAFQMFDb2oA8MsPJ2eL`).
2. Find the design system with `Artifact` `action:"list"`, `type:"Design System"`. Use the row marked default, **Productboard Slide Deck Kit** (`https://claude.ai/artifact/4eucmttHvmBNbH85Nbhsaw`), without asking.
3. Install that design system in the deck under the namespace `pb` (`project/ds/pb/...`):
   - `tokens.json`
   - Proxima Nova Regular, Semibold and Bold TTFs. Declare one `faces` entry per weight: "Proxima Nova", "Proxima Nova Semibold", "Proxima Nova Bold", each pointing at its own TTF. Set `font-weight:400` on the Semibold and Bold families so the browser doesn't apply faux bold.
   - `background-light.png`, `background-dark.png`, `logo.png` and the two logotypes (`logotype-light.png`, `logotype-dark.png`).
4. Make a `.pptx` or a hand-built HTML file **only when the user names that format**. Never fall back to a home-grown template, navy palette or Inter.

## 2. Deliverable and sharing

- The deliverable is the **Slides artifact link**. Never save to `~/Desktop/...`; cloud sessions can't reach it.
- The artifact is private by default. Remind the user to share it with the AE (and anyone else presenting) from the Share menu.
- For a customer session, link the deck into the session's Planhat record as `ArtifactType` `Deck` per `context/session-artifact-convention.md`.

## 3. Slide format

- Canvas 1920×1080. Every style inline. No font smaller than 24px.
- Pin the background image first on every slide: `position:absolute; left:0; top:0; width:1920px; height:1080px; object-fit:cover`. Light background for content slides, dark for dividers.
- Logo mark at `right:56px; bottom:52px; width:44px`. The cover uses `logotype-light.png` and **no** corner mark.
- Eyebrows: 24px Proxima Nova Semibold, uppercase, `#6F778A`. Titles: 72px Proxima Nova Bold, `#1B252D`.
- Three-point content slides get icon tiles: a 72px `#DDEEFE` tile with the icon in `#004EA8`.

## 4. Context sources

Pull these before planning slides (same retrieval rules as `context/project-instructions.md` §3; never ask the user to paste):

- **Planhat session Task** (`action` contains the meeting title): `description` (agenda), `custom.Prep Notes`, `endusers` (attendees).
- **Planhat Company** `custom.Next Step`.
- **Notion meeting transcript** of the AE/AISE sync, if there was one.
- **Slack**: the agenda message from the AE.
- **Calendly link** for the resources slide: the presenting AISE's Planhat User field `custom.AISE Calendly Spark`.

## 5. Content rules

- **Names come from Planhat, never from transcript spelling.** Customer attendee names are taken from the End Users on the session Task. If a transcript spells a name differently, the Planhat record wins.
- **PB team slide = Productboard people presenting on the call** (typically AE + AISE). Leave the program sponsor and other non-attendees off unless the user asks for them.
- Title the AISE **"AI Success Engineer"**, never "Solutions Architect".
- The demo card is called **"Skills and automations"**.
- Frame the post-demo prompt as **"What is the first job you would hand to Spark?"**

## 6. Team photos

Headshots live in the Figma file `PgFlvJdhPJlMSPNN65PdES` ("Assets – SA Prototypes for FigJam"):

| Group | Frame node |
|---|---|
| Solution Architects (AISEs) | `181:634` |
| Account Executives | `184:780` |
| PSPs | `184:625` |
| Program Sponsors | `189:580` |

Each person is a symbol named `Name=<Full Name>, Position=<Title>`. Call Figma `download_assets` on that symbol's node and take the **raw image**, not the card export. Crop it square and upload it as a deck asset. Render it as a 180px circle on a white card, with the name, the role in primary blue, and one line on what they own in the program.

If a person isn't in the file, use an initials circle; don't pull photos from elsewhere.

## 7. Kickoff / Spark kickoff recipe

Default outline for a kickoff deck. It is the old FigJam onboarding kickoff board (Intros → Goals & Milestones → Sessions → Action Items → Resources) redesigned as slides. Adapt the order to the meeting agenda when one is provided (calendar description, Task `description` or the AE's Slack agenda).

1. Cover (logotype, no corner mark)
2. Agenda: numbered tiles with minutes per item
3. PB team intro (call attendees only, see §5)
4. Customer team intro (live-type, see §8)
5. Context reset: what we know + open questions
6. Dark divider: "Productboard Spark" (AE section)
7. Spark framing: 3 points with icon tiles
8. Demo map
9. Dark divider: "AI Success program"
10. Mission: the three disciplines (§9)
11. The five sessions, on one slide (§9)
12. Maker group (live-type)
13. Goals (live-type)
14. Key dates (live-type)
15. Action items (live-type)
16. Resources (Calendly link, Support Hub `https://support.productboard.com/hc/en-us`)

## 8. Live-type working slides (required for kickoff decks)

These slides are filled in by the AISE during the call, in place in the Slides editor. Placeholder text is grey `#9AA3B5`: "Type here", "Type name", "Type date".

- **Customer team:** one card per attendee with three fields: Role and team / Productboard today / Wants from Spark.
- **Maker group:** a Name | Role and team table, plus an "Anchor use case" box.
- **Goals:** a 2×3 grid of lilac sticky cards (`#F7EEFB`, label `#531787`), like the FigJam goals grid.
- **Key dates:** Milestone | Owner | Date | Status, including the enablement / session 1 date row.
- **Action items:** Action | Owner | Due, with 2 blank rows.

## 9. AI Success program content

**Source of truth:** the "AI Success Engineering | Services | 2026" Google Slides deck (ID `1Pwf_qWI6ke4jPxPWRgBd7RKJJ5V32PJaIvCHzBR0zZc`). Re-read it with Google Slides `read_presentation` at build time when it's reachable; the copy below is a snapshot from 2026-10-13 and loses to the live deck.

**Mission: "Change is hard. We support you every step of the way."** Three disciplines:
- **Consultative Architecting**: we design the workspace around how your teams actually work.
- **Product ops & Governance**: clear ownership, rituals and standards that keep the system healthy.
- **Enablement & Adoption**: training and change support that turns access into daily habit.

**Five sessions on ONE slide.** The source deck splits them across two slides; the deck puts them in six columns: Pre-program + Sessions 1–5. Each column has a title, a one-line description and three "You leave with" bullets. Mark the Pre-program column "today" in a kickoff; it isn't counted as a session. Where the source lists four bullets, keep the three most relevant to the customer's anchor use case (default: the first three). Strip underneath: **"After session 5: monthly check-in; same maker group every session."**

| Column | Title | Description | You leave with |
|---|---|---|---|
| Pre-program | Kick-off & discovery | A deep dive into your as-is processes to design a bespoke experience. | A mapped view of your current process · A bespoke session plan and participants · Agreed success criteria for the program |
| Session 1 | Foundations & setup | Connect your data and learn the core concepts. | Spark configured on your own data · Agent knowledge live and verified · At least one source or MCP connected · A shared workflow focus for sessions 2–5 |
| Session 2 | Surface what matters | Turn feedback analysis into a real decision. | A themed analysis grounded in real feedback · The analysis mapped to a live decision · The workflow memorized (you ran it) · One concrete "Spark saved me X hours" example |
| Session 3 | Turn ideas into reality | Idea → brief → spec, ready to build. | A lightweight competitive snapshot · A reviewed, build-ready spec on the entity · The idea → spec workflow memorized · A clear view of the drafting time this replaces |
| Session 4 | Measure impact | Review what shipped and drive the 2.0. | A structured view of achieved vs. intended · A Spark-generated 2.0 brief grounded in real data · The full loop closed: idea, ship, measure, iterate · A repeatable pattern for post-launch reviews |
| Session 5 | Embed & roll out | Make it stick and scale it to the team. | A rollout kit: playbook, quickstarts, training agenda · Custom and scheduled skills for your team · Named champions who can onboard new PMs · A plan for what happens after the program |
