# Plan: send the spec's event format

28 Oct 2026 · branch `feat/app-base` · gap 1 in `docs/delta-current-vs-requirements.md`

**Goal:** every event the app saves and sends passes the backend's check against `auramath-backend/spec/contracts/events.schema.json` (spec pack v0.3.0). Resume still works by replaying the log through the engine.

**Why now:** today the backend would refuse every event the app sends.

## The calls in this plan (please check)

1. **One log, in the spec's format.** The outbox stores the spec events themselves, not the engine's raw inputs. Resume turns them back into engine inputs. One log means nothing on the phone can disagree with what the server holds (the guide's "the log holds the truth").
2. **The engine uses the spec's names.**
   - **Step ids:** `draw_known_bar`, `size_second_bar`, `place_difference`, `place_total`, `choose_operation`, `find_unknown`, `find_total`.
   - **Mistake types:** `sub_smaller_from_larger`, `carry_dropped`, `relation_reversed`, `difference_as_amount`, `transposition`, `keyword_strategy`, `answered_wrong_question`.
   - That way the server reads the phone's decisions directly (`step_committed.correct` and `error_type`) and needs no Python lesson machine.
3. **Placing bar B and sizing it are one spec step** (`size_second_bar`). Placing it is saved as `object_placed` with `committed: false`; sizing it as `committed: true` with `relative_to_bar_a`.
4. **`child_ref` and `device_id`** come from setup and pairing, which don't exist in the app yet. Until then they come from `env/dev.json` (`ch_dev…`, `dv_dev…`), and the backend's demo flag (`is_demo: true`) marks those sessions.
5. **The sample pack gains the spec's problem fields:** `template_id` (`cmp.comparison`), `template_version`, `story_id` (`lemon-fig`), `level` (`L4`), `relation`.
6. **Seq starts at 0**, as in the spec; today it starts at 1.

## Steps (each test-first)

1. **Engine: spec names.**
   - Rename the step ids, and give every wrong move its spec `error_type`, including the drawing steps (relation reversed, gap on the wrong bar).
   - Update the golden files.
2. **Engine: event writer** (`lib/src/contract.dart`). A pure function turns one child input plus the engine's result into the spec events for it. For example, `NumberEntered(81)` at `find_unknown` gives `value_entered`, then `step_committed` (wrong, `sub_smaller_from_larger`), then `side_lesson_started`.
   - Also `session_started`, `problem_shown`, `problem_completed`, `badge_awarded` and `session_ended`.
   - Golden test: the spec's own worked example, `contracts/examples/lesson-session.events.json`.
3. **Engine: reader.** Spec events back to engine inputs, for resume. Round-trip test: write, then read back, gives the same inputs.
4. **Contract check in our tests.** Copy `events.schema.json` into the repo as a test fixture, and validate every event the lesson tests produce against it. If the backend's contract changes, our tests fail first.
5. **App: outbox and sync.**
   - The outbox stores the spec envelope (`event_id` is a UUID).
   - The sync batch uses the spec shape.
   - The fake API rejects anything that fails the schema, as the real one does.
   - The old local outbox table is dropped, since there are no real users yet.
6. **Pack and env:** the new pack fields, `child_ref` and `device_id` in the env files, and `app_version` from the build.

## Not in this plan

- The engine reading the spec's YAML template and the five levels (the next plan).
- The real HTTP client, and setup and pairing (which supply the real `child_ref` and `device_id`).

## For the backend team

The app will send `step_committed` with `correct` and `error_type`, and `problem_completed` with the outcome. The spec already allows these. If the backend builds its reports and mastery from these fields, it can retire `core/`.

## Done 28 Oct, and the calls made while building

**Built:**
- Every event the app saves passes the backend's own schema; the tests check this on a full lesson.
- Resume replays the spec events.
- Engine 86 tests and app 62 tests pass.

**Calls made while building:**
1. **The engine keeps its internal names.** `contract.dart` maps them to the spec's step ids and mistake types, which gives the server the same result with far less churn than renaming. *Cost if wrong:* one mapping table to keep in step with the template.
2. **Each session holds one problem for now.** "Something easier" opens a new session; resume starts from the latest `problem_shown`. A session becomes the whole sitting when the 30-minute cap lands (next item). *Cost if wrong:* the session grouping changes in one place, the view model.
3. **`help_opened` is written when a help option is chosen,** not when the sheet opens; opening and closing the sheet without choosing isn't logged. *Cost if wrong:* one extra input.
4. **Several idle-prompt levels firing in one tick are written as one `idle_prompt_shown`** at the highest level. Replay gives the same state.
5. **On the answer sheet, "check one part" is written as `route: check_unknown_first`.** The policy has no name for that route.
6. **Prod builds refuse to start without a child ref and device id.** Only dev has placeholders.
7. **The spec's worked example isn't used as a golden file,** because it skips steps our lesson draws. The schema check on every event covers the contract instead.
8. **The outbox table moves to version 2 and drops the old rows.** No real family has used the app.
