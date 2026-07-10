WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('centaur veteran', 'Centaur Veteran', 'a7c2878030bdc99b3d0aa9d6194122da', 'battle_rule_v1:e35f3ce9a67c2de7b719f5ea094632a7', '{"_activated_rule_effects":[{"_keywords_are_self":true,"ability_kind":"activated","activated_effect":"regenerate_source","activation_cost_colors":["G"],"activation_cost_generic":0,"activation_cost_mana":"{G}","activation_discard_count":1,"activation_discard_target":"any_card","activation_requires_discard_card":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_regenerate_source_v1","duration":"until_end_of_turn","effect":"regenerate_source","keywords":["trample"],"regenerate_source":true,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"RegenerateSourceEffect"}],"_keywords_are_self":true,"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_regenerate_source_v1","activated_effect":"regenerate_source","activation_cost_colors":["G"],"activation_cost_generic":0,"activation_cost_mana":"{G}","activation_discard_count":1,"activation_discard_target":"any_card","activation_requires_discard_card":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_regenerate_source_v1","duration":"until_end_of_turn","effect":"creature","keywords":["trample"],"regenerate_source":true,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","trample":true,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"RegenerateSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CentaurVeteran translated into ManaLoom runtime scope xmage_permanent_simple_activated_regenerate_source_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('deepwood ghoul', 'Deepwood Ghoul', 'b0b618643b86c0988608c4bd63abb49e', 'battle_rule_v1:29b27ad949f2a0feccff92ec8a36370f', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"regenerate_source","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_life_cost":2,"activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_regenerate_source_v1","duration":"until_end_of_turn","effect":"regenerate_source","regenerate_source":true,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"RegenerateSourceEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_regenerate_source_v1","activated_effect":"regenerate_source","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_life_cost":2,"activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_regenerate_source_v1","duration":"until_end_of_turn","effect":"creature","regenerate_source":true,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"RegenerateSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeepwoodGhoul translated into ManaLoom runtime scope xmage_permanent_simple_activated_regenerate_source_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('marrow bats', 'Marrow Bats', '13915d0190c111ada0a320e33aa8255d', 'battle_rule_v1:627a532a5466d2e059212b0f09f07d2e', '{"_activated_rule_effects":[{"_keywords_are_self":true,"ability_kind":"activated","activated_effect":"regenerate_source","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_life_cost":4,"activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_regenerate_source_v1","duration":"until_end_of_turn","effect":"regenerate_source","keywords":["flying"],"regenerate_source":true,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"RegenerateSourceEffect"}],"_keywords_are_self":true,"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_regenerate_source_v1","activated_effect":"regenerate_source","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_life_cost":4,"activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_regenerate_source_v1","duration":"until_end_of_turn","effect":"creature","flying":true,"keywords":["flying"],"regenerate_source":true,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"RegenerateSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MarrowBats translated into ManaLoom runtime scope xmage_permanent_simple_activated_regenerate_source_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mischievous poltergeist', 'Mischievous Poltergeist', '1d4c28511b92b358353a30f5ed2ea864', 'battle_rule_v1:16334bd23c8bf65025cc0e18abb544f8', '{"_activated_rule_effects":[{"_keywords_are_self":true,"ability_kind":"activated","activated_effect":"regenerate_source","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_life_cost":1,"activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_regenerate_source_v1","duration":"until_end_of_turn","effect":"regenerate_source","keywords":["flying"],"regenerate_source":true,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"RegenerateSourceEffect"}],"_keywords_are_self":true,"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_regenerate_source_v1","activated_effect":"regenerate_source","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_life_cost":1,"activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_regenerate_source_v1","duration":"until_end_of_turn","effect":"creature","flying":true,"keywords":["flying"],"regenerate_source":true,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"RegenerateSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MischievousPoltergeist translated into ManaLoom runtime scope xmage_permanent_simple_activated_regenerate_source_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sentry of the underworld', 'Sentry of the Underworld', '73a705cab53339dede31c0ca712cfeb2', 'battle_rule_v1:9de50b65fd645a62bc46d4c369b84c4d', '{"_activated_rule_effects":[{"_keywords_are_self":true,"ability_kind":"activated","activated_effect":"regenerate_source","activation_cost_colors":["W","B"],"activation_cost_generic":0,"activation_cost_mana":"{W}{B}","activation_life_cost":3,"activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_regenerate_source_v1","duration":"until_end_of_turn","effect":"regenerate_source","keywords":["flying","vigilance"],"regenerate_source":true,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"RegenerateSourceEffect"}],"_keywords_are_self":true,"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_regenerate_source_v1","activated_effect":"regenerate_source","activation_cost_colors":["W","B"],"activation_cost_generic":0,"activation_cost_mana":"{W}{B}","activation_life_cost":3,"activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_regenerate_source_v1","duration":"until_end_of_turn","effect":"creature","flying":true,"keywords":["flying","vigilance"],"regenerate_source":true,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","vigilance":true,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"RegenerateSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SentryOfTheUnderworld translated into ManaLoom runtime scope xmage_permanent_simple_activated_regenerate_source_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tunneler wurm', 'Tunneler Wurm', 'bf60dc8ee6f3fc31a5d4a40b014a65fa', 'battle_rule_v1:6eff9f19b181732abd0a6c4d6d1d0069', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"regenerate_source","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_discard_count":1,"activation_discard_target":"any_card","activation_requires_discard_card":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_regenerate_source_v1","duration":"until_end_of_turn","effect":"regenerate_source","regenerate_source":true,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"RegenerateSourceEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_regenerate_source_v1","activated_effect":"regenerate_source","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_discard_count":1,"activation_discard_target":"any_card","activation_requires_discard_card":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_regenerate_source_v1","duration":"until_end_of_turn","effect":"creature","regenerate_source":true,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"RegenerateSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TunnelerWurm translated into ManaLoom runtime scope xmage_permanent_simple_activated_regenerate_source_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
matched_cards AS (
  SELECT
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    c.id AS card_id,
    c.name AS db_card_name
  FROM proposed p
  LEFT JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
target_cards AS (
  SELECT
    normalized_name,
    card_name,
    oracle_hash,
    count(card_id) AS target_card_rows,
    min(card_id::text)::uuid AS canonical_card_id,
    min(db_card_name) AS canonical_card_name
  FROM matched_cards
  GROUP BY normalized_name, card_name, oracle_hash
),
rule_rows AS (
  SELECT p.normalized_name, count(r.*) AS existing_rule_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
  GROUP BY p.normalized_name
),
expected_rows AS (
  SELECT p.normalized_name, count(r.*) AS expected_rule_rows_before
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
  GROUP BY p.normalized_name
),
shadow_rows AS (
  SELECT p.normalized_name, count(r.*) AS would_deprecate_shadow_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key <> p.logical_rule_key
   AND r.review_status NOT IN ('deprecated', 'rejected')
   AND r.execution_status <> 'disabled'
  GROUP BY p.normalized_name
)
SELECT
  p.card_name,
  p.normalized_name,
  p.oracle_hash,
  p.logical_rule_key,
  p.shadow_handling,
  tc.target_card_rows,
  tc.canonical_card_id,
  rr.existing_rule_rows,
  er.expected_rule_rows_before,
  sr.would_deprecate_shadow_rows
FROM proposed p
JOIN target_cards tc USING (normalized_name, card_name, oracle_hash)
JOIN rule_rows rr USING (normalized_name)
JOIN expected_rows er USING (normalized_name)
JOIN shadow_rows sr USING (normalized_name)
ORDER BY p.card_name;
