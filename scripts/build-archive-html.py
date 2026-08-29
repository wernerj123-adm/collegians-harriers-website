#!/usr/bin/env python3
"""Build lightweight, searchable HTML pages for extractable archived result PDFs."""

from __future__ import annotations

import argparse
import html
import json
import re
import sys
from pathlib import Path

import pdfplumber

from historical_time_trial_html import add_comparison, parse_historical_pdf, render_historical_html


ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "assets" / "data" / "results-archive.json"
OUTPUT_ROOT = ROOT / "results" / "archive"
PUBLIC_PDF_ROOT = "https://wernerj123-adm.github.io/collegians-harriers-website/"
CATEGORY_LABELS = {
    "time-trial": "Weekly time trial",
    "road": "Road race",
    "trail": "Trail race",
    "championship": "Club championship",
    "hosted-event": "Hosted event",
}


def e(value: object) -> str:
    return html.escape(str(value), quote=True)


def clean_text(value: str | None) -> str:
    if not value:
        return ""
    value = value.replace("\ufffd", " ").replace("\x00", "")
    value = re.sub(r"[ \t]+$", "", value, flags=re.M)
    value = re.sub(r"\n{4,}", "\n\n\n", value)
    return value.strip()


def clean_table(table: list[list[str | None]]) -> list[list[str]]:
    rows: list[list[str]] = []
    width = max((len(row) for row in table), default=0)
    for raw_row in table:
        row = [clean_text(cell).replace("\n", " ") for cell in raw_row]
        row.extend([""] * (width - len(row)))
        if any(row):
            rows.append(row)
    while rows and not any(rows[-1]):
        rows.pop()
    return rows


def useful_table(table: list[list[str]]) -> bool:
    if len(table) < 3 or max((len(row) for row in table), default=0) < 2:
        return False
    cells = [cell for row in table for cell in row]
    filled = sum(bool(cell) for cell in cells)
    return filled >= 6 and filled / max(len(cells), 1) >= 0.28


def extract_pdf(pdf_path: Path) -> tuple[list[dict], int]:
    pages: list[dict] = []
    total_chars = 0
    with pdfplumber.open(pdf_path) as document:
        for number, page in enumerate(document.pages, start=1):
            text = clean_text(page.extract_text(layout=True, x_tolerance=2, y_tolerance=3))
            total_chars += len(re.sub(r"\s+", "", text))
            tables: list[list[list[str]]] = []
            try:
                for raw_table in page.extract_tables() or []:
                    table = clean_table(raw_table)
                    if useful_table(table):
                        tables.append(table)
            except Exception:
                tables = []
            pages.append({"number": number, "text": text, "tables": tables})
    return pages, total_chars


def render_table(table: list[list[str]], page_number: int, index: int) -> str:
    header = table[0]
    body = table[1:]
    head = "".join(f'<th scope="col">{e(cell or "Column")}</th>' for cell in header)
    rows = []
    for row in body:
        rows.append("<tr>" + "".join(f"<td>{e(cell)}</td>" for cell in row) + "</tr>")
    return f'''<div class="archive-table-wrap"><table class="archive-source-table">
<caption>Extracted table {index} from source page {page_number}</caption>
<thead><tr>{head}</tr></thead><tbody>{''.join(rows)}</tbody></table></div>'''


def render_source_page(page: dict) -> str:
    tables = "\n".join(
        render_table(table, page["number"], index)
        for index, table in enumerate(page["tables"], start=1)
    )
    text = e(page["text"] or "No machine-readable text was found on this page.")
    open_attribute = "" if tables else " open"
    return f'''<section class="source-page" aria-labelledby="source-page-{page['number']}">
<div class="source-page-head"><h2 id="source-page-{page['number']}">Source page {page['number']}.</h2><span>{len(page['tables'])} extracted table{'s' if len(page['tables']) != 1 else ''}</span></div>
{tables}
<details class="source-transcript"{open_attribute}><summary>{'View source transcript' if tables else 'Source transcript'}</summary><pre>{text}</pre></details>
</section>'''


def render_html(record: dict, pages: list[dict]) -> str:
    title = record["title"]
    season = record["season"]
    category = CATEGORY_LABELS.get(record["category"], record["category"])
    date_label = record.get("dateLabel") or record["date"]
    pdf_url = PUBLIC_PDF_ROOT + record["file"]
    return_page = "time-trial-results.html" if record["category"] == "time-trial" else "race-event-results.html"
    return_label = "Back to time-trial results" if record["category"] == "time-trial" else "Back to race archive"
    sections = "\n".join(render_source_page(page) for page in pages)
    table_count = sum(len(page["tables"]) for page in pages)
    return f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><base href="../../../">
<meta name="description" content="Searchable HTML presentation of {e(title)}."><title>{e(title)} | Collegians Harriers</title>
<link rel="stylesheet" href="assets/css/site.css?v=20260825d"><link rel="stylesheet" href="assets/css/crest-fix.css?v=20260827a"><link rel="stylesheet" href="assets/css/pages-v02.css?v=20260825d"><link rel="stylesheet" href="assets/css/archive-detail-v081.css?v=20260828a"><link rel="stylesheet" href="assets/css/watermark.css?v=20260826a"><link rel="stylesheet" href="assets/css/production-v04.css?v=20260826a"><meta name="theme-color" content="#d71920"><link rel="icon" type="image/png" href="assets/img/collegians-logo.png?v=20260825d"></head><body>
<a class="skip-link" href="#main-content">Skip to main content</a><div class="topbar"><div class="wrap"><span>Pietermaritzburg &middot; KwaZulu-Natal</span><div class="topbar-links"><a href="https://www.facebook.com/CollegiansHarriersPmb" target="_blank" rel="noopener noreferrer">Facebook</a><a href="https://www.instagram.com/collegiansharrierspmbrunning/" target="_blank" rel="noopener noreferrer">Instagram</a><a href="https://www.strava.com/clubs/collegiansharriers" target="_blank" rel="noopener noreferrer">Strava</a></div></div></div>
<header class="site-header"><div class="wrap nav"><a class="brand" href="index.html"><span class="crest-shell"><img src="assets/img/collegians-logo.png?v=20260825d" alt="Collegians Harriers crest" width="100" height="164"></span><span class="brand-copy"><strong>COLLEGIANS HARRIERS</strong><span>Running &middot; Community &middot; Tradition</span></span></a><nav class="nav-links" id="site-nav" aria-label="Primary navigation"><a href="index.html">Home</a><a href="about.html">About</a><a href="membership.html">Membership</a><a href="running.html">Running</a><a href="events.html">Events</a><a class="active" aria-current="page" href="results.html">Results</a><a href="news.html">News</a><a href="photos.html">Photos</a><a href="contact.html">Contact</a></nav><a class="join-btn desktop" href="https://form.jotform.com/collegiansharriers/collegians-harriers-Member-2026" target="_blank" rel="noopener noreferrer">Join the club</a><button class="menu-btn" aria-label="Open navigation" aria-controls="site-nav" aria-expanded="false">&#9776;</button></div></header>
<main id="main-content"><section class="archive-detail-hero"><div class="wrap"><span class="section-kicker light">{e(category.upper())} &middot; {e(season)}</span><h1>{e(title)}</h1><p>{e(date_label)} &middot; Searchable HTML archive</p></div></section>
<section class="page-content archive-detail"><div class="wrap"><div class="archive-detail-summary"><article><small>Source pages</small><strong>{len(pages)}</strong></article><article><small>Extracted tables</small><strong>{table_count}</strong></article><article><small>Archive year</small><strong>{e(season)}</strong></article></div><aside class="archive-detail-note"><strong>HTML reading copy</strong><p>This page is an automated, searchable transcription of the approved source document. Where exact layout or scanned marks matter, use the preserved original PDF.</p><a href="{e(pdf_url)}" target="_blank" rel="noopener noreferrer">Open preserved original PDF &rarr;</a></aside>
{sections}<div class="result-footer-actions"><a class="btn" href="{return_page}">{return_label}</a><a class="btn secondary" href="results-archive.html">All historical results</a></div></div></section></main>
<footer><div class="wrap"><div class="footer-grid"><div class="footer-brand"><span class="footer-crest"><img src="assets/img/collegians-logo.png?v=20260825d" alt="Collegians crest" width="100" height="164"></span><div><h3>COLLEGIANS HARRIERS</h3><p>Pietermaritzburg, KwaZulu-Natal<br>Running &middot; Community &middot; Tradition</p></div></div><div class="footer-links"><h4>Explore</h4><a href="about.html">About</a><a href="running.html">Running</a><a href="events.html">Events</a><a href="results.html">Results</a><a href="photos.html">Photos</a></div><div class="footer-links"><h4>Connect</h4><a href="membership.html">Membership</a><a href="contact.html">Contact</a></div></div><div class="copyright"><span>&copy; 2026 Collegians Harriers. All rights reserved.</span><span>Established 1934 &middot; Pietermaritzburg</span></div></div></footer><script src="assets/js/site.js"></script></body></html>'''


def output_path(record: dict) -> Path:
    stem = Path(record["file"]).stem
    return OUTPUT_ROOT / str(record["season"]) / f"{stem}.html"


def web_path(record: dict) -> str:
    return output_path(record).relative_to(ROOT).as_posix()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--audit", action="store_true", help="Inspect extractability without writing HTML or the register.")
    parser.add_argument("--minimum-characters", type=int, default=120)
    parser.add_argument("--category", action="append", choices=sorted(CATEGORY_LABELS))
    args = parser.parse_args()

    data = json.loads(MANIFEST.read_text(encoding="utf-8"))
    converted = skipped = failed = 0
    source_bytes = html_bytes = 0
    skip_reasons: dict[str, int] = {}
    modern_time_trials: dict[str, dict] = {}
    modern_parse_reasons: dict[str, int] = {}
    modern_parse_files: list[dict[str, str]] = []
    previous_time_trial: dict | None = None
    time_trial_records = sorted(
        (record for record in data.get("results", []) if record.get("category") == "time-trial"),
        key=lambda record: record.get("date", ""),
    )
    for record in time_trial_records:
        pdf_path = ROOT / record["file"]
        if not pdf_path.is_file():
            continue
        try:
            parsed = parse_historical_pdf(pdf_path, record["date"])
            add_comparison(parsed, previous_time_trial)
            modern_time_trials[record["file"]] = parsed
            previous_time_trial = parsed
        except Exception as exc:
            reason = str(exc).splitlines()[0]
            modern_parse_reasons[reason] = modern_parse_reasons.get(reason, 0) + 1
            modern_parse_files.append({"file": record["file"], "reason": reason})

    for index, record in enumerate(data.get("results", []), start=1):
        if args.category and record.get("category") not in args.category:
            continue
        pdf_path = ROOT / record["file"]
        if not pdf_path.is_file():
            failed += 1
            skip_reasons["missing PDF"] = skip_reasons.get("missing PDF", 0) + 1
            continue
        if record["file"] in modern_time_trials:
            converted += 1
            source_bytes += pdf_path.stat().st_size
            if not args.audit:
                destination = output_path(record)
                destination.parent.mkdir(parents=True, exist_ok=True)
                rendered = render_historical_html(
                    modern_time_trials[record["file"]], record["title"], PUBLIC_PDF_ROOT + record["file"]
                )
                destination.write_text(rendered, encoding="utf-8", newline="\n")
                html_bytes += destination.stat().st_size
                record["page"] = web_path(record)
                record["htmlFormat"] = "HTML"
                record["pageStyle"] = "structured-time-trial"
            if index % 25 == 0:
                print(f"Reviewed {index} records...", file=sys.stderr)
            continue
        try:
            pages, characters = extract_pdf(pdf_path)
        except Exception as exc:
            failed += 1
            skip_reasons[type(exc).__name__] = skip_reasons.get(type(exc).__name__, 0) + 1
            print(f"WARN {record['file']}: {exc}", file=sys.stderr)
            continue
        if characters < args.minimum_characters:
            skipped += 1
            skip_reasons["scan or insufficient text"] = skip_reasons.get("scan or insufficient text", 0) + 1
            record.pop("page", None)
            record.pop("htmlFormat", None)
            record.pop("pageStyle", None)
            continue
        converted += 1
        source_bytes += pdf_path.stat().st_size
        if not args.audit:
            destination = output_path(record)
            destination.parent.mkdir(parents=True, exist_ok=True)
            rendered = render_html(record, pages)
            destination.write_text(rendered, encoding="utf-8", newline="\n")
            html_bytes += destination.stat().st_size
            record["page"] = web_path(record)
            record["htmlFormat"] = "HTML"
            record["pageStyle"] = "archive-transcript"
        if index % 25 == 0:
            print(f"Reviewed {index} records...", file=sys.stderr)

    if not args.audit:
        MANIFEST.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")
    report = {
        "converted": converted,
        "skipped": skipped,
        "failed": failed,
        "sourcePdfBytes": source_bytes,
        "htmlBytes": html_bytes,
        "estimatedSavedBytes": max(source_bytes - html_bytes, 0),
        "modernTimeTrials": len(modern_time_trials),
        "modernTimeTrialFallbacks": len(time_trial_records) - len(modern_time_trials),
        "modernParseReasons": modern_parse_reasons,
        "modernFallbackFiles": modern_parse_files,
        "skipReasons": skip_reasons,
        "mode": "audit" if args.audit else "build",
    }
    print(json.dumps(report, indent=2))
    return 0 if failed == 0 else 2


if __name__ == "__main__":
    raise SystemExit(main())
