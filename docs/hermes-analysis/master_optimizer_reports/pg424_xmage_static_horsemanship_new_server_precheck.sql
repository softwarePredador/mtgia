WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('barbarian general', 'Barbarian General', '6f10a2a07dbc67283d061eeaaded1b53', 'battle_rule_v1:7d208ac6a5625631cd5f858097f64cdd', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_horsemanship_creature_v1","effect":"creature","horsemanship":true,"keywords":["horsemanship"],"static_effect":"self_horsemanship","target":"self","target_controller":"self","xmage_ability_class":"HorsemanshipAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BarbarianGeneral translated into ManaLoom runtime scope xmage_static_self_horsemanship_creature_v1. This row is package-ready only because the source signature is a narrow creature static self horsemanship evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lady zhurong, warrior queen', 'Lady Zhurong, Warrior Queen', '6f10a2a07dbc67283d061eeaaded1b53', 'battle_rule_v1:7d208ac6a5625631cd5f858097f64cdd', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_horsemanship_creature_v1","effect":"creature","horsemanship":true,"keywords":["horsemanship"],"static_effect":"self_horsemanship","target":"self","target_controller":"self","xmage_ability_class":"HorsemanshipAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LadyZhurongWarriorQueen translated into ManaLoom runtime scope xmage_static_self_horsemanship_creature_v1. This row is package-ready only because the source signature is a narrow creature static self horsemanship evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lu meng, wu general', 'Lu Meng, Wu General', '6f10a2a07dbc67283d061eeaaded1b53', 'battle_rule_v1:7d208ac6a5625631cd5f858097f64cdd', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_horsemanship_creature_v1","effect":"creature","horsemanship":true,"keywords":["horsemanship"],"static_effect":"self_horsemanship","target":"self","target_controller":"self","xmage_ability_class":"HorsemanshipAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LuMengWuGeneral translated into ManaLoom runtime scope xmage_static_self_horsemanship_creature_v1. This row is package-ready only because the source signature is a narrow creature static self horsemanship evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shu cavalry', 'Shu Cavalry', '6f10a2a07dbc67283d061eeaaded1b53', 'battle_rule_v1:7d208ac6a5625631cd5f858097f64cdd', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_horsemanship_creature_v1","effect":"creature","horsemanship":true,"keywords":["horsemanship"],"static_effect":"self_horsemanship","target":"self","target_controller":"self","xmage_ability_class":"HorsemanshipAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShuCavalry translated into ManaLoom runtime scope xmage_static_self_horsemanship_creature_v1. This row is package-ready only because the source signature is a narrow creature static self horsemanship evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shu elite companions', 'Shu Elite Companions', '6f10a2a07dbc67283d061eeaaded1b53', 'battle_rule_v1:7d208ac6a5625631cd5f858097f64cdd', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_horsemanship_creature_v1","effect":"creature","horsemanship":true,"keywords":["horsemanship"],"static_effect":"self_horsemanship","target":"self","target_controller":"self","xmage_ability_class":"HorsemanshipAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShuEliteCompanions translated into ManaLoom runtime scope xmage_static_self_horsemanship_creature_v1. This row is package-ready only because the source signature is a narrow creature static self horsemanship evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wei elite companions', 'Wei Elite Companions', '6f10a2a07dbc67283d061eeaaded1b53', 'battle_rule_v1:7d208ac6a5625631cd5f858097f64cdd', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_horsemanship_creature_v1","effect":"creature","horsemanship":true,"keywords":["horsemanship"],"static_effect":"self_horsemanship","target":"self","target_controller":"self","xmage_ability_class":"HorsemanshipAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WeiEliteCompanions translated into ManaLoom runtime scope xmage_static_self_horsemanship_creature_v1. This row is package-ready only because the source signature is a narrow creature static self horsemanship evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wei scout', 'Wei Scout', '6f10a2a07dbc67283d061eeaaded1b53', 'battle_rule_v1:7d208ac6a5625631cd5f858097f64cdd', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_horsemanship_creature_v1","effect":"creature","horsemanship":true,"keywords":["horsemanship"],"static_effect":"self_horsemanship","target":"self","target_controller":"self","xmage_ability_class":"HorsemanshipAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WeiScout translated into ManaLoom runtime scope xmage_static_self_horsemanship_creature_v1. This row is package-ready only because the source signature is a narrow creature static self horsemanship evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wei strike force', 'Wei Strike Force', '6f10a2a07dbc67283d061eeaaded1b53', 'battle_rule_v1:7d208ac6a5625631cd5f858097f64cdd', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_horsemanship_creature_v1","effect":"creature","horsemanship":true,"keywords":["horsemanship"],"static_effect":"self_horsemanship","target":"self","target_controller":"self","xmage_ability_class":"HorsemanshipAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WeiStrikeForce translated into ManaLoom runtime scope xmage_static_self_horsemanship_creature_v1. This row is package-ready only because the source signature is a narrow creature static self horsemanship evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wu elite cavalry', 'Wu Elite Cavalry', '6f10a2a07dbc67283d061eeaaded1b53', 'battle_rule_v1:7d208ac6a5625631cd5f858097f64cdd', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_horsemanship_creature_v1","effect":"creature","horsemanship":true,"keywords":["horsemanship"],"static_effect":"self_horsemanship","target":"self","target_controller":"self","xmage_ability_class":"HorsemanshipAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WuEliteCavalry translated into ManaLoom runtime scope xmage_static_self_horsemanship_creature_v1. This row is package-ready only because the source signature is a narrow creature static self horsemanship evasion with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wu light cavalry', 'Wu Light Cavalry', '6f10a2a07dbc67283d061eeaaded1b53', 'battle_rule_v1:7d208ac6a5625631cd5f858097f64cdd', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_horsemanship_creature_v1","effect":"creature","horsemanship":true,"keywords":["horsemanship"],"static_effect":"self_horsemanship","target":"self","target_controller":"self","xmage_ability_class":"HorsemanshipAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WuLightCavalry translated into ManaLoom runtime scope xmage_static_self_horsemanship_creature_v1. This row is package-ready only because the source signature is a narrow creature static self horsemanship evasion with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
