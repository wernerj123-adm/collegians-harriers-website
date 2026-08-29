#!/usr/bin/env python3
"""Parse legacy Herman's Delight spreadsheets and render modern result pages."""

from __future__ import annotations

import importlib.util
import re
import sys
from datetime import datetime
from pathlib import Path

import pdfplumber


ROOT = Path(__file__).resolve().parent.parent
CURRENT_BUILDER = ROOT / "scripts" / "build-time-trial-html.py"
SPEC = importlib.util.spec_from_file_location("collegians_current_time_trial", CURRENT_BUILDER)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"Unable to load {CURRENT_BUILDER}")
CURRENT = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = CURRENT
SPEC.loader.exec_module(CURRENT)

COURSE_RE = re.compile(r"(?P<distance>\d+(?:\.\d+)?)\s*Km\s*Course", re.I)
MILE_RE = re.compile(r"1[- ]?Mile\s+Herman'?s\s+Dash", re.I)
POSITION_RE = re.compile(r"^(?:Pos|Position)$", re.I)
TIME_RE = re.compile(r"^(?:\d{1,2}[:.]\d{2}|\d{1,2}[:.]\d{2}[:.]\d{2})$")


def clean(value: object) -> str:
    if value is None:
        return ""
    return re.sub(r"\s+", " ", str(value).replace("\ufffd", " ")).strip()


def normalize_position(value: str) -> str:
    compact = re.sub(r"\s+", "", value)
    return compact if compact.isdigit() else ""


def normalize_time(value: str) -> str:
    value = clean(value).replace(".", ":").replace(",", ":")
    return value if TIME_RE.match(value) else ""


def seconds_from_time(value: str) -> int:
    parts = [int(part) for part in value.split(":")]
    if len(parts) == 2:
        return parts[0] * 60 + parts[1]
    return parts[0] * 3600 + parts[1] * 60 + parts[2]


def pace_for(time_value: str, distance: str) -> str:
    kilometres = 1.609344 if distance == "1 mile" else float(distance)
    seconds = round(seconds_from_time(time_value) / kilometres)
    return f"{seconds // 60}:{seconds % 60:02d}"


def course_labels(row: list[object]) -> list[tuple[int, str]]:
    labels: list[tuple[int, str]] = []
    for index, cell in enumerate(row):
        cell_text = clean(cell)
        if match := COURSE_RE.search(cell_text):
            labels.append((index, match.group("distance")))
        elif MILE_RE.search(cell_text):
            labels.append((index, "1 mile"))
    return labels


def nearest_course(start: int, labels: list[tuple[int, str]]) -> str:
    return min(labels, key=lambda item: abs(item[0] - start))[1]


def parse_table(table: list[list[object]], routes: dict[str, list[dict[str, str]]]) -> None:
    course_row_indexes = [index for index, row in enumerate(table) if course_labels(row)]
    for section_index, course_row_index in enumerate(course_row_indexes):
        end_index = course_row_indexes[section_index + 1] if section_index + 1 < len(course_row_indexes) else len(table)
        labels = course_labels(table[course_row_index])
        header_index = None
        starts: list[int] = []
        for candidate in range(course_row_index + 1, min(end_index, course_row_index + 5)):
            starts = [index for index, cell in enumerate(table[candidate]) if POSITION_RE.match(clean(cell))]
            if starts:
                header_index = candidate
                break
        if header_index is None:
            continue
        width = max((len(row) for row in table), default=0)
        for start_number, start in enumerate(starts):
            end = starts[start_number + 1] if start_number + 1 < len(starts) else width
            header = [clean(cell) for cell in table[header_index][start:end]]
            name_offset = next((i for i, value in enumerate(header) if value.lower() == "name"), 1)
            category_offset = next((i for i, value in enumerate(header) if value.lower() == "category"), None)
            time_offset = next((i for i, value in enumerate(header) if value.lower() == "time"), len(header) - 1)
            distance = nearest_course(start, labels)
            destination = routes.setdefault(distance, [])
            for raw_row in table[header_index + 1 : end_index]:
                row = [clean(cell) for cell in raw_row]
                row.extend([""] * max(0, end - len(row)))
                segment = row[start:end]
                if not segment:
                    continue
                position = normalize_position(segment[0])
                name = segment[name_offset] if name_offset < len(segment) else ""
                category = segment[category_offset] if category_offset is not None and category_offset < len(segment) else "-"
                time_value = normalize_time(segment[time_offset] if time_offset < len(segment) else "")
                if not position or not name or not time_value:
                    continue
                destination.append(
                    {
                        "position": position,
                        "name": name,
                        "group": category or "-",
                        "time": time_value,
                        "pace": pace_for(time_value, distance),
                    }
                )


def word_lines(page) -> list[list[dict]]:
    lines: list[list[dict]] = []
    for word in sorted(page.extract_words() or [], key=lambda item: (item["top"], item["x0"])):
        if not lines or abs(lines[-1][0]["top"] - word["top"]) > 3.0:
            lines.append([word])
        else:
            lines[-1].append(word)
    for line in lines:
        line.sort(key=lambda item: item["x0"])
    return lines


def line_courses(words: list[dict]) -> list[tuple[float, str]]:
    labels: list[tuple[float, str]] = []
    for index in range(len(words) - 2):
        number = clean(words[index]["text"])
        if re.fullmatch(r"\d+(?:\.\d+)?", number) and clean(words[index + 1]["text"]).lower() == "km":
            if clean(words[index + 2]["text"]).lower().startswith("course"):
                labels.append((float(words[index]["x0"]), number))
        if clean(words[index]["text"]).lower().replace("-", "") == "1mile":
            labels.append((float(words[index]["x0"]), "1 mile"))
    return labels


def parse_word_layout(page, routes: dict[str, list[dict[str, str]]]) -> None:
    lines = word_lines(page)
    course_indexes = [index for index, words in enumerate(lines) if line_courses(words)]
    for section_number, course_index in enumerate(course_indexes):
        section_end = course_indexes[section_number + 1] if section_number + 1 < len(course_indexes) else len(lines)
        labels = line_courses(lines[course_index])
        header_index = None
        position_words: list[dict] = []
        for candidate in range(course_index + 1, min(section_end, course_index + 6)):
            position_words = [word for word in lines[candidate] if POSITION_RE.match(clean(word["text"]))]
            if position_words:
                header_index = candidate
                break
        if header_index is None:
            continue
        header_words = lines[header_index]
        for group_number, position_header in enumerate(position_words):
            start = float(position_header["x0"]) - 8
            end = float(position_words[group_number + 1]["x0"]) - 8 if group_number + 1 < len(position_words) else float(page.width) + 1
            group_headers = [word for word in header_words if start <= float(word["x0"]) < end]
            name_header = next((word for word in group_headers if clean(word["text"]).lower() == "name"), None)
            time_header = next((word for word in group_headers if clean(word["text"]).lower() == "time"), None)
            category_header = next((word for word in group_headers if clean(word["text"]).lower() == "category"), None)
            if name_header is None or time_header is None:
                continue
            distance = min(labels, key=lambda item: abs(item[0] - float(position_header["x0"])))[1]
            destination = routes.setdefault(distance, [])
            category_x = float(category_header["x0"]) - 10 if category_header else None
            time_x = float(time_header["x0"]) - 8
            for words in lines[header_index + 1 : section_end]:
                group = [word for word in words if start <= float(word["x0"]) < end]
                if not group:
                    continue
                before_name_end = category_x if category_x is not None else time_x
                position_tokens = [clean(word["text"]) for word in group if float(word["x1"]) < float(name_header["x0"])]
                position = normalize_position("".join(token for token in position_tokens if token.isdigit()))
                time_candidates = [normalize_time(word["text"]) for word in group if float(word["x0"]) >= time_x]
                time_value = next((value for value in time_candidates if value), "")
                name_words = [
                    clean(word["text"])
                    for word in group
                    if float(word["x0"]) >= float(position_header["x1"]) + 2
                    and float(word["x0"]) < before_name_end
                ]
                category_words = (
                    [clean(word["text"]) for word in group if category_x <= float(word["x0"]) < time_x]
                    if category_x is not None
                    else []
                )
                name = " ".join(word for word in name_words if word)
                category = " ".join(word for word in category_words if word) or "-"
                if not position or not name or not time_value:
                    continue
                destination.append(
                    {
                        "position": position,
                        "name": name,
                        "group": category,
                        "time": time_value,
                        "pace": pace_for(time_value, distance),
                    }
                )


def finalized_routes(routes: dict[str, list[dict[str, str]]]) -> list:
    parsed_routes = []
    distance_value = lambda value: 1.609344 if value == "1 mile" else float(value)
    for distance, rows in sorted(routes.items(), key=lambda item: distance_value(item[0])):
        unique: dict[tuple[str, str, str], dict[str, str]] = {}
        for row in rows:
            unique[(row["position"], row["name"], row["time"])] = row
        ordered = sorted(unique.values(), key=lambda row: int(row["position"]))
        if ordered:
            parsed_routes.append(CURRENT.Route(distance=distance, stated_count=len(ordered), rows=ordered))
    return parsed_routes


def parse_historical_pdf(pdf_path: Path, result_date: str) -> dict:
    table_routes: dict[str, list[dict[str, str]]] = {}
    word_routes: dict[str, list[dict[str, str]]] = {}
    extracted_text: list[str] = []
    with pdfplumber.open(pdf_path) as document:
        if not document.pages:
            raise ValueError("The PDF contains no pages.")
        for page in document.pages:
            extracted_text.append(page.extract_text(layout=True) or "")
            for table in page.extract_tables() or []:
                parse_table(table, table_routes)
            parse_word_layout(page, word_routes)
    candidates = [candidate for candidate in (finalized_routes(table_routes), finalized_routes(word_routes)) if candidate]
    if not candidates:
        raise ValueError("No structured route tables were found.")
    parsed_date = datetime.strptime(result_date, "%Y-%m-%d")
    attendance_text = "\n".join(extracted_text)
    attendance_match = re.search(r"This Week'?s Attendance:\s*(\d+(?:[.,]\d+)?)", attendance_text, re.I)
    attendance = int(float(attendance_match.group(1).replace(",", "."))) if attendance_match else None
    if attendance is not None:
        exact = [candidate for candidate in candidates if sum(route.stated_count for route in candidate) == attendance]
        if not exact:
            read_counts = sorted({sum(route.stated_count for route in candidate) for candidate in candidates})
            raise ValueError(f"Attendance says {attendance} but route parsing produced {read_counts} rows.")
        parsed_routes = max(exact, key=lambda candidate: len(candidate))
    else:
        parsed_routes = max(candidates, key=lambda candidate: sum(route.stated_count for route in candidate))
    total_finishers = sum(route.stated_count for route in parsed_routes)
    return {
        "title": "Herman's Delight Weekly Results",
        "event_name": "Herman's Delight",
        "date": parsed_date,
        "comparison_date": "",
        "comparison": [],
        "comparison_total": None,
        "faster": None,
        "slower": None,
        "same": None,
        "new": None,
        "dropped": None,
        "routes": parsed_routes,
        "total_finishers": total_finishers,
        "note": CURRENT.route_list_label(parsed_routes) + f" - {total_finishers} finishers",
    }


def normalized_name(value: str) -> str:
    return re.sub(r"[^a-z0-9]", "", value.lower())


def participant_times(data: dict) -> dict[str, int]:
    participants: dict[str, int] = {}
    for route in data["routes"]:
        for row in route.rows:
            key = normalized_name(row["name"])
            if key:
                participants[key] = seconds_from_time(row["time"])
    return participants


def add_comparison(current: dict, previous: dict | None) -> None:
    if previous is None:
        return
    if previous["date"].year != current["date"].year or (current["date"] - previous["date"]).days > 21:
        return
    previous_routes = {route.distance: route for route in previous["routes"]}
    comparison = []
    for route in current["routes"]:
        last_count = previous_routes.get(route.distance).stated_count if route.distance in previous_routes else 0
        comparison.append(
            {
                "distance": route.distance,
                "this_week": str(route.stated_count),
                "last_week": str(last_count),
                "change": f"{route.stated_count - last_count:+d}",
                "average": CURRENT.average_time(route.rows),
            }
        )
    current_times = participant_times(current)
    previous_times = participant_times(previous)
    shared = current_times.keys() & previous_times.keys()
    current["comparison_date"] = previous["date"].strftime("%d %B %Y")
    current["comparison"] = comparison
    current["comparison_total"] = {
        "this_week": str(current["total_finishers"]),
        "last_week": str(previous["total_finishers"]),
        "change": f"{current['total_finishers'] - previous['total_finishers']:+d}",
    }
    current["faster"] = sum(current_times[name] < previous_times[name] for name in shared)
    current["slower"] = sum(current_times[name] > previous_times[name] for name in shared)
    current["same"] = sum(current_times[name] == previous_times[name] for name in shared)
    current["new"] = len(current_times.keys() - previous_times.keys())
    current["dropped"] = len(previous_times.keys() - current_times.keys())


def render_historical_html(data: dict, public_title: str, pdf_url: str) -> str:
    return CURRENT.render_html(
        data,
        public_title,
        pdf_url,
        base_href="../../../",
        back_href="time-trial-results.html",
        back_label="Back to time-trial results",
    )
