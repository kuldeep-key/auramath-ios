# Testing the app by hand (dev)

29 Oct 2026 · branch `feat/app-base` · everything runs on this Mac: the backend, the iPhone simulator and the Android emulator. Real phones need the backend team's HTTPS dev server, which isn't ready yet.

## 1. Start (once per session)

1. **Backend:** in `/Users/admin/Projects/auramath/auramath-backend`, run `make dev`. Check http://localhost:8080/api/health answers `{"ok":true…`.
2. **Invite a family.** The dev server lets in invited families only. Use a new email each time:

   ```bash
   curl -s -X POST localhost:8080/api/admin/parents \
     -H 'Authorization: Bearer demo-operator-token' \
     -H 'Content-Type: application/json' \
     -d '{"email":"tester1@example.com"}'
   ```

   The reply also contains a grown-up token, which you only need for checking the server by hand (section 5).
3. **Run the app.** Use the iPhone 16 simulator for the grown-up and the Android emulator for the child's own phone, or both flows on one device.
   - **iPhone:** `flutter run -d E249BC3D-67BF-4BA7-977C-5A2993ECFED2 --dart-define-from-file=env/dev.json`
   - **Android:** run `adb reverse tcp:8080 tcp:8080` first, then `flutter run -d emulator-5554 --dart-define-from-file=env/dev.json`
4. **Start fresh** (forget the sign-in and pairing):
   - **iPhone:** `xcrun simctl uninstall E249BC3D-67BF-4BA7-977C-5A2993ECFED2 net.auramath.app && xcrun simctl keychain E249BC3D-67BF-4BA7-977C-5A2993ECFED2 reset`
   - **Android:** `adb uninstall net.auramath.app`

## 2. Grown-up flow (iPhone)

1. **I'm a grown-up → Get started.**
2. **Child's first name.** Use letters only, such as Sam: the dev server refuses real-looking names until the legal review.
3. **Age → school year → what they can do** (or "I'm not sure") **→ goal → I agree.**
4. **Use my email** → type the invited email → **Email me a link.**
5. **Open the link (dev only).** On a real server this would be the emailed link.
6. **All set!** Then pick one:
   - **Hand over to Sam** → Use a passcode (type it twice) → Sam's home → Keep going → the lesson.
   - **Sam has their own phone** → a 6-digit code shows, valid for 10 minutes. Use it in the child flow below.
7. **Grown-up area:**
   - From the child's home, tap **For grown-ups** and enter the passcode.
   - Try: family and phones, add a child, settings, the plan, the book, data and rights (export, delete the account), sign out.

## 3. Child flow (Android, or a second fresh install)

1. **I'm a kid** → type the 6-digit code from the grown-up's phone.
2. **Is this you? → Yes, that's me!** → **Let's go** → home → **Keep going.**
3. **Play the lesson:** listen, draw the bars, choose the sum, type the answers.
   - Help me → **Show me how:** a worked example.
   - Type a wrong answer such as **81** for 186 − 107: the side lesson with tens and ones opens.
4. **Solve it:** after-case screens, a badge, then My badges and My trail.

## 4. Things worth trying

- **Connection drop:**
  - Stop the backend mid-lesson (Ctrl+C on `make dev`). The lesson pauses with "Lost the internet. Your work is saved."
  - Start the backend again, tap **Try again**: the lesson carries on where it stopped.
- **No connection at the start:** with the backend stopped, Keep going shows "We need the internet to start".
- **Remove a phone:**
  - On the grown-up's phone: grown-up area → Family and phones → Remove.
  - On the child's phone, the next action shows "This phone was removed".
- **Wrong pairing code:** "That code didn't work". After 5 wrong tries, it asks the child to wait.
- **Leave mid-lesson and come back:** Keep going reopens the same case.

## 5. Check the server's side

Replace `<token>` with the token from step 1.2.

```bash
curl -s localhost:8080/api/sessions?limit=3 -H 'Authorization: Bearer <token>'
curl -s localhost:8080/api/sessions/<session id>/events -H 'Authorization: Bearer <token>'
```

## 6. What won't work yet (expected)

- **Continue with Apple / Google:** these say they're not switched on until the client ids and the Apple developer account exist.
- **Real emailed links:** dev has no mail service. Use the "Open the link (dev only)" button.
- **Book, plan and report:** mostly empty. The backend still builds them from the old lesson.
- **Parent email after a session:** dev only logs it.
- **The trail and badges:** show what this phone has seen, not the child's whole history.
- **Forgot passcode:** ends with the backend's refusal. The backend needs a reset route.

## 7. Automated version of the same flows

```bash
flutter test integration_test/setup_to_lesson_test.dart -d <device> --dart-define-from-file=env/dev.json
flutter test integration_test/pair_to_lesson_test.dart -d <device> --dart-define-from-file=env/dev.json
```

Both pass on the iPhone 16 simulator and the Android emulator. Start fresh first (section 1, step 4).
