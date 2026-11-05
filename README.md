# Auramath mobile

The Auramath app: bar-model word problems for children aged 6 to 10, with a grown-up's area for the family. Flutter, iPhone first; Android also works.

The app is **online-first**: the server opens each lesson and records every tap, while the answer checking runs on the phone in the Dart teaching engine (`packages/auramath_engine`).

## Requirements

- Flutter 3.44 (Dart 3.12)
- Xcode with an iOS 18 simulator, and/or Android Studio with an API 35 emulator
- The backend, [`auramath-backend`](https://github.com/kuldeep-key/auramath-backend) (`feature/initial-setup`), running locally

## Run

1. **Start the backend:** `make dev` in `auramath-backend`. It listens on http://localhost:8080.
2. **Invite a family.** The dev server lets in invited families only:

   ```bash
   curl -s -X POST localhost:8080/api/admin/parents \
     -H 'Authorization: Bearer demo-operator-token' \
     -H 'Content-Type: application/json' \
     -d '{"email":"tester1@example.com"}'
   ```

3. **Run the app:**

   ```bash
   flutter run -d <device> --dart-define-from-file=env/dev.json
   ```

   On the Android emulator, run `adb reverse tcp:8080 tcp:8080` first so it can reach the backend.

4. **Start fresh** (forget the sign-in and pairing):
   - iOS: `xcrun simctl uninstall <device> net.auramath.app && xcrun simctl keychain <device> reset`
   - Android: `adb uninstall net.auramath.app`

The flows to try by hand, step by step, are in [`docs/testing-guide.md`](docs/testing-guide.md).

### Settings

`--dart-define-from-file` picks the environment:

| Key | `env/dev.json` | `env/prod.json` |
| --- | --- | --- |
| `API_BASE` | `http://localhost:8080` | `https://api.auramath.net` |
| `DEMO` | `true` | `false` |
| `GOOGLE_IOS_CLIENT_ID` | empty | empty |

Apple and Google sign-in stay switched off until their client ids and the Apple developer account exist. Email-link sign-in works now.

## Test

```bash
flutter analyze
flutter test                                  # unit, widget and screenshot tests
(cd packages/auramath_engine && dart test)    # the teaching engine
```

- The screenshot tests (`test/helpers/shots.dart`) render every screen at iPhone, small iPhone, large iPhone and iPad sizes. They fail on overflow, on touch targets under 44/48 pt, on unlabelled taps and on low text contrast.
- The end-to-end tests run against the local backend on a simulator or emulator:

  ```bash
  flutter test integration_test/setup_to_lesson_test.dart -d <device> --dart-define-from-file=env/dev.json
  flutter test integration_test/pair_to_lesson_test.dart -d <device> --dart-define-from-file=env/dev.json
  ```

  `setup_to_lesson` covers the grown-up's setup through a lesson the server records. `pair_to_lesson` covers a child's phone pairing with a code through a lesson. Start fresh before each run.

## Project layout

```
lib/
  main.dart, app.dart, deps.dart   start-up and the shared dependencies
  config/                          environment settings
  routing/                         paths, the router and its access rules per role
  data/
    services/                      HTTP client, secure storage, the event outbox, voice, sign-in plugins
    repositories/                  account, family, sessions, progress, setup, grown-up
    models/
  ui/
    core/                          theme tokens (from Figma) and shared parts: button, choice, keypad, page frame
    features/
      setup/                       grown-up setup, consent and sign-in
      pairing/                     the child's own phone: code, who's here, removed
      lesson/                      the lesson: bars, sum, answers, help, breaks
      child_home/                  home, badges, trail, after-case screens
      grown_ups/                   the grown-up area behind the passcode
  l10n/                            English strings (app_en.arb)
packages/auramath_engine/          the pure-Dart teaching engine: problems, steps, mistakes, the event contract
assets/                            fonts, images, the sample problem pack and the vendored spec files
integration_test/                  end-to-end tests against the backend
test/                              unit, widget and screenshot tests
```

The architecture is MVVM: views listen to `ChangeNotifier` view models, which call repositories. Navigation is `go_router`, with redirects for each role (no account, the child's own phone, a grown-up).

## Docs

| Doc | What it covers |
| --- | --- |
| [`docs/architecture.md`](docs/architecture.md) | The app's architecture and main choices |
| [`docs/testing-guide.md`](docs/testing-guide.md) | Testing the grown-up and child flows by hand |
| [`docs/backend-integration-review.md`](docs/backend-integration-review.md) | What the app uses from the backend, and what the backend still needs |
| [`docs/status-2026-10-29.md`](docs/status-2026-10-29.md) | Status on 29 Oct: what's built, backend and Figma alignment |
| [`docs/plans/`](docs/plans/) | Build plans, by date |
| [`docs/knowledge/`](docs/knowledge/) | Summaries of the PRD and the product documents |

## Not working yet

- Apple and Google sign-in, real emailed links and TestFlight wait on the accounts and keys.
- Real phones need an HTTPS dev server.
- The book, plan and report are mostly empty until the backend builds them from the new lesson events.
- Problems come from a sample pack of 4 until the backend sends generated ones.
