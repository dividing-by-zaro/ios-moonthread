"""Import periods from a CSV file into the database via the API.

Usage:
    uv run import_periods.py periods.csv --url https://your-backend-url.example.com --api-key YOUR_KEY
"""

import argparse
import csv
import sys
from datetime import datetime

import httpx


def main():
    parser = argparse.ArgumentParser(description="Import periods from CSV")
    parser.add_argument("csv_file", help="Path to CSV file")
    parser.add_argument("--url", required=True, help="Backend API URL")
    parser.add_argument("--api-key", default=None)
    args = parser.parse_args()

    api_key = args.api_key
    if not api_key:
        from app.config import settings
        api_key = settings.api_key

    headers = {"X-API-Key": api_key}

    # Fetch existing periods to detect duplicates
    resp = httpx.get(f"{args.url}/periods", headers=headers)
    if resp.status_code != 200:
        print(f"Failed to fetch existing periods: {resp.text}")
        sys.exit(1)
    existing_starts = {p["start_date"] for p in resp.json()}

    with open(args.csv_file) as f:
        reader = csv.DictReader(f)
        rows = sorted(reader, key=lambda r: r["start_date"])

    print(f"Found {len(rows)} periods in CSV, {len(existing_starts)} already in DB")

    # --- Validation pass ---
    errors = []
    today = datetime.now().date()
    seen_starts = set()

    for i, row in enumerate(rows, 1):
        start_raw = row.get("start_date", "").strip()
        end_raw = row.get("end_date", "").strip()

        if not start_raw:
            errors.append(f"  Row {i}: missing start_date")
            continue

        try:
            start_dt = datetime.strptime(start_raw, "%Y-%m-%d").date()
        except ValueError:
            errors.append(f"  Row {i}: invalid start_date '{start_raw}'")
            continue

        end_dt = None
        if end_raw:
            try:
                end_dt = datetime.strptime(end_raw, "%Y-%m-%d").date()
            except ValueError:
                errors.append(f"  Row {i}: invalid end_date '{end_raw}'")
                continue

        if end_dt and start_dt > end_dt:
            errors.append(f"  Row {i}: start_date {start_raw} is after end_date {end_raw}")

        if start_dt > today:
            errors.append(f"  Row {i}: start_date {start_raw} is in the future")

        if end_dt and end_dt > today:
            errors.append(f"  Row {i}: end_date {end_raw} is in the future")

        if start_raw in seen_starts:
            errors.append(f"  Row {i}: duplicate start_date {start_raw} within CSV")
        seen_starts.add(start_raw)

    # Check for overlapping periods (sorted by start)
    parsed = []
    for row in rows:
        s = row.get("start_date", "").strip()
        e = row.get("end_date", "").strip()
        if s:
            try:
                sd = datetime.strptime(s, "%Y-%m-%d").date()
                ed = datetime.strptime(e, "%Y-%m-%d").date() if e else today
                parsed.append((sd, ed, s, e))
            except ValueError:
                pass

    for j in range(1, len(parsed)):
        prev_start, prev_end, ps, pe = parsed[j - 1]
        curr_start, curr_end, cs, ce = parsed[j]
        if curr_start <= prev_end:
            errors.append(
                f"  Overlap: period {ps}..{pe or 'ongoing'} overlaps with {cs}..{ce or 'ongoing'}"
            )

    if errors:
        print(f"Validation failed with {len(errors)} error(s):")
        for err in errors:
            print(err)
        sys.exit(1)

    print("Validation passed.")

    skipped = 0
    imported = 0
    for row in rows:
        start = row["start_date"].strip()
        end = row["end_date"].strip()

        if start in existing_starts:
            skipped += 1
            continue

        if not end:
            skipped += 1
            continue

        # Start period
        resp = httpx.post(
            f"{args.url}/periods",
            json={"start_date": start},
            headers=headers,
        )
        if resp.status_code == 409:
            detail = resp.json().get("detail", "")
            print(f"  409 on {start}: {detail}")
            skipped += 1
            continue
        if resp.status_code != 201:
            print(f"  FAIL on row {skipped + imported + 1}: {resp.status_code}")
            sys.exit(1)

        # End period (only if end_date is provided)
        if end:
            period_id = resp.json()["id"]
            resp = httpx.patch(
                f"{args.url}/periods/{period_id}",
                json={"end_date": end},
                headers=headers,
            )
            if resp.status_code != 200:
                print(f"  FAIL on row {skipped + imported + 1}: {resp.status_code}")
                sys.exit(1)

        imported += 1

    print(f"Done! Imported {imported}, skipped {skipped} duplicates.")


if __name__ == "__main__":
    main()
