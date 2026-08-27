#!/usr/bin/env python3
"""Convert a Collegians weekly time-trial PDF into a responsive HTML page."""

from __future__ import annotations

import argparse
import html
import json
import re
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

import pdfplumber


ROW_RE = re.compile(
    r"^(?P<position>\d+)\s+(?P<name>.+?)\s+(?P<group>[A-Z](?:/[A-Z])?)\s+"
    r"(?P<time>\d{1,2}:\d{2}(?::\d{2})?)\s+(?P<pace>\d{1,2}:\d{2})$"
)
ROUTE_RE = re.compile(r"^(?P<distance>\d+(?:\.\d+)?)\s*km\s+(?P<count>\d+)\s+finishers$", re.I)
COMPARISON_RE = re.compile(
    r"^(?P<distance>\d+(?:\.\d+)?)\s*km\s+(?P<this_week>\d+)\s+"
    r"(?P<last_week>\d+)\s+(?P<change>[+-]?\d+)\s+(?P<average>\d{1,2}:\d{2})$",
    re.I,
)


@dataclass
class Route:
    distance: str
    stated_count: int
    rows: list[dict[str, str]]


def clean_text(value: str) -> str:
    return value.replace("\ufffd", " ").replace("\u00b7", " ").strip()


def extract_lines(pdf_path: Path) -> list[list[str]]:
    with pdfplumber.open(pdf_path) as document:
        if not document.pages:
            raise ValueError("The PDF contains no pages.")
        pages: list[list[str]] = []
        for page in document.pages:
            text = page.extract_text(x_tolerance=2, y_tolerance=3) or ""
            pages.append([clean_text(line) for line in text.splitlines() if clean_text(line)])
        return pages


def parse_pdf(pdf_path: Path, result_date: str) -> dict:
    pages = extract_lines(pdf_path)
    first_page = pages[0]
    if not first_page:
        raise ValueError("No readable text was found on the first PDF page.")

    title = first_page[0]
    visible_date_match = next(
        (re.search(r"\b\d{4}-\d{2}-\d{2}\b", line) for line in first_page if re.search(r"\b\d{4}-\d{2}-\d{2}\b", line)),
        None,
    )
    if visible_date_match and visible_date_match.group(0) != result_date:
        raise ValueError(
            f"The selected date is {result_date}, but the PDF displays {visible_date_match.group(0)}."
        )
    event_name = re.sub(r"\s+(?:weekly\s+)?results(?:\s+.*)?$", "", title, flags=re.I).strip()
    if not event_name:
        event_name = "Herman's Delight"

    comparison: list[dict[str, str]] = []
    comparison_total: dict[str, str] | None = None
    comparison_date = ""
    faster = slower = same = new = dropped = None
    for line in first_page:
        if match := re.search(r"This week vs\s+(\d{4}-\d{2}-\d{2})", line, re.I):
            comparison_date = match.group(1)
        if match := COMPARISON_RE.match(line):
            comparison.append(match.groupdict())
        if match := re.match(r"^Total\s+(\d+)\s+(\d+)\s+([+-]?\d+)", line, re.I):
            comparison_total = {
                "this_week": match.group(1),
                "last_week": match.group(2),
                "change": match.group(3),
            }
        if match := re.search(r"Faster:\s*(\d+)\s+Slower:\s*(\d+)\s+Same:\s*(\d+)", line, re.I):
            faster, slower, same = map(int, match.groups())
        if match := re.search(r"New this week:\s*(\d+)\s+Dropped from previous week:\s*(\d+)", line, re.I):
            new, dropped = map(int, match.groups())

    routes: list[Route] = []
    for page_lines in pages[1:]:
        if not page_lines:
            continue
        route_match = next((ROUTE_RE.match(line) for line in page_lines if ROUTE_RE.match(line)), None)
        if not route_match:
            continue
        rows: list[dict[str, str]] = []
        for line in page_lines:
            if row_match := ROW_RE.match(line):
                rows.append(row_match.groupdict())
        distance = route_match.group("distance")
        stated_count = int(route_match.group("count"))
        if len(rows) != stated_count:
            raise ValueError(
                f"The {distance} km page says {stated_count} finishers, but {len(rows)} result rows were read."
            )
        routes.append(Route(distance=distance, stated_count=stated_count, rows=rows))

    if not routes:
        raise ValueError(
            "No time-trial route tables could be read. Use a PDF exported in the approved weekly results layout."
        )

    parsed_date = datetime.strptime(result_date, "%Y-%m-%d")
    total_finishers = sum(route.stated_count for route in routes)
    route_note = " and ".join(f"{route.distance} km" for route in routes)
    return {
        "title": title,
        "event_name": event_name,
        "date": parsed_date,
        "comparison_date": comparison_date,
        "comparison": comparison,
        "comparison_total": comparison_total,
        "faster": faster,
        "slower": slower,
        "same": same,
        "new": new,
        "dropped": dropped,
        "routes": routes,
        "total_finishers": total_finishers,
        "note": f"{route_note} - {total_finishers} finishers",
    }


def average_time(rows: list[dict[str, str]]) -> str:
    seconds: list[int] = []
    for row in rows:
        parts = [int(part) for part in row["time"].split(":")]
        value = parts[0] * 60 + parts[1] if len(parts) == 2 else parts[0] * 3600 + parts[1] * 60 + parts[2]
        seconds.append(value)
    mean = round(sum(seconds) / len(seconds))
    if mean >= 3600:
        return f"{mean // 3600}:{(mean % 3600) // 60:02d}:{mean % 60:02d}"
    return f"{mean // 60}:{mean % 60:02d}"


def e(value: object) -> str:
    return html.escape(str(value), quote=True)


def render_route(route: Route, index: int) -> str:
    rows = "\n".join(
        "<tr>"
        f'<td class="numeric">{e(row["position"])}</td>'
        f'<th scope="row">{e(row["name"])}</th>'
        f'<td>{e(row["group"])}</td>'
        f'<td class="numeric">{e(row["time"])}</td>'
        f'<td class="numeric">{e(row["pace"])}</td>'
        "</tr>"
        for row in route.rows
    )
    return f"""<section class="result-section" aria-labelledby="route-{index}-title">
<div class="result-section-head"><h2 id="route-{index}-title">{e(route.distance)} km.</h2><p>{route.stated_count} finishers &middot; Average time {e(average_time(route.rows))}</p></div>
<div class="result-table-wrap">
<table class="result-table">
<caption>{e(route.distance)} kilometre results with {route.stated_count} finishers</caption>
<thead><tr><th scope="col">Pos</th><th scope="col">Name</th><th scope="col">J/W/L</th><th scope="col">Time</th><th scope="col">Pace (min/km)</th></tr></thead>
<tbody>
{rows}
</tbody>
</table>
</div>
</section>"""


def render_comparison(data: dict) -> str:
    if not data["comparison"]:
        return ""
    rows = "\n".join(
        f'<tr><th scope="row">{e(item["distance"])} km</th>'
        f'<td class="numeric">{e(item["this_week"])}</td>'
        f'<td class="numeric">{e(item["last_week"])}</td>'
        f'<td class="numeric">{e(item["change"])}</td>'
        f'<td class="numeric">{e(item["average"])}</td></tr>'
        for item in data["comparison"]
    )
    parsed_total = data["comparison_total"]
    this_total = int(parsed_total["this_week"]) if parsed_total else sum(int(item["this_week"]) for item in data["comparison"])
    last_total = int(parsed_total["last_week"]) if parsed_total else sum(int(item["last_week"]) for item in data["comparison"])
    change = int(parsed_total["change"]) if parsed_total else this_total - last_total
    comparison_label = data["comparison_date"] or "the previous published week"
    notes: list[str] = []
    if data["faster"] is not None:
        notes.extend([f'Faster: {data["faster"]}', f'Slower: {data["slower"]}', f'Same: {data["same"]}'])
    if data["new"] is not None:
        notes.extend([f'New this week: {data["new"]}', f'Dropped from previous week: {data["dropped"]}'])
    note_html = f'<p class="result-note">{e(" - ".join(notes))}</p>' if notes else ""
    return f"""<section class="result-section" aria-labelledby="comparison-title">
<div class="result-section-head"><h2 id="comparison-title">Weekly comparison.</h2><p>This week compared with {e(comparison_label)}.</p></div>
<div class="result-table-wrap">
<table class="result-table">
<caption>Weekly comparison by distance</caption>
<thead><tr><th scope="col">Distance</th><th scope="col">This week</th><th scope="col">Last week</th><th scope="col">Change</th><th scope="col">Average time</th></tr></thead>
<tbody>
{rows}
<tr class="total-row"><th scope="row">Total</th><td class="numeric">{this_total}</td><td class="numeric">{last_total}</td><td class="numeric">{change:+d}</td><td>-</td></tr>
</tbody>
</table>
</div>
{note_html}
</section>"""


def render_html(data: dict, public_title: str, pdf_web_path: str) -> str:
    date: datetime = data["date"]
    month_day = date.strftime("%d %B").lstrip("0").upper()
    distances = " and ".join(f"{route.distance} km" for route in data["routes"])
    route_sections = "\n\n".join(render_route(route, index + 1) for index, route in enumerate(data["routes"]))
    comparison = render_comparison(data)
    stats = [
        ("Total finishers", str(data["total_finishers"])),
        ("Routes", str(len(data["routes"]))),
        ("Result date", date.strftime("%d %b %Y").upper()),
    ]
    if data["comparison"]:
        parsed_total = data["comparison_total"]
        last_total = int(parsed_total["last_week"]) if parsed_total else sum(int(item["last_week"]) for item in data["comparison"])
        weekly_change = int(parsed_total["change"]) if parsed_total else data["total_finishers"] - last_total
        stats[1] = ("Week-on-week change", f'{weekly_change:+d}')
        if data["faster"] is not None:
            stats[2] = ("Faster this week", str(data["faster"]))
    stat_html = "\n".join(
        f'<article class="result-stat"><small>{e(label)}</small><strong>{e(value)}</strong></article>'
        for label, value in stats
    )
    kicker = f'{data["event_name"].upper()} - WEEKLY TIME TRIAL'
    description = f'{public_title} for {date.strftime("%d %B %Y")}, with {distances} results.'
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<base href="../../">
<meta name="description" content="{e(description)}">
<title>{e(public_title)} - {date.strftime('%d %B %Y')} | Collegians Harriers</title>
<link rel="stylesheet" href="assets/css/site.css?v=20260825d">
<link rel="stylesheet" href="assets/css/crest-fix.css?v=20260826c">
<link rel="stylesheet" href="assets/css/pages-v02.css?v=20260825d">
<link rel="stylesheet" href="assets/css/pages-v03.css?v=20260826a">
<link rel="stylesheet" href="assets/css/result-detail-v057.css?v=20260826c">
<link rel="stylesheet" href="assets/css/watermark.css?v=20260826a">
<link rel="stylesheet" href="assets/css/production-v04.css?v=20260826a">
<meta name="theme-color" content="#d71920">
<link rel="icon" type="image/png" href="assets/img/collegians-logo.png?v=20260825d">
</head>
<body>
<a class="skip-link" href="#main-content">Skip to main content</a>
<div class="topbar"><div class="wrap"><span>Pietermaritzburg &middot; KwaZulu-Natal</span><div class="topbar-links">
<a href="https://www.facebook.com/CollegiansHarriersPmb" target="_blank" rel="noopener noreferrer">Facebook</a>
<a href="https://www.instagram.com/collegiansharrierspmbrunning/" target="_blank" rel="noopener noreferrer">Instagram</a>
<a href="https://www.strava.com/clubs/collegiansharriers" target="_blank" rel="noopener noreferrer">Strava</a>
</div></div></div>
<header class="site-header"><div class="wrap nav">
<a class="brand" href="index.html"><span class="crest-shell"><img src="assets/img/collegians-logo.png?v=20260825d" alt="Collegians Harriers crest" width="100" height="164"></span><span class="brand-copy"><strong>COLLEGIANS HARRIERS</strong><span>Running &middot; Community &middot; Tradition</span></span></a>
<nav class="nav-links" id="site-nav" aria-label="Primary navigation"><a href="index.html">Home</a><a href="about.html">About</a><a href="membership.html">Membership</a><a href="running.html">Running</a><a href="events.html">Events</a><a class="active" aria-current="page" href="results.html">Results</a><a href="news.html">News</a><a href="photos.html">Photos</a><a href="contact.html">Contact</a></nav>
<a class="join-btn desktop" href="https://form.jotform.com/collegiansharriers/collegians-harriers-Member-2026" target="_blank" rel="noopener noreferrer">Join the club</a>
<button class="menu-btn" aria-label="Open navigation" aria-controls="site-nav" aria-expanded="false">&#9776;</button>
</div></header>
<main id="main-content">
<section class="result-hero"><div class="wrap result-hero-grid"><div>
<span class="section-kicker light">{e(kicker)}</span>
<h1>{e(month_day)}<br><span class="red">{date.year}.</span></h1>
<p>Official weekly results for {data["total_finishers"]} finishers across the {e(distances)} routes.</p>
</div><div class="result-hero-actions"><a class="btn secondary" href="{e(pdf_web_path)}" target="_blank" rel="noopener noreferrer">Download original PDF</a></div></div></section>
<section class="page-content result-detail"><div class="wrap">
<div class="result-summary" aria-label="Weekly result summary">{stat_html}</div>
{comparison}
{route_sections}
<div class="result-footer-actions"><a class="btn" href="results.html">Back to all results</a><a class="btn secondary" href="{e(pdf_web_path)}" target="_blank" rel="noopener noreferrer">Original PDF</a></div>
</div></section>
</main>
<footer><div class="wrap"><div class="footer-grid">
<div class="footer-brand"><span class="footer-crest"><img src="assets/img/collegians-logo.png?v=20260825d" alt="Collegians crest" width="100" height="164"></span><div><h3>COLLEGIANS HARRIERS</h3><p>Pietermaritzburg, KwaZulu-Natal<br>Running &middot; Community &middot; Tradition</p></div></div>
<div class="footer-links"><h4>Explore</h4><a href="about.html">About</a><a href="running.html">Running</a><a href="events.html">Events</a><a href="results.html">Results</a><a href="photos.html">Photos</a></div>
<div class="footer-links"><h4>Connect</h4><a href="membership.html">Membership</a><a href="contact.html">Contact</a><a href="https://www.facebook.com/CollegiansHarriersPmb" target="_blank" rel="noopener noreferrer">Facebook</a><a href="https://www.instagram.com/collegiansharrierspmbrunning/" target="_blank" rel="noopener noreferrer">Instagram</a></div>
</div><div class="copyright"><span>&copy; 2026 Collegians Harriers. All rights reserved.</span><span>Established 1934 &middot; Pietermaritzburg</span></div></div></footer>
<script src="assets/js/site.js"></script>
</body>
</html>
"""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pdf", required=True, type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--date", required=True)
    parser.add_argument("--title", required=True)
    parser.add_argument("--pdf-web-path", required=True)
    parser.add_argument("--validate-only", action="store_true")
    args = parser.parse_args()

    try:
        data = parse_pdf(args.pdf, args.date)
        if not args.validate_only:
            if args.output is None:
                raise ValueError("--output is required unless --validate-only is used.")
            args.output.parent.mkdir(parents=True, exist_ok=True)
            temporary = args.output.with_suffix(args.output.suffix + ".tmp")
            temporary.write_text(render_html(data, args.title, args.pdf_web_path), encoding="utf-8", newline="\n")
            temporary.replace(args.output)
        print(json.dumps({"title": data["title"], "note": data["note"], "finishers": data["total_finishers"], "routes": len(data["routes"])}))
        return 0
    except Exception as exc:
        print(f"HTML conversion failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
