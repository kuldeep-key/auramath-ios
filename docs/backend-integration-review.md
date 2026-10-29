# Backend review: what we can connect now, what's missing, and Tuesday

29 Oct 2026. Mobile app is on branch `feat/app-base`. The backend is `auramath-backend`, branch `feature/initial-setup`, at commit `4740765`. There have been no new backend commits since 28 Oct, and `prod` is still the initial commit.

**How this was checked:**
- I read the backend's routes.
- I ran the backend on this Mac (`make dev`, localhost:8080, dev mode, demo parent token).
- I sent it real calls:
  - created a session;
  - posted the spec's 21-event example lesson;
  - paired a phone with a 6-digit code;
  - used the phone token to start a session;
  - read the content bundle.
- The deployed addresses (`api.auramath.net`, `auramath.net`) don't answer, so there is no shared dev server yet.

## 1. Summary

- **We can connect the child's lesson to the backend now.** Sessions, events, pairing and resume all work. The local test accepted all 21 spec events.
- **Two things block a clean connection:**
  1. The server makes the session id.
  2. The server fixes the child id (`child_ref`).

  So the app has to ask the server for a session before it sends events. Today the app makes its own ids, and the server rejected those events with "session_id: does not match the session in the URL".
- **What the server builds from the events is wrong for our lesson.** Mastery, the level, spaced checks and the parent report all come from the old burger lesson. In the test, a solved lesson came back as "The taught problem was not completed." The events are stored, but they aren't read.
- **Parent sign-in is built but can't be switched on yet.** Google needs a client id. Apple needs the Apple developer account. Email needs a mail service.

## 2. What we can connect today

| Backend feature | Route | Tested | Use in the app |
| --- | --- | --- | --- |
| Start a session | `POST /api/sessions` | Yes, 200; returns `id` and `childRef` | At lesson start. Put the returned id and `childRef` in every event. |
| Send events | `POST /api/sessions/{id}/events` | Yes, 21 of 21 accepted | The outbox sync. A repeat send is ignored by `event_id`. Refused events come back with reasons, and the app must show them as errors, not drop them. |
| Pair a phone | `POST /api/devices/pairing` (parent), `POST /api/devices/redeem` (phone) | Yes; code then phone token | Child-phone pairing screen. The phone token can start sessions and send events, but can't read the record (403, as the spec says). |
| List and remove phones | `GET /api/devices`, `DELETE /api/devices/{id}` | Read only | The grown-up area, later. |
| Resume on another phone | `GET /api/sessions/resumable` | Read only | It returns the unfinished session's events, which the app can replay with its own engine. Its "phase/step" hint comes from the burger machine, so ignore it. |
| Health | `GET /api/health` | Yes | The "Lost the internet" check. |
| Content values | `GET /api/content/bundle` | Yes; version hash `fc91fab64b01` | Optional: compare with the spec files bundled in the app. These are spec values, not problem packs. |
| Parent sign-in | `POST /api/auth/google`, `/apple`, `/email-link` (+ `/verify`) | Config only | Returns a parent token. Today Google and Apple return 501 (not configured); the email link works in dev. |
| Family setup | `POST/GET /api/children`, `POST /api/parent/consent`, `GET /api/parent/consents` | Read only | Parent setup: child profile and consent. |
| Grown-up area | `GET/PUT /api/family/passcode`, `POST /api/family/passcode/check`, `GET/PUT /api/family/settings/reports`, `GET /api/children/{id}/plan` | Read only | Passcode gate, report email settings, the plan. |
| Privacy | `GET /api/parent/export`, `POST /api/parent/export-jobs`, `POST /api/parent/erase`, invites and members | Read only | Export, delete the account, second grown-up. |

**Small things to agree with the backend:**

- **`device_id`.** The contract wants `dv_` plus 8–32 letters or digits. Pairing returns a UUID. Suggestion: the app sends `dv_` plus the UUID with its dashes removed, the same rule the server uses for `child_ref`.
- **Google sign-in client id.** The backend checks one Google client id. Mobile sign-in has to request its token for that same id, or the backend must accept the iOS and Android client ids too.
- **Phones need HTTPS.** iOS blocks plain `http://` except on localhost. A shared dev server needs HTTPS (a `*.run.app` address is enough).

## 3. What the backend is missing for the first version

| # | Missing | Why it matters | Size |
| --- | --- | --- | --- |
| B1 | **Accept a session id made by the phone.** `POST /api/sessions` should take an `id`. | The child can start a lesson offline (the spec). Without this, the app must be online at the start of every lesson. | Small (a few lines) |
| B2 | **Mastery, level, spaced checks and parent report read the new events.** They should use `step_committed` (`correct`, `error_type`), `hint_shown` and `problem_completed` (`outcome`, `wrong_count`, `hints_used`). | Without this, every parent note is wrong or empty. "A parent gets a true note" is the 17 Nov goal. | Medium |
| B3 | **Sessions shouldn't be fixed to `burger-drink`.** The problem comes from `problem_shown`. | Reports and the plan would name the wrong problem. | Small, with B2 |
| B4 | **A shared dev server phones can reach**, over HTTPS; then a prod project in Australia. | Without it, nothing runs on a real phone, TestFlight included. | Infra |
| B5 | **Sign-in switched on:** Google client ids (web, iOS, Android) and the Apple client id. | Parents can't sign up in the app. Apple needs the developer account (Julia meeting). | Config, once accounts exist |
| B6 | **A mail service.** | The parent report is an email (PAR-01), and so is email sign-in. Today mail only logs to the console. | Small + a provider decision |
| B7 | **Real-family sign-off** (`ALLOW_REAL_ACCOUNTS`, after the legal review). | The five families at home can't be created without it. | Decision, not code |
| B8 | **An endpoint for app errors** (DAT-08). | The app needs somewhere to report its own errors. Only an analytics read exists today. | Small |

**Can wait until after the first version:**
- signed content packs, the story pipeline and recorded audio;
- retiring the Python lesson machine (`core/`) and the old web routes;
- three DB schemas, Pub/Sub, a separate note worker.

Content packs can wait only if product accepts that the phone makes the problems from Julia's template. The app already does this for all 5 levels.

## 4. What the app is missing for the first version

**Done since the 28 Oct delta:**
- spec event format;
- Julia's template with 5 levels and generated problems;
- the 30-minute cap and taking a break;
- resume;
- the "Lost the internet" notice.

| # | Missing | Needs from backend |
| --- | --- | --- |
| A1 | **Real HTTP client** in place of `FakeApi`. Every failure becomes `ApiException`, and refused events are shown, not dropped. | None, works today |
| A2 | **Session handshake:** ask the server for a session, then use its `id` and `childRef`. | Works today (B1 makes offline start possible) |
| A3 | **Child phone pairing:** enter the 6-digit code; keep the phone token in the Keychain. | Works today |
| A4 | **Level progression:** a hidden score per skill, move up or down, choose the next problem. This is how difficulty rises with performance. | None (the phone decides) |
| A5 | **Parent setup:** sign in with Apple or Google, consent, child profile, "please don't help", make a pairing code. | B5 |
| A6 | **Grown-up area:** passcode, report settings, remove a phone, delete the account. Apple requires in-app account deletion for App Store release. | Works today |
| A7 | **Release:** app icon and splash (Apoorv), TestFlight and Play internal testing, prod settings. | B4, developer accounts |
| A8 | **Accessibility pass** (WCAG 2.2 AA) and read-aloud with the device voice. The voice works; recorded clips can wait. | None |

## 5. Tuesday 3 Nov

None of our docs say what Tuesday's delivery is. Below is my proposal; please confirm or correct the scope.

**Proposed Tuesday goal:** a child does the lesson on a phone. Every tap reaches the dev backend and is stored, and the phone is paired with a 6-digit code. There is no parent sign-in yet; a dev parent token makes the code.

**Required from us (app):**
1. A1: real HTTP client, base URL from the env file.
2. A2: session handshake. If the phone is offline at the start, the lesson still runs, and the session is created and the events sent when it's back online.
3. A3: pairing screen and token storage. `device_id` uses the `dv_` rule above.
4. A check, run on both the Android emulator and the iPhone simulator, against the backend, that the lesson's events show up on the server.

**Required from the backend team:**
1. B1, or agree to the online-start fallback in step 2 above.
2. B4: a dev URL with HTTPS for real phones. Without it, Tuesday is emulator and simulator only, against a backend on this Mac.
3. Agree the `device_id` format.
4. A way to make a pairing code in dev. The dev parent token works today.

**Not in Tuesday:**
- parent sign-in, which needs the Google and Apple accounts;
- parent reports from the new events (B2);
- level progression (A4);
- content packs.

**Open decision that changes this:** product's reply on running the lesson online (`docs/flag-online-lesson.md`). If the lesson is online, B1 matters less, and the session handshake gets simpler.
