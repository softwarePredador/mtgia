WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('academy raider', 'Academy Raider', '3e46e09ecb55365da7e4dd2e732481fe', 'battle_rule_v1:a4d063281c448f4bec8585f7e7dcb67b', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_combat_damage_draw_cards_v1","combat_damage_draw_count":1,"combat_damage_draw_optional":true,"combat_damage_draw_optional_cost":"discard_card","combat_damage_draw_optional_cost_count":1,"combat_damage_player_draw":true,"draw_count":1,"effect":"creature","intimidate":true,"keywords":["intimidate"],"trigger":"combat_damage_to_player","trigger_effect":"draw_cards","xmage_ability_class":"DealsCombatDamageToAPlayerTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AcademyRaider translated into ManaLoom runtime scope xmage_creature_combat_damage_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature combat-damage-to-player triggered fixed draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('impaler shrike', 'Impaler Shrike', '6156a6fef3833f7cf07af940eb2d4444', 'battle_rule_v1:8af13cd3416861af948a408a70633ecf', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_combat_damage_draw_cards_v1","combat_damage_draw_count":3,"combat_damage_draw_optional":true,"combat_damage_draw_optional_cost":"sacrifice_source","combat_damage_draw_optional_cost_count":1,"combat_damage_player_draw":true,"draw_count":3,"effect":"creature","flying":true,"keywords":["flying"],"trigger":"combat_damage_to_player","trigger_effect":"draw_cards","xmage_ability_class":"DealsCombatDamageToAPlayerTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ImpalerShrike translated into ManaLoom runtime scope xmage_creature_combat_damage_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature combat-damage-to-player triggered fixed draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
