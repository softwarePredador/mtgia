\pset pager off

CREATE TEMP TABLE pg070_target_cards AS
SELECT
  c.id,
  c.name,
  c.type_line,
  c.mana_cost,
  c.cmc,
  md5(coalesce(c.oracle_text, '')) AS oracle_hash,
  c.oracle_text
FROM cards c
WHERE c.name IN ('Faithless Looting', 'Gamble');

CREATE TEMP TABLE pg070_target_rules AS
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
WHERE c.name IN ('Faithless Looting', 'Gamble');

SELECT
  count(*) FILTER (
    WHERE (name = 'Faithless Looting' AND oracle_hash = '2e734d8bae3f331866abf1b030c92781')
       OR (name = 'Gamble' AND oracle_hash = '9b3fc8ab7f664f6c084e0bda0ccf9a7c')
  ) AS target_cards_with_expected_oracle_hash,
  (SELECT count(*) FROM pg070_target_rules) AS existing_rule_rows,
  (
    SELECT count(*)
    FROM pg070_target_rules
    WHERE logical_rule_key IN (
      'battle_rule_v1:554fe811b81e8a284b8a5ca9c6543caa',
      'battle_rule_v1:2861739f22e978549e28d2339288df2a'
    )
  ) AS target_specific_rule_rows,
  (
    SELECT count(*)
    FROM pg070_target_rules
    WHERE review_status IN ('verified', 'active', 'needs_review')
      AND execution_status IN ('auto', 'executable', 'review_only')
      AND logical_rule_key NOT IN (
        'battle_rule_v1:554fe811b81e8a284b8a5ca9c6543caa',
        'battle_rule_v1:2861739f22e978549e28d2339288df2a'
      )
  ) AS old_active_shadow_rows,
  (
    SELECT count(*)
    FROM pg070_target_rules
    WHERE (
        normalized_name = 'faithless looting'
        AND logical_rule_key = 'battle_rule_v1:554fe811b81e8a284b8a5ca9c6543caa'
        AND (
          oracle_hash IS NULL
          OR effect_json->>'effect' <> 'loot'
          OR effect_json->>'battle_model_scope' IS DISTINCT FROM 'draw_two_discard_two_flashback_annotation_v1'
        )
      )
      OR (
        normalized_name = 'gamble'
        AND logical_rule_key = 'battle_rule_v1:2861739f22e978549e28d2339288df2a'
        AND (
          oracle_hash IS NULL
          OR effect_json->>'effect' <> 'tutor'
          OR effect_json->>'battle_model_scope' IS DISTINCT FROM 'any_card_to_hand_then_random_discard_v1'
          OR effect_json->>'discard_after_tutor_random' IS DISTINCT FROM 'true'
        )
      )
  ) AS target_specific_defect_rows,
  to_regclass('manaloom_deploy_audit.pg070_deck6_red_discard_runtime_20260623_042617') IS NOT NULL AS backup_table_already_exists
FROM pg070_target_cards;

SELECT
  name,
  type_line,
  mana_cost,
  cmc,
  oracle_hash,
  oracle_text
FROM pg070_target_cards
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
FROM pg070_target_rules
ORDER BY name, review_status, execution_status, logical_rule_key;
