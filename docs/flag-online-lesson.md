# Decision needed: move the child's lesson online

**From:** Engineering (mobile)
**To:** Ashutosh (product), Apoorv (product design)
**Cc:** Kuldeep (engineering lead, owner of SES-04), Vishal (AI models), Karan
**Reply by:** this week. It changes the app and backend work starting now.

---

## In short

- **We recommend:** the child's lesson runs online, so the app needs an internet connection to run a lesson.
- **Why:** live AI and evaluation during the lesson, one live record on the server, and reliable phone switching, parent notes and levels.
- **What it changes in the PRD:** SES-04, TUT-01 / D-26 and NFR-05.
- **What we need:** Ashutosh's approval (with Julia for teaching), Kuldeep's agreement on SES-04, and Vishal's call on the models.

---

## 1. Why online

| What we gain | Requirement or plan |
| --- | --- |
| **AI and evals during the lesson.** Rubric, metric and LLM-judge evaluation of each step, and AI-chosen help, with models hosted. Not possible in an offline lesson. | PRD §2.6 "Okay to change to AI"; live AI coaching |
| **Switching phones mid-lesson always works.** Every tap is on the server as it happens. | DEV-05 |
| **The parent note arrives on time.** The session's events reach the server straight away. | PAR-01 (within about 5 min) |
| **Scores, levels and the learner profile are current on every phone.** No phone works from a stale profile. | SKL-02 to SKL-05, TUT-15 |
| **One source of truth.** The server holds the record live, with no queue to reconcile. | DAT-01 |
| **Always the latest content and on/off switches.** | CON-08, PLAT-06 |

## 2. How we'd build it

1. **Instant checks stay on the phone.** Right or wrong, mistake routes and hint order run in the app's teaching engine, which is already built and tested. The tutor keeps latency to a minimum, and the backend doesn't rebuild that logic.
2. **AI runs on the server, live.** It evaluates steps and can choose or word the help, with code checks as the guardrail. Only ids, steps, outcomes and numbers go to the model, never a child's name or free text (PRV-01).
3. **Short drops are handled gently.** Taps are held and resent. If the connection is gone, the lesson pauses with a "Lost the internet" notice and resumes exactly where it stopped. Nothing is lost.

## 3. PRD changes needed

| Item | Today | Proposed |
| --- | --- | --- |
| **SES-04** (firm, M2+) | The lesson continues offline; a full problem can be finished in airplane mode | The lesson pauses when the connection drops and resumes where it stopped; no tap is lost |
| **TUT-01, D-26** | Code decides; no model call during a session | Code checks right and wrong; server-side AI may evaluate steps and choose or word help, within the code's guardrails |
| **NFR-05** | Tutor response within 300 ms | Low-latency code checks; a stated time limit for AI moments, with the code's line shown if AI is late |

## 4. Costs and risks we accept

- **No connection, no lesson.** A child with no internet waits until it's back. We mitigate this with the pause notice and an exact resume.
- **Backend work.** A live endpoint for AI evaluation, models hosted in Australia (D-17), and monitoring of response times.
- **"Never wrong" stays with code.** The AI judges and guides; code still decides whether an answer is right.

## 5. Decisions needed

| Who | Decision |
| --- | --- |
| **Ashutosh** (with Julia for teaching) | Approve the online lesson and the three PRD changes |
| **Kuldeep** | Agree the SES-04 change as owner; confirm backend capacity for the live AI endpoint |
| **Vishal** | Which models, where they run (Australia, D-17), and the time limit for AI responses |
