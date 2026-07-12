WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('baleful force', 'Baleful Force', 'fb8d47d64fa7e14343b15de060bb255b', 'battle_rule_v1:276930ae70d2d610491bd5eef09ad151', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_upkeep_draw_lose_life_v1","beginning_upkeep_draw_count":1,"beginning_upkeep_life_loss":1,"draw_count":1,"effect":"draw_engine","life_loss":1,"trigger":"each_upkeep","trigger_effect":"draw_lose_life","xmage_ability_class":"BeginningOfUpkeepTriggeredAbility","xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BalefulForce translated into ManaLoom runtime scope xmage_beginning_upkeep_draw_lose_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('phyrexian arena', 'Phyrexian Arena', '8a4151e2039700f749e91bdaab3607e5', 'battle_rule_v1:f479c035a58a4068586f6f5eca51a15d', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_upkeep_draw_lose_life_v1","beginning_upkeep_draw_count":1,"beginning_upkeep_life_loss":1,"draw_count":1,"effect":"draw_engine","life_loss":1,"trigger":"controller_upkeep","trigger_effect":"draw_lose_life","xmage_ability_class":"BeginningOfUpkeepTriggeredAbility","xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PhyrexianArena translated into ManaLoom runtime scope xmage_beginning_upkeep_draw_lose_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
