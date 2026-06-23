\pset pager off

CREATE TEMP TABLE pg076_target_cards AS
SELECT
  c.id,
  c.name,
  c.type_line,
  c.mana_cost,
  c.cmc,
  md5(coalesce(c.oracle_text, '')) AS oracle_hash,
  c.oracle_text
FROM cards c
WHERE c.name = 'Chaos Warp';

CREATE TEMP TABLE pg076_target_rules AS
SELECT
  c.name,
  cbr.normalized_name,
  cbr.logical_rule_key,
  cbr.source,
  cbr.review_status,
  cbr.execution_status,
  cbr.confidence,
  cbr.rule_version,
  cbr.oracle_hash,
  cbr.effect_json,
  cbr.deck_role_json
FROM card_battle_rules cbr
JOIN cards c ON c.id = cbr.card_id
WHERE c.name = 'Chaos Warp';

SELECT
  count(*) FILTER (
    WHERE name = 'Chaos Warp'
      AND oracle_hash = '7db2bc44526b855fd22302e9569746b5'
  ) AS target_cards_with_expected_oracle_hash,
  (SELECT count(*) FROM pg076_target_rules) AS existing_rule_rows,
  (
    SELECT count(*)
    FROM pg076_target_rules
    WHERE logical_rule_key = 'battle_rule_v1:0b547d7209a38ac2d23a1cca07917680'
  ) AS target_specific_rule_rows,
  (
    SELECT count(*)
    FROM pg076_target_rules
    WHERE review_status IN ('verified', 'active', 'needs_review')
      AND execution_status IN ('auto', 'executable', 'review_only')
      AND logical_rule_key <> 'battle_rule_v1:0b547d7209a38ac2d23a1cca07917680'
  ) AS old_active_shadow_rows,
  (
    SELECT count(*)
    FROM pg076_target_rules
    WHERE normalized_name = 'chaos warp'
      AND logical_rule_key = 'battle_rule_v1:0b547d7209a38ac2d23a1cca07917680'
      AND (
        oracle_hash IS NULL
        OR effect_json->>'effect' <> 'remove_permanent'
        OR effect_json->>'target' IS DISTINCT FROM 'permanent'
        OR effect_json->>'destination' IS DISTINCT FROM 'library'
        OR effect_json->>'battle_model_scope' IS DISTINCT FROM 'target_permanent_shuffle_into_owner_library_reveal_top_permanent_to_battlefield_v1'
      )
  ) AS target_specific_defect_rows,
  to_regclass('manaloom_deploy_audit.pg076_deck6_chaos_warp_runtime_20260623_055230') IS NOT NULL AS backup_table_already_exists
FROM pg076_target_cards;

SELECT
  name,
  type_line,
  mana_cost,
  cmc,
  oracle_hash,
  oracle_text
FROM pg076_target_cards
ORDER BY name;

SELECT
  name,
  normalized_name,
  logical_rule_key,
  source,
  review_status,
  execution_status,
  confidence,
  rule_version,
  oracle_hash,
  effect_json,
  deck_role_json
FROM pg076_target_rules
ORDER BY name, review_status, execution_status, logical_rule_key;
