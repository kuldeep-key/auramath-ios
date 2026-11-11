Julia's teaching values, as the backend serves them: spec pack v0.4.1
(PRD v4.1, 2 Nov; its files still say version 0.4.0, the pack's own
number) plus the backend's DRAFT defaults on top, copied from
auramath-backend/spec, branch integrate/r1-ai (446de96, 11 Nov). AUR-31
asked for v0.4.1: this is it. policy.yaml and app-config.yaml differ from
the pack's own copy only by those defaults (the age word list, the case
partner's script, sitting_gap_minutes, rewards names, the score_drop side
lesson trigger, and the dev flags); skill-map.yaml and the template are
the pack's, byte for byte.

- policy.yaml              spec/tutor/policy.yaml                     0.4.0
- app-config.yaml          spec/content/app-config.yaml               0.4.0
- skill-map.yaml           spec/content/skill-map.yaml                0.3.0 (unchanged number; v4 text)
- comparison-two-step.yaml spec/content/templates/comparison-two-step.yaml 0.3.0

v0.4 brings the AI layer's drafts: the case partner's script
(line.intro.*, case_partner_intro), the age word list
(story_generation.age_word_list, draft for Julia), question_buttons,
side_lessons.abandon_after_wrong_practice and the AI-07 forbidden phrases.
Every line in lines.pack is still approved: false.

Don't edit by hand: copy them in again when the spec pack changes, e.g.

    git -C ../auramath-backend show integrate/r1-ai:spec/tutor/policy.yaml > policy.yaml
