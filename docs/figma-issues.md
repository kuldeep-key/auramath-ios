# Figma issues found while building the screens

29 Oct 2026 · Figma file "Auramath", page "Screens · Prototype copy (27 Oct)" (629:2) · for Apoorv (design) and Ashutosh (product).

The app is built from the current Figma. Where Figma breaks a platform rule, a PRD rule or a basic standard, the app does the right thing now, and Figma should be updated to match. Each item says what the app does today. Items marked **Decide** need an answer from product or design.

## 1. Platform guidelines (App Store / Play review risk)

| # | Screen | Issue | What the app does now |
| --- | --- | --- | --- |
| P1 | SignIn 653:2, SavePlace 643:235 | **The Apple and Google buttons don't follow their guidelines.** Apple uses a phone icon and Google a text "G". Apple's HIG requires the Apple logo in an approved style; Google's branding requires the official "G" and colours. Apple rejects sign-in where its button is smaller or lower than other options. | Apple's own button (white with outline) and Google's official "G", both the same size as the email option. |
| P2 | Rights 667:66 | **Delete the account in the app.** Apple requires it for any app with sign-up. Figma has no design for it: no confirmation and no "what happens" screen. Its "Delete Aarav's data · Gone in 30 days" also doesn't match the backend, which erases the whole family straight away. | "Delete the family account", with its own confirmation screen listing what goes. **Decide:** per-child delete and a 30-day delay need backend work. |
| P3 | Welcome 643:2 | "Try a free check first" leads to the free check, which isn't in this term's scope. | Hidden. |
| P4 | Plans 659:71, Settings 652:75 | Membership / payments are out of scope this term (PRD v3.3). On iOS they would also need in-app purchase. | Not built; hidden from Settings. |
| P5 | Notify 659:52 | The bell icon and the "Aarav cracked the Tree case!" quote look like a push notification. There is no push service; the PRD's note is an email (PAR-01). | Copy changed to "An email after each session" with a mail icon; it switches the report email on. **Decide:** wording. |

## 2. PRD rules Figma breaks

| # | Screen | Issue | What the app does now |
| --- | --- | --- | --- |
| R1 | Age 643:40, Start 643:102, Data 643:203, SavePlace 643:235, section 642:4, flow notes (Book 652:74, FirstEmail 652:172) | **Gendered copy:** "His age", "What he can already do", "His details stay safe", "Save his place", "When he needs help", "his level", "his book". The PRD says no gender anywhere. | The child's name, or "your child". |
| R2 | OtherPhone 653:24 (and note 653:54) | **"You started this case on Mum's phone."** The PRD says the grown-up is never "Mum". | The phone's name, or "another phone". |
| R3 | A1 644:38, WhichChild 653:115, Ready 644:2 | **Portraits imply gender:** a girl for Maya, a boy for Aarav. The server stores no avatar and no gender, so choosing by name would be guessing. | The same detective for every child (initials in the grown-up area). **Decide:** the avatar picker (Figma "Pick your detective" 658:2) needs a backend avatar field. |
| R4 | StartNotSure 643:145, Ready 644:2 | Promise features that aren't built this term: "Four quick sums first", "starts with a short warm-up". | Shown as designed. **Decide:** remove the lines, or confirm they're coming. |
| R5 | Y4 648:83 | "Your grown-up sees it too", but the grown-up's book doesn't show badges yet (the backend doesn't read `badge_awarded`). | Shown. **Decide:** keep the line once the backend shows badges, or change it. |

## 3. Accessibility

| # | Screen | Issue | What the app does now |
| --- | --- | --- | --- |
| A1 | All top bars (Back 684:40) | The back button is 32×32 pt; the minimum touch target is 44 pt. | 48 pt tap area, with the arrow on the 16 pt margin. |
| A2 | Name 643:24, SignIn 653:2, SavePlace, Invite 652:251 | Input boxes have no label or placeholder (WCAG 3.3.2). On Name the box floats mid-screen, under the keyboard. | A visible label above every field; Name's field sits under the title. |
| A3 | Keypad part (lesson, GetCode, GPass) | Keys are 48 pt high; child screens need 56 pt. | Unchanged. **Decide:** design. |
| A4 | Settings 652:75, Book 652:35, PHome 658:84 | Setting rows (~38 pt), the Book tabs (37 pt) and some buttons (48 pt) are under or near the minimum. The Settings values don't look tappable, and their other choices aren't shown. | Rows and tabs are 44 pt; each setting cycles through its values on tap. **Decide:** the design for choosing a value. |
| A5 | Child icon buttons (Home, trail, badges) | 48 pt; the child minimum is 56 pt. | 56 pt tap area. |
| A6 | All | No Dynamic Type (large text) or dark mode designs. | Text scales up to 1.3×, and every screen scrolls rather than clips. Light mode only. |
| A7 | K2 trail 651:68 | On iPhone SE the trail scales down and its labels become about 12 pt. | As designed, scaled. **Decide:** a scrolling trail on small phones. |
| A8 | WelcomeBack 651:133 | The only way out is into the case. | As designed. **Decide:** add a home button? |

## 4. States that aren't designed

The app has a version of each, built in the same style. Design should replace them.

- **Connection (online-first):**
  - "Lost the internet" now pauses the lesson, with "Try again" and "Go home". The 28 Oct spec said it must not block the lesson; that is now wrong.
  - "We need the internet to start".
- **Loading, error and empty states:** none exist anywhere. Built for every screen that reads the server, for example:
  - "No children yet", "No badges yet", "Nothing planned", "Nothing saved yet";
  - "Couldn't load, Try again";
  - an offline message on GetCode.
- **Sign-in:**
  - a link that is used or expired;
  - "send it again" (not built);
  - Face ID failed or not set up;
  - the backend's "test names only" refusal (dev).
- **Passcode:**
  - choosing it (after Lock 644:20), typed twice;
  - a family that already has one;
  - wrong passcode;
  - too many tries (locked until a time).
- **Codes:**
  - a pairing code that ran out (JoinCode, NewCode);
  - too many wrong tries on the child's phone;
  - the shake on CodeWrong (in the note, never drawn).
- **Phones:**
  - "This phone was removed" on the child's phone (Figma has only the grown-up's confirmation, 653:172);
  - invite sent;
  - export states: pending, ready, failed, expired.
- **Time's up** 650:118: no "Finish this one" choice (SES-01).
- **After a case:**
  - X1's copy for a same-level or easier next case;
  - art for the Brave Asker badge and the sash;
  - B1 when every badge is earned;
  - the trail's "New!" stop.

## 5. Layout and component mismatches

| # | Screen | Issue | What the app does now |
| --- | --- | --- | --- |
| L1 | T1 649:239 | The Ones column wraps under Hundreds, which breaks place-value order. | Hundreds, Tens, Ones in one row. |
| L2 | Ribbon part | The type size differs between the part and the screens (24 vs 28 pt). | 24 pt, radius 12, a light gloss. |
| L3 | A1 644:38 | The Grown-ups button has its lock on the left and is 84 pt high, unlike the Button part. | The standard button. |
| L4 | WhichChild 653:115 | The back arrow has nowhere to go once the phone is paired. | Hidden. |
| L5 | B1 650:233 | The earned badge is an 82×130 pill (an auto-layout bug). | A 130 pt circle. |
| L6 | Home 649:2 | "My trail" and "My badges" can't fit their label and icon at 390 pt. | Icons show only on wider screens. |
| L7 | PHome 658:84 | "OCTOBER PROGRESS" shows a broken icon font ("show_chart"). | A real icon. |
| L8 | Age 643:40 | Chip numbers are top-aligned. | Centred. |
| L9 | Setup progress bar | 25% on every step. | Moves on with each step. |
| L10 | Play screens | The ✦ sparkles and the richer gradient aren't in the shared background. | A plain two-tone gradient. **Decide:** add them to the background part. |
| L11 | CodeBoxes | Different looks across screens: blue-bordered on NewCode, white with a shadow on GPass. | One look. **Decide:** which. |
| L12 | Book 652:35 | The gear sits beside the title, not at the right edge as on PHome. | At the right edge. |

## 6. Product decisions the screens need

- **Ages and years:** the Welcome copy and Figma say ages 5–10; the brief said 6–10; the backend accepts 4–12. Figma's year list stops at Year 4.
  - The app shows ages 5–10, and Kindergarten to Year 5 (NSW).
- **Goal list:** Figma has four goals; the backend knows only "Do well in the school curriculum" and "I'm not sure".
  - The app shows Figma's four, but only "Catch up" sends a value.
- **"What can they already do":** Figma's six options mapped to the spec's skill ids. This is a best guess and needs product to confirm.
  - For example, "Counting to 100" became `ns.count-fwd-30`, because the skill map has no "count to 100".
- **Trail stops:** the skill map has no trail order and no child-friendly names.
  - The app uses five placeholder stops: Adding to 1000, Taking away to 1000, Tree cases, Tricky word cases, Burger cases.
  - Product needs to supply the real list.
- **Settings "Number pad":** "Phone's own" is one choice; the other is undefined.
  - The app uses "The app's own".
  - D-32 (PRD v3.3) says the phone's own pad for answers and our keypad for number sentences, but the lesson frames (D5/D6) draw our keypad for answers.
  - The lesson keeps our keypad until this is settled.
- **Data "Learn more":** there's no page to link to. Hidden until the full privacy notice has a URL.

## 7. Shown in Figma, not on the server yet

- **Plan 652:119:** "Drag to change what comes next", and a topic list. There is no route to save the order and no topic list, so the screen is read-only.
- **Book / Monthly / R0:**
  - the Skills tab, skill levels over time, the month chart and the "Working on" rows (the server reports none of this);
  - the parent's name ("Hi Priya"; the app says "Hi there");
  - names for invited grown-ups (shown by email);
  - the grown-up's own phone in the phone list.
- **Forgot passcode:** the backend asks for the old passcode even after a fresh sign-in. A wrong one counts as a failed try and can lock the family out. The app explains the 403; the backend needs a reset route.
- **Edit a child** ("Fix something" on Rights): there's no route.
- **Per-child avatar:** see R3.
- **Badges and trail across phones:** a child's phone can't read progress (grown-up only), so they show what this phone has seen.
