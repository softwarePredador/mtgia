CREATE TEMP TABLE pg087_deck606_remaining_semantic_expected AS
SELECT *
FROM (VALUES
  ('hexing squelcher', 'battle_rule_v1:c6587e309bfd402ee1b98b4848abc6d3', 'ed00818e6ca804b7d1a3ef47c29277ea', 'creature', 'creature_body_uncounterable_ward_static_counter_protection_annotations_v1'),
  ('ragavan, nimble pilferer', 'battle_rule_v1:3e0569d6bae4ed8b6e6e4289ea75084e', 'e337b9515b6984af8a1572db48f47eec', 'creature', 'creature_body_haste_combat_damage_treasure_impulse_dash_annotations_v1'),
  ('skyclave apparition', 'battle_rule_v1:4f29c7a4bbe21a160f28452406153846', '4d0c162906712b2c428b754ad2f0b3a0', 'creature', 'creature_etb_exile_nonland_nontoken_mv_lte4_leave_illusion_annotation_v1'),
  ('underworld breach', 'battle_rule_v1:3f9f5259b05245670ee19b357aa2e999', 'a98ca5777789e48c44daff97999f2beb', 'passive', 'escape_grant_nonland_graveyard_end_step_sacrifice_annotation_v1')
) AS t(normalized_name, expected_logical_rule_key, expected_oracle_hash, expected_effect, expected_scope);

CREATE TEMP TABLE pg087_deck606_remaining_semantic_target_rules AS
SELECT c.name, cbr.*, e.expected_oracle_hash, e.expected_effect, e.expected_scope
FROM pg087_deck606_remaining_semantic_expected e
JOIN cards c ON lower(c.name) = e.normalized_name
JOIN card_battle_rules cbr
  ON cbr.card_id = c.id
 AND cbr.logical_rule_key = e.expected_logical_rule_key;

CREATE TEMP TABLE pg087_deck606_remaining_semantic_target_cards AS
SELECT c.id
FROM pg087_deck606_remaining_semantic_expected e
JOIN cards c ON lower(c.name) = e.normalized_name;

WITH
non_disabled_shadow_rows AS (
  SELECT r.*
  FROM card_battle_rules r
  JOIN pg087_deck606_remaining_semantic_target_cards c ON c.id = r.card_id
  WHERE r.logical_rule_key NOT IN (
    SELECT expected_logical_rule_key FROM pg087_deck606_remaining_semantic_expected
  )
    AND (
      r.source = 'generated'
      OR r.review_status IN ('needs_review', 'review_only')
      OR r.execution_status = 'review_only'
    )
    AND r.execution_status IS DISTINCT FROM 'disabled'
),
disabled_shadow_rows AS (
  SELECT r.*
  FROM card_battle_rules r
  JOIN pg087_deck606_remaining_semantic_target_cards c ON c.id = r.card_id
  WHERE r.logical_rule_key NOT IN (
    SELECT expected_logical_rule_key FROM pg087_deck606_remaining_semantic_expected
  )
    AND r.execution_status = 'disabled'
)
SELECT
  (SELECT count(*) FROM pg087_deck606_remaining_semantic_expected) AS expected_target_rules,
  (SELECT count(*) FROM pg087_deck606_remaining_semantic_target_rules) AS target_rule_rows,
  (SELECT count(*) FROM pg087_deck606_remaining_semantic_target_rules WHERE oracle_hash = expected_oracle_hash) AS target_hash_match_rows,
  (SELECT count(*) FROM pg087_deck606_remaining_semantic_target_rules WHERE nullif(oracle_hash, '') IS NULL) AS target_missing_hash_rows,
  (SELECT count(*) FROM pg087_deck606_remaining_semantic_target_rules WHERE effect_json->>'effect' = expected_effect) AS target_expected_effect_rows,
  (SELECT count(*) FROM pg087_deck606_remaining_semantic_target_rules WHERE effect_json->>'battle_model_scope' = expected_scope) AS target_expected_scope_rows,
  (SELECT count(*) FROM pg087_deck606_remaining_semantic_target_rules WHERE review_status = 'verified' AND execution_status = 'auto') AS trusted_auto_rows,
  (SELECT count(*) FROM pg087_deck606_remaining_semantic_target_rules WHERE coalesce(rule_version, 0) >= 2) AS rule_version_at_least_2_rows,
  (SELECT count(*) FROM non_disabled_shadow_rows) AS non_disabled_shadow_rows,
  (SELECT count(*) FROM disabled_shadow_rows) AS disabled_shadow_rows,
  (SELECT count(*) FROM pg087_deck606_remaining_semantic_target_rules WHERE name = 'Hexing Squelcher' AND effect_json->>'spells_you_control_cant_be_countered_status' = 'runtime_counter_target_filter') AS hexing_counter_filter_rows,
  (SELECT count(*) FROM pg087_deck606_remaining_semantic_target_rules WHERE name = 'Skyclave Apparition' AND effect_json->>'target_mana_value_max' = '4' AND effect_json->>'target_nontoken' = 'true' AND effect_json->>'exile_target' = 'true') AS skyclave_target_filter_rows,
  (SELECT count(*) FROM pg087_deck606_remaining_semantic_target_rules WHERE name = 'Underworld Breach' AND effect_json->>'escape_grant_status' = 'annotation_only') AS underworld_escape_annotation_rows,
  (SELECT count(*) FROM pg087_deck606_remaining_semantic_target_rules WHERE name = 'Ragavan, Nimble Pilferer' AND effect_json->>'dash_status' = 'annotation_only') AS ragavan_dash_annotation_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg087_deck606_remaining_semantic_20260623_085349) AS backup_rows;

SELECT
  name,
  logical_rule_key,
  oracle_hash,
  effect_json->>'effect' AS effect,
  effect_json->>'battle_model_scope' AS battle_model_scope,
  effect_json->>'oracle_runtime_scope' AS oracle_runtime_scope,
  review_status,
  execution_status,
  rule_version,
  effect_json,
  deck_role_json
FROM pg087_deck606_remaining_semantic_target_rules
ORDER BY name;
