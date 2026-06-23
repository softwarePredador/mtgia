\pset pager off

WITH expected(normalized_name, old_logical_rule_key, new_logical_rule_key, expected_oracle_hash, expected_scope, expected_effect) AS (
  VALUES
    (
      'artist''s talent',
      'battle_rule_v1:1a21b06bc25fe4cc34352b3dcb8d3903',
      'battle_rule_v1:e57aa58c2e76015a0851a6bfef5dca90',
      'd49d9b1a361e7d2b0f9a373cb239b875',
      'class_level1_own_noncreature_spell_optional_discard_draw_level2_level3_annotations_v1',
      'draw_engine'
    ),
    (
      'pinnacle monk // mystic peak',
      'battle_rule_v1:720ffd7f16297a705ae4352b033b186e',
      'battle_rule_v1:bcde63b5e56f2b9f20af6384bc70ad5d',
      'aa1967461796c715e0c5e0b4d741f249',
      'front_creature_prowess_etb_return_instant_or_sorcery_graveyard_to_hand_back_land_annotation_v1',
      'creature'
    ),
    (
      'redirect lightning',
      'battle_rule_v1:fb9b2b633a4842d42599c293e0de4d68',
      'battle_rule_v1:d47b67e18fbd03ed1745f6917901d6c9',
      'f031e271e574af339ecf11d43dbe6a5d',
      'single_target_spell_or_ability_redirect_additional_cost_annotation_v1',
      'redirect_removal'
    )
),
old_targets AS (
  SELECT cbr.*, e.new_logical_rule_key, e.expected_oracle_hash, e.expected_scope, e.expected_effect
  FROM expected e
  JOIN card_battle_rules cbr
    ON cbr.normalized_name = e.normalized_name
   AND cbr.logical_rule_key = e.old_logical_rule_key
),
new_key_conflicts AS (
  SELECT cbr.*
  FROM expected e
  JOIN card_battle_rules cbr
    ON cbr.normalized_name = e.normalized_name
   AND cbr.logical_rule_key = e.new_logical_rule_key
),
shadows AS (
  SELECT cbr.*
  FROM expected e
  JOIN card_battle_rules cbr
    ON cbr.normalized_name = e.normalized_name
   AND cbr.source = 'generated'
)
SELECT
  (SELECT count(*) FROM old_targets) AS old_target_rows,
  (SELECT count(*) FROM old_targets WHERE source = 'curated' AND review_status = 'verified' AND execution_status = 'auto') AS old_trusted_auto_rows,
  (SELECT count(*) FROM old_targets WHERE oracle_hash IS NULL OR oracle_hash = '') AS old_missing_hash_rows,
  (SELECT count(*) FROM new_key_conflicts) AS new_key_conflict_rows,
  (SELECT count(*) FROM shadows) AS generated_shadow_rows,
  (SELECT count(*) FROM shadows WHERE execution_status <> 'disabled') AS non_disabled_shadow_rows,
  (SELECT count(*) FROM cards WHERE lower(name) IN (SELECT normalized_name FROM expected)) AS cards_resolved_rows;

WITH expected(normalized_name, old_logical_rule_key, new_logical_rule_key, expected_oracle_hash, expected_scope, expected_effect) AS (
  VALUES
    (
      'artist''s talent',
      'battle_rule_v1:1a21b06bc25fe4cc34352b3dcb8d3903',
      'battle_rule_v1:e57aa58c2e76015a0851a6bfef5dca90',
      'd49d9b1a361e7d2b0f9a373cb239b875',
      'class_level1_own_noncreature_spell_optional_discard_draw_level2_level3_annotations_v1',
      'draw_engine'
    ),
    (
      'pinnacle monk // mystic peak',
      'battle_rule_v1:720ffd7f16297a705ae4352b033b186e',
      'battle_rule_v1:bcde63b5e56f2b9f20af6384bc70ad5d',
      'aa1967461796c715e0c5e0b4d741f249',
      'front_creature_prowess_etb_return_instant_or_sorcery_graveyard_to_hand_back_land_annotation_v1',
      'creature'
    ),
    (
      'redirect lightning',
      'battle_rule_v1:fb9b2b633a4842d42599c293e0de4d68',
      'battle_rule_v1:d47b67e18fbd03ed1745f6917901d6c9',
      'f031e271e574af339ecf11d43dbe6a5d',
      'single_target_spell_or_ability_redirect_additional_cost_annotation_v1',
      'redirect_removal'
    )
)
SELECT
  c.name,
  c.type_line,
  c.mana_cost,
  md5(coalesce(c.oracle_text, '')) AS current_oracle_hash,
  e.expected_oracle_hash,
  cbr.logical_rule_key AS old_logical_rule_key,
  cbr.effect_json->>'effect' AS old_effect,
  cbr.effect_json AS old_effect_json,
  cbr.deck_role_json AS old_deck_role_json
FROM expected e
JOIN card_battle_rules cbr
  ON cbr.normalized_name = e.normalized_name
 AND cbr.logical_rule_key = e.old_logical_rule_key
JOIN cards c
  ON c.id = cbr.card_id
ORDER BY c.name;
