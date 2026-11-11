Julia's teaching values, copied from the spec pack v0.4.0 (2 Nov, PRD v4)
in auramath-backend/spec, branch integrate/r1-ai (eaad558, 10 Nov):

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
