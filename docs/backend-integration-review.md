# Backend review and gaps: online-first

29 Oct 2026 (updated). Mobile app is on branch `feat/app-base`. The backend is `auramath-backend`, branch `feature/initial-setup`, at commit `4740765`.

**Decision taken:** the app is online-first. A lesson needs an internet connection. Short drops are held and resent; a longer drop pauses the lesson, which then resumes where it stopped. See `docs/flag-online-lesson.md`.

**Also decided:** the Google and Apple client ids come later. We build sign-in, setup and every screen end to end now, then switch the keys on when they arrive.

## How this was checked

- I read the backend's routes, then ran it on this Mac (`make dev`, localhost:8080, dev mode). The deployed addresses (`api.auramath.net`, `auramath.net`) don't answer, so there is no shared dev server yet.
- I sent it real calls:
  - created a session and posted the spec's 21-event example lesson: all 21 accepted;
  - paired a phone with a 6-digit code, and the phone token started a session;
  - the phone token reading the family's records was refused (403), as the spec says;
  - created a parent with the operator token, then got an email sign-in link (dev shows the link in the response).

## 1. Summary

- **Online-first fits the backend as it is.** The server already makes the session id and `child_ref` when a lesson starts. The earlier "accept a phone-made session id" gap is gone.
- **We can build the whole loop now, with no Google or Apple keys.** In dev, a parent signs in with the email link (no mail service is needed, because dev shows the link). From there the parent can:
  - give consent;
  - add the child;
  - make a pairing code.

  The child's phone pairs, the child does the lesson, the events land on the server, and the session ends.
- **The biggest backend gap:** mastery, the level, spaced checks and the parent report still read the old burger lesson. In the test, a lesson the child solved came back as "not completed". This blocks a true parent note. It does not block app work.
- **New gaps that online-first brings:**
  - a live AI endpoint for the lesson;
  - closing a lesson that never comes back online;
  - the server telling the app the child's current level.

## 2. What we can connect today (tested)

| Backend feature | Route | Use in the app |
| --- | --- | --- |
| Start a session | `POST /api/sessions` → `id`, `childRef` | The lesson start. The app puts both in every event. No connection means no lesson. |
| Send events | `POST /api/sessions/{id}/events` | Live, as the child taps. A repeat is ignored by `event_id`. Refused events come back with reasons, and the app must show them as errors. |
| Resume, on any phone | `GET /api/sessions/resumable` | It returns the unfinished session's events, and the app replays them with its own engine. Ignore its `phase/step` hint, which comes from the burger lesson. |
| Pair a phone | `POST /api/devices/pairing` (parent), `POST /api/devices/redeem` (phone) | GetCode and JoinCode screens. The phone token can start sessions and send events, but can't read the record. |
| Phones list and remove | `GET /api/devices`, `DELETE /api/devices/{id}` | RemovePhone screen. |
| Parent sign-in | `POST /api/auth/email-link` + `/verify` (works now); `/google`, `/apple` (return 501 until the keys come) | SignIn screen. All three return the same parent token, so only the button differs. |
| Sign-in options | `GET /api/auth/config` | Shows only the sign-in buttons this server can use, so the keys switch on with no app change. |
| Family setup | `POST/GET /api/children`, `POST /api/parent/consent`, `GET /api/parent/consents` | Data, AddChild and Who's learning screens. |
| Grown-up area | `GET/PUT /api/family/passcode`, `POST /api/family/passcode/check`, `GET/PUT /api/family/settings/reports`, `GET /api/children/{id}/plan` | Lock, GPass, Settings and Plan screens. |
| Privacy | `GET /api/parent/export`, `POST /api/parent/export-jobs`, `POST /api/parent/erase`, invites, members | Rights and Family screens. Delete the account; Apple requires this in the app. |
| Health | `GET /api/health` | The connection check behind "Lost the internet". |

## 3. Backend gaps, online-first

| # | Gap | Why it matters | Must for v1 |
| --- | --- | --- | --- |
| B1 | **Mastery, level, spaced checks and parent report read the new events.** They should use `step_committed` (`correct`, `error_type`), `hint_shown` and `problem_completed` (`outcome`, `wrong_count`, `hints_used`). Also, sessions shouldn't be fixed to `burger-drink`; the problem comes from `problem_shown`. | Every parent note would be wrong. "A parent gets a true note" is the 17 Nov goal. | Yes |
| B2 | **The current level comes back at lesson start**, in the `POST /api/sessions` reply or from `/plan`, worked out from B1. | Online-first means one live profile, so every phone starts at the same level. The app then makes a problem at that level. | Yes |
| B3 | **Close lessons that never come back.** Today a session ends only when a `session_ended` event arrives. A child who drops off and never returns leaves it open forever, so no report is sent. | It needs an idle timeout on the server, for example 30 minutes with no events. | Yes |
| B4 | **A shared dev server with HTTPS** (a `*.run.app` address is enough), then a prod project in Australia. | iOS blocks plain `http://`. Without it, nothing runs on a real phone or in TestFlight. | Yes, soon |
| B5 | **Live AI endpoint for the lesson**, with a time limit. The AI may evaluate a step or choose or word the help. Code still decides right and wrong. The model has to run in Australia, and only ids, steps and numbers go to it. `/api/utterance` is a start, but it only rewords lines and runs a stub model. | This is the reason for going online. It needs a model decision from Vishal; the Gemini API terms bar apps likely used by under-18s. | Agree scope |
| B6 | **Switch the keys on:** the Google client ids and the Apple client id. Today the backend checks one Google client id, so mobile must request its token for that id, or the backend must accept the iOS and Android ids too. | Code is ready on both sides; only config remains. | Later, when the keys come |
| B7 | **A mail service.** | The parent report is an email (PAR-01), and so is the email link. In dev it only logs. | Yes, before families |
| B8 | **Email link must open the app.** The link goes to `/parent#m=…` on the web. Mobile needs a Universal Link / App Link, which needs the Apple team id and a hosted file. Or the backend sends a 6-digit code instead of a link. | Without it, email sign-in works only in dev. | Yes, or use the code option |
| B9 | **An endpoint for app errors** (DAT-08). | The app needs somewhere to report its own errors. | Yes |
| B10 | **Real-family sign-off** (`ALLOW_REAL_ACCOUNTS`, after the legal review). | The five families can't be created without it. | Yes (a decision) |
| B11 | **Update the spec pack and PRD:** SES-04, TUT-01 / D-26 and NFR-05 change with online-first. Today the backend enforces `model_rewording: false`. | So the backend's checks and the spec agree. | Yes (paperwork) |

**Can wait:**
- signed content packs, the story pipeline and recorded audio. Online-first lets the server serve problems later; the phone makes them from Julia's template for now;
- retiring the Python lesson machine (`core/`) and the old web routes;
- three DB schemas, Pub/Sub, a separate note worker.

## 4. App gaps, online-first

**Already built:**
- the lesson with Julia's template, 5 levels and generated problems;
- the spec event format;
- the 30-minute cap and taking a break;
- resume by replay;
- the outbox, which becomes the short-drop buffer;
- the theme and parts from Figma.

| # | Work | Change from offline-first | Backend dependency |
| --- | --- | --- | --- |
| A1 | **Real HTTP client** in place of `FakeApi`. Every failure becomes `ApiException`, and refused events are shown, not dropped. | — | None |
| A2 | **Session from the server.** Start a lesson with `POST /api/sessions`, then use its `id` and `childRef`. If there's no connection, show a "We need the internet to start" screen with a retry. | Changed: no more phone-made session ids. | None |
| A3 | **Connection handling.** Send taps as they happen, hold and resend during a short drop, and pause the lesson after a longer one ("Lost the internet. Your work is saved."). Carry on exactly where it stopped. | Changed: today the notice doesn't block the lesson; it must pause it. | None |
| A4 | **Resume from the server,** on the same phone or another, with "carry on?". | Changed: the server's log is the source, not the phone's. | None |
| A5 | **Level from the server.** Read the level at lesson start, and make the problem at it. "Something easier" means one level down. | Changed: the phone no longer keeps its own score. | B2 (until then, a fixed level) |
| A6 | **AI moments seam.** Ask the server, with a time limit; if it's late or fails, show the code's own line. | New | B5 |
| A7 | **Parent setup.** Sign in (Apple, Google and email buttons, shown from `/api/auth/config`), consent, child profile, "please don't help", make the pairing code. Uses the SignIn, Data, AddChild, Who's learning and GetCode screens. | — | B6 for Apple and Google; the email link works now |
| A8 | **Child phone.** JoinCode screen; keep the token in the Keychain or Keystore; hand the parent's phone to the child. | — | None |
| A9 | **Grown-up area.** Lock, GPass, PHome, Book, Plan, Settings, Rights, Family, RemovePhone and SignOut, including delete account and export. | — | B1 for true Book and Plan content |
| A10 | **Release.** App icon and splash, prod settings, TestFlight and Play internal testing. | — | B4, developer accounts |
| A11 | **Accessibility pass** (WCAG 2.2 AA), read-aloud with the device voice, error reporting. | — | B9 for error reporting |

## 5. Blockers

**Nothing blocks the end-to-end build.** Every screen and call above can be built and tested now, against the backend on this Mac, on the Android emulator and iPhone simulator.

**What blocks parts of it:**

| Blocker | What it holds up | Owner |
| --- | --- | --- |
| **No shared dev server with HTTPS** (B4) | Running on real phones and TestFlight. Dev work is not held up. | Backend (Kuldeep) |
| **Reports and levels still read the burger lesson** (B1, B2) | A true parent note and server-held levels. The app builds against the routes and shows real data once they're fixed. | Backend |
| **AI model choice and terms** (B5) | The AI moments only. The app ships the seam with the code's fallback line. | Vishal |
| **Apple developer account** | Sign in with Apple testing, Universal Links (B8) and TestFlight. Code isn't held up. | Julia meeting |
| **Google client ids** | Google sign-in testing only. | Backend / accounts |
| **Design** | Figma has every parent screen. Still needed: the "Lost the internet" **pause** state (the spec sent to Apoorv says it must not block, which is now wrong), a "need the internet to start" screen, the official Apple and Google buttons, the updated Time's up screen, the app icon and splash. We build with placeholders until they arrive. | Apoorv |

## 6. Figma screens: built, buildable now, waiting

Source: Figma page "Screens · Prototype copy (27 Oct)" (629:2), about 130 frames.

**Built in the app (lesson flow):**
- M0/M1 (the question), M1-D2 to M1-D6 (the drawing steps);
- M1-help, a simple H2-1 to H2-3 (show me how), a simple T1 (side lesson);
- W1, J17 (wrong answers), M1-pause, R1, R2, TU;
- Y2 (case cracked), Y3 (badge), a basic Home;
- the N1, N1b and N1s problem variants, which are the same screens with other numbers.

**Buildable now, with backend routes already there:**

| Group | Screens |
| --- | --- |
| Parent setup | Welcome 643:2, Name 643:24, Age 643:40, Year 643:66, Start 643:102, StartNotSure 643:145, Goal 643:169, Data 643:203, SavePlace 643:235, Ready 644:2, Lock 644:20, Who's learning 644:38, AddChild 667:87 |
| Pairing and phones | JoinCode 644:75, Open (Who's here?) 644:107, GetCode 644:147, IsThisYou 644:205, PhoneJoined 644:240, CodeWrong 653:55, NewCode 653:89, WhichChild 653:115, OtherPhone 653:24, RemovePhone 653:159, Removed 653:172 |
| Sign-in | SignIn 653:2, CheckEmail 653:144, ForgotPass 653:132, SignOut 659:105 |
| Grown-up area | GPass 652:173, PHome 658:84, Settings 652:75, Family 652:213, Invite 652:251, Rights 667:66 |
| Child extras | WelcomeBack 651:133, Y4 (sent to your grown-up) 648:83, Sound 650:149, NoVoice 659:39, Notify 659:52, P1b (phone call) 650:63, Lock0 667:34 |
| Lesson, full versions | H2 (smaller example) 667:2, interactive T1 board 649:239, N0/N0b/N1b/N1 (easier and same-pattern intros) 649:49 to 649:193 |
| Badges and progress (on the phone) | B1 (my badges) 650:233, B2 (badge close-up) 651:2, Streak 650:202, K2 (my trail) 651:68, TrailTop 659:2, Up (something new) 651:35, X1 (case closed) 650:166 |

**Buildable now, but the data is wrong until the backend reads the new events (B1):**
- Book 652:35, Plan 652:119, R0 (simple report) 667:44, Monthly 658:121;
- Check (spaced check) 651:165.

**Not an app screen:** Email 652:2 and FirstEmail 652:151 are emails the backend sends.

**Waiting on a decision or content:**
- **Other problem types** need Julia's templates; the spec pack has only the comparison one:
  - L0/L1 (level 1) 654:98, 654:146;
  - WT1/WT2 (weights);
  - TD1/TD2 (total and difference, M3);
  - BS1/BS2 (bar sense);
  - NS1/NS2/NS3 (number sense);
  - N0s/N1s (the flip).
- **Warm-up and choose today** (A2 647:2, A3 647:56, A2e 658:192) and **Quick sums** (QS1, QSgo, QS2, QS3; LES-16, behind a flag). They need the arithmetic content and a product call on when they show.
- **"New from Kush"** — the free check (FC0, FC1, FCp, FCR, FCKeep, FCBack), LookPick (pick your detective) and Voice (case partner). Not agreed in the PRD; the memo says it changes Julia's SOW.
- **Plans (membership) 659:71:** payments are out of scope this term (PRD v3.3). Don't build.

**Copy fix needed before building:** several setup frames say "His age", "What he can already do" and "His details". The PRD rule (PRV-07) is no gender anywhere, so the app uses the child's name, or "your child", instead. The goal list on Goal 643:169 is a placeholder; product must supply it (the backend has only "Do well in the school curriculum").

## 7. Tuesday 3 Nov

**Proposed goal:** the lesson works online, end to end, against the backend:
1. A parent signs in with the email link (dev), gives consent, adds the child and gets a 6-digit code.
2. The child's phone pairs with that code.
3. The child does the lesson. Every tap reaches the server live; a dropped connection pauses the lesson, and it resumes where it stopped.
4. Apple and Google buttons are in place and switch on when the keys come.

**From us:** A1, A2, A3, A4, A7 (email path), A8, and the SignIn, Data, AddChild, GetCode and JoinCode screens. All of it is checked on the Android emulator and the iPhone simulator.

**From the backend team, if possible by Tuesday:** a dev URL with HTTPS (B4), so it runs on a real phone too. Without it, Tuesday is emulator and simulator only.

**Not in Tuesday:**
- true parent reports and levels from the server (B1, B2);
- AI moments (B5);
- the grown-up area beyond setup (A9);
- TestFlight.
