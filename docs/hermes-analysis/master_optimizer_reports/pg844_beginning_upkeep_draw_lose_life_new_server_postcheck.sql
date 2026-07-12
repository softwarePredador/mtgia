WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('baleful force', 'Baleful Force', 'fb8d47d64fa7e14343b15de060bb255b', 'battle_rule_v1:276930ae70d2d610491bd5eef09ad151', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_upkeep_draw_lose_life_v1","beginning_upkeep_draw_count":1,"beginning_upkeep_life_loss":1,"draw_count":1,"effect":"draw_engine","life_loss":1,"trigger":"each_upkeep","trigger_effect":"draw_lose_life","xmage_ability_class":"BeginningOfUpkeepTriggeredAbility","xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BalefulForce translated into ManaLoom runtime scope xmage_beginning_upkeep_draw_lose_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('phyrexian arena', 'Phyrexian Arena', '8a4151e2039700f749e91bdaab3607e5', 'battle_rule_v1:f479c035a58a4068586f6f5eca51a15d', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_upkeep_draw_lose_life_v1","beginning_upkeep_draw_count":1,"beginning_upkeep_life_loss":1,"draw_count":1,"effect":"draw_engine","life_loss":1,"trigger":"controller_upkeep","trigger_effect":"draw_lose_life","xmage_ability_class":"BeginningOfUpkeepTriggeredAbility","xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PhyrexianArena translated into ManaLoom runtime scope xmage_beginning_upkeep_draw_lose_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
rule_rows AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash,
    r.review_status,
    r.execution_status
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
)
SELECT
  p.card_name,
  p.normalized_name,
  p.logical_rule_key,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS promoted_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS promoted_verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg844_beginning_upkeep_draw_lose_life_ne_20260712_205128) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
