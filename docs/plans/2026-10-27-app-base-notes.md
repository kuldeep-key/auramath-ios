# App base: what was built, calls made, what is left

27 Oct 2026 · branch `feat/app-base` · plan `docs/plans/2026-10-27-app-base.md`

## Status

- All 12 plan tasks done. `flutter test`: 54 pass. `dart test` (engine): 73 pass. `flutter analyze`: clean.
- The lemon-tree lesson plays end to end from Home by taps, offline, and every tap is saved and synced in order (against a fake backend).
- A fresh reviewer read the whole branch. Its 2 Critical and 3 Important findings: 4 fixed with tests, 1 deferred (below).
- **Checked on Android (28 Oct).** The whole lemon lesson plays on the "Latest_device" emulator (Pixel 7 Pro, Android 15), from Home to the badge. The old "Pixel" emulator (16 KB page image) is broken; don't use it. That check found 4 bugs, each fixed with a test first:
  - the coach bubble stayed on "Drag a bar up here." for the whole lesson; every board step now says its own line (prototype STEPLINE);
  - "I know it" / "Help me" shrank to their text; they now fill their half;
  - the "Case cracked!" background only covered part of the screen;
  - the Taller / Shorter chips (not in Figma) are now drawn as tray pieces with a small bar picture, so a child who can't read yet still gets them; they're 56pt tall.
- **iOS still not checked.** Xcode isn't installed.

## Needed from you before the next step

1. **Install Xcode:** click Get on the App Store page (already opened), or run `! sudo mas get 497799835`. Then `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer` and `sudo xcodebuild -runFirstLaunch`. These need your Mac password, so I can't run them for you.
2. **Designer sign-off** on the Taller / Shorter chips, which use our own design.

## Calls made during the build

Each has what it costs if it is wrong.

| # | Call | Cost if wrong |
| --- | --- | --- |
| 1 | Worked on branch `feat/app-base` in the repo, no separate worktree | None |
| 2 | Engine badge type named `BadgeInfo` (Flutter already has a `Badge` widget) | One rename |
| 3 | No Podfile: Flutter 3.44 uses Swift Package Manager; iOS 16 is set in the Xcode project | Add `platform :ios, '16.0'` if a CocoaPods plugin arrives |
| 4 | The next problem is the "fast" one only with no wrong moves, no hints and no side lesson | One condition |
| 5 | When b is found by adding, the side lesson after two misses is the carry one | One switch |
| 6 | A right "I know it" after bar A is drawn counts as "partway" for both problem kinds | One condition |
| 7 | "Let's draw it" clears the board back to an empty first step | A child redraws one bar |
| 8 | Help buttons only work on the board steps | None for now |
| 9 | Golden test files are written by `UPDATE_GOLDEN=1 dart test test/golden_test.dart`, then reviewed by hand | None |
| 10 | No coach face in the lesson header (Figma has none) | Add one image |
| 11 | Home and celebrations use the prototype's default detective (Aarav) | Swap one file |
| 12 | Keypad has no + / − keys yet (only needed for "write the number sentence") | One key row later |
| 13 | Bar A is drawn by dropping or tapping the tray's Bar piece on its slot (as in Figma) | One gesture |
| 14 | A tap on bar B's handle counts as "same height", so the coach asks "taller or shorter?" | None |
| 15 | Engine fix: a slip that gives the right answer (no regrouping needed) is not a mistake route, so it no longer blocks a problem | The backend could ship a problem the app can't route |
| 16 | Side lesson is a simple screen; Figma's interactive "break a ten" board is a later task | A child can't practise the regrouping yet |
| 17 | "Show me how" only says a line; the animated worked example is a later task | Help is thinner than designed |
| 18 | After "Add to my sash" the next problem opens; "Sent to your grown-up" comes with the grown-up area | One screen |
| 19 | "You solved the case!" (packs have no problem title yet); badge art is an emoji per badge | One pack field each |
| 20 | Hint lines are filled with the problem's numbers by the view model | One engine field later |
| 21 | Help, answer and "still there?" sheets are drawn inside the lesson screen | No Android back-gesture to close them |
| 22 | No `provider` package: services are passed in through constructors | Add it when features multiply |
| 23 | Home's Keep going always opens the lemon problem until progress is stored | Home restarts at lemon after reopening |
| 24 | **Deferred: resume after the app is killed.** Events are saved and replay works, but the app doesn't yet remember which session was open | A killed app restarts the current case |

## Smaller items left for later (from the final review)

- After one side lesson, every later wrong answer at "find the fig tree" reopens it.
- A right total after "check one part" always counts as "knew it", even if bar A was drawn.
- The real HTTP client must turn every failure into `ApiException`, or sync stops retrying until the next tap.
- `restore()` should take the next seq from the last saved event, not the count.
- The view model copies the engine's line slots; the engine should export them.
- Two corner radii (14) are hard-coded instead of coming from the theme.
