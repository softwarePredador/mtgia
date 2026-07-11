WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('cloudblazer', 'Cloudblazer', '0c4c46eee1e928181e5ad49e8ebd06df', 'battle_rule_v1:a2e9e3898e7fb57c8271996957f6345a', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_gain_life_draw_cards_v1","draw_count":2,"effect":"creature","etb_draw_count":2,"etb_life_gain_amount":2,"etb_life_gain_draw":true,"etb_trigger_effect":"life_gain_draw","flying":true,"keywords":["flying"],"life_gain_amount":2,"resolution_order":"gain_then_draw","trigger":"enters_battlefield","trigger_effect":"life_gain_draw","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_classes":["GainLifeEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Cloudblazer translated into ManaLoom runtime scope xmage_creature_etb_gain_life_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('elite guardmage', 'Elite Guardmage', 'ec08795757538f182c192e6b5d89754d', 'battle_rule_v1:6029c2bcb98d10e624308c4171f0c6a5', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_gain_life_draw_cards_v1","draw_count":1,"effect":"creature","etb_draw_count":1,"etb_life_gain_amount":3,"etb_life_gain_draw":true,"etb_trigger_effect":"life_gain_draw","flying":true,"keywords":["flying"],"life_gain_amount":3,"resolution_order":"gain_then_draw","trigger":"enters_battlefield","trigger_effect":"life_gain_draw","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_classes":["GainLifeEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EliteGuardmage translated into ManaLoom runtime scope xmage_creature_etb_gain_life_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('inspiring overseer', 'Inspiring Overseer', 'f439383516b5b053e1620acef32a6636', 'battle_rule_v1:2175e84b8027d2a04b7e0070616cb4bd', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_gain_life_draw_cards_v1","draw_count":1,"effect":"creature","etb_draw_count":1,"etb_life_gain_amount":1,"etb_life_gain_draw":true,"etb_trigger_effect":"life_gain_draw","flying":true,"keywords":["flying"],"life_gain_amount":1,"resolution_order":"gain_then_draw","trigger":"enters_battlefield","trigger_effect":"life_gain_draw","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_classes":["GainLifeEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class InspiringOverseer translated into ManaLoom runtime scope xmage_creature_etb_gain_life_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('priest of ancient lore', 'Priest of Ancient Lore', 'ad803d8b8e94e3d742306497af5eab37', 'battle_rule_v1:9f85f598a9f42c9fa90f7639234aa2aa', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_gain_life_draw_cards_v1","draw_count":1,"effect":"creature","etb_draw_count":1,"etb_life_gain_amount":1,"etb_life_gain_draw":true,"etb_trigger_effect":"life_gain_draw","life_gain_amount":1,"resolution_order":"gain_then_draw","trigger":"enters_battlefield","trigger_effect":"life_gain_draw","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_classes":["GainLifeEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PriestOfAncientLore translated into ManaLoom runtime scope xmage_creature_etb_gain_life_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
