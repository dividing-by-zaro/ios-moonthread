## MoonThread

A period tracking iOS app with cloud backup.

### Features
- [x] Start/end period tracking with single tap
- [x] Infinite-scroll calendar with period highlighting and predicted future periods (dashed gold)
- [x] Predicted remaining days for in-progress periods
- [x] Stats dashboard with 5 chart visualizations (cycle trends, monthly breakdown, duration variation, regularity gauge, start day patterns)
- [x] Year picker with "All years" default view
- [x] Full period history log with swipe-to-edit and swipe-to-delete
- [x] Auto-refresh data from server on app foreground
- [x] Cloud backup via FastAPI + PostgreSQL backend on Railway
- [x] Password-based API key authentication with iOS Keychain storage
- [x] CSV import utility with duplicate detection and data validation
- [x] Animated zen moon & stars home screen with full-screen rotating star field
- [x] Predicted date shown alongside countdown on home screen (e.g. "Next expected Feb 18 — in 6 days")
- [x] Smoky green ultra-modern dark theme with pulsing animations
- [x] Backend security hardening: timing-safe auth, rate limiting, date validation, overlap detection, stats caching, API docs disabled
- [x] Demo mode via `DEMO_API_KEY` — read-only access to seeded sample data for screenshots

### Stack
- **iOS:** SwiftUI, iOS 17+, MVVM
- **Backend:** FastAPI, async SQLAlchemy, PostgreSQL, Alembic
- **Hosting:** Railway
- **Package management:** uv

### Setup

**Backend:**
```bash
cd backend
uv sync
# Set DATABASE_URL and API_KEY in .env
uv run alembic upgrade head
uv run uvicorn app.main:app --reload
```

**iOS:**
```bash
cp PeriodTracker/Local.xcconfig.example PeriodTracker/Local.xcconfig
# Edit Local.xcconfig with your Apple Team ID, backend URL, and bundle ID
```
Open `PeriodTracker/PeriodTracker.xcodeproj` in Xcode, build and run.

**CSV Import:**
```bash
cd backend
uv run import_periods.py periods.csv --url https://your-backend-url.example.com --api-key YOUR_KEY
```

CSV format: `start_date,end_date` with `YYYY-MM-DD` dates. Leave `end_date` blank for an ongoing period.
