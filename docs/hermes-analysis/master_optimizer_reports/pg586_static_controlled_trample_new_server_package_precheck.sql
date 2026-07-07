WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('aggressive mammoth', 'Aggressive Mammoth', '1a9fad0b7e938d5339fcb2a9a6c76427', 'battle_rule_v1:31ed27eaaea6b43f5bce5a1219f39dc0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"creature","keywords":["trample"],"permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":true,"static_granted_keywords":["trample"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self"},"target_controller":"self","trample":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AggressiveMammoth translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bloodcrusher of khorne', 'Bloodcrusher of Khorne', 'add52677a0e693e79ccd3290ab703076', 'battle_rule_v1:31ed27eaaea6b43f5bce5a1219f39dc0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"creature","keywords":["trample"],"permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":true,"static_granted_keywords":["trample"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self"},"target_controller":"self","trample":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BloodcrusherOfKhorne translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('groundshaker sliver', 'Groundshaker Sliver', '585fdd46d978b86a9007554050630ca9', 'battle_rule_v1:48e0618f7275569070a4db62d971a9ba', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"creature","permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":false,"static_granted_keywords":["trample"],"static_required_subtypes":["sliver"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self","subtypes":["sliver"]},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GroundshakerSliver translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('khenra charioteer', 'Khenra Charioteer', '65f7b9f5ecda0ab8578963164076b601', 'battle_rule_v1:31ed27eaaea6b43f5bce5a1219f39dc0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"creature","keywords":["trample"],"permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":true,"static_granted_keywords":["trample"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self"},"target_controller":"self","trample":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KhenraCharioteer translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nylea''s forerunner', 'Nylea''s Forerunner', '65f7b9f5ecda0ab8578963164076b601', 'battle_rule_v1:31ed27eaaea6b43f5bce5a1219f39dc0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"creature","keywords":["trample"],"permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":true,"static_granted_keywords":["trample"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self"},"target_controller":"self","trample":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NyleasForerunner translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('primal rage', 'Primal Rage', 'b532311af37638867a24270200d81d24', 'battle_rule_v1:363974e6bda920ddcbd5655a2ba63caa', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"passive","permanent_type":"enchantment","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":false,"static_granted_keywords":["trample"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"passive","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PrimalRage translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('roughshod mentor', 'Roughshod Mentor', '03eba077ad4be2b9a9fbaad44087cf62', 'battle_rule_v1:0e7575f499a93af361184ebc70967e84', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"creature","permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":false,"static_granted_keywords":["trample"],"static_required_colors":["G"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"colors":["G"],"controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RoughshodMentor translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thicket crasher', 'Thicket Crasher', 'c0da9dbcfb5eff6e27a2929dbac73811', 'battle_rule_v1:64dc5dab62cd8f17e3c7f4ede9228277', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"creature","keywords":["trample"],"permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":true,"static_granted_keywords":["trample"],"static_required_subtypes":["elemental"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self","subtypes":["elemental"]},"target_controller":"self","trample":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThicketCrasher translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
