---
name: spark-onepager
description: >
  Generate a customer-facing Spark AI Adoption Program one-pager as a styled,
  print-ready HTML file. Collects customer name and Calendly booking link, writes
  the file to the Cowork outputs folder, and presents it. Invoke with
  /spark-onepager or "Spark one-pager for [customer]".
---

Generate a customer-facing Spark AI Adoption Program one-pager as a styled, print-ready HTML file.

## Triggers

Use this skill when the user says any of:
- `/spark-onepager`
- "Spark one-pager for [customer]"
- "Spark program slide for [customer]"
- "generate a Spark onepager"
- "create the Spark adoption one-slider for [customer]"

## Inputs

Collect via AskUserQuestion if not already provided in the request:
1. **Customer name** — as it should appear in the slide header (e.g. `Acme Corp`, `Stripe`, `Onfido · Entrust`)
2. **Booking link** — full Calendly URL for the "Book a session" button

## Steps

1. If `customer_name` or `booking_link` are missing from the request, ask for them using AskUserQuestion (one question with both fields, or two separate questions if one is already known).
2. Generate the filename: lowercase the customer name, replace spaces and special characters with hyphens → `{slug}-spark-onepager.html` (e.g. `acme-corp-spark-onepager.html`, `onfido-entrust-spark-onepager.html`).
3. Write the HTML file to the Cowork outputs folder by substituting `{{CUSTOMER_NAME}}` and `{{BOOKING_LINK}}` in the template below. Everything else in the template is fixed — do not alter it.
4. Call `mcp__cowork__present_files` with the output path.
5. Reply with one sentence confirming it's ready and reminding the user that Cmd+P prints it cleanly in landscape.

## Notes

- The 5 sessions, all copy, stats, chips, PB logo, and CSS are fixed — never alter them.
- The `@media print` block is finalized — do not modify it. See the comment in the template for the reasoning.
- The presenter block (Klara Martinez / AI Success Engineer · Productboard) is always fixed.
- `zoom: 0.78` on `html` is the only Chrome-reliable way to scale a 1280px slide to fit landscape paper. Do not change it.

## Template

Replace only `{{CUSTOMER_NAME}}` and `{{BOOKING_LINK}}`. Write the entire file verbatim otherwise.

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Spark Adoption Program — {{CUSTOMER_NAME}}</title>
<style>
  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap');

  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

  :root {
    --pb-purple: #6C47FF;
    --pb-purple-dark: #4A2FCC;
    --pb-purple-light: #EDE9FF;
    --pb-orange: #FF6B35;
    --pb-navy: #0E0E2C;
    --pb-gray: #F4F3FF;
    --pb-text: #1C1C3A;
    --pb-muted: #6B7280;
    --pb-border: #E5E3F7;
    --radius: 12px;
    --radius-sm: 8px;
  }

  body {
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
    background: #f0eef8;
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: 100vh;
    padding: 24px;
    color: var(--pb-text);
  }

  /* === SLIDE WRAPPER — 16:9 === */
  .slide {
    width: 1280px;
    min-height: 720px;
    background: #ffffff;
    border-radius: 20px;
    overflow: hidden;
    box-shadow: 0 24px 80px rgba(108, 71, 255, 0.15), 0 4px 20px rgba(0,0,0,0.08);
    display: flex;
    flex-direction: column;
    position: relative;
  }

  /* === TOP STRIPE === */
  .stripe {
    height: 5px;
    background: linear-gradient(90deg, var(--pb-purple) 0%, var(--pb-orange) 100%);
  }

  /* === HEADER === */
  .header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 28px 48px 20px;
    border-bottom: 1px solid var(--pb-border);
  }

  .header-left {
    display: flex;
    align-items: center;
    gap: 16px;
  }

  .pb-logo {
    display: flex;
    align-items: center;
    gap: 10px;
  }

  .pb-logo-mark {
    width: 34px;
    height: 34px;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .pb-logo-mark svg {
    width: 34px;
    height: 34px;
  }

  .pb-logo-text {
    font-size: 16px;
    font-weight: 700;
    color: var(--pb-navy);
    letter-spacing: -0.3px;
  }

  .divider-v {
    width: 1px;
    height: 28px;
    background: var(--pb-border);
  }

  .customer-name {
    font-size: 14px;
    font-weight: 600;
    color: var(--pb-purple);
    letter-spacing: 0.3px;
    text-transform: uppercase;
  }

  .spark-badge {
    display: flex;
    align-items: center;
    gap: 8px;
    background: linear-gradient(135deg, var(--pb-purple) 0%, var(--pb-orange) 100%);
    color: white;
    padding: 8px 16px;
    border-radius: 100px;
    font-size: 13px;
    font-weight: 600;
    letter-spacing: 0.2px;
  }

  .spark-badge svg {
    width: 16px;
    height: 16px;
  }

  /* === HERO === */
  .hero {
    padding: 28px 48px 20px;
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: 32px;
  }

  .hero-text h1 {
    font-size: 30px;
    font-weight: 800;
    color: var(--pb-navy);
    line-height: 1.15;
    letter-spacing: -0.8px;
    margin-bottom: 8px;
  }

  .hero-text h1 span {
    background: linear-gradient(90deg, var(--pb-purple) 0%, var(--pb-orange) 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
  }

  .hero-text p {
    font-size: 15px;
    color: var(--pb-muted);
    line-height: 1.5;
    max-width: 520px;
  }

  .hero-stats {
    display: flex;
    gap: 16px;
    flex-shrink: 0;
  }

  .stat {
    background: var(--pb-gray);
    border: 1px solid var(--pb-border);
    border-radius: var(--radius);
    padding: 14px 20px;
    text-align: center;
    min-width: 100px;
  }

  .stat-number {
    font-size: 26px;
    font-weight: 800;
    color: var(--pb-purple);
    line-height: 1;
    margin-bottom: 4px;
  }

  .stat-label {
    font-size: 11px;
    font-weight: 500;
    color: var(--pb-muted);
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  /* === SESSIONS GRID === */
  .sessions-section {
    padding: 4px 48px 20px;
    flex: 1;
  }

  .section-label {
    font-size: 11px;
    font-weight: 700;
    color: var(--pb-muted);
    text-transform: uppercase;
    letter-spacing: 1px;
    margin-bottom: 14px;
  }

  .sessions-grid {
    display: grid;
    grid-template-columns: repeat(5, 1fr);
    gap: 12px;
  }

  .session-card {
    background: var(--pb-gray);
    border: 1.5px solid var(--pb-border);
    border-radius: var(--radius);
    padding: 18px 16px;
    position: relative;
    transition: border-color 0.2s;
    display: flex;
    flex-direction: column;
    gap: 10px;
  }

  .session-card:hover {
    border-color: var(--pb-purple);
  }

  .session-num {
    width: 28px;
    height: 28px;
    border-radius: 8px;
    background: linear-gradient(135deg, var(--pb-purple) 0%, var(--pb-purple-dark) 100%);
    color: white;
    font-size: 13px;
    font-weight: 700;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
  }

  .session-icon {
    font-size: 22px;
    line-height: 1;
  }

  .session-title {
    font-size: 13px;
    font-weight: 700;
    color: var(--pb-navy);
    line-height: 1.2;
  }

  .session-subtitle {
    font-size: 11.5px;
    color: var(--pb-muted);
    line-height: 1.4;
    flex: 1;
  }

  .session-output {
    display: flex;
    align-items: flex-start;
    gap: 6px;
    background: white;
    border: 1px solid var(--pb-border);
    border-radius: var(--radius-sm);
    padding: 8px 10px;
    margin-top: 2px;
  }

  .output-dot {
    width: 6px;
    height: 6px;
    border-radius: 50%;
    background: var(--pb-orange);
    flex-shrink: 0;
    margin-top: 3px;
  }

  .output-text {
    font-size: 10.5px;
    color: var(--pb-text);
    font-weight: 500;
    line-height: 1.35;
  }

  .sessions-grid {
    position: relative;
  }

  /* === BOTTOM BAND === */
  .bottom-band {
    padding: 16px 48px 24px;
    display: flex;
    align-items: stretch;
    gap: 16px;
    border-top: 1px solid var(--pb-border);
  }

  .included-block {
    flex: 1;
    background: var(--pb-gray);
    border: 1px solid var(--pb-border);
    border-radius: var(--radius);
    padding: 14px 18px;
  }

  .included-block h3 {
    font-size: 11px;
    font-weight: 700;
    color: var(--pb-muted);
    text-transform: uppercase;
    letter-spacing: 0.8px;
    margin-bottom: 10px;
  }

  .included-items {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
  }

  .chip {
    display: flex;
    align-items: center;
    gap: 5px;
    background: white;
    border: 1px solid var(--pb-border);
    border-radius: 100px;
    padding: 5px 10px;
    font-size: 11.5px;
    font-weight: 500;
    color: var(--pb-text);
  }

  .chip-dot {
    width: 7px;
    height: 7px;
    border-radius: 50%;
    background: var(--pb-purple);
    flex-shrink: 0;
  }

  .cta-block {
    background: linear-gradient(135deg, var(--pb-purple) 0%, var(--pb-purple-dark) 100%);
    border-radius: var(--radius);
    padding: 16px 20px;
    min-width: 210px;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    gap: 10px;
  }

  .cta-block h3 {
    font-size: 13px;
    font-weight: 700;
    color: white;
    line-height: 1.3;
  }

  .cta-block p {
    font-size: 11px;
    color: rgba(255,255,255,0.75);
    line-height: 1.4;
  }

  .cta-contact {
    display: flex;
    flex-direction: column;
    gap: 2px;
  }

  .contact-name {
    font-size: 12px;
    font-weight: 600;
    color: white;
  }

  .contact-role {
    font-size: 10.5px;
    color: rgba(255,255,255,0.65);
  }

  .arrow {
    position: absolute;
    top: 50%;
    transform: translateY(-50%);
    color: var(--pb-purple);
    font-size: 14px;
    opacity: 0.4;
    pointer-events: none;
  }

  /* =====================================================
     PRINT STYLES — DO NOT MODIFY
     zoom: 0.78 on html is the only Chrome-reliable way
     to scale a 1280px slide to fit landscape paper.
     transform: scale() does not affect layout dimensions.
     @page { size: 1280px 720px } is not honored by Chrome.
     padding: 20px on body shows the purple bg as margin
     and exposes the slide's border-radius rounded corners.
     ===================================================== */
  @media print {
    @page {
      size: landscape;
      margin: 0;
    }
    html {
      -webkit-print-color-adjust: exact !important;
      print-color-adjust: exact !important;
      zoom: 0.78;
    }
    body {
      display: flex !important;
      align-items: flex-start !important;
      justify-content: center !important;
      margin: 0 !important;
      padding: 20px !important;
      min-height: 0 !important;
      height: auto !important;
      background: #f0eef8 !important;
    }
    .slide {
      margin: 0 !important;
      border-radius: 20px !important;
      box-shadow: none !important;
    }
    a {
      color: #6C47FF !important;
      text-decoration: none !important;
    }
  }
</style>
</head>
<body>

<div class="slide">
  <!-- TOP STRIPE -->
  <div class="stripe"></div>

  <!-- HEADER -->
  <div class="header">
    <div class="header-left">
      <div class="pb-logo">
        <div class="pb-logo-mark">
          <svg width="28" height="28" viewBox="0 0 28 28" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M18.6666 4.66666L28 14L18.6666 23.3334L9.33325 14L18.6666 4.66666Z" fill="#0071E1"/>
            <path d="M18.6667 4.66666L9.33335 14L0 4.66666H18.6667Z" fill="#FFC600"/>
            <path d="M9.33335 14L18.6667 23.3333H0L9.33335 14Z" fill="#F84136"/>
          </svg>
        </div>
        <span class="pb-logo-text">productboard</span>
      </div>
      <div class="divider-v"></div>
      <span class="customer-name">{{CUSTOMER_NAME}}</span>
    </div>
    <div class="spark-badge">
      <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M13 2L4.5 13.5H12L11 22L19.5 10.5H12L13 2Z" fill="white" stroke="white" stroke-width="1.5" stroke-linejoin="round"/>
      </svg>
      Spark Adoption Program
    </div>
  </div>

  <!-- HERO -->
  <div class="hero">
    <div class="hero-text">
      <h1>From zero to fully adopted<br>on <span>Spark AI</span> &#8211; in 5 sessions.</h1>
      <p>Your dedicated AI Success Engineer guides a consistent group of ~5 PMs through a structured program &#8211; the same team across all 5 sessions &#8211; designed to make Spark part of how you work, not just another tool you tried.</p>
    </div>
    <div class="hero-stats">
      <div class="stat">
        <div class="stat-number">5</div>
        <div class="stat-label">Sessions</div>
      </div>
      <div class="stat">
        <div class="stat-number">30</div>
        <div class="stat-label">Days or less</div>
      </div>
      <div class="stat">
        <div class="stat-number">45</div>
        <div class="stat-label">Mins / session</div>
      </div>
    </div>
  </div>

  <!-- SESSIONS -->
  <div class="sessions-section">
    <div class="section-label">The 5-session journey</div>
    <div class="sessions-grid">

      <!-- Session 1 -->
      <div class="session-card">
        <div style="display:flex; align-items:center; gap:8px;">
          <div class="session-num">1</div>
          <span class="session-icon">🏗️</span>
        </div>
        <div class="session-title">Foundations &amp; Agent Knowledge</div>
        <div class="session-subtitle">Walkthrough of Spark + building your agent knowledge base &#8211; strategy docs, personas, competitive intel &#8211; and designing a workflow to keep it enriched over time.</div>
        <div class="session-output">
          <div class="output-dot"></div>
          <span class="output-text">Live agent knowledge base on your own data</span>
        </div>
      </div>

      <!-- Session 2 -->
      <div class="session-card">
        <div style="display:flex; align-items:center; gap:8px;">
          <div class="session-num">2</div>
          <span class="session-icon">🔍</span>
        </div>
        <div class="session-title">Feedback, Findings &amp; Opportunities</div>
        <div class="session-subtitle">Synthesize customer feedback into themes, findings, and opportunities &#8211; and build a repeatable process to turn raw signal into decisions.</div>
        <div class="session-output">
          <div class="output-dot"></div>
          <span class="output-text">Themed findings &amp; opportunities from your live queue</span>
        </div>
      </div>

      <!-- Session 3 -->
      <div class="session-card">
        <div style="display:flex; align-items:center; gap:8px;">
          <div class="session-num">3</div>
          <span class="session-icon">✍️</span>
        </div>
        <div class="session-title">Turning Ideas into Reality</div>
        <div class="session-subtitle">AI-assisted spec writing and feature definition that turns discovery into clear, aligned requirements &#8211; faster.</div>
        <div class="session-output">
          <div class="output-dot"></div>
          <span class="output-text">A Spark-drafted spec on a feature your team owns</span>
        </div>
      </div>

      <!-- Session 4 -->
      <div class="session-card">
        <div style="display:flex; align-items:center; gap:8px;">
          <div class="session-num">4</div>
          <span class="session-icon">📊</span>
        </div>
        <div class="session-title">Measuring Impact</div>
        <div class="session-subtitle">Use Spark for post-release review and outcome tracking &#8211; close the loop from idea to delivery to result.</div>
        <div class="session-output">
          <div class="output-dot"></div>
          <span class="output-text">Impact review built on a shipped feature</span>
        </div>
      </div>

      <!-- Session 5 -->
      <div class="session-card" style="border-color: var(--pb-purple); background: var(--pb-purple-light);">
        <div style="display:flex; align-items:center; gap:8px;">
          <div class="session-num" style="background: linear-gradient(135deg, var(--pb-orange) 0%, #e04e1e 100%);">5</div>
          <span class="session-icon">🚀</span>
        </div>
        <div class="session-title">Embed &amp; Review</div>
        <div class="session-subtitle">Sustain adoption, enable your internal champions, and review what's changed in how your team ships.</div>
        <div class="session-output" style="border-color: var(--pb-border);">
          <div class="output-dot" style="background: var(--pb-purple);"></div>
          <span class="output-text">Adoption review + champion-led next steps</span>
        </div>
      </div>

    </div>
  </div>

  <!-- BOTTOM BAND -->
  <div class="bottom-band">
    <div class="included-block">
      <h3>What's included</h3>
      <div class="included-items">
        <div class="chip"><div class="chip-dot"></div>Expert-led sessions with your AI Success Engineer</div>
        <div class="chip"><div class="chip-dot"></div>Spark Skills designed for your workflows</div>
        <div class="chip"><div class="chip-dot"></div>Customized to your PM workflows &amp; data</div>
        <div class="chip"><div class="chip-dot"></div>Real outputs on your data every session</div>
      </div>
    </div>
    <div class="cta-block">
      <div>
        <h3>Ready to get started?</h3>
        <p>Book session 1 directly &#8211; your program is ready to kick off whenever your team is.</p>
      </div>
      <a href="{{BOOKING_LINK}}" target="_blank" style="display:inline-flex; align-items:center; gap:7px; background:white; color: #6C47FF; font-size:12px; font-weight:700; padding:9px 14px; border-radius:100px; text-decoration:none; letter-spacing:0.2px; margin-top:2px;">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="3" y="4" width="18" height="17" rx="2.5" stroke="#6C47FF" stroke-width="2"/><path d="M3 9H21" stroke="#6C47FF" stroke-width="2"/><path d="M8 2V6" stroke="#6C47FF" stroke-width="2" stroke-linecap="round"/><path d="M16 2V6" stroke="#6C47FF" stroke-width="2" stroke-linecap="round"/></svg>
        Book a session
      </a>
      <div class="cta-contact">
        <span class="contact-name">Klara Martinez</span>
        <span class="contact-role">AI Success Engineer &#183; Productboard</span>
      </div>
    </div>
  </div>

</div>

</body>
</html>
```
