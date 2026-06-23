\pset pager off

CREATE TEMP TABLE pg079_deck606_high_targets(
  normalized_name text,
  logical_rule_key text,
  expected_oracle_hash text,
  expected_scope text
);

INSERT INTO pg079_deck606_high_targets(normalized_name, logical_rule_key, expected_oracle_hash, expected_scope)
VALUES
  ('flare of duplication', 'battle_rule_v1:b82bbb548dab138fa0700cb4cf905617', '3b1f1bcd5e69cb1f5f306e83345b2a1f', 'copy_target_instant_or_sorcery_stack_spell_alt_cost_annotation_v1'),
  ('powerbalance', 'battle_rule_v1:e35051e9c60b94a84ac9b71c11c7fc4b', '8cbde54a4e2e1464a5deb5171928e203', 'opponent_spell_reveal_top_same_mana_value_free_cast_v1'),
  ('reforge the soul', 'battle_rule_v1:90b82cfc81ff726ac0fc96a1b220f263', '041645992d04029f74855292bb1459f4', 'each_player_discard_hand_draw_seven_miracle_annotation_v1'),
  ('rise of the eldrazi', 'battle_rule_v1:57d155e410ca3cc6a96e14ed50f524d4', '6cad51822d2ad0e019c29770033c7d21', 'uncounterable_destroy_target_permanent_target_player_draw_four_extra_turn_exile_v1'),
  ('rite of the dragoncaller', 'battle_rule_v1:b23bca3229a81d65750cf9c453c7943d', '9308f0eadf924f7ea0c8ea2463224c9a', 'instant_sorcery_cast_create_5_5_flying_dragon_v1'),
  ('storm herd', 'battle_rule_v1:b041641dc875caa7987253389dc52839', '25e798eec6b64f1ae52d3af1ca8597dd', 'life_total_flying_pegasus_token_maker_v1'),
  ('witch enchanter // witch-blessed meadow', 'battle_rule_v1:5768b971f1ab4f2d4d9b8bd6a768c132', 'cd5355a1a3cd44df9237726d9e3006c5', 'creature_etb_destroy_opponent_artifact_or_enchantment_v1');

WITH target_rows AS (
  SELECT
    t.normalized_name,
    t.logical_rule_key,
    t.expected_oracle_hash,
    t.expected_scope,
    c.name,
    c.type_line,
    c.mana_cost,
    c.cmc,
    md5(coalesce(c.oracle_text, '')) AS current_oracle_hash,
    cbr.source,
    cbr.review_status,
    cbr.execution_status,
    cbr.oracle_hash,
    cbr.rule_version,
    cbr.effect_json,
    cbr.deck_role_json
  FROM pg079_deck606_high_targets t
  LEFT JOIN card_battle_rules cbr
    ON cbr.normalized_name = t.normalized_name
   AND cbr.logical_rule_key = t.logical_rule_key
  LEFT JOIN cards c
    ON c.id = cbr.card_id
),
shadow_rows AS (
  SELECT
    count(*) FILTER (WHERE cbr.execution_status <> 'disabled') AS non_disabled_shadow_rows,
    count(*) FILTER (WHERE cbr.review_status = 'needs_review' OR cbr.execution_status = 'review_only') AS review_shadow_rows
  FROM card_battle_rules cbr
  WHERE cbr.normalized_name IN (SELECT normalized_name FROM pg079_deck606_high_targets)
    AND NOT EXISTS (
      SELECT 1
      FROM pg079_deck606_high_targets t
      WHERE t.normalized_name = cbr.normalized_name
        AND t.logical_rule_key = cbr.logical_rule_key
    )
)
SELECT
  (SELECT count(*) FROM pg079_deck606_high_targets) AS expected_target_rules,
  count(*) FILTER (WHERE logical_rule_key IS NOT NULL) AS target_rule_rows,
  count(*) FILTER (WHERE source = 'curated' AND review_status IN ('active', 'verified') AND execution_status = 'auto') AS trusted_auto_rows,
  count(*) FILTER (WHERE current_oracle_hash = expected_oracle_hash) AS oracle_hash_precondition_rows,
  count(*) FILTER (WHERE oracle_hash IS NULL) AS target_missing_hash_rows,
  count(*) FILTER (WHERE oracle_hash = expected_oracle_hash) AS target_hash_match_rows,
  count(*) FILTER (WHERE effect_json->>'battle_model_scope' = expected_scope) AS target_expected_scope_rows,
  (SELECT non_disabled_shadow_rows FROM shadow_rows) AS non_disabled_shadow_rows,
  (SELECT review_shadow_rows FROM shadow_rows) AS review_shadow_rows,
  to_regclass('manaloom_deploy_audit.pg079_deck606_high_battle_critical_20260623_074912') IS NOT NULL AS backup_table_already_exists
FROM target_rows;

SELECT
  c.name,
  c.type_line,
  replace(coalesce(c.oracle_text, ''), E'\n', ' <NL> ') AS oracle_text,
  cbr.logical_rule_key,
  cbr.review_status,
  cbr.execution_status,
  cbr.oracle_hash,
  md5(coalesce(c.oracle_text, '')) AS expected_oracle_hash,
  cbr.effect_json,
  cbr.deck_role_json
FROM pg079_deck606_high_targets t
JOIN card_battle_rules cbr
  ON cbr.normalized_name = t.normalized_name
 AND cbr.logical_rule_key = t.logical_rule_key
JOIN cards c
  ON c.id = cbr.card_id
ORDER BY c.name;
