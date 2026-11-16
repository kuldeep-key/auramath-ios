Julia's teaching values and the journey's settings, as the backend serves
them: spec pack v0.5.4 (12 Nov 2026, PRD v4.1 with the v4.2 delta), copied
from auramath-backend/spec (6012d04, "Run on spec pack v0.5.4"). The
backend's DRAFT defaults of v0.4.1 are in the pack itself from v0.5.x, so
every file here is the pack's, byte for byte. The served bundle
(GET /api/content/bundle) wins over these copies whenever the phone holds one.

- policy.yaml              spec/tutor/policy.yaml                         0.5.4
- app-config.yaml          spec/content/app-config.yaml                   0.5.4
- skill-map.yaml           spec/content/skill-map.yaml                    0.3.0 (unchanged number; v4 text)
- comparison-two-step.yaml spec/content/templates/comparison-two-step.yaml 0.3.0 (with CON-09's five new height stories)
- tutors.yaml              spec/tutor/tutors.yaml                         0.1.0 (D-59, TTR-01 to TTR-08)
- looks.yaml               spec/avatar/looks.yaml                         0.1.0 (D-59, ACC-12, AVT-01 to AVT-03)
- journey.yaml             spec/journey/journey.yaml                      0.1.0 (D-59, JRN-01 to JRN-07)
- catalogue.yaml           spec/rewards/catalogue.yaml                    0.2.2 (D-51: names by world)
- rules.yaml               spec/rewards/rules.yaml                        0.3.4 (D-51: celebrations, orders)

v0.5.4 brings the tutor's own lines (line.tutor.*, line.home.greeting,
line.pick.*), read-aloud on for every age (TTR-03), the quiet timer
starting after the tutor's line (TUT-07), the rewards switches, and the
age word list in its own file (content/age-word-list.yaml, CON-13: the
server checks it; the app doesn't bundle it). Every line in lines.pack is
still approved: false.

Don't edit by hand: copy them in again when the spec pack changes, e.g.

    cp ../auramath-backend/spec/tutor/policy.yaml policy.yaml
