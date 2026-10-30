# Delta: what exists today vs what we have to build

28 Oct 2026 · compared against three sources:

- **Architecture v2 guide** (27 Oct, cites PRD v3.3). The spec we build the app from.
- **Spec pack v0.3.0** (9 Oct, PRD v3.2), vendored in the backend at `auramath-backend/spec/`: 120 requirements, the event contract, the comparison template, tutor policy and scoring.
- **Figma and the prototype** (26 Oct, 82 journeys).

Systems checked:

- **Mobile app:** branch `feat/app-base`.
- **Backend:** `auramath-backend`, branch `feature/initial-setup`, at commit `4740765`. It had 39 new commits since 27 Oct; I pulled them into the local clone.

## 1. The five gaps that matter most

| # | Gap | Who | Why it matters |
| --- | --- | --- | --- |
| 1 | **The app's events don't match the backend's contract.** The app sends its own names (`BarADrawn`, `NumberEntered`…). The backend accepts only the spec's 35 names (`step_entered`, `value_entered`, `hint_shown`…) in a new envelope (`event_id`, `child_ref`, `device_id`, `app_version`, `payload`), or the old 18 burger names. | App | Connected today, the backend would refuse every event the app sends. This is the app's next job. |
| 2 | **Two teaching brains.** The backend runs its own Python lesson machine (a port of the August TypeScript core, for the burger problem). The app runs the Dart engine (the comparison problem). | Backend | The guide's rule is one engine. Today the server's reports and mastery are built from burger-lesson events the new app will never send. See section 4. |
| 3 | **The server creates session ids.** `POST /api/sessions` makes the id and fixes the problem to the burger one. | Backend | v2 needs the phone to start a lesson offline, so the phone has to create the id. |
| 4 | **No content pipeline or signed packs.** No story generation, no number picking, no two-way answer check, no pack manifest or signature, no CDN, no audio. The backend serves the spec's YAML values (`/api/content/bundle`), not problem packs. | Backend / AI | The app can only play the 4 problems we wrote by hand. CON-01, CON-08 and the read-aloud audio all depend on this. |
| 5 | **The API language is different from the guide.** The guide says keep the Node API and use Python only for the AI services. The team rebuilt the API in Python (FastAPI). | Lead decision | Not wrong in itself, but the guide and the ADRs need to say so, or the next engineer builds the wrong thing. |

## 2. Backend: built vs required

**Built and in line with the requirements** (good news, more than on 27 Oct):

- **Sign-in:** Apple, Google, and email link (ACC-02). Password sign-in still exists too.
- **Accounts:** versioned consent that gates the child (ACC-03), invited second grown-up (ACC-08), export and erase that survive a restore (ACC-09), optional child profile with no gender (ACC-04, PRV-07).
- **Devices:** 6-digit pairing codes, 10 minutes, 5 tries (DEV-02); remove a phone (DEV-03); phone tokens can write but not read the record (DEV-04); a resume lookup (DEV-05).
- **Event intake:** each event is checked against the spec contract and refused with reasons; repeats are ignored by `event_id` or `seq` (DAT-02, DAT-04, DAT-07).
- **Parent report:** emailed after each session; every sentence carries event ids and is checked; template fallback; report settings; grown-up passcode (PAR-01 to PAR-05, PAR-10).
- **Spaced checks** at 7 and 21 days after moving up (SKL-06).
- **Platform:** Australian regions, dev/prod split, real families refused without a recorded sign-off, CI checks the spec files (PLAT-01, PLAT-02, PLAT-05, PRV-05).
- **Live AI line rewriting is switched off** (`model_rewording: false`, D-26), so there's no model call during a lesson.

**Missing or different:**

| Area | Required (guide / spec) | Backend today |
| --- | --- | --- |
| Session start | Phone creates the session id; any problem from a pack | Server creates the id; problem fixed to `burger-drink` |
| Reports and mastery | Built from the v2 events | Built from old burger events (`evaluation_produced`, `step_satisfied`, `hint_level_raised`); new events are stored but not read |
| Content | Python pipeline: Gemini story pieces → code picks numbers → Dart engine checks → signed pack → CDN, nightly | None; only the spec's YAML values |
| Audio | Text-to-speech clips per problem, 3 problems ahead | None |
| Parent note | Separate Python note worker on Pub/Sub, sees only a random key | Inside the API; drafts with the model, falls back to a template. Works, but not split out |
| Database | Three schemas (identity / record / derived); Python role that can't read identity | One schema |
| Messaging | Pub/Sub: session-ended, content-merged, pack-published | None |
| Error reporting | Our own endpoint (DAT-08) | `/api/analytics/events` exists; an app error endpoint isn't confirmed |
| Old web endpoints | Retired with the web app | Still there: `/api/utterance`, `/api/presenter`, `/api/problems`, `/api/rubric` |

## 3. Mobile app: built vs required

**Built:** the lesson for one comparison problem, end to end on a real Android emulator.

- **Lesson:** question first, the bar board with a tap for every drag, wrong moves wobble, Help me shakes after two misses, "I know it" with the answer-sheet routes, mistake routes and side lessons, hints, quiet-child timers, choosing the sum, the number pad, the badge and the next problem.
- **Data:** offline outbox with retry, and replay through the engine.
- **Base:** the theme and parts from Figma, the device voice, and English strings in one file.

**Missing, by milestone** (spec milestones: M2 = child lesson in dev, M3 = 17 Nov parent loop, M4 = 1–8 Dec five families):

| Milestone | Missing in the app | Requirement ids |
| --- | --- | --- |
| M2 (now) | **Spec event contract** (35 names, envelope, payloads) | DAT-03, DAT-04, DAT-05, DAT-06 |
| M2 | **Engine reads the spec template:** levels L1–L5, the spec's step and error names, and "Something easier" as one level down. Today the engine is hand-coded with our own names and one level | PLAT-03, SKL-10, CON-06, SKL-08 |
| M2 | Choices that check the reading (the optional "name the quantities" step) | LES-12, TUT-16 |
| M2 | 30-minute session cap with the work kept, pause and resume, leave a question and come back | SES-01, SES-03, SES-06 |
| M2 | Approved line library with 3–5 versions per line, never the same one twice in a row | TUT-11, TUT-14 |
| M2 | Full "Show me how" worked example and the interactive side-lesson board (today both are simple versions) | TUT-03, TUT-05, TUT-08, CON-05 |
| M2+ | Hidden score per skill, moving up a level, choosing the next problem | SKL-02 to SKL-05, SKL-09 |
| M2+ | Tap a word to see its meaning; an easier number sentence; quick sums (behind a flag) | LES-10, TUT-09, LES-16 |
| M2+ | Content pack download, signature check, 3 problems ahead | CON-01, CON-08 |
| M3 | **Parent setup:** sign in with Apple or Google, consent, child profile, "ask parents not to help" | ACC-01 to ACC-06, ACC-10 |
| M3 | **Phones:** hand the parent's phone to the child, pair the child's phone with a 6-digit code, switch phones mid-lesson | DEV-01, DEV-02, DEV-05 |
| M3 | Grown-up area behind the passcode: the book, the plan, settings, report email controls | ACC-07, PRV-06, PAR-05, PAR-06 |
| M3 | Read-aloud with recorded clips, and "My voice is resting" | NFR-06 |
| M3 | Accessibility to WCAG 2.2 AA (only partly checked so far) | NFR-04 |
| M4 | Real API client, TestFlight, error reporting to our own endpoint | DAT-08 |

## 4. The Dart engine vs the Python logic

**What the Dart engine is** (`packages/auramath_engine` in this repo): the app's teaching brain. Given the problem and every tap so far, it decides:

- whether the move is right;
- which mistake a wrong answer shows (81 = a regrouping slip);
- which hint comes next, and when a side lesson or "Help me" shake starts;
- the badge and the next problem.

It runs on the phone, offline, with no clock or randomness. Same taps in, same decisions out, every time. It also builds a command-line checker (`auramath_check`) so the Python side can check problems with the phone's exact rules.

**What the Python logic is** (`auramath-backend/auramath/core/`, about 4,300 lines): a line-by-line port of the August TypeScript core. It even carries shims (`_js.py`) so Python rounds like JavaScript. It is a **second, complete lesson machine** for the old **burger problem** (total and difference):

- its own evaluator over a drawing canvas, tutor policy, hint ladder, mastery, walkthrough and parent summary;
- the server uses it to rebuild mastery and the parent report from events;
- it also serves the old web app's problems and rubric.

**Why two brains is a problem:**

1. **They teach different things.** Python knows burger events. The app sends comparison events. The server's report and mastery would come out empty or wrong for every real v2 lesson.
2. **Even on the same problem they would drift.** Every teaching change would have to be made twice, in two languages, and kept identical. The guide's rule is "one engine, so the app and the checker can never disagree". A parent report that disagrees with what the child saw breaks PAR-02 ("every sentence is true").
3. **The spec says the phone decides.** The server's job is to store the record and read it, not to re-teach the lesson.

**The fix (my recommendation):**

- **The phone writes its decisions into the events.** For example, `value_entered` carries the value, whether it was right and the `error_type`; `hint_shown` carries the rung. The backend builds the report and mastery by reading those fields. It doesn't re-run any lesson logic.
- **When the server must re-check something** (a rebuild job, or the content pipeline checking a new problem), it calls the Dart checker (`dart compile exe`). This is already built and tested in this repo.
- **The backend retires `core/`** (session, evaluator, policy, walkthrough, problems) along with the old web endpoints. It keeps only the event-reading parts of the report.

## 5. Where the sources disagree (to settle)

- **API language:** the guide says Node; the backend is Python. Update the guide or an ADR.
- **Event names:** the guide's example uses `answer_checked`; the spec contract says `value_entered`. The contract wins, since it's what the backend enforces.
- **iPad:** the PRD says not this term; the guide says adaptive. You confirmed iPhone first with screens that adapt to iPad.

## 6. Suggested order

1. **App:** switch to the spec event contract, and have the engine read the spec's comparison template (levels, step ids, error types). Golden vectors are shared with the backend.
2. **Backend:**
   - let the phone create the session id;
   - read the v2 events for the report and mastery;
   - retire `core/` and the old web endpoints;
   - call the Dart checker wherever it needs to check a problem.
3. **Backend / AI:** the content pipeline and signed packs, then audio.
4. **App:** parent setup, phones and the grown-up area (M3), then read-aloud.
