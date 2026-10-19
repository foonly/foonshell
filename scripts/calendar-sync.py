#!/usr/bin/env python3
"""Fetch iCal feeds listed in calendars.json and write upcoming events as JSON.

Usage: calendar-sync.py <calendars.json> <output.json>

The output is written atomically so the bar never reads a half written file.
A calendar that fails to load keeps its events from the previous run.
"""

import json
import os
import sys
import urllib.request
from datetime import date, datetime, timedelta

import icalendar
import recurring_ical_events

# How far back and ahead to expand events, so paging through nearby months shows them
DAYS_BACK = 45
DAYS_AHEAD = 120


def fetch(url: str) -> icalendar.Calendar:
    request = urllib.request.Request(url, headers={"User-Agent": "foonshell-calendar"})
    with urllib.request.urlopen(request, timeout=20) as response:
        return icalendar.Calendar.from_ical(response.read())


def to_iso(value) -> tuple[str, bool]:
    """Return an ISO string in local time and whether it's an all day value."""
    if isinstance(value, datetime):
        # Floating times (no tz) are already local
        if value.tzinfo is not None:
            value = value.astimezone()
        return value.replace(tzinfo=None).isoformat(timespec="minutes"), False
    return value.isoformat(), True


def events_for(calendar: dict, start: date, end: date) -> list[dict]:
    ical = fetch(calendar["url"])
    events = []
    for event in recurring_ical_events.of(ical).between(start, end):
        if str(event.get("STATUS", "")).upper() == "CANCELLED":
            continue
        begin, all_day = to_iso(event["DTSTART"].dt)
        if "DTEND" in event:
            finish, _ = to_iso(event["DTEND"].dt)
        elif "DURATION" in event:
            finish, _ = to_iso(event["DTSTART"].dt + event["DURATION"].dt)
        else:
            finish = begin
        events.append({
            "calendar": calendar.get("name", ""),
            "color": calendar.get("color", ""),
            "title": str(event.get("SUMMARY", "")).strip() or "(No title)",
            "location": str(event.get("LOCATION", "")).strip(),
            "start": begin,
            # All day events end on the following day (exclusive), as in iCal
            "end": finish,
            "allDay": all_day,
        })
    return events


def main() -> int:
    config_path, output_path = sys.argv[1], sys.argv[2]

    try:
        with open(config_path) as f:
            calendars = json.load(f).get("calendars", [])
    except FileNotFoundError:
        calendars = []

    try:
        with open(output_path) as f:
            previous = json.load(f).get("events", [])
    except (FileNotFoundError, json.JSONDecodeError):
        previous = []

    today = date.today()
    start, end = today - timedelta(days=DAYS_BACK), today + timedelta(days=DAYS_AHEAD)

    events, errors = [], []
    for calendar in calendars:
        try:
            events += events_for(calendar, start, end)
        except Exception as error:  # noqa: BLE001 - one broken feed shouldn't hide the others
            name = calendar.get("name", calendar.get("url", "?"))
            errors.append(f"{name}: {error}")
            events += [e for e in previous if e["calendar"] == calendar.get("name", "")]

    events.sort(key=lambda e: (e["start"], not e["allDay"], e["title"]))

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    tmp = output_path + ".tmp"
    with open(tmp, "w") as f:
        json.dump({
            "updated": datetime.now().isoformat(timespec="seconds"),
            "configured": len(calendars) > 0,
            "errors": errors,
            "events": events,
        }, f)
    os.replace(tmp, output_path)

    for error in errors:
        print(error, file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
