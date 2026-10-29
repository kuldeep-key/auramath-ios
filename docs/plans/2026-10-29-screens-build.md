# Plan: build every buildable Figma screen, online-first

29 Oct 2026 · branch `feat/app-base` · decisions in `docs/backend-integration-review.md` (online-first; Google/Apple keys come later).

Figma file "Auramath", page **Screens · Prototype copy (27 Oct)** (629:2). Each section has flow notes under every frame: read them with `get_screenshot` on the section (642:2 to 642:14).

## Split

| Group | Owns (routes file) | Screens |
| --- | --- | --- |
| G1 Setup + sign-in | `lib/ui/features/setup/` (`setup_routes.dart`) | Welcome 643:2, Name 643:24, Age 643:40, Year 643:66, Start 643:102, StartNotSure 643:145, Goal 643:169, Data 643:203, SavePlace 643:235, Ready 644:2, Lock 644:20 (+ "choose a passcode", not in Figma), JoinCode 644:75, SignIn 653:2, CheckEmail 653:144, the `/auth/verify` landing |
| G2 Child phone + picker | `lib/ui/features/pairing/` (`pairing_routes.dart`) | Open 644:107, GetCode 644:147, CodeWrong 653:55, WhichChild 653:115, IsThisYou 644:205, PhoneJoined 644:240, Removed (child side, not in Figma), A1 Who's learning 644:38, OtherPhone 653:24 |
| G3 Grown-up area | `lib/ui/features/grown_ups/` (`grown_up_routes.dart`) | GPass 652:173, ForgotPass 653:132, PHome 658:84, Settings 652:75, Family 652:213, Invite 652:251, NewCode 653:89, RemovePhone 653:159, Removed 653:172 (parent side), AddChild 667:87, Rights 667:66, Notify 659:52, SignOut 659:105, Book 652:35, Plan 652:119, R0 667:44, Monthly 658:121 |
| G4 Child screens | `lib/ui/features/child_home/` (`child_routes.dart`) | Home 649:2, WelcomeBack 651:133, Sound 650:149, NoVoice 659:39, B1 650:233, B2 651:2, K2 651:68, TrailTop 659:2, Check 651:165, after a case: X1 650:166, Streak 650:202, Up 651:35, Y4 648:83 |
| Lead (not delegated) | `lib/routing/`, the lesson, `main.dart`, `app.dart`, shared repositories | Online-first lesson (server session, pause on drop, resume from server), lesson screens H2/T1/N0/N1, merging |

**Not built** (decisions in the review doc): other problem types, Quick sums, warm-up, the free check, LookPick, Voice, Membership.

## Files

- **Yours:** everything under your feature folder; your feature's repository `lib/data/repositories/<group>_repository.dart`; your tests under `test/ui/features/<group>/`; new image assets under `assets/images/`; your strings in `lib/l10n/app_en.arb`.
- **Not yours:** `lib/routing/*`, `lib/app.dart`, `lib/main.dart`, `lib/deps.dart`, the lesson, `account_repository.dart`, `family_repository.dart`, `session_repository.dart`, `outbox_db.dart`. If you need a change there, don't make it: say so in your report.
- **Shared parts** (`lib/ui/core/parts/`): use them; add a new part there only if two groups would plainly need it, and name it after what it is.

## The base you build on

- `Deps` (`lib/deps.dart`): account, family, client, sessions, pack, voice, sitting, deviceLock, outbox. Route builders get `deps`; screens take what they use in their constructors.
- **Account** (`AccountRepository`): `role` (none / parent / device), `childId`, `chooseChild`, `sendEmailLink` (returns the dev link on a dev server), `verifyEmailLink`, `signInWithGoogle`, `signInWithApple`, `redeemPairing`, `signOut`, `forgetPhone`, `unlockGrownUps`, `useFaceId`/`setUseFaceId`, `draft` (the setup answers before sign-in), `authConfig()`.
- **Family** (`FamilyRepository`): `children()`, `addChild(draft.toChildJson())`, `giveConsent()`, `passcodeStatus()`, `setPasscode()`, `checkPasscode()`.
- **Your other calls:** your own repository over `deps.client` (`ApiClient.get/post/put/delete`). For exact shapes, read the backend route in `../auramath-backend/auramath/api/*.py`.
- **Errors:** every failure is an `ApiException` (`status` null = offline). Show the server's message where the grown-up can see it, near the action, with a way to try again. Never treat a failure as success.
- **Parts:**
  - `AuraPage(top:, body:, bottom:, play:)`: the responsive frame. It is centred at most 560 wide, the body scrolls when tall, and the bottom stays pinned above the keyboard.
  - `AuraTopBar(progress:, close:, trailing:, fallback:, light:)`, `AuraHeading`, `AuraLink`.
  - `AuraButton(color: blue)` is the main action on white screens; `yellow` is the main action on blue play screens; `white` is secondary. Never build a button by hand.
  - `ChoiceTile`, `AuraTextField` (always labelled), `CodeBoxes`, `Keypad` (`onChanged`, `onCheck`, `maxDigits`), `Ribbon`, `Portrait`, `AuraCard`.
  - Colours and type only from `tokens.dart`.

## Navigation rules

1. **Navigate only by path,** with `Paths.*` from `lib/routing/paths.dart`. Never use `Navigator.push` or a string literal path.
2. **`context.push` for a step inside a flow,** so back pops it.
3. **`context.go` when a flow ends or the area changes,** such as setup → Ready, or sign-in → home. It replaces the stack, so finished flows never pile up.
4. **The router's `redirect` already guards access** (`lib/routing/redirect.dart`): the role, the passcode lock, a removed phone, the chosen child. After signing in or pairing, just `go` where the flow goes next. Don't re-check the role in screens.
5. **Back:** `AuraTopBar` pops, or goes to `fallback` when nothing is underneath. Give every screen reachable by `go` or a deep link a sensible `fallback`.
6. **Confirmations** (remove a phone, sign out, delete the account) are their own Figma screens. Push them; their Cancel pops.
7. **Lists of children and phones come from the server,** never from Figma sample data. Use the child's real name everywhere Figma says "Aarav".

## Copy and standards (PRD rules; Figma breaks some)

- **No gender anywhere:** "his/he/him" becomes the child's name or "your child". Never "Mum" or "Dad"; say "your grown-up".
- **No score:** no %, "N of M", score, label or year level shown to the child.
- **No red, and colour is never the only signal.**
- **Touch targets** at least 44 pt; child screens 56 pt.
- **Every input has a visible label.**
- **Every icon button has a tooltip or semantics label.**
- **Strings go in `lib/l10n/app_en.arb`,** keys prefixed by group (`setup…`, `pair…`, `gu…`, `kid…`). Run `flutter gen-l10n` after editing.
- **Apple / Google sign-in buttons:**
  - follow Apple's Human Interface Guidelines and Google's branding guidelines: the official logo, official colours, "Continue with Apple" / "Continue with Google";
  - same size and same prominence as the other options, Apple not below Google;
  - Figma uses a phone icon and a text "G": don't copy that. Use the `sign_in_with_apple` package's `SignInWithAppleButton` (or Apple's exact style), and Google's "G" mark;
  - if you can't get Google's official asset, use a placeholder and report it.

## How each screen is checked

1. **Implement from Figma.** Follow the `figma:figma-design-to-code` skill: load it before `get_design_context`, and pass `skillNames`. Download assets as it says.
2. **Screenshot test:**
   - Write `test/ui/features/<group>/<screen>_test.dart` calling `shotAllSizes(tester, '<group>_<screen>', screen)` (`test/helpers/shots.dart`).
   - It renders at iPhone 15 (Figma size), iPhone SE, Pro Max and iPad, and fails on any overflow.
   - Use `testDeps()` (`test/helpers/app_harness.dart`) with a `FakeServer` for data.
3. **Compare with Figma:**
   - Read `build/shots/<name>@iphone15.png` next to Figma's `get_screenshot`.
   - Fix every difference in layout, spacing, type, colour, assets and copy, except where a rule above says Figma is wrong.
   - Check the SE and iPad shots too.
4. **Behaviour tests** for each screen's actions:
   - where a tap goes (the shot router shows `went to <path>` for any other path);
   - which server call it makes (`FakeServer.calls`);
   - what an error shows.
5. **Before finishing:**
   - `flutter analyze` must be clean;
   - run `flutter test test/ui/features/<group> test/routing test/helpers` (and any test you touched).
   - Commit on your branch in small conventional commits. No `Co-Authored-By` line, no `--no-verify`, no skipped tests.

## Report (keep it short)

1. **Screens built:** Figma id → file → path.
2. **Calls you made** where Figma, the PRD and the backend disagree.
3. **Figma issues:** missing states (loading, error, empty), standard-practice gaps (platform guidelines, accessibility, copy rules), and anything not designed that you had to invent.
4. **Anything not built, and why.**
5. **Changes you need** in files that aren't yours.

## Done 29 Oct

**Built.** About 60 screens are built, every one checked against its Figma frame at iPhone 15, SE, Pro Max and iPad sizes (screenshots in `build/shots/`), and each with behaviour tests:
- setup and sign-in (G1);
- the child's phone and the picker (G2);
- the grown-up area (G3);
- the child's screens around the lesson (G4);
- the online-first lesson:
  - the server opens each session;
  - the lesson pauses while offline;
  - resume works across phones;
  - an interactive side lesson (T1);
  - "Show me how" (H2).

**Checks:**
- `flutter analyze` is clean, and all unit and widget tests pass.
- **End to end against the dev backend, on the iPhone 15 and SE simulators and the Android emulator (Pixel 7 Pro, API 35):**
  - `integration_test/setup_to_lesson_test.dart`: a grown-up sets up with an emailed link, gives consent, the child is saved, a passcode is set, the phone is handed over, and the lesson's events reach the server.
  - `integration_test/pair_to_lesson_test.dart`: a child's phone pairs with a 6-digit code, and its lesson reaches the server.

**Figma issues:** `docs/figma-issues.md`.

**Still open:**
- **Keys:** Google and Apple sign-in are coded but untested until the client ids and the Apple developer account exist.
- **Emailed links:** a link doesn't open the app on a real phone yet. It needs a Universal Link (Apple team id) and a backend link format the app can open (gap B8). The dev servers return the link in the response, which the check-email screen uses.
- **Generic simulator build:** `flutter build ios --simulator` with no device fails in Flutter's unpack step. Builds for a named simulator work.
- **Lesson settings:** the grown-up's lesson settings (time each day, read aloud, number pad) are saved on the phone, but the lesson doesn't read them yet.
- **Keypad:** `onCheck` returns an `int`, which drops leading zeros. The code and passcode screens read the typed string instead.
