\pset pager off

CREATE TEMP TABLE pg077_target_cards AS
SELECT
  c.id,
  c.name,
  c.type_line,
  c.mana_cost,
  c.cmc,
  md5(coalesce(c.oracle_text, '')) AS oracle_hash,
  c.oracle_text
FROM cards c
WHERE c.name IN ('Jeska''s Will', 'Mizzix''s Mastery');

CREATE TEMP TABLE pg077_target_rules AS
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
WHERE c.name IN ('Jeska''s Will', 'Mizzix''s Mastery');

SELECT
  count(*) FILTER (
    WHERE (name = 'Jeska''s Will' AND oracle_hash = 'e323893e6c38ee2d618b4f9c737fadee')
       OR (name = 'Mizzix''s Mastery' AND oracle_hash = '8b822f0c58e4ab4e91f9e4946e8c04e9')
  ) AS target_cards_with_expected_oracle_hash,
  (SELECT count(*) FROM pg077_target_rules) AS existing_rule_rows,
  (
    SELECT count(*)
    FROM pg077_target_rules
    WHERE logical_rule_key IN (
      'battle_rule_v1:c8621a807cc65adc820a8b8189979f70',
      'battle_rule_v1:e44a8b8d0e4f8fc8e8a5ebd93a73194f'
    )
  ) AS target_specific_rule_rows,
  (
    SELECT count(*)
    FROM pg077_target_rules
    WHERE review_status IN ('verified', 'active', 'needs_review')
      AND execution_status IN ('auto', 'executable', 'review_only')
      AND logical_rule_key NOT IN (
        'battle_rule_v1:c8621a807cc65adc820a8b8189979f70',
        'battle_rule_v1:e44a8b8d0e4f8fc8e8a5ebd93a73194f'
      )
  ) AS old_active_shadow_rows,
  (
    SELECT count(*)
    FROM pg077_target_rules
    WHERE (
        normalized_name = 'jeska''s will'
        AND logical_rule_key = 'battle_rule_v1:c8621a807cc65adc820a8b8189979f70'
        AND (
          oracle_hash IS NULL
          OR effect_json->>'effect' <> 'ramp_ritual'
          OR effect_json->>'mana_produced_from_target_opponent_hand_size' IS DISTINCT FROM 'true'
          OR effect_json->>'impulse_exile_top_count' IS DISTINCT FROM '3'
          OR effect_json->>'battle_model_scope' IS DISTINCT FROM 'choose_both_with_commander_red_by_target_opponent_hand_impulse_top_three_v1'
        )
      )
      OR (
        normalized_name = 'mizzix''s mastery'
        AND logical_rule_key = 'battle_rule_v1:e44a8b8d0e4f8fc8e8a5ebd93a73194f'
        AND (
          oracle_hash IS NULL
          OR effect_json->>'effect' <> 'overload_recursion'
          OR effect_json->>'target' IS DISTINCT FROM 'instant_or_sorcery_graveyard'
          OR effect_json->>'casts_copies_without_paying_mana' IS DISTINCT FROM 'true'
          OR effect_json->>'exiles_self' IS DISTINCT FROM 'true'
          OR effect_json->>'battle_model_scope' IS DISTINCT FROM 'target_or_overload_graveyard_instant_sorcery_copy_cast_runtime_v1'
        )
      )
  ) AS target_specific_defect_rows,
  to_regclass('manaloom_deploy_audit.pg077_deck6_l4_battle_support_20260623_061411') IS NOT NULL AS backup_table_already_exists
FROM pg077_target_cards;

SELECT
  name,
  type_line,
  mana_cost,
  cmc,
  oracle_hash,
  oracle_text
FROM pg077_target_cards
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
FROM pg077_target_rules
ORDER BY name, review_status, execution_status, logical_rule_key;
