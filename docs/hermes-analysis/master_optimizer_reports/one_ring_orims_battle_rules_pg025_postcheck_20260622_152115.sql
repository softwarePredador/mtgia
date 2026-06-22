\pset pager off

SELECT
  'pg025_one_ring_orims_postcheck_counts' AS check_name,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'the one ring'
      AND logical_rule_key = 'battle_rule_v1:a71907ee296b5801e92e8d7f1940dba1'
      AND effect_json->>'effect' = 'draw_engine'
      AND effect_json->>'burden' = 'true'
      AND effect_json->>'draw_on_enter' = 'false'
      AND effect_json->>'protection_from_everything_on_enter' = 'true'
      AND effect_json->>'activated_burden_draw' = 'true'
      AND effect_json->>'activation_requires_tap' = 'true'
      AND review_status = 'verified'
      AND execution_status = 'auto'
      AND source = 'curated'
  ) AS one_ring_exact_executable_rule_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'the one ring'
      AND logical_rule_key <> 'battle_rule_v1:a71907ee296b5801e92e8d7f1940dba1'
      AND effect_json->>'effect' = 'draw_engine'
      AND (
        NOT (effect_json ? 'draw_on_enter')
        OR NOT (effect_json ? 'protection_from_everything_on_enter')
        OR NOT (effect_json ? 'activated_burden_draw')
      )
      AND execution_status IN ('auto', 'executable', 'review_only')
  ) AS one_ring_legacy_enabled_draw_engine_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'orim''s chant'
      AND logical_rule_key = 'battle_rule_v1:2332a82b6395a065b6516702d3e326c7'
      AND effect_json->>'effect' = 'silence_spell'
      AND effect_json->>'instant' = 'true'
      AND effect_json->>'kicker_prevent_attacks' = 'true'
      AND effect_json->>'prevent_attacks_if_kicked' = 'true'
      AND effect_json->>'kicker_cost' = '{W}'
      AND review_status = 'verified'
      AND execution_status = 'auto'
      AND source = 'curated'
  ) AS orims_chant_exact_executable_rule_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'orim''s chant'
      AND logical_rule_key <> 'battle_rule_v1:2332a82b6395a065b6516702d3e326c7'
      AND effect_json->>'effect' IN ('silence_spell', 'silence_opponents')
      AND (
        NOT (effect_json ? 'kicker_prevent_attacks')
        OR NOT (effect_json ? 'prevent_attacks_if_kicked')
      )
      AND execution_status IN ('auto', 'executable', 'review_only')
  ) AS orims_chant_legacy_enabled_silence_rows;

SELECT
  'pg025_one_ring_orims_rule_postcheck' AS check_name,
  card_name,
  logical_rule_key,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  execution_status,
  oracle_hash,
  reviewed_by,
  reviewed_at
FROM card_battle_rules
WHERE normalized_name IN ('the one ring', 'orim''s chant')
ORDER BY card_name, source, review_status, execution_status, logical_rule_key;

SELECT
  'pg025_one_ring_orims_snapshot_postcheck' AS check_name,
  name,
  function_tags,
  battle_rules
FROM card_intelligence_snapshot
WHERE lower(name) IN ('the one ring', 'orim''s chant')
ORDER BY name;
