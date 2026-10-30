# Auramath mobile

The Auramath app (Flutter, iOS first) and the Dart teaching engine.

- Architecture: `docs/architecture.md`
- Decisions pending sign-off: `docs/decisions-to-confirm.md`
- Current build plan: `docs/plans/2026-10-27-app-base.md`

## Run

```bash
flutter run --dart-define-from-file=env/dev.json
flutter test
(cd packages/auramath_engine && dart test)
```
