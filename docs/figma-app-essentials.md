# Figma check: app essentials for a first TestFlight build

28 Oct 2026 · Figma file "Auramath" (Dev Mode, read only)

**Limit of this check:** only the open page, **Screens · Prototype copy (27 Oct)** (629:2), returned full detail. The other pages returned section names only. "Missing" means not on 629:2 and not suggested by any section name elsewhere. To confirm across the whole file, open each page in Figma and rerun the check.

## Missing: needed from the designer, in priority order

1. **App icon.**
   - A 1024×1024 master with no transparency, plus Android adaptive foreground and background layers.
   - TestFlight cannot ship without it.
2. **Launch / splash screen.**
   - A background colour plus the logo, or approval to reuse the "Who's here?" look (644:107).
3. **Logo / wordmark as a vector** (SVG or PDF).
   - Today it's only live Nunito text (694:465, 700:1124).
4. **Sign-in buttons in Apple's and Google's official styles.**
   - SignIn (653:2) uses a phone icon for Apple and a text "G" for Google. Getting this wrong blocks App Review.
5. **Detective child portraits.**
   - Full-resolution exports (512px or more) of all 8 portraits; the Assets frame is 629:3.
   - Two images are missing: the empty grey tiles at about 632:11 and 632:12.
6. **System states not designed:**
   - the "Lost the internet" notice;
   - a generic error / retry screen;
   - "Finish this one or call it a day" (the time's-up choice);
   - the "Want a hand?" nudge.
7. **Badge art.**
   - Decide: bespoke art, or keep Fluent Emoji 3D (Microsoft, MIT licence, needs an attribution note).
   - Still needed: the "Brave Asker" badge and the sash art.
8. **Lesson illustrations:**
   - lemon tree, fig tree, mango and guava (emoji today; only the bowl and mug have 3D images, 703:1451 and 703:1452);
   - the word-meaning drawings (LES-10);
   - the parent-and-child everyday-example picture (TUT-06).
9. **Notification icon (Android monochrome) and sound / audio cue files.**
   - The permission screen exists (Notify 659:52).
10. **Before store submission:**
    - store screenshots and preview art;
    - dark mode;
    - Dynamic Type sizes;
    - accessibility notes;
    - a tutor character, if product still wants one ("Case partner" 658:48 reuses the child's portrait).

## Found

| Item | Where | Note |
| --- | --- | --- |
| Parent screens | SignIn 653:2, Data 643:203, AddChild 667:87, Who's learning 644:38, JoinCode 644:75, GetCode 644:147, Lock 644:20, GPass 652:173, PHome 658:84, Book 652:35, Plan 652:119, Settings 652:75, Rights 667:66, Family 652:213, RemovePhone 653:159, SignOut 659:105 | Screens exist; sign-in buttons need the official styles |
| System states | NoVoice 659:39, time's up TU 650:118, Sound 650:149, pause and resume M1-pause 666:70 / R1 650:104 / R2 650:77, help M1-help 666:2, wrong answer W1 650:2 / J17 650:15, CodeWrong 653:55, "Nothing saved yet" 704:1849 | |
| Side lesson board (T1) | 649:239 | Vector blocks, sticks and dots; no bitmap needed |
| Show me how (Building A and B) | H2 667:2, 666:146 to 666:220 | Plain bars |
| Trail | K2 651:68, TrailTop 659:2 | Drawn scene with emoji decorations; needs exporting |
| Badges | B1 650:233, B2 651:2, X1 650:166 | Tree Detective, First Clue, Weight Watcher, Skill Climber (Fluent Emoji placeholders) |
| Fonts and tokens | Foundations 130:2 (Colour 148:2133, Type 148:2223, Spacing 148:2280) | Nunito, free under the SIL Open Font License; the app already ships it |
