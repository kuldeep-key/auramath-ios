# Knowledge base: what each source says that matters to the app

Kept so later work doesn't have to re-read the originals. These are summaries, not copies. When a point decides something, go back to the source.

## PRD v3.3 (12 Oct 2026, Ashutosh; draft for engineering start)

- **Scope this term:**
  - comparison problems at 5 levels (heights; weights from M2+);
  - total-and-difference problems (M3);
  - arithmetic support (A1–A10);
  - starting check, Quick sums, tap-to-ask.
- **Not this term:** Android, iPad layouts, a second language, payments, live AI coaching, an AI voice.
- **Milestones:** M2 27 Oct (the lesson), M3 17 Nov (a parent sets up alone and gets a true note), M4 1–8 Dec (five families at home), close 14 Dec.
- **Rules that never move:**
  - data in Australia;
  - real families refused until the legal review;
  - no personal information to any AI;
  - no child free text;
  - code decides answers;
  - nothing red, and colour is never the only signal.
- **The YAML spec pack beside the PRD is the source of truth.** We hold only v0.3.0 (PRD v3.2). Missing from v3.3:
  - NFR-08: tap to hear the question with the built-in voice, from M2;
  - D-31: when the level goes down;
  - D-32: the phone's number pad for answers, our keypad for number sentences;
  - D-33: Julia gets a weekly email, not an admin screen.
- **Not in the YAML we hold:** `features/` (Gherkin tests), `evals/`, `design-map.yaml`, `adr/`, `tools/validate.py`.
- **Copy rules:**
  - praise is short ("You solved the Tree Word Problem!"), with step details only in the parent note;
  - no score, %, "N of M", label or year level anywhere;
  - the grown-up is never "Mum"; no gender is asked.
- **Goals:**
  - a child completes a problem alone;
  - 3 or more sessions per child in the home week;
  - at least half solved alone by the third session;
  - 4 of 5 parents find the note useful;
  - zero wrong answers marked right.

## Discovery Kit (18 Sep 2026, Ashutosh to Julia)

- **Where the teaching comes from:**
  - Julia's mock lesson: sequence, words, escalation, wait times;
  - her question types and the families she teaches: device, age band;
  - her voice, her red lines and her mastery rule;
  - audio of real sessions: the error catalogue and idle timings;
  - six questions for parents: what the note and progress page say.
- **For later:** the parents' answers (what they want after a lesson, what device the child uses) should shape the parent note and the first screen. Ask whether they were collected.

## "AI-native, built on Julia's and Dr Fong's teaching" (13 Oct 2026, Ashutosh to Kushagra; internal draft)

- **Direction:** voice, tutor characters with personality, one tutor that knows each child, a free assessment before sign-up, monthly progress for parents, kind streaks. The pedagogy decides; the AI delivers.
- **Safety and legal points that constrain the build:**
  - **The Gemini API terms bar apps likely used by under-18s.** Vertex AI's terms are unverified, so the model provider is an open question. This affects the content pipeline and any server-side evals.
  - **Characters say they're AI and never act as a friend**, which keeps us outside "companion" rules (California SB 243, eSafety codes).
  - **Voice:** scripted lines first. Live speech only after parent consent, a zero-retention provider, no stored audio, filters, red-teaming, an eSafety risk assessment and an Apple check. Tap always stays as the fallback. Children's speech recognition is weak (Whisper misheard about 25% of children's words).
  - **No paid streak freezes, no public leaderboards.** Streaks get rest days, free freezes and no loss wording; reminders are set by parents.
  - **Free assessment:** anonymous, on the phone, saved only when a parent signs up.
  - **Regulation:** Apple's Kids category bars sending personal data to third parties. Australian Children's Online Privacy Code (draft, by 10 Dec 2026), eSafety codes (since 9 Mar 2026), US COPPA (amended, 22 Apr 2026).
  - **Ownership:** under the MSA, custom deliverables, including methods, belong to IQ Maths Centre once paid for.
- **Proposed timing:** characters, scripted voice, kind streaks and the assessment by 17 Nov; live voice in the home week only if the safety gate is met. Not agreed; it changes Julia's SOW.

## Other sources already in the repo

- **Architecture v2 guide (27 Oct):** see `docs/architecture.md`.
- **Spec pack v0.3.0:** `../auramath-backend/spec/`.
- **Delta vs requirements:** `docs/delta-current-vs-requirements.md`.
- **Flag to product on moving the lesson online:** `docs/flag-online-lesson.md` (sent 28 Oct, awaiting reply).
