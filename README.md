## MoonThread

A period tracking iOS app with cloud backup.

### Features
- [x] Start/end period tracking with single tap
- [x] Calendar view with period days highlighted
- [x] Stats dashboard (average cycle length, average period length, next prediction)
- [x] Full period history log
- [x] Cloud backup via FastAPI + PostgreSQL backend on Railway
- [x] Password-based API key authentication with iOS Keychain storage
- [x] CSV import utility with duplicate detection
- [x] Smoky green ultra-modern dark theme with pulsing animations

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
Open `PeriodTracker/PeriodTracker.xcodeproj` in Xcode, build and run.

**CSV Import:**
```bash
cd backend
uv run import_periods.py periods.csv --api-key YOUR_KEY
```

CSV format: `start_date,end_date` with `YYYY-MM-DD` dates. Leave `end_date` blank for an ongoing period.
