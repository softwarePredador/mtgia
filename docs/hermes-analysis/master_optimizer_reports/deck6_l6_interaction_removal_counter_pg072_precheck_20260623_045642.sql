\pset pager off

CREATE TEMP TABLE pg072_target_cards AS
SELECT
  c.id,
  c.name,
  c.type_line,
  c.mana_cost,
  c.cmc,
  md5(coalesce(c.oracle_text, '')) AS oracle_hash,
  c.oracle_text
FROM cards c
WHERE c.name IN ('Get Lost', 'Pyroblast');

CREATE TEMP TABLE pg072_target_rules AS
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
WHERE c.name IN ('Get Lost', 'Pyroblast');

SELECT
  count(*) FILTER (
    WHERE (name = 'Get Lost' AND oracle_hash = '6b6517e1b5b60db5cf6bbcd991dbc1ec')
       OR (name = 'Pyroblast' AND oracle_hash = 'ecf9ad1f393a664f16867aab8a6edf77')
  ) AS target_cards_with_expected_oracle_hash,
  (SELECT count(*) FROM pg072_target_rules) AS existing_rule_rows,
  (
    SELECT count(*)
    FROM pg072_target_rules
    WHERE logical_rule_key IN (
      'battle_rule_v1:8e7da3df51386d58c857a596433f73ea',
      'battle_rule_v1:141ff57f44bc4c229393f05f7daf667c'
    )
  ) AS target_specific_rule_rows,
  (
    SELECT count(*)
    FROM pg072_target_rules
    WHERE review_status IN ('verified', 'active', 'needs_review')
      AND execution_status IN ('auto', 'executable', 'review_only')
      AND logical_rule_key NOT IN (
        'battle_rule_v1:8e7da3df51386d58c857a596433f73ea',
        'battle_rule_v1:141ff57f44bc4c229393f05f7daf667c'
      )
  ) AS old_active_shadow_rows,
  (
    SELECT count(*)
    FROM pg072_target_rules
    WHERE (
        normalized_name = 'get lost'
        AND logical_rule_key = 'battle_rule_v1:8e7da3df51386d58c857a596433f73ea'
        AND (
          oracle_hash IS NULL
          OR effect_json->>'effect' <> 'remove_permanent'
          OR effect_json->>'target' IS DISTINCT FROM 'creature_enchantment_or_planeswalker'
          OR effect_json->>'battle_model_scope' IS DISTINCT FROM 'destroy_creature_enchantment_planeswalker_create_two_map_tokens_v1'
        )
      )
      OR (
        normalized_name = 'pyroblast'
        AND logical_rule_key = 'battle_rule_v1:141ff57f44bc4c229393f05f7daf667c'
        AND (
          oracle_hash IS NULL
          OR effect_json->>'effect' <> 'counter'
          OR effect_json->>'requires_blue_target' IS DISTINCT FROM 'true'
          OR effect_json->>'battle_model_scope' IS DISTINCT FROM 'blue_spell_counter_runtime_destroy_blue_permanent_annotation_v1'
        )
      )
  ) AS target_specific_defect_rows,
  to_regclass('manaloom_deploy_audit.pg072_deck6_l6_interaction_removal_counter_20260623_045642') IS NOT NULL AS backup_table_already_exists
FROM pg072_target_cards;

SELECT
  name,
  type_line,
  mana_cost,
  cmc,
  oracle_hash,
  oracle_text
FROM pg072_target_cards
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
FROM pg072_target_rules
ORDER BY name, review_status, execution_status, logical_rule_key;
