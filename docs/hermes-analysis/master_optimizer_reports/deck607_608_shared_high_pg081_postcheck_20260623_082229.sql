\pset pager off

WITH expected(normalized_name, logical_rule_key, expected_oracle_hash, expected_scope, expected_effect) AS (
  VALUES
    (
      'artist''s talent',
      'battle_rule_v1:e57aa58c2e76015a0851a6bfef5dca90',
      'd49d9b1a361e7d2b0f9a373cb239b875',
      'class_level1_own_noncreature_spell_optional_discard_draw_level2_level3_annotations_v1',
      'draw_engine'
    ),
    (
      'pinnacle monk // mystic peak',
      'battle_rule_v1:bcde63b5e56f2b9f20af6384bc70ad5d',
      'aa1967461796c715e0c5e0b4d741f249',
      'front_creature_prowess_etb_return_instant_or_sorcery_graveyard_to_hand_back_land_annotation_v1',
      'creature'
    ),
    (
      'redirect lightning',
      'battle_rule_v1:d47b67e18fbd03ed1745f6917901d6c9',
      'f031e271e574af339ecf11d43dbe6a5d',
      'single_target_spell_or_ability_redirect_additional_cost_annotation_v1',
      'redirect_removal'
    )
),
target_rules AS (
  SELECT cbr.*, e.expected_oracle_hash, e.expected_scope, e.expected_effect
  FROM expected e
  JOIN card_battle_rules cbr
    ON cbr.normalized_name = e.normalized_name
   AND cbr.logical_rule_key = e.logical_rule_key
),
shadow_rules AS (
  SELECT cbr.*
  FROM expected e
  JOIN card_battle_rules cbr
    ON cbr.normalized_name = e.normalized_name
   AND cbr.source = 'generated'
),
old_problem_rows AS (
  SELECT *
  FROM card_battle_rules
  WHERE execution_status <> 'disabled'
    AND (
      (normalized_name = 'pinnacle monk // mystic peak' AND effect_json->>'effect' = 'remove_permanent')
      OR (normalized_name = 'redirect lightning' AND effect_json->>'effect' = 'draw_cards')
    )
)
SELECT
  (SELECT count(*) FROM target_rules) AS target_rule_rows,
  (SELECT count(*) FROM target_rules WHERE oracle_hash = expected_oracle_hash) AS target_hash_match_rows,
  (SELECT count(*) FROM target_rules WHERE oracle_hash IS NULL OR oracle_hash = '') AS target_missing_hash_rows,
  (SELECT count(*) FROM target_rules WHERE effect_json->>'battle_model_scope' = expected_scope) AS target_expected_scope_rows,
  (SELECT count(*) FROM target_rules WHERE effect_json->>'effect' = expected_effect) AS target_expected_effect_rows,
  (SELECT count(*) FROM target_rules WHERE source = 'curated' AND review_status = 'verified' AND execution_status = 'auto') AS trusted_auto_rows,
  (SELECT count(*) FROM target_rules WHERE rule_version >= 2) AS rule_version_at_least_2_rows,
  (SELECT count(*) FROM shadow_rules WHERE execution_status <> 'disabled') AS non_disabled_shadow_rows,
  (SELECT count(*) FROM shadow_rules WHERE review_status = 'deprecated' AND execution_status = 'disabled') AS disabled_shadow_rows,
  (SELECT count(*) FROM old_problem_rows) AS old_problem_active_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg081_deck607_608_shared_high_20260623_082229) AS backup_rows;

WITH expected(normalized_name, logical_rule_key, expected_oracle_hash, expected_scope, expected_effect) AS (
  VALUES
    (
      'artist''s talent',
      'battle_rule_v1:e57aa58c2e76015a0851a6bfef5dca90',
      'd49d9b1a361e7d2b0f9a373cb239b875',
      'class_level1_own_noncreature_spell_optional_discard_draw_level2_level3_annotations_v1',
      'draw_engine'
    ),
    (
      'pinnacle monk // mystic peak',
      'battle_rule_v1:bcde63b5e56f2b9f20af6384bc70ad5d',
      'aa1967461796c715e0c5e0b4d741f249',
      'front_creature_prowess_etb_return_instant_or_sorcery_graveyard_to_hand_back_land_annotation_v1',
      'creature'
    ),
    (
      'redirect lightning',
      'battle_rule_v1:d47b67e18fbd03ed1745f6917901d6c9',
      'f031e271e574af339ecf11d43dbe6a5d',
      'single_target_spell_or_ability_redirect_additional_cost_annotation_v1',
      'redirect_removal'
    )
)
SELECT
  cbr.card_name,
  cbr.logical_rule_key,
  cbr.oracle_hash,
  cbr.effect_json->>'effect' AS effect,
  cbr.effect_json->>'battle_model_scope' AS battle_model_scope,
  cbr.effect_json,
  cbr.deck_role_json
FROM card_battle_rules cbr
JOIN expected e
  ON e.normalized_name = cbr.normalized_name
 AND e.logical_rule_key = cbr.logical_rule_key
ORDER BY cbr.card_name;
