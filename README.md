## Moonthread

A personal period tracking app you can sideload onto your iPhone. Moonthread tracks one thing: your period. No ads, no upsells, you control your data.

> Note: Screenshots contain AI-generated demo data.

<p align="center">
  <img src="screenshots/moonthread-1-home.png" width="200" />
  &nbsp;&nbsp;
  <img src="screenshots/moonthread-2-calendar.png" width="200" />
  &nbsp;&nbsp;
  <img src="screenshots/moonthread-4-stats.png" width="200" />
</p>

### Features

- Start/end period tracking with a single tap
- Zen moon & stars home screen with animated star field
- Predicted next period date with countdown on home screen
- Infinite-scroll calendar with logged dates (solid) and predicted dates (dashed gold)
- Period history log with swipe-to-edit and swipe-to-delete
- Stats dashboard with year picker and 5 chart visualizations
- Cloud backup via your own backend and database
- API key authentication stored in the iOS Keychain
- CSV import utility for historical data

### Stack

- **iOS:** SwiftUI, iOS 17+, MVVM
- **Backend:** Python, FastAPI, async SQLAlchemy, PostgreSQL, Alembic
- **Hosting:** Railway (or any platform that runs Docker)
- **Package management:** uv

---

### Prerequisites

- A Mac (or anything that can run Xcode)
- An iPhone
- A cable to connect the two
- [Xcode](https://developer.apple.com/xcode/) installed
- An [Apple Developer account](https://developer.apple.com/) (free works, but app signatures expire after 7 days; $99/year for persistent apps)
- A [Railway](https://railway.app/) account (or another hosting provider for the backend)

---

### Setting Up the Backend on Railway

The backend is a FastAPI server that stores your period data in PostgreSQL. Moonthread uses an API key for authentication rather than a username/password, since it's designed for one person.

I recommend [Railway](https://railway.app/) for deployment:
- One subscription keeps all your services in one place
- Affordable (~$10/month for several projects, and the free tier is surprisingly capable)
- Link a GitHub repo for automatic deploys when `main` gets updated

Here's how to set it up:

**1. Create a new project in Railway**

- Deploy the backend by connecting this GitHub repo
- Add a Postgres instance to the same project

<img src="screenshots/ios-moonthread-backend.png" width="350" />

**2. Create an API key**

Generate a strong, random string to use as your API key. Save it in your password manager. You'll enter this in the app to log in.

Add it to your backend's **Variables** tab in Railway as `API_KEY`.

**3. Set up the database URL**

From your Postgres instance in Railway, grab the `DATABASE_URL`. Add it as a variable on your backend service.

Modify the start of the URL so it reads `postgresql+asyncpg://` instead of just `postgresql://` (the backend uses async database operations).

<img src="screenshots/ios-moonthread-variables.png" width="500" />

**4. Configure the deployment settings**

In your backend service's **Settings** tab:

- Under **Source**, set the root directory to `/backend` (this deploys just the backend, not the entire repo)
- Under **Networking**, click **Generate Domain** to get a public URL for the app to talk to

<img src="screenshots/ios-moonthread-source.png" width="500" />

<img src="screenshots/ios-moonthread-networking.png" width="500" />

That's it for the backend. Railway will build the Dockerfile, run database migrations automatically, and start the server.

---

### Configuring the iOS App

Before building, you need to create a local config file with your personal settings.

**1. Copy the example config**

```bash
cp PeriodTracker/Local.xcconfig.example PeriodTracker/Local.xcconfig
```

**2. Edit `PeriodTracker/Local.xcconfig`** with your values:

```
DEVELOPMENT_TEAM = ABC123DEF4
API_BASE_URL = https://your-app.up.railway.app
PRODUCT_BUNDLE_IDENTIFIER = com.yourname.moonthread
```

| Variable | What it is | Where to find it |
|---|---|---|
| `DEVELOPMENT_TEAM` | Your Apple Developer Team ID | Xcode > Settings > Accounts > your account > Team ID |
| `API_BASE_URL` | Your Railway backend URL | The domain you generated in step 4 above |
| `PRODUCT_BUNDLE_IDENTIFIER` | A unique bundle ID for the app | Pick something like `com.yourname.moonthread` |

`Local.xcconfig` is gitignored, so your personal values won't be committed.

---

### Building & Sideloading onto Your Device

**1. Open the project in Xcode**

Open `PeriodTracker/PeriodTracker.xcodeproj`.

**2. Sign the app**

- Click on the top-level **PeriodTracker** project in the sidebar
- Go to **Signing & Capabilities**
- Check **Automatically manage signing**
- Set **Team** to your personal team (e.g. "Your Name (Personal Team)")

> If you filled in `Local.xcconfig` correctly, the bundle identifier and team should already be populated.

<img src="screenshots/sideloading-1-signing.png" width="600" />

**3. Connect your iPhone and build**

- Plug your iPhone into your Mac
- In the toolbar at the top of Xcode, select **PeriodTracker** and choose your phone from the device dropdown
- Click the play button (or press Cmd+R) to build and install

<img src="screenshots/sideloading-2-running.png" width="500" />

**4. Trust the developer profile on your phone**

The first time you sideload, iOS may block the app from opening. Go to **Settings > General > VPN & Device Management**, find your developer profile, and tap **Trust**.

**5. Open Moonthread and enter your API key**

The app will prompt you for your API key on first launch. This is the key you created in the Railway setup. It's stored securely in your device's Keychain.

---

### Importing Historical Data (Optional)

If you have existing period data, you can import it from a CSV file.

**CSV format:** two columns, `start_date` and `end_date`, in `YYYY-MM-DD` format. Leave `end_date` blank for an ongoing period.

```csv
start_date,end_date
2024-01-15,2024-01-20
2024-02-12,2024-02-17
```

**Import:**

```bash
cd backend
uv run import_periods.py periods.csv --url https://your-app.up.railway.app --api-key YOUR_KEY
```

The script validates dates, checks for overlaps, and skips duplicates.

---

### Local Development

If you want to run the backend locally:

```bash
cd backend
uv sync
```

Create a `backend/.env` file with:

```
DATABASE_URL=postgresql+asyncpg://user:pass@localhost:5432/moonthread
API_KEY=your-dev-key
```

> You don't need a local Postgres instance. You can use your Railway database by grabbing the `DATABASE_PUBLIC_URL` from your Postgres instance in Railway and using it as `DATABASE_URL` here (don't forget to add `+asyncpg`).

Then:

```bash
uv run alembic upgrade head
uv run uvicorn app.main:app --reload
```

The server will start on `http://localhost:8000`.

---

### Privacy

Your period data is stored in your own database. No one else has access to it unless you give them your API key.

- `periods.csv`, `.env`, and `Local.xcconfig` are all gitignored
- The backend disables API docs (`/docs`, `/redoc`) in production
- Authentication is timing-safe to prevent side-channel attacks
- Rate limiting is enabled (10 requests/min per IP)
