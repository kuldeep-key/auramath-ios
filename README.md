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

| Key | `env/dev.json` | `env/dev-cloud.json` | `env/prod.json` |
| --- | --- | --- | --- |
| `API_BASE` | `http://localhost:8080` | `https://api-dev.auramath.net` | `https://api.auramath.net` |
| `DEMO` | `true` | `false` | `false` |
| `GOOGLE_IOS_CLIENT_ID` | set | set | empty |
| `PROBLEMS` | `bundled` (the sample pack; a local backend older than spec v0.4.1 has no `problems/next`) | `server` | `server` |

`env/dev-cloud.json` is the deployed dev backend: any `@key.ai` Google account signs in there. It sends no email yet (the link and the 6-digit code go to the API's Cloud Logging), so use Google sign-in day to day. Builds shared with testers use this file. Its lessons are not marked demo, so testers see their own summaries, plan, progress and resume (the server hides demo sessions from all four).

To try a screen whose flag is off on the server (the trail, badges, three in a row), add `--dart-define=FLAGS=trail,mastery_badges,three_in_a_row` to the run; `-name` switches one off. Never in a prod build.

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
- The contract test (`test_backend/backend_contract_test.dart`) drives the app's data layer over HTTP against a running backend. CI runs it on every pull request (`.github/workflows/contract.yml`, BE-22) through the backend's `scripts/contract/run.sh`, which starts the backend on Postgres and runs the test. Locally, from the backend's checkout:

  ```bash
  APP_DIR=../auramath-ios DATABASE_URL=postgres://tutor:tutor@localhost:5432/<empty db> scripts/contract/run.sh
  ```

### CI

`.github/workflows/contract.yml` needs the repository secret `CONTRACT_REPO_TOKEN`: a fine-grained token with Contents: read-only on `kuldeep-key/auramath-backend` (`GITHUB_TOKEN` cannot read another private repository). Without it the job prints a notice and is skipped. It tests against the backend's `deploy/ai-layer-dev`; another branch: the `backend_ref` input when run by hand, or the repository variable `CONTRACT_BACKEND_REF`.

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

## App links (PLAT-11)

The emailed sign-in link is `https://auramath.net/parent#m=<token>`. With the app installed it opens the app on Verify; without it, the browser.

- **iOS:** `ios/Runner/Runner.entitlements` claims `applinks:auramath.net`. iOS checks `https://auramath.net/.well-known/apple-app-site-association`, which the backend serves once `APPLE_APP_IDS` is `<TEAM_ID>.net.auramath.app`.
- **Android:** the `autoVerify` intent filter in `AndroidManifest.xml` claims `https://auramath.net/parent`. Android checks `https://auramath.net/.well-known/assetlinks.json`, which the backend serves once `ANDROID_APP_LINKS` is `net.auramath.app=<SHA-256 of the release key>` (`keytool -list -v -keystore <your keystore>`). Add the Play App Signing key's SHA-256 too once Play signs the app.
- Until those are set the files are a 404 and the link opens in the browser. `auramath://auth/verify?m=…` still works for dev.
- Only `m=` (sign-in) links open in the app. The others on `/parent` (`v=`, `r=`, `i=`) go to the app's start, so the backend should claim only `#m=*` in its AASA components.

## Release signing and sign-in ids (ACC-02)

Nothing secret is in this repo. The team provides each item below; the build reads it.

### Android release key

1. Create the upload key once and keep it out of git (`*.jks` and `key.properties` are ignored):

   ```bash
   keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Copy `android/key.properties.example` to `android/key.properties` and fill in the store path (relative to `android/`), alias and passwords.
3. `flutter build appbundle --release --dart-define-from-file=env/prod.json`.

Without a complete `key.properties`, release builds are signed with the debug key and Gradle prints a `WARNING`. Play refuses those. Put the release key's SHA-256 (and later Play App Signing's) into the backend's `ANDROID_APP_LINKS` and into the Android OAuth client in Google Cloud.

### Sign in with Apple

- `ios/Runner/Runner.entitlements` turns on Sign in with Apple and associated domains. The App ID `net.auramath.app` needs both capabilities in the Apple Developer account, and the provisioning profile must include them.
- **Team-provided:** the Apple Team ID, and a Services ID (for example `net.auramath.signin`) for the web and Android. Set the backend's `APPLE_CLIENT_ID` to `net.auramath.app,<services id>`: the iPhone's token names the bundle id, the web's names the Services ID. `APPLE_APP_IDS` is `<TEAM_ID>.net.auramath.app`.

### Google on iOS

- **Team-provided:** the prod iOS OAuth client id. Put it in `env/prod.json` as `GOOGLE_IOS_CLIENT_ID`. It is empty now, so the prod build's Google button says it isn't set up.
- Also add its reversed id (`com.googleusercontent.apps.<id>`) to `CFBundleURLTypes` in `ios/Runner/Info.plist`, beside the dev one.

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
