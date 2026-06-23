\pset pager off

CREATE TEMP TABLE pg071_target_cards AS
SELECT
  c.id,
  c.name,
  c.type_line,
  c.mana_cost,
  c.cmc,
  md5(coalesce(c.oracle_text, '')) AS oracle_hash,
  c.oracle_text
FROM cards c
WHERE c.name IN ('Lotus Petal', 'Ruby Medallion');

CREATE TEMP TABLE pg071_target_rules AS
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
WHERE c.name IN ('Lotus Petal', 'Ruby Medallion');

SELECT
  count(*) FILTER (
    WHERE (name = 'Lotus Petal' AND oracle_hash = 'a5b9069217908acfd75c5704b414b035')
       OR (name = 'Ruby Medallion' AND oracle_hash = '52bc55846d69bacf3afba1ffa734b81e')
  ) AS target_cards_with_expected_oracle_hash,
  (SELECT count(*) FROM pg071_target_rules) AS existing_rule_rows,
  (
    SELECT count(*)
    FROM pg071_target_rules
    WHERE logical_rule_key IN (
      'battle_rule_v1:d3366a0b9063a1af91a75a6398c1962d',
      'battle_rule_v1:bd05ea5e0a5343c1bf8f2284d001471a'
    )
  ) AS target_specific_rule_rows,
  (
    SELECT count(*)
    FROM pg071_target_rules
    WHERE review_status IN ('verified', 'active', 'needs_review')
      AND execution_status IN ('auto', 'executable', 'review_only')
      AND logical_rule_key NOT IN (
        'battle_rule_v1:d3366a0b9063a1af91a75a6398c1962d',
        'battle_rule_v1:bd05ea5e0a5343c1bf8f2284d001471a'
      )
  ) AS old_active_shadow_rows,
  (
    SELECT count(*)
    FROM pg071_target_rules
    WHERE (
        normalized_name = 'lotus petal'
        AND logical_rule_key = 'battle_rule_v1:d3366a0b9063a1af91a75a6398c1962d'
        AND (
          oracle_hash IS NULL
          OR effect_json->>'effect' <> 'ramp_ritual'
          OR effect_json->>'battle_model_scope' IS DISTINCT FROM 'zero_mana_artifact_sacrifice_one_mana_one_shot_runtime_v1'
        )
      )
      OR (
        normalized_name = 'ruby medallion'
        AND logical_rule_key = 'battle_rule_v1:bd05ea5e0a5343c1bf8f2284d001471a'
        AND (
          oracle_hash IS NULL
          OR effect_json->>'effect' <> 'passive'
          OR effect_json->>'battle_model_scope' IS DISTINCT FROM 'red_spell_cost_reduction_annotation_only_v1'
        )
      )
  ) AS target_specific_defect_rows,
  to_regclass('manaloom_deploy_audit.pg071_deck6_l3_fast_mana_cost_reduction_20260623_043623') IS NOT NULL AS backup_table_already_exists
FROM pg071_target_cards;

SELECT
  name,
  type_line,
  mana_cost,
  cmc,
  oracle_hash,
  oracle_text
FROM pg071_target_cards
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
FROM pg071_target_rules
ORDER BY name, review_status, execution_status, logical_rule_key;
