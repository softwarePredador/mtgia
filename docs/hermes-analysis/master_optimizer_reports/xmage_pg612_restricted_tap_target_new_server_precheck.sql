WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('ali baba', 'Ali Baba', '9d2a321e3c668d8a701485c346c42c1a', 'battle_rule_v1:f3d57d6ac678195ce05ee4e8e781b39c', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"tap_target","activated_tap_target":"wall_creature","activation_cost_colors":["R"],"activation_cost_generic":0,"activation_cost_mana":"{R}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_tap_target_v1","effect":"tap_target","target":"wall_creature","target_constraints":{"card_types":["creature"],"required_subtypes":["wall"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"TapTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_tap_target_v1","activated_effect":"tap_target","activated_tap_target":"wall_creature","activation_cost_colors":["R"],"activation_cost_generic":0,"activation_cost_mana":"{R}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_tap_target_v1","effect":"creature","target":"wall_creature","target_constraints":{"card_types":["creature"],"required_subtypes":["wall"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"wall_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AliBaba translated into ManaLoom runtime scope xmage_permanent_simple_activated_tap_target_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('coeurl', 'Coeurl', 'dc320bded3c84b47cf4dda77e8a61525', 'battle_rule_v1:b416e913affdf6c3acced3e0aa5cad3b', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"tap_target","activated_tap_target":"nonenchantment_creature","activation_cost_colors":["W"],"activation_cost_generic":1,"activation_cost_mana":"{1}{W}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_tap_target_v1","effect":"tap_target","target":"nonenchantment_creature","target_constraints":{"card_types":["creature"],"exclude_card_types":["enchantment"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"TapTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_tap_target_v1","activated_effect":"tap_target","activated_tap_target":"nonenchantment_creature","activation_cost_colors":["W"],"activation_cost_generic":1,"activation_cost_mana":"{1}{W}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_tap_target_v1","effect":"creature","target":"nonenchantment_creature","target_constraints":{"card_types":["creature"],"exclude_card_types":["enchantment"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"nonenchantment_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Coeurl translated into ManaLoom runtime scope xmage_permanent_simple_activated_tap_target_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kitsune diviner', 'Kitsune Diviner', '917ed923cf08e4a8073b524b16174e7a', 'battle_rule_v1:292dafa735745dd648240e2e7adf5f80', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"tap_target","activated_tap_target":"spirit_creature","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_tap_target_v1","effect":"tap_target","target":"spirit_creature","target_constraints":{"card_types":["creature"],"required_subtypes":["spirit"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"TapTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_tap_target_v1","activated_effect":"tap_target","activated_tap_target":"spirit_creature","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_tap_target_v1","effect":"creature","target":"spirit_creature","target_constraints":{"card_types":["creature"],"required_subtypes":["spirit"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"spirit_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KitsuneDiviner translated into ManaLoom runtime scope xmage_permanent_simple_activated_tap_target_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('law-rune enforcer', 'Law-Rune Enforcer', '8844325fa17c7065e2a8d621dde94fa2', 'battle_rule_v1:4f355610aaa475281bb90e85180ca261', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"tap_target","activated_tap_target":"creature_mana_value_2_or_greater","activation_cost_colors":[],"activation_cost_generic":1,"activation_cost_mana":"{1}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_tap_target_v1","effect":"tap_target","target":"creature_mana_value_2_or_greater","target_constraints":{"card_types":["creature"],"mana_value_min":2},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"TapTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_tap_target_v1","activated_effect":"tap_target","activated_tap_target":"creature_mana_value_2_or_greater","activation_cost_colors":[],"activation_cost_generic":1,"activation_cost_mana":"{1}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_tap_target_v1","effect":"creature","target":"creature_mana_value_2_or_greater","target_constraints":{"card_types":["creature"],"mana_value_min":2},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature_mana_value_2_or_greater"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LawRuneEnforcer translated into ManaLoom runtime scope xmage_permanent_simple_activated_tap_target_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sigardian priest', 'Sigardian Priest', 'df262801a1beb003dc72e34e4cdcf5d5', 'battle_rule_v1:9cae008fc7e7c5dd76fc3d5bbec0b55c', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"tap_target","activated_tap_target":"non_human_creature","activation_cost_colors":[],"activation_cost_generic":1,"activation_cost_mana":"{1}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_tap_target_v1","effect":"tap_target","target":"non_human_creature","target_constraints":{"card_types":["creature"],"exclude_subtypes":["human"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"TapTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_tap_target_v1","activated_effect":"tap_target","activated_tap_target":"non_human_creature","activation_cost_colors":[],"activation_cost_generic":1,"activation_cost_mana":"{1}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_tap_target_v1","effect":"creature","target":"non_human_creature","target_constraints":{"card_types":["creature"],"exclude_subtypes":["human"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"non_human_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SigardianPriest translated into ManaLoom runtime scope xmage_permanent_simple_activated_tap_target_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sterling keykeeper', 'Sterling Keykeeper', '69ca93bc4e3d96263ce9c8727524865f', 'battle_rule_v1:79c8df6d7b60de0c04ce52c71d7cf16c', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"tap_target","activated_tap_target":"non_mount_creature","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_tap_target_v1","effect":"tap_target","target":"non_mount_creature","target_constraints":{"card_types":["creature"],"exclude_subtypes":["mount"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"TapTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_tap_target_v1","activated_effect":"tap_target","activated_tap_target":"non_mount_creature","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_tap_target_v1","effect":"creature","target":"non_mount_creature","target_constraints":{"card_types":["creature"],"exclude_subtypes":["mount"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"non_mount_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SterlingKeykeeper translated into ManaLoom runtime scope xmage_permanent_simple_activated_tap_target_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('storm front', 'Storm Front', '2345441c7f4fa2a3adce46ca934931de', 'battle_rule_v1:369f1e4c26619dbdfb3a20640fe95cbf', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"tap_target","activated_tap_target":"flying_creature","activation_cost_colors":["G","G"],"activation_cost_generic":0,"activation_cost_mana":"{G}{G}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_tap_target_v1","effect":"tap_target","target":"flying_creature","target_constraints":{"card_types":["creature"],"required_keywords":["flying"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"TapTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_tap_target_v1","activated_effect":"tap_target","activated_tap_target":"flying_creature","activation_cost_colors":["G","G"],"activation_cost_generic":0,"activation_cost_mana":"{G}{G}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_tap_target_v1","effect":"enchantment","target":"flying_creature","target_constraints":{"card_types":["creature"],"required_keywords":["flying"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"enchantment","target":"flying_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StormFront translated into ManaLoom runtime scope xmage_permanent_simple_activated_tap_target_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
