WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('liliana''s elite', 'Liliana''s Elite', '0e5c88060b6b53bbb24c8fca3d83a82f', 'battle_rule_v1:124626c61ac3f48ff46db14909e9681f', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_equal_graveyard_count_v1","effect":"creature","graveyard_count_card_types":["creature"],"graveyard_count_scope":"controller_graveyard","static_effect":"source_power_toughness_boost_equal_graveyard_count","static_power_bonus_per_graveyard_count":1,"static_toughness_bonus_per_graveyard_count":1,"target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LilianasElite translated into ManaLoom runtime scope xmage_static_source_boost_equal_graveyard_count_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost equal to graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('salvage slasher', 'Salvage Slasher', '4e36ff100ca10bd502ce20633c7ce415', 'battle_rule_v1:72d8bb5d5b6e8f637c637aee8d2ba831', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_equal_graveyard_count_v1","effect":"creature","graveyard_count_card_types":["artifact"],"graveyard_count_scope":"controller_graveyard","static_effect":"source_power_toughness_boost_equal_graveyard_count","static_power_bonus_per_graveyard_count":1,"static_toughness_bonus_per_graveyard_count":0,"target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SalvageSlasher translated into ManaLoom runtime scope xmage_static_source_boost_equal_graveyard_count_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost equal to graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wight of precinct six', 'Wight of Precinct Six', '721b083840f7456c239247f2df849056', 'battle_rule_v1:02c4275c60f5bb144bd4db5b98f1deba', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_equal_graveyard_count_v1","effect":"creature","graveyard_count_card_types":["creature"],"graveyard_count_scope":"opponents_graveyards","static_effect":"source_power_toughness_boost_equal_graveyard_count","static_power_bonus_per_graveyard_count":1,"static_toughness_bonus_per_graveyard_count":1,"target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WightOfPrecinctSix translated into ManaLoom runtime scope xmage_static_source_boost_equal_graveyard_count_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost equal to graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
