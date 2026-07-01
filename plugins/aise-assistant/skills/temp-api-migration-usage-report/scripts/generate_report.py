#!/usr/bin/env python3
"""
Generate a Productboard API v1 usage report PDF from a Looker CSV export.
Temporary utility for the API v1 sunset (2026-07-08) — delete after.
"""
import argparse
import csv
import glob
import json
import os
import re
import sys
from collections import defaultdict
from pathlib import Path

HEX_ID = re.compile(r"^[0-9a-f]{8}$")
NUM_ID = re.compile(r"^\d{5,}$")
DROP_SUBSTRINGS = [
    "feature_links",
    "/notes/links/",
    "features.custom-fields",
    "/feature/{uuid}",
    "/note/{uuid}",
    "anonymous-onboarding",
]
DROP_METHODS = {"HEAD", "OPTIONS"}

GROUP_MAP = {
    "companies": "Companies & company custom fields",
    "notes": "Notes (feedback)",
    "features": "Features",
    "components": "Components & products",
    "products": "Components & products",
    "objectives": "Objectives, initiatives & key results",
    "initiatives": "Objectives, initiatives & key results",
    "key-results": "Objectives, initiatives & key results",
    "feature-statuses": "Configuration / system",
    "releases": "Configuration / system",
    "release-groups": "Configuration / system",
    "webhooks": "Configuration / system",
}

GROUP_ORDER = [
    "Companies & company custom fields",
    "Notes (feedback)",
    "Features",
    "Components & products",
    "Objectives, initiatives & key results",
    "Configuration / system",
    "Other",
]


def normalize_endpoint(ep: str) -> str:
    parts = ep.split("/")
    return "/".join("{uuid}" if (HEX_ID.match(s) or NUM_ID.match(s)) else s for s in parts)


def resource_group(ep: str) -> str:
    seg = ep.strip("/").split("/")[0]
    return GROUP_MAP.get(seg, "Other")


_SINGULAR = {
    "companies": "company",
    "feature-statuses": "feature status",
    "release-groups": "release group",
    "key-results": "key result",
    "webhooks": "webhook",
    "initiatives": "initiative",
    "objectives": "objective",
    "releases": "release",
    "features": "feature",
    "components": "component",
    "products": "product",
    "notes": "note",
}


def _singular(word: str) -> str:
    if word in _SINGULAR:
        return _SINGULAR[word]
    if word.endswith("ies"):
        return word[:-3] + "y"
    if word.endswith("ses") or word.endswith("xes"):
        return word[:-2]
    return word.rstrip("s")


def describe(ep: str, method: str) -> str:
    parts = [p for p in ep.strip("/").split("/") if p]
    base = _singular(parts[0]) if parts else "item"
    has_id = ep.rstrip("/").endswith("{uuid}")
    if (
        "links" in parts
        or "feature-links" in ep
        or (len(parts) > 1 and parts[-1] in ("features", "notes") and method == "POST")
    ):
        return "Link " + " / ".join(p for p in parts if p not in ("{uuid}",))
    if method == "GET":
        plural = parts[0] if parts else "items"
        return ("Get a single %s" % base) if has_id else ("List %s" % plural)
    if method == "POST":
        return "Create a %s" % base
    if method in ("PATCH", "PUT"):
        return "Update a %s" % base
    if method == "DELETE":
        return "Delete a %s" % base
    return ep


def is_dropped(normalized_ep: str, method: str, count: int) -> bool:
    if count < 3:
        return True
    if method in DROP_METHODS:
        return True
    if "/gw/" in normalized_ep or normalized_ep == "/plugin-integrations":
        return True
    if any(d in normalized_ep for d in DROP_SUBSTRINGS):
        return True
    return False


def _normalize_col(headers: list) -> dict:
    mapping = {}
    targets = {"endpoint": "Endpoint", "http method": "Http method", "count": "Count", "max timestamp": "Max Timestamp"}
    for h in headers:
        key = h.strip().lower()
        for target_lower, target_canonical in targets.items():
            if key == target_lower:
                mapping[target_canonical] = h
                break
    return mapping


def load_csv(csv_path: str):
    rows = []
    max_ts = ""
    with open(csv_path, newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        col_map = _normalize_col(reader.fieldnames or [])
        for r in reader:
            ep = r.get(col_map.get("Endpoint", "Endpoint"), "").strip()
            if not ep or ep.startswith("/v2/"):
                continue
            method = r.get(col_map.get("Http method", "Http method"), "").strip().upper()
            raw_count = r.get(col_map.get("Count", "Count"), "0").strip().replace(",", "")
            try:
                count = int(raw_count)
            except ValueError:
                count = 0
            ts = r.get(col_map.get("Max Timestamp", "Max Timestamp"), "").strip()
            if ts > max_ts:
                max_ts = ts
            rows.append((ep, method, count, ts))
    return rows, max_ts


def infer_customer_from_filename(csv_path: str) -> str:
    stem = Path(csv_path).stem
    # Strip common suffixes like -v1-usage, -api-logs, etc.
    stem = re.sub(r"[-_](v1|api|usage|logs|export|report|data).*$", "", stem, flags=re.IGNORECASE)
    return stem.replace("-", " ").replace("_", " ").title().strip()


def build_aggregations(rows):
    agg = defaultdict(lambda: [0, ""])
    for ep, method, count, ts in rows:
        k = (normalize_endpoint(ep), method)
        agg[k][0] += count
        if ts > agg[k][1]:
            agg[k][1] = ts
    return agg


def split_kept_dropped(agg):
    kept = {k: v for k, v in agg.items() if not is_dropped(k[0], k[1], v[0])}
    dropped = {k: v for k, v in agg.items() if is_dropped(k[0], k[1], v[0])}
    return kept, dropped


def focus_narrative(groups_by_name: dict, total: int, top_ep: str, top_count: int, top_pct: float) -> str:
    group_totals = {name: sum(v[0] for v in items.values()) for name, items in groups_by_name.items()}
    dominant = max(group_totals, key=group_totals.get) if group_totals else "Other"
    dominant_pct = round(100 * group_totals.get(dominant, 0) / total) if total else 0

    top_ep_clean = top_ep.replace("{uuid}", "{id}")

    if "companies" in top_ep and "custom-fields" in top_ep:
        framing = (
            "a CRM-style sync of company data — reading company custom fields like ARR, location, and segment. "
            "The v2 API collapses this: custom-field values are returned as fields directly on the entity "
            "(<code>/v2/entities/{id}</code>), which typically replaces several v1 calls with one."
        )
    elif dominant in ("Features", "Components & products", "Objectives, initiatives & key results") and group_totals.get(dominant, 0) > total * 0.3:
        framing = (
            "they're creating and editing their product hierarchy and its data from an upstream flow — "
            "likely a planning, roadmap, or PM-tooling sync pushing structure and field values into Productboard. "
            "In v2, entities replace features/components/objectives/initiatives as a unified hierarchy type "
            "(<code>/v2/entities/{id}</code>), so this migration is mostly a path rename with adjusted payloads."
        )
    elif dominant == "Notes (feedback)":
        framing = (
            "a feedback-inflow integration — pulling feedback in from customers and internal stakeholders "
            "and linking it to features. "
            "The v2 API preserves the notes concept (<code>/v2/notes</code>) with a largely compatible structure; "
            "the main change is how note–entity links are expressed."
        )
    else:
        framing = (
            "%s is %d%% of traffic — prioritize migrating it first." % (dominant, dominant_pct)
        )

    second = ""
    sorted_groups = sorted(group_totals.items(), key=lambda x: -x[1])
    if len(sorted_groups) >= 2:
        second_name, second_vol = sorted_groups[1]
        second_pct = round(100 * second_vol / total) if total else 0
        if second_pct >= 15 and second_name != dominant:
            second = (
                " %s is also notable at %d%% of traffic." % (second_name, second_pct)
            )

    return (
        "<p>The highest-volume endpoint is <code>%(ep)s</code> at %(pct)d%% of all v1 traffic. "
        "That pattern suggests %(framing)s%(second)s</p>"
        "<p>If you're not sure who owns this integration, start at "
        "<strong>Settings → Integrations → API keys</strong> — each token shows who created it and when. "
        "I'm happy to set up a sync with whoever owns the flow once you've traced it.</p>"
    ) % {"ep": top_ep_clean, "pct": top_pct, "framing": framing, "second": second}


def format_count(n: int) -> str:
    return f"{n:,}"


def method_badge(method: str) -> str:
    lc = method.lower()
    return f'<span class="m {lc}">{method}</span>'


def build_table_rows(kept: dict) -> tuple:
    by_group = defaultdict(dict)
    for (ep, method), (count, ts) in kept.items():
        group = resource_group(ep)
        by_group[group][(ep, method)] = [count, ts]

    group_totals = {g: sum(v[0] for v in items.values()) for g, items in by_group.items()}
    ordered_groups = sorted(by_group.keys(), key=lambda g: -group_totals.get(g, 0))

    rows_html = []
    for group in ordered_groups:
        items = by_group[group]
        rows_html.append(f'<tr class="grp"><td colspan="4">{group}</td></tr>')
        for (ep, method), (count, _) in sorted(items.items(), key=lambda x: -x[1][0]):
            what = describe(ep, method)
            rows_html.append(
                f"<tr>"
                f'<td class="ep"><code>{ep}</code></td>'
                f"<td>{method_badge(method)}</td>"
                f'<td class="cnt">{format_count(count)}</td>'
                f"<td>{what}</td>"
                f"</tr>"
            )
    return "\n".join(rows_html), by_group


HTML_TEMPLATE = """\
<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">
<title>{{customer}} — Productboard API v1 Usage Report</title>
<style>
  @page {{ size: 200mm 290mm; margin: 15mm 16mm 16mm; }}
  :root{{--ink:#1d1d27;--muted:#6b6b7b;--line:#e6e6ee;--pb:#ff5c39;--pb-soft:#fff1ec;
        --blue:#2f6df6;--blue-soft:#eef3ff;--amber:#b7791f;--amber-soft:#fdf6e7;--green:#1f8a5b;--green-soft:#e9f7f0;}}
  *{{box-sizing:border-box}} html,body{{margin:0;padding:0;}}
  body{{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,Arial,sans-serif;color:var(--ink);line-height:1.5;font-size:13px;}}
  .head{{border-bottom:2px solid var(--pb);padding-bottom:16px;margin-bottom:18px;}}
  .kicker{{font-size:11px;letter-spacing:.09em;text-transform:uppercase;color:var(--pb);font-weight:700;margin:0 0 6px;}}
  h1{{font-size:23px;margin:0 0 6px;}} .sub{{color:var(--muted);font-size:13px;margin:0;}}
  h2{{font-size:15px;margin:22px 0 9px;padding-bottom:6px;border-bottom:2px solid var(--pb-soft);}}
  p{{font-size:13px;margin:8px 0;}}
  .cards{{display:flex;gap:12px;margin:16px 0 6px;}}
  .card{{flex:1;background:#fafafe;border:1px solid var(--line);border-radius:9px;padding:12px 14px;}}
  .card .n{{font-size:21px;font-weight:700;line-height:1.1;}} .card .l{{font-size:11.5px;color:var(--muted);margin-top:3px;}}
  .callout{{border-radius:9px;padding:12px 15px;margin:13px 0;font-size:13px;}}
  .callout.blue{{background:var(--blue-soft);border:1px solid #d3e0ff;}}
  .callout.amber{{background:var(--amber-soft);border:1px solid #f3e4bf;}}
  .callout.green{{background:var(--green-soft);border:1px solid #cbebda;}}
  .callout b{{display:block;margin-bottom:3px;}}
  code{{font-family:"SFMono-Regular",Menlo,Consolas,monospace;background:#f0f0f6;padding:1px 5px;border-radius:5px;font-size:12px;color:#c0392b;}}
  table{{width:100%;border-collapse:collapse;margin:8px 0 4px;font-size:12.5px;}}
  th{{text-align:left;background:#fafafe;color:var(--muted);font-weight:600;padding:7px 9px;border-bottom:1px solid var(--line);font-size:11px;text-transform:uppercase;letter-spacing:.03em;}}
  td{{padding:7px 9px;border-bottom:1px solid var(--line);vertical-align:top;}}
  td.ep code{{color:#1d1d27;background:#eef0f7;}}
  td.cnt{{text-align:right;font-variant-numeric:tabular-nums;font-weight:600;white-space:nowrap;}}
  tr{{break-inside:avoid;}}
  .grp td{{font-weight:700;font-size:13px;background:#fff6f3;color:var(--pb);}}
  .m{{display:inline-block;font-size:10px;font-weight:700;padding:1px 6px;border-radius:4px;letter-spacing:.03em;}}
  .get{{background:#e9f7f0;color:var(--green);}} .post{{background:#eef3ff;color:var(--blue);}}
  .patch,.put{{background:var(--amber-soft);color:var(--amber);}} .delete{{background:#fdeceb;color:#c0392b;}}
  .foot{{color:var(--muted);font-size:11px;margin-top:20px;padding-top:13px;border-top:1px solid var(--line);}}
  a{{color:var(--blue);text-decoration:none;}} h2,.callout{{break-after:avoid;}}
</style></head><body>
  <div class="head">
    <p class="kicker">Productboard · API Migration</p>
    <h1>{customer} — API v1 usage report</h1>
    <p class="sub">Endpoints called against API v1 over the {period}, prepared for the v1 → v2 migration ahead of the 8 July 2026 sunset.</p>
  </div>
  <div class="cards">
    <div class="card"><div class="n">{total_requests}</div><div class="l">API v1 requests in {period_short}</div></div>
    <div class="card"><div class="n">{active_endpoints}</div><div class="l">endpoints in active use</div></div>
    <div class="card"><div class="n">{top_count}</div><div class="l">calls to a single endpoint ({top_pct}%)</div></div>
  </div>
  <div class="callout green"><b>Scope — this only affects integrations you built</b>
    Native Productboard integrations (e.g. <strong>Salesforce, Jira</strong>) are managed on our side and are <strong>not affected</strong>. This migration applies only to your own <strong>custom automations, Zapier flows, and custom-built integrations</strong> that call the API directly. The activity below is exactly that.</div>
  <div class="callout blue"><b>How to tell v1 from v2</b>
    It’s in the path. <strong>API v2 endpoints all start with <code>/v2/…</code></strong> (e.g. <code>/v2/entities/{{id}}</code>). Anything without that prefix — like <code>/features</code>, <code>/notes</code>, or <code>/companies/…</code> below — is v1 and needs migrating. Every endpoint in this report is v1.</div>
  <div class="callout amber"><b>Tracing usage back to a source</b>
    On our side we can see the endpoints being called, but <strong>we don’t have a mapping of which API token calls which endpoint</strong>. The reliable way to trace this is on your end: open <a href="{api_keys_url}">Settings → Integrations → API keys</a>, review each token (<strong>who created it and when</strong>) and contact that person to confirm where it’s used. As you migrate, build a simple map of <strong>which token belongs to which integration, what each does, and which tools are involved</strong>.</div>
  <h2>What you’re actually using</h2>
  <p>Grouped by resource and ranked by request volume. Counts combine identical calls (specific record IDs collapsed into <code>{{uuid}}</code>). One-off and exploratory calls are excluded — see the note at the end.</p>
  <table><thead><tr><th>Endpoint</th><th>Method</th><th style="text-align:right">Requests</th><th>What it does</th></tr></thead>
  <tbody>
  {table_rows}
  </tbody></table>
  <h2>Where to focus</h2>
  {focus_narrative}
  <p class="foot">Source: Productboard API v1 request logs, {period}. Counts normalize specific record IDs to <code>{{uuid}}</code>. Excluded: ~{dropped_endpoints} one-off / exploratory endpoints totaling ~{dropped_requests} requests (≈{dropped_pct}% of traffic) — single relationship lookups, manual test calls, internal gateway probes, and a few malformed paths — none representing an active integration. Full raw export available on request.</p>
</body></html>
"""


def generate_report(csv_path: str, customer: str, period: str, subdomain: str, out_dir: str) -> dict:
    rows, max_ts = load_csv(csv_path)
    if not rows:
        return {"skipped": True, "reason": "empty or no v1 rows after filtering"}

    if not period:
        period_short = "last 30 days"
        period = "last 30 days (through %s)" % max_ts if max_ts else "last 30 days"
    else:
        period_short = period

    agg = build_aggregations(rows)
    kept, dropped_agg = split_kept_dropped(agg)

    if not kept:
        return {"skipped": True, "reason": "no v1 endpoints remaining after noise filter"}

    total = sum(v[0] for v in kept.values())
    dropped_requests = sum(v[0] for v in dropped_agg.values())
    dropped_endpoints = len(dropped_agg)
    total_all = total + dropped_requests
    dropped_pct = round(100 * dropped_requests / total_all) if total_all else 0

    top_key, top_val = max(kept.items(), key=lambda x: x[1][0])
    top_ep, top_method = top_key
    top_count_n = top_val[0]
    top_pct = round(100 * top_count_n / total) if total else 0

    table_rows_html, by_group = build_table_rows(kept)
    narrative = focus_narrative(by_group, total, top_ep, top_count_n, top_pct)

    if subdomain:
        api_keys_url = "https://%s.productboard.com/settings/integrations/api-keys" % subdomain
    else:
        slug = re.sub(r"[^a-z0-9]", "", customer.lower())
        api_keys_url = "https://<your-workspace>.productboard.com/settings/integrations/api-keys"

    dominant_group = max(
        {g: sum(v[0] for v in items.values()) for g, items in by_group.items()}.items(),
        key=lambda x: x[1],
        default=("Other", 0),
    )[0]
    # Infer integration type label for summary
    if "companies" in top_ep and "custom-fields" in top_ep:
        integration_type = "CRM sync"
    elif dominant_group in ("Features", "Components & products", "Objectives, initiatives & key results"):
        integration_type = "Hierarchy/planning sync"
    elif dominant_group == "Notes (feedback)":
        integration_type = "Feedback inflow"
    else:
        integration_type = "Mixed / other"

    html = HTML_TEMPLATE.format(
        customer=customer,
        period=period,
        period_short=period_short,
        total_requests=format_count(total),
        active_endpoints=len(kept),
        top_count=format_count(top_count_n),
        top_pct=top_pct,
        api_keys_url=api_keys_url,
        table_rows=table_rows_html,
        focus_narrative=narrative,
        dropped_endpoints=dropped_endpoints,
        dropped_requests=format_count(dropped_requests),
        dropped_pct=dropped_pct,
    )

    os.makedirs(out_dir, exist_ok=True)
    customer_slug = re.sub(r"[^a-z0-9]+", "-", customer.lower()).strip("-")
    out_path = os.path.join(out_dir, "%s-API-v1-usage-report.pdf" % customer_slug)

    try:
        import weasyprint
        weasyprint.HTML(string=html).write_pdf(out_path)
    except ImportError:
        # Fallback: write HTML for manual conversion
        html_path = out_path.replace(".pdf", ".html")
        with open(html_path, "w", encoding="utf-8") as f:
            f.write(html)
        print("WeasyPrint not available — wrote HTML instead: %s" % html_path, file=sys.stderr)
        out_path = html_path

    return {
        "skipped": False,
        "customer": customer,
        "total_v1_requests": total,
        "active_endpoints": len(kept),
        "top_endpoint": top_ep,
        "top_pct": top_pct,
        "integration_type": integration_type,
        "out_path": out_path,
    }


def resolve_csv_paths(csv_arg: str) -> list:
    p = Path(csv_arg)
    if p.is_dir():
        return sorted(str(f) for f in p.glob("*.csv"))
    expanded = glob.glob(csv_arg)
    if expanded:
        return sorted(expanded)
    if p.exists():
        return [str(p)]
    return []


def main():
    parser = argparse.ArgumentParser(description="Generate Productboard API v1 usage report PDF")
    parser.add_argument("--csv", required=True, help="Path to CSV, directory, or glob pattern")
    parser.add_argument("--customer", default="", help="Customer name (optional — inferred from CSV if absent)")
    parser.add_argument("--period", default="", help="Reporting period label")
    parser.add_argument("--subdomain", default="", help="Productboard workspace subdomain")
    parser.add_argument("--out-dir", default="", help="Output directory for PDF(s)")
    args = parser.parse_args()

    csv_paths = resolve_csv_paths(args.csv)
    if not csv_paths:
        print("ERROR: no CSV files found at: %s" % args.csv, file=sys.stderr)
        sys.exit(1)

    # Resolve output dir
    out_dir_base = args.out_dir or ""
    if not out_dir_base:
        desktop = Path.home() / "Desktop" / "aise-assistant" / "reports"
        try:
            desktop.mkdir(parents=True, exist_ok=True)
            (desktop / ".write_test").touch()
            (desktop / ".write_test").unlink()
            out_dir_base = str(desktop)
        except Exception:
            out_dir_base = str(Path.cwd() / "outputs")

    single = len(csv_paths) == 1

    results = []
    for csv_path in csv_paths:
        customer = args.customer
        if not customer:
            # Try to read from CSV customer column
            try:
                with open(csv_path, newline="", encoding="utf-8-sig") as f:
                    reader = csv.DictReader(f)
                    headers = [h.strip().lower() for h in (reader.fieldnames or [])]
                    if "customer" in headers:
                        real_header = (reader.fieldnames or [])[headers.index("customer")]
                        for row in reader:
                            val = row.get(real_header, "").strip()
                            if val:
                                customer = val
                                break
            except Exception:
                pass
        if not customer:
            customer = infer_customer_from_filename(csv_path)
        if not customer:
            results.append({
                "csv": csv_path,
                "skipped": True,
                "reason": "could not identify customer (rename file to include the customer name, e.g. <customer>-v1-usage.csv)",
            })
            continue

        customer_slug = re.sub(r"[^a-z0-9]+", "-", customer.lower()).strip("-")
        out_dir = os.path.join(out_dir_base, customer_slug) if not args.out_dir else args.out_dir

        try:
            result = generate_report(csv_path, customer, args.period, args.subdomain, out_dir)
            result["csv"] = csv_path
            results.append(result)
        except Exception as e:
            results.append({"csv": csv_path, "skipped": True, "reason": "error: %s" % e})

    if single:
        r = results[0]
        if r.get("skipped"):
            print("SKIPPED — %s" % r.get("reason", "unknown reason"))
            sys.exit(1)
        else:
            print(r["out_path"])
    else:
        # Bulk mode: print summary table as JSON for the skill to format
        print(json.dumps(results, indent=2))


if __name__ == "__main__":
    main()
