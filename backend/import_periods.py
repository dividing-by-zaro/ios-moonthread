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
    parser.add_argument("--url", default="https://your-backend-url.example.com")
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

    skipped = 0
    imported = 0
    for row in rows:
        start = row["start_date"].strip()
        end = row["end_date"].strip()

        # Validate start date
        datetime.strptime(start, "%Y-%m-%d")

        if start in existing_starts:
            skipped += 1
            continue

        # Start period
        resp = httpx.post(
            f"{args.url}/periods",
            json={"start_date": start},
            headers=headers,
        )
        if resp.status_code != 201:
            print(f"  FAIL on row {skipped + imported + 1}: {resp.status_code}")
            sys.exit(1)

        # End period (only if end_date is provided)
        if end:
            datetime.strptime(end, "%Y-%m-%d")
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
