## MoonThread — Project Context

### Architecture
- **Backend:** FastAPI + async SQLAlchemy + PostgreSQL, deployed on Railway
- **iOS:** SwiftUI (iOS 17+), MVVM with `@Observable` ViewModels, `actor APIClient`
- **Auth:** Password-based API key. Backend checks `X-API-Key` header; iOS stores password in Keychain

### Backend (`backend/`)
- Entry point: `app/main.py`
- Config auto-converts `postgresql://` → `postgresql+asyncpg://` for Railway compatibility
- Single `periods` table: `id`, `start_date`, `end_date` (nullable for open periods), `created_at`
- Alembic migrations run on container startup before uvicorn
- `import_periods.py` — CSV backfill utility with duplicate detection. Never print period data to console.

### iOS (`PeriodTracker/`)
- App displays as "MoonThread" (`CFBundleDisplayName` in Info.plist)
- Base URL hardcoded to Railway production URL (no debug/release split)
- Theme: smoky green dark palette — `ColorTokens.swift` and `Typography.swift`
- Three tabs: Home (status + toggle), Calendar (month grid), Log (stats + history)
- All views handle 401 by resetting to password entry screen

### Privacy
- `periods.csv` is gitignored — never read, print, or commit personal health data
- `.env` is gitignored — contains `API_KEY`

### Build & Run
```bash
# Backend locally
cd backend && uv run alembic upgrade head && uv run uvicorn app.main:app --reload

# iOS (requires Xcode with iOS SDK)
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project PeriodTracker/PeriodTracker.xcodeproj -scheme PeriodTracker -destination 'platform=iOS Simulator,name=iPhone 16e' build
```
