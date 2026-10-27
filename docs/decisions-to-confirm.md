# Auramath mobile: decisions to confirm

27 Oct 2026 · draft for stakeholders

Four decisions in section 1 need sign-off before the first TestFlight build, because they are costly or impossible to undo after release. Section 2 lists what we have already set and only needs a quick confirm. Everything else can follow later.

Each item gives the default the mobile app will be built with if no one objects, and why it matters. Reply with "OK" or a different answer per item.

## 1. Hard to change after first release (needs sign-off)

1. **iOS bundle ID and Android application ID**
   - Default: `net.auramath.app` for both.
   - Why: fixed once the first build is uploaded to App Store Connect or published on Google Play. A new ID means a new app: users reinstall and lose reviews.

2. **Apple Developer account**
   - Default: an organisation account in the company's legal name, not a personal account.
   - Why: the seller name shows on the App Store. Moving the app to another account later is a transfer, and Sign in with Apple user IDs change unless migrated.

3. **Google Play developer account**
   - Default: an organisation account, same legal entity as Apple. Needed only when Android ships.
   - Why: same as Apple; the publisher name is public and transfers are slow.

4. **Kids Category (iOS) and Families target audience (Google Play)**
   - Default: yes, list it for children. Apple asks for one age band (6–8 or 9–11); which one?
   - Why: brings strict rules (no third-party analytics or ads, a parental gate before purchases, links out and settings). Apple makes it hard to leave the category once approved; to verify in App Store Connect help before choosing.

## 2. Set by us (please confirm)

1. **Link domain:** `auramath.net` for universal links (iOS) and App Links (Android), used by email sign-in links and the parent note.
2. **Content pack signing:** the backend holds the private key; the app ships with the public key and room for a second key so it can be rotated.
3. **Minimum OS versions:** iOS 16 and Android 8.0 (API 26).
4. **Devices at first release:** iPhone only. Screens are built adaptive so iPad is a layout task later. Once a version ships with iPad support, later versions cannot drop it.

## 3. Needed before external TestFlight or App Store

1. **Privacy policy URL and legal review (D-15).** Required for external testers and the App Store. `real_families` stays off until done.
2. **App Store privacy label and age rating answers.** Must match what the app stores: child first name, age, year, and learning events.
3. **Parental gate design.** How a child is kept out of parent setup and settings; required in the Kids Category. Default: a question only an adult can answer, such as typing a number written in words.
4. **Error reporting.** No Crashlytics or Sentry (DAT-08). Default: errors go to an endpoint on our own API, which the backend needs to provide.
5. **Reserve the name "Auramath" in App Store Connect.** The display name can change later; reserving early stops someone else taking it.
6. **iOS build service.** Xcode Cloud if the Apple account is ready, otherwise Codemagic (open decision in the guide).

## 4. Product questions that shape the app's data

1. Can one phone hold more than one child? Default: yes, a child picker behind the parental gate.
2. Can one family have several parents and several children? Default: yes, one family with many parents and many children.
3. What happens to data on the phone when a parent signs out? Default: local events are deleted only after the server has confirmed them.
## 5. Already decided

- The Architecture v2 guide (27 Oct) is the spec. Ages 6–10.
- Gamification means bar-model visual interaction and difficulty that follows the child. No scores, percentages or "3 of 5" anywhere.
- Parents onboard inside the app. Progress tracking is a separate web portal plus email, not in this app.
- Flutter for iOS and Android. First release is iOS, iPhone first, with layouts that adapt to iPad.
- This repo holds the mobile app and the Dart teaching engine (`packages/auramath_engine`). The backend lives in its own repo and pulls the engine at a tagged version.
- App name is "Auramath" for now; it can change later.
- Language is English only for now.

## 6. Easy to change later (no sign-off needed)

- Display name, app icon, colours and theme.
- Folder layout, Dart package names, state management and other libraries.
- How many problems are downloaded ahead (starts at 3).
- Repo name `auramath-ios`: it will hold Android too, so renaming it now is cheap if anyone minds.
