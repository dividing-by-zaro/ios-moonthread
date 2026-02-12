# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

### Backend
```bash
cd backend
uv sync                                    # Install dependencies
uv run alembic upgrade head                # Run migrations (requires running PostgreSQL)
uv run uvicorn app.main:app --reload       # Start dev server on :8000
uv run import_periods.py periods.csv --url $URL --api-key $KEY  # Import CSV data
```

### iOS
```bash
# Build
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project PeriodTracker/PeriodTracker.xcodeproj \
  -scheme PeriodTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16e' build

# Install & launch in simulator
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl install booted \
  ~/Library/Developer/Xcode/DerivedData/PeriodTracker-*/Build/Products/Debug-iphonesimulator/PeriodTracker.app
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl launch booted <PRODUCT_BUNDLE_IDENTIFIER>
```

## Architecture

Two independent codebases in one repo: a Python backend and a SwiftUI iOS app communicating over REST.

### Backend (`backend/`)
FastAPI + async SQLAlchemy + PostgreSQL, deployed on Railway.

- **Entry point:** `app/main.py` — mounts period routes; `/health` is unauthenticated. OpenAPI docs (`/docs`, `/redoc`, `/openapi.json`) are disabled in production.
- **Auth:** `app/auth.py` — `verify_api_key` dependency checks `X-API-Key` header via `hmac.compare_digest` (timing-safe) against `API_KEY` and optionally `DEMO_API_KEY`. Returns `"user"` or `"demo"` owner string. Rate-limited to 10 req/min per IP via `slowapi`. Config rejects default `dev-key` when `RAILWAY_ENVIRONMENT` is set. Config validates `DEMO_API_KEY` differs from `API_KEY`.
- **Demo mode:** Separate `demo_periods` table (identical schema to `periods`) with seeded sample data. `_model(owner)` helper in `period_service.py` returns `DemoPeriod` or `Period` based on owner. Demo owner is read-only (mutations return 403). Stats cache is owner-keyed.
- **Data model:** `periods` table — `id`, `start_date` (UNIQUE), `end_date` (NULL = ongoing), `created_at`. `demo_periods` table — same schema, pre-seeded with 27 demo periods.
- **Layering:** Routes (`app/routes/`) → Services (`app/services/`) → ORM (`app/models.py`)
- **Config:** `app/config.py` auto-converts Railway's `postgresql://` to `postgresql+asyncpg://`
- **Migrations:** Alembic with async engine; runs automatically on container startup via Dockerfile. Migration failure prevents the app from starting. Migration 002 adds UNIQUE on `start_date`; migration 003 creates `demo_periods` table and seeds 27 demo periods.
- **Validation:** All date inputs are bounded (10 years past to today). Overlap detection (`_check_overlap`) runs on create/update/end to prevent intersecting periods. DB-level UNIQUE on `start_date` guards against race conditions. `IntegrityError` caught and converted to `ValueError`.
- **Stats logic** (`services/period_service.py`): cycle length = gap between consecutive start dates; period length = end - start + 1; prediction = last start + avg cycle. Stats response is cached in-memory for 30s per owner; any mutation invalidates that owner's cache.
- **Error responses:** Routes return generic error messages (not internal exception text) to avoid information disclosure.
- **CRUD:** Full period CRUD — POST (create), PATCH (end), PUT (update start/end dates), DELETE. Schemas: `PeriodCreate`, `PeriodEnd`, `PeriodUpdate`, `PeriodResponse`.

### iOS (`PeriodTracker/`)
SwiftUI iOS 17+, MVVM pattern. Display name is "MoonThread".

- **Networking:** `APIClient` is an `actor` singleton. Reads API key from iOS Keychain, sends as `X-API-Key` header. Base URL read from `Info.plist` → `APIBaseURL`, set via `Local.xcconfig` (gitignored).
- **Auth flow:** `PasswordEntryView` → saves to Keychain → validates via `/periods/stats` → 401 resets back to password screen. All four tab ViewModels watch for 401 and trigger re-auth.
- **MVVM:** Each tab has an `@Observable` ViewModel (`HomeViewModel`, `CalendarViewModel`, `StatsViewModel`, `LogViewModel`). Views bind to these.
- **Data refresh:** All views reload from the server on foreground via `willEnterForegroundNotification`.
- **Theme:** Smoky green dark palette in `ColorTokens.swift`, rounded typography in `Typography.swift`. Forced dark mode at app root.
- **Tabs (order):** Home (moon/stars zen scene when inactive + start/end toggle, predicted date in subtitle), Calendar (bidirectional infinite-scroll calendar with period highlighting + predicted future periods), Log (avg stats + period history with swipe-to-edit/delete), Stats (5 chart visualizations using Swift Charts + custom SwiftUI)
- **Home inactive state:** `StarField` view renders full-screen scattered dots with clustered distribution (deterministic hash-based positions). Slowly rotates in `HomeView` as a background layer. `PeriodStatusCard` shows `moon.stars` SF Symbol, "No active period" headline, and prediction subtitle with formatted date (e.g. "Next expected Feb 18 — in 6 days").
- **Calendar predictions:** `CalendarViewModel.computePredictions()` derives avg cycle length and avg period duration from fetched periods, projects up to 24 future cycles. Predicted days stored in a `Set<Date>` for O(1) lookup. Also predicts remaining days of in-progress periods. `DayCell` renders predictions as dashed gold circles. Calendar scrolls to current month on appear via `ScrollViewReader`.
- **Stats tab:** Year picker with "All" default. Charts: Cycle Length Trend (line+area), Days per Month (bar), Period Duration Variation (scatter+range band), Cycle Regularity Gauge (custom arc, year-only), Start Day Patterns (horizontal bar, all-years-only). Uses `ChartCard` wrapper. `StatsViewModel` computes all chart data as derived properties from `selectedYear`.
- **Local config:** `PeriodTracker/Local.xcconfig` (gitignored) sets `DEVELOPMENT_TEAM`, `API_BASE_URL`, and `PRODUCT_BUNDLE_IDENTIFIER`. Copy `Local.xcconfig.example` to get started.
- **Xcode project:** Hand-written `.pbxproj` — when adding Swift files, they must be registered in both the PBXFileReference and PBXBuildFile sections.

## Privacy Rules
- `periods.csv` is gitignored. **Never read, print, or display period data to the console.** This includes dates, durations, or any content from the CSV or API responses.
- `.env` contains `API_KEY` — gitignored, never commit or print.
- `Local.xcconfig` contains `DEVELOPMENT_TEAM`, `API_BASE_URL`, and `PRODUCT_BUNDLE_IDENTIFIER` — gitignored, never commit or print.

## Deployment
- **Backend:** Railway auto-deploys from `backend/` directory. Dockerfile chains `alembic upgrade head && uvicorn` so the app won't start on a broken schema.
- **Env vars on Railway:** `DATABASE_URL` (from Postgres addon), `API_KEY` (user-chosen password), `DEMO_API_KEY` (optional, enables read-only demo mode with seeded data)
- **iOS config:** Copy `PeriodTracker/Local.xcconfig.example` to `PeriodTracker/Local.xcconfig` and set `DEVELOPMENT_TEAM`, `API_BASE_URL`, and `PRODUCT_BUNDLE_IDENTIFIER`.
- **Production URL:** Set in `Local.xcconfig` (not tracked in git)
