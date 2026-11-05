# Design asset specs for release

28 Oct 2026 · for Apoorv · what the mobile app needs from design before the first TestFlight build. The full Figma check is in `docs/figma-app-essentials.md`.

## 1. App icon

| For | Size and format | Notes |
| --- | --- | --- |
| iOS | 1024×1024 PNG, sRGB | No transparency, square corners (iOS rounds them). Xcode makes every other size from this. |
| Android adaptive: foreground | 432×432 PNG, transparent background | Keep the artwork inside the central 264×264 px; Android crops it to circles, squircles and other shapes. |
| Android adaptive: background | A colour (hex), or 432×432 PNG | |
| Android monochrome (themed icons, Android 13+) | 432×432 PNG, one colour on transparent | The foreground artwork, flattened to one colour. |
| Play Store | 512×512 PNG, under 1 MB | |
| Source | SVG | So every size can be regenerated. |

Keep it simple and legible down to about 40 px, with no small text.

## 2. Splash / launch screen

- A background colour (hex) and a centred logo mark: no text, no animation. iOS shows it as a static launch screen.
- Logo for the splash: SVG, plus a 1152×1152 PNG with a transparent background. Keep the artwork inside the central 768 px circle, because Android 12+ crops the splash icon to a circle (288dp canvas, 192dp visible).
- Optional: a dark-mode version (background colour plus logo).

## 3. Logo / wordmark

- Vector SVG (and PDF), with text converted to outlines.
- Two versions: full colour, and white for the blue backgrounds.
- A transparent background, plus PNG exports at @1x, @2x and @3x.
- A minimum size and clear-space note, if there is one.

## 4. Sign-in buttons (App Review checks these)

**Apple** (follow Apple's "Sign in with Apple" guidelines):
- Black, white or white-with-outline style.
- The official Apple logo from Apple's design resources; don't redraw it.
- Text "Continue with Apple" or "Sign in with Apple".
- At least 140×44 pt (Apple's minimum is 30 pt high; 44 pt for touch).

**Google** (follow Google's sign-in branding guidelines):
- The official multi-colour "G" from Google's branding kit, unchanged.
- Text "Continue with Google".
- Google's light or dark button colours.

**Both:**
- The Apple, Google and email buttons must be the same size and equally prominent. Apple rejects apps where Sign in with Apple is smaller or placed lower than the others.
- Include pressed and disabled states.

## 5. Screens

**"Lost the internet" notice** (SES-04):
- It shows while the app can't reach the server; the lesson carries on underneath, so it must not block the lesson.
- Needed: placement (top or bottom, clear of the tray and the I-know-it / Help buttons), icon, colours, and an optional "back online" state.
- No red, and colour must not be the only signal (NFR-03).
- Copy today: "Lost the internet. Your work is saved."

**Time's up** (update to the existing TU screen, Figma 650:118):
- SES-01 needs two choices: "Finish this one" and "Call it a day" (or OK). Figma has only OK today.
- Needed: button hierarchy, copy, and what shows after the child finishes that last problem.
- No clock or countdown anywhere (SES-02).

## General, for every screen

- Frames at 390×844 (iPhone 15), checked at 375×667 (iPhone SE).
- Colours from the Foundations tokens (130:2).
- Touch targets at least 44 pt; the child's screens use 56 pt.
