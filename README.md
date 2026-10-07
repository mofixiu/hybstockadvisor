# HybStockAdvisor

HybStockAdvisor is moving from a final-year project into a private research companion for West African investors. The first release focuses on daily NGX closing data, manual portfolios and watchlists, and Lexi’s timestamped research context. The app does not place trades. It hides directional signals until market data and model validation are explicitly approved.

## Current product rules

- NGX only, with NGN prices and daily closing timestamps.
- No sample prices or simulated sentiment are shown as market data.
- Missing and stale data are labeled; stale data cannot produce a directional signal.
- The primary research horizon is 10 trading days, with 5–20 day evaluation.
- New accounts require a one-use invitation from the backend operator.
- Portfolio holdings and watchlist entries remain manual.

## Run the app

Install Flutter dependencies, then run the app. It uses `https://hybstockadvisor-us.onrender.com/api` by default. To point it at a local backend, pass the backend origin without `/api` (Android emulator: `10.0.2.2:8000`; iOS simulator and web: `127.0.0.1:8000`):

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=https://your-api.example
```

The API host is public configuration. Never pass NGX, Gemini, database, JWT, or SMTP secrets to the Flutter build.

See the backend repository’s `MARKET_DATA_SETUP.md` for database migration, personal Investo setup, licensed NGX access for testers, invitations, and research workflow. The free Investo key is restricted to the configured owner account; tester market data requires a source agreement that permits that use.

## App areas

- **Dashboard:** NGX market summary and verified daily price history, with recency and unavailable states.
- **Research details:** available evidence and validation context, or an explicit explanation that no signal passed review. Lexi is available for timestamped data questions and general explanations.
- **Portfolio:** manual holdings and watchlists, showing local currency and closing-data recency. Market value and change alerts are omitted when data is missing or stale.
- **Account:** login and password recovery; invite-only registration is enforced by the backend.

## Checks

Run `flutter analyze` from this repository. The backend has unit and integration checks under `tests/`; run them from the backend repository with `python -m unittest discover -s tests -v`.
