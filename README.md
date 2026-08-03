# budget-app-mobile — Direct Debits (iOS)

A native SwiftUI port of just the **Direct Debits** module from
[`budget-app-railway`](../budget-app-railway), for personal use on your own
device (not intended for App Store distribution).

It talks to the **same** Railway-hosted backend and Supabase Postgres
database as the web app — there's no separate backend here. Adding a debit
on your phone shows up on the website immediately, and vice versa.

## What was ported

- `backend/routes/directDebits.js` → `Networking/DirectDebitsAPI.swift` (same
  4 endpoints: list/create/update/delete under `/api/direct-debits`)
- `backend/routes/auth.js` → `Networking/AuthManager.swift` (same
  `POST /api/auth/login`, same JWT Bearer scheme)
- `frontend/src/pages/DirectDebits.jsx` → `Views/DirectDebitsListView.swift`
  + `DirectDebitFormView.swift` + `DirectDebitRowView.swift` +
  `SummaryCardsView.swift` + `Stores/DirectDebitsStore.swift` (month
  partitioning, copy-to-next-month, status/payment/tag/search filters, bulk
  "mark paid", due-soon highlighting, history log)

**Not ported** (out of scope for "just the Direct Debits module"): the Excel
export button, and every other page in the app (Transactions, Budgets,
Savings, Loans, Mortgage, chat, etc).

## Important: this code was written on Windows, unbuilt

I don't have Xcode/macOS/Swift Playgrounds access in this environment, so
none of this — including `Package.swift` — has been compiled or opened.
It's structured to match Swift Playgrounds' App-project format, but budget
for a fix or two on first open (see the fallback below if it won't open at
all).

## Opening on your iPad (Swift Playgrounds)

1. Get the whole `BudgetAppMobile.swiftpm` folder (not just the files inside
   it) onto your iPad — e.g. via the OneDrive app, since this repo already
   lives in your OneDrive-synced workspace. Make sure it lands somewhere in
   the Files app (an "On My iPad" or "Browse" location Playgrounds can see).
2. Install **Swift Playgrounds** from the App Store (free) if you don't have
   it.
3. In the Files app, tap `BudgetAppMobile.swiftpm` — it should open directly
   in Swift Playgrounds as a project (that's what the `.swiftpm` extension
   signals to iPadOS).
4. Tap **Run**. First run will ask you to trust your Apple ID as a developer
   under Settings → General → VPN & Device Management — follow the prompt.
5. Log in with the same `APP_USERNAME` / `APP_PASSWORD` you use on the web
   app.

**If step 3 doesn't open it as a runnable project** (Playgrounds' exact
`Package.swift` format has changed across versions, and I couldn't verify
this one against a real device): create a new blank **App** playground
in Swift Playgrounds first — this generates a guaranteed-correct
`Package.swift` for your installed version. Then, in the Files app, copy
everything from `BudgetAppMobile.swiftpm/Sources/BudgetAppMobile/` into
that new project's own `Sources/<TargetName>/` folder, overwriting its
placeholder file. Playgrounds' own `Package.swift` and target name stay as
generated — only the source files move over.

A free Apple ID sideload expires after **7 days**; just reopen the project
in Playgrounds and tap Run again to refresh it.

## Configuration

- **API base URL**: `Sources/BudgetAppMobile/Config.swift` — defaults to
  `https://vkannan.store/api`, matching `budget-app-railway/CLAUDE.md`'s
  documented custom domain. Change it if that domain ever changes.
- **Login**: uses the same `APP_USERNAME` / `APP_PASSWORD` you set in
  Railway's environment variables for the web app — there's no separate
  account system.
- **Session persistence**: the JWT is currently kept in memory only
  (`AuthManager`), so you'll need to log in again each time you relaunch the
  app. If that gets annoying, the next step is storing the token in iOS
  Keychain instead — ask and this can be added.
- **CORS**: `backend/server.js` only allows browser origins
  (`localhost:5173` / `FRONTEND_URL`) via CORS, but that's a browser-only
  restriction — it doesn't affect native `URLSession` requests from this
  app, so no backend changes are needed.

## Project layout

```
budget-app-mobile/
  BudgetAppMobile.swiftpm/
    Package.swift            Playgrounds/SwiftPM app manifest
    Sources/
      BudgetAppMobile/
        App/                 App entry point, root auth-gated view
        Config.swift         API base URL
        Models/              DirectDebit, HistoryEntry, DirectDebitPayload
        Networking/          APIClient, AuthManager, DirectDebitsAPI
        Stores/              DirectDebitsStore (all the business logic)
        Views/               LoginView, DirectDebitsListView, row/form/summary views
        Utilities/           Formatters (currency, month keys, ordinals, due-soon)
```

## If you later get access to a Mac

The same `Sources/BudgetAppMobile/*.swift` files work unchanged in a regular
Xcode project too — create a new iOS App (SwiftUI) project, delete its
default `ContentView.swift`/`*App.swift`, and drag these files in instead.
