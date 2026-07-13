WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('punk frogs', 'Punk Frogs', '4491763795274f7ce062b50a69d8c0df', 'battle_rule_v1:646fcaa58b271a6669f00d0e6549f931', '{"_keywords_are_self":true,"battle_model_scope":"xmage_static_self_combat_keyword_creature_v1","effect":"creature","keywords":[],"ward":"{3}","ward_cost":"{3}","ward_cost_status":"runtime_executor_v1","ward_mana_value":3,"xmage_ability_classes":["WardAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PunkFrogs translated into ManaLoom runtime scope xmage_static_self_combat_keyword_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rimeshield frost giant', 'Rimeshield Frost Giant', '4491763795274f7ce062b50a69d8c0df', 'battle_rule_v1:646fcaa58b271a6669f00d0e6549f931', '{"_keywords_are_self":true,"battle_model_scope":"xmage_static_self_combat_keyword_creature_v1","effect":"creature","keywords":[],"ward":"{3}","ward_cost":"{3}","ward_cost_status":"runtime_executor_v1","ward_mana_value":3,"xmage_ability_classes":["WardAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RimeshieldFrostGiant translated into ManaLoom runtime scope xmage_static_self_combat_keyword_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spider-rex, daring dino', 'Spider-Rex, Daring Dino', 'cfde276b568e3227ab1a5d23b980b02d', 'battle_rule_v1:2423442d397012ba21a508b50416d84f', '{"_keywords_are_self":true,"battle_model_scope":"xmage_static_self_combat_keyword_creature_v1","effect":"creature","keywords":["reach","trample"],"reach":true,"trample":true,"ward":"{2}","ward_cost":"{2}","ward_cost_status":"runtime_executor_v1","ward_mana_value":2,"xmage_ability_classes":["ReachAbility","TrampleAbility","WardAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpiderRexDaringDino translated into ManaLoom runtime scope xmage_static_self_combat_keyword_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tomakul honor guard', 'Tomakul Honor Guard', '6bd51c150a01631e1f5baf38e59ee39f', 'battle_rule_v1:34f4729c41611935e9c204335337d063', '{"_keywords_are_self":true,"battle_model_scope":"xmage_static_self_combat_keyword_creature_v1","effect":"creature","keywords":[],"ward":"{2}","ward_cost":"{2}","ward_cost_status":"runtime_executor_v1","ward_mana_value":2,"xmage_ability_classes":["WardAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TomakulHonorGuard translated into ManaLoom runtime scope xmage_static_self_combat_keyword_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('waterfall aerialist', 'Waterfall Aerialist', '8009a54c00bb7c689882802e0bc37276', 'battle_rule_v1:f1324914fb7d71e8add2219aa03eb63e', '{"_keywords_are_self":true,"battle_model_scope":"xmage_static_self_combat_keyword_creature_v1","effect":"creature","flying":true,"keywords":["flying"],"ward":"{2}","ward_cost":"{2}","ward_cost_status":"runtime_executor_v1","ward_mana_value":2,"xmage_ability_classes":["FlyingAbility","WardAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WaterfallAerialist translated into ManaLoom runtime scope xmage_static_self_combat_keyword_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
