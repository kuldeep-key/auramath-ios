# Auramath mobile: base architecture

27 Oct 2026 · proposal for approval

This repo holds the Auramath app (Flutter, iOS first, Android later) and the Dart teaching engine. The backend (Python API, Postgres, content and note workers) lives in its own repo; the app only talks to it over HTTP.

## 0. Sources of truth

| Source | Decides |
| --- | --- |
| Architecture v2 guide (27 Oct) | The rules: code decides, AI writes ahead of time, event log, offline, privacy |
| Living prototype (`auramath-prototype-standalone.html`) and Figma page "Screens · Prototype copy (27 Oct)" | Every screen, flow and behaviour in the app. Figma is a layer copy of the prototype at 390 × 844 |
| `docs/decisions-to-confirm.md` | Platform settings (bundle ID, minimum OS, devices) |

Everything in the prototype and Figma is in scope for the app. Screen IDs from Figma (`M1`, `D3`, `GPass`…) appear in each screen widget's doc comment (`/// Figma: M1`), so a designer and an engineer can search for the same thing.

## 1. Rules the code must keep

1. **Code decides.** Every right answer, mistake, hint, next problem, skill change and badge comes from the engine. The app never computes or shows a number the engine did not produce.
2. **No AI on the phone.** The app never calls a model. Everything a child sees or hears comes from a downloaded content pack or the app itself.
3. **The event log is the truth.** Every tap is saved as an append-only event, first on the phone, then on the server. Resume is a replay of events through the engine. No snapshots.
4. **Offline first.** Everything the child does works with no network. The grown-up area may need the network, and shows the last copy it saw when offline.
5. **No third-party SDKs in the child's experience** (no Firebase, Crashlytics, analytics). Child data leaves the phone only as events to our own API. The child's name is never in a recorded clip.
6. **The child never sees scores, streak counts or levels.** Badges say what the child did. Quick sums has an energy meter, not a count.

## 2. What the app contains

All of it maps to Figma sections. Grouped by who uses it:

**Setup and phones (Figma 1, 8, 10, 11)**
- Parent setup: Welcome, child's name, age, year, starting skill (or "I'm not sure"), goal, data consent, save place (Apple, Google or email), Ready.
- Free 5-minute check before sign-up (FC0 to FCR), keep or email the result (FCKeep), pick it up later (FCBack).
- Hand over on a shared phone: lock grown-up areas with Face ID or a 4-digit passcode, then "Who's learning?".
- Child's own phone: "I'm a kid", type the 6-digit join code (single use, 24 hours, 5 tries), "Is this you?", joined.
- Family and phones: add a phone, add a child (up to 6), invite a second grown-up, remove a lost phone, forgot passcode, sign in on a new phone, sign out.
- Notifications ask: our own screen first, then the system prompt.

**The child (Figma 2 to 6, 9, Lesson)**
- Home, My trail (with "New!" stops and top of the trail), My badges and badge close-up, pick your detective, meet your case partner (voice), welcome back, carry on or something new.
- Warm-up sums and a softer start after three "Not sure" answers, choose today, and a quick check every few weeks.
- The lesson: question full screen, meet the problem, draw it on the bar board, place the gap, choose the sum, solve, case cracked, your badge, sent to your grown-up, case closed.
- Help: hint ladder, show me how (smaller worked example), an easier one, side lessons (take away across a ten, adding with a carry), what does this word mean, a simpler number sentence, check your sum again, write the number sentence.
- Not yet: wobble with no red or cross, Help me shakes, longer or shorter bar prompt.
- Quiet, paused or away: next move glows (25 s), hand shows the drag (40 s), "Still there?", auto pause on a call or lock, pause, time's up, sound off, offline, voice not working.
- Other activities: quick sums rush, level 1 one-step cases, weights with bars across, total and difference, bar sense, counting patterns with a hundred chart hint, the flip, same pattern with new numbers.

**The grown-up (Figma 7, 10, 11, Other screens), behind the lock**
- Grown-up home with each child, child's book (this week, skills, badges), month view chart since the free check, the plan (age, year, level, goal), settings, your data and rights (download, fix, delete), membership (Free and Family, 7-day trial).

The emails (`Email`, `FirstEmail`) are sent by the backend; the app only links into the book from them.

## 3. Repo layout

Follows Flutter's recommended layering: UI (views and view models) and data (repositories and services). The engine package is the domain layer.

```
auramath-ios/
  lib/
    main.dart                  reads env, builds services and repositories, starts the app
    routing.dart               go_router; routes named by Figma screen ID
    data/
      services/                api_client, outbox_db (SQLite), pack_store, audio, secure_store,
                               biometrics, purchases, push
      repositories/            auth, family, devices, session (event log + sync), packs,
                               progress (book, month view), membership
      models/                  API JSON models
    ui/
      core/
        theme/                 colours, Nunito type scale, radii, shadows (from the prototype CSS)
        parts/                 one widget per Figma "Prototype parts" component: Button, Card,
                               Pill, Chip, Keypad, Speech bubble, Story card, Trail stop, Ribbon…
        board/                 Board, Bar, Brace, Gap segment, Tray piece, Ten stick, Mini bar,
                               Number box, Number line hop, Number sentence
      features/
        setup/                 Figma 1 + free check (FC*) + Lock + Notify
        join/                  Open, GetCode, IsThisYou, PhoneJoined, CodeWrong, NewCode
        child_home/            A1, Home, trail, badges, LookPick, Voice, WelcomeBack, R2
        lesson/                A2, A3, M*, D*, H*, W*, T*, J*, S*, Q*, Y*, X1, N*, PA, TU, Check…
        activities/            QS*, L*, WT*, TD*, BS*, NS*
        grown_up/              GPass, PHome, Book, Monthly, Plan, Settings, Rights, Family,
                               Invite, AddChild, WhichChild, RemovePhone, Plans, SignOut…
  packages/auramath_engine/    pure Dart, no Flutter, no IO
    lib/                       rule interpreter
    bin/auramath_check.dart    command-line checker for the backend
    test/golden/               golden vectors (JSON)
  assets/
    fonts/                     Nunito (bundled, never fetched at runtime)
    images/                    detectives, badges, story objects (exported from Figma "Assets")
    sounds/                    UI sound packs
    sample_pack/               one pack so the app runs with no backend
  env/                         dev.json, prod.json
  test/  ios/  android/  docs/
```

Each feature has a view (widget) and a view model (`ChangeNotifier`, shown with `ListenableBuilder`). View models get repositories through their constructor; `provider` hands them down the tree. Repositories own caching, offline and retry; services are thin wrappers over HTTP, SQLite and plugins.

## 4. The engine (`packages/auramath_engine`)

- **Pure.** No network, no clock, no files, no randomness it was not given. Time and seeds come in as inputs.
- **Two functions:** `replay(pack, profile, events) -> LessonState` and `step(pack, state, input) -> (newState, decisions)`. A timer tick is an input, so quiet timers, the quick sums fuse and time's up are all engine decisions.
- **Rules are data in the pack.** Activities, levels, steps, mistake routes, hints, side lessons, timer lengths, what comes next ("how he solved it decides what comes next": flip, same pattern or easier one), skill moves, and badge rules. A teaching change is a pack update, not an app release.
- **Activities it runs:** comparison story problems (and the flip, same pattern, easier one), one-step level 1 cases, weights, total and difference, bar sense, counting patterns, quick sums, warm-up, free check and the quick check.
- **Badges.** The engine awards one per session, always true, plus the "On a roll" surprise. Badge definitions live in the pack; the art ships with the app.
- **Placement.** The free check and warm-up produce a starting skill; "I'm not sure" starts at a typical level and lets the first sums find the real one.
- **Replay scope.** Replay covers the current session. The child's profile (skill, trail, badges earned) comes from the server and is cached on the phone, so the child side still works offline.
- **Golden vectors** in JSON are run by both the Dart tests and the backend's Python tests. The **checker CLI** reads a problem and prints the answers and every mistake route's number. Until real content arrives, the sample pack uses the four Figma problems (lemon tree, easier one, mango, the flip), marked as sample data.

## 5. Identity, phones and the grown-up lock

- **Family account:** Sign in with Apple, Google Sign-In, or an email link that opens the app (universal links / App Links on `auramath.net`). The token lives in the Keychain / Keystore.
- **Shared phone:** the parent stays signed in; "Who's learning?" picks the child. The grown-up lock is Face ID / fingerprint (`local_auth`) or a 4-digit passcode stored as a salted hash in secure storage. "Forgot passcode" means signing in again.
- **Child's own phone:** the join code is exchanged for a device token scoped to that child (or to several children for a shared phone, WhichChild). That phone can never open the grown-up area.
- **Removed phone:** the next API call returns "removed"; the app sends any events still waiting, wipes local data and shows `Removed`. Progress lives with the child on the server.
- **Before sign-up:** the free check runs under a temporary local child id. On save, its events upload and attach to the new child. On "Not now" they stay on the phone until the parent comes back or asks for the result by email.

## 6. Data on the phone and sync

- **Write path (events).** Every event goes into SQLite (`sqflite`) first: `session_id`, `seq`, timestamp, pack version, problem or line id, schema version. A sync loop sends batches, retries after 2 s doubling to 30 s and on every return to the foreground. The server ignores a repeated (session_id, seq). If the server says a session is finished, the phone drops its copy. Error reports ride the same outbox as their own event kind; there is no crash SDK.
- **Read path (profile and grown-up views).** The child profile, the book, the month view, family and membership come from the API. Each repository keeps the last response on disk, so screens open offline with the last copy and a quiet "offline" note.
- **Resume on another phone:** the app downloads that session's events and replays them; "Learning on another phone" shows on the old one.
- **Badge earned offline:** kept on the phone as an event, reaches the grown-up when it syncs (Y4off).

## 7. Packs, audio and assets

- The API returns a manifest; the app downloads the pack and the clips for the next 3 problems from the CDN, for the chosen case partner voice only.
- Every pack is checked against an Ed25519 signature (`cryptography`) with public keys from `env/`; two keys are allowed for rotation. Packs live in the app support folder, which iOS does not wipe.
- Clips play with `just_audio`. A missing clip falls back to the device voice (`flutter_tts`, on device); no voice at all shows "My voice is resting" with bigger words. Lines with the child's name always use the device voice.
- UI sound packs, detective and badge art, story object images and the Nunito font ship inside the app.

## 8. Membership

- Free (a few lessons each week, session note) and Family (every day, full book and month view, plan builder, up to 6 children, 7-day free trial), from the `Plans` screen.
- Purchases use Flutter's official `in_app_purchase` plugin (StoreKit on iOS, Play Billing on Android), only from the grown-up area. The backend verifies receipts and owns the entitlement; the app reads it from the API and caches it.
- The engine is told the weekly lesson allowance as an input; the child never sees a lock ("Aarav never sees a lock").

## 9. Notifications

- One kind: "a note after each session" to the parent. Our own ask first, then the system prompt, so a "no" never wastes it.
- The backend sends the push after `session_ended`. On iOS the app registers with APNs directly through a small native channel (no Firebase). Android push needs FCM, which is a third-party SDK; that decision waits for the Android release.

## 10. Platform settings

Bundle ID / application ID `net.auramath.app`; iOS 16+, Android 8.0 (API 26)+; iPhone only at first release, portrait only (my call), screens laid out for 390 × 844 and adaptive for later iPad; English only.

## 11. Testing

- **Engine:** golden vectors plus unit tests. Most tests live here, because the engine makes every decision.
- **View models and repositories:** unit tests against a `FakeApi` and the sample pack, including outbox retry, duplicates, removed phone and the free check upload.
- **Widgets:** tests for the board parts (drag and its tap alternative, LES-13) and key screens.
- **Accessibility:** a test that every theme colour pair meets contrast rules.
- CI waits for the iOS build service decision; until then `flutter analyze` and `flutter test` run locally.

## 12. Build order

1. Project at the repo root with the platform settings, theme, fonts, assets and the `parts/` widget kit.
2. Engine: rule interpreter, comparison activity with its four sample problems, golden vectors, checker CLI.
3. The lesson end to end on the sample pack: board, keypad, help, not yet, quiet timers, pause, case cracked, badge.
4. Outbox, sync and resume against `FakeApi`.
5. Setup, free check, shared phone lock and child's own phone join.
6. Child home: trail, badges, detective, voice, welcome back.
7. Packs, signature check, audio and the device-voice fallback.
8. Other activities: quick sums, weights, total and difference, bar sense, counting patterns, level 1.
9. Grown-up area: home, book, month view, plan, settings, data and rights, family and phones.
10. Membership and notifications.

The real API replaces `FakeApi` screen by screen as the backend lands.

## 13. Built for change

Everything in sections 0 to 12 is the baseline. New features, screens and design changes will keep coming, so each kind of change has one place it lands:

| Change | Where it lands | App release? |
| --- | --- | --- |
| Teaching: new problems, levels, hints, routes, timers, badge rules | Pack data from the backend | No |
| Turn a feature on or off, or roll it out to some families | A `flags` map in the pack manifest from the API | No |
| Wording on a screen | One English strings file (`lib/l10n/app_en.arb`, Flutter's `gen-l10n`); a new language later is a new file | Yes, but one file |
| Colours, type, spacing, corner radius | `ui/core/theme/` only; no screen hard-codes a colour or size | Yes, one place |
| A Figma component changes | Its one widget in `ui/core/parts/` or `ui/core/board/`; every screen picks it up | Yes, one place |
| A new screen or flow | A new folder in `ui/features/` plus one route | Yes |
| A new activity type | Engine rules for it, plus one board view registered under its activity id | Yes, once; its content then flows through packs |
| Backend API changes | `data/services/` and `data/models/`; repositories map API JSON to app models, so screens never see the change | Yes, small |
| Event or pack format changes | Both carry a schema version; the app reads every version it has ever shipped | Yes |

Rules that keep this true: features never import each other (they share only `ui/core/` and repositories); screens never call services directly; every new behaviour gets a test next to it.

## 14. Open calls (not blockers)

- **Simple report (R0):** Julia asked for star ratings, but the PRD says no rating ("still Apoorv's call"). Built without stars until decided.
- **Number pad:** Figma's Keypad is a copy of the iPhone number pad plus a done key and + / − keys (needed for "write the number sentence"). The system pad has no + / −, so we build it in-app to look like the system one; it then also looks the same on Android.
- **Android push:** needs FCM; decide before the Android release.

## 15. Left to the builder

Widget structure inside each feature, file names, the exact pack JSON fields (drafted in the engine and shared with the backend), animations (confetti, wobble, energy meter), and the exact API endpoints (drafted with `FakeApi`, aligned with the backend later).
