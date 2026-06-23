\pset pager off

CREATE TEMP TABLE pg073_target_cards AS
SELECT
  c.id,
  c.name,
  c.type_line,
  c.mana_cost,
  c.cmc,
  md5(coalesce(c.oracle_text, '')) AS oracle_hash,
  c.oracle_text
FROM cards c
WHERE c.name IN ('Esper Sentinel', 'Wheel of Misfortune');

CREATE TEMP TABLE pg073_target_rules AS
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
WHERE c.name IN ('Esper Sentinel', 'Wheel of Misfortune');

SELECT
  count(*) FILTER (
    WHERE (name = 'Esper Sentinel' AND oracle_hash = 'd8e8e60e34140942af13aa1be250a961')
       OR (name = 'Wheel of Misfortune' AND oracle_hash = 'fa744c33b4bc56c05977ec9c378e5b7d')
  ) AS target_cards_with_expected_oracle_hash,
  (SELECT count(*) FROM pg073_target_rules) AS existing_rule_rows,
  (
    SELECT count(*)
    FROM pg073_target_rules
    WHERE logical_rule_key IN (
      'battle_rule_v1:83dbd32fed8c770f977cd7b1fcd2883d',
      'battle_rule_v1:402155f35799993b812ca441586017cd'
    )
  ) AS target_specific_rule_rows,
  (
    SELECT count(*)
    FROM pg073_target_rules
    WHERE review_status IN ('verified', 'active', 'needs_review')
      AND execution_status IN ('auto', 'executable', 'review_only')
      AND logical_rule_key NOT IN (
        'battle_rule_v1:83dbd32fed8c770f977cd7b1fcd2883d',
        'battle_rule_v1:402155f35799993b812ca441586017cd'
      )
  ) AS old_active_shadow_rows,
  (
    SELECT count(*)
    FROM pg073_target_rules
    WHERE (
        normalized_name = 'esper sentinel'
        AND logical_rule_key = 'battle_rule_v1:83dbd32fed8c770f977cd7b1fcd2883d'
        AND (
          oracle_hash IS NULL
          OR effect_json->>'effect' <> 'draw_engine'
          OR effect_json->>'trigger' IS DISTINCT FROM 'opponent_noncreature_spell'
          OR effect_json->>'opponent_first_noncreature_spell_each_turn' IS DISTINCT FROM 'true'
          OR effect_json->>'battle_model_scope' IS DISTINCT FROM 'first_opponent_noncreature_spell_power_tax_draw_v1'
        )
      )
      OR (
        normalized_name = 'wheel of misfortune'
        AND logical_rule_key = 'battle_rule_v1:402155f35799993b812ca441586017cd'
        AND (
          oracle_hash IS NULL
          OR effect_json->>'effect' <> 'draw_cards'
          OR effect_json->>'wheel_like' IS DISTINCT FROM 'true'
          OR effect_json->>'misfortune_secret_number_model' IS DISTINCT FROM 'true'
          OR effect_json->>'battle_model_scope' IS DISTINCT FROM 'wheel_of_misfortune_secret_number_damage_discard_draw_compact_v1'
        )
      )
  ) AS target_specific_defect_rows,
  to_regclass('manaloom_deploy_audit.pg073_deck6_l4_card_flow_20260623_051141') IS NOT NULL AS backup_table_already_exists
FROM pg073_target_cards;

SELECT
  name,
  type_line,
  mana_cost,
  cmc,
  oracle_hash,
  oracle_text
FROM pg073_target_cards
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
FROM pg073_target_rules
ORDER BY name, review_status, execution_status, logical_rule_key;
