\pset pager off

SELECT
  'pg025_one_ring_orims_current_rule_state' AS check_name,
  c.id::text AS card_id,
  c.name,
  c.type_line,
  c.cmc,
  c.oracle_text,
  md5(regexp_replace(lower(coalesce(c.oracle_text, '')), '\s+', ' ', 'g')) AS oracle_hash,
  cbr.logical_rule_key,
  cbr.effect_json,
  cbr.deck_role_json,
  cbr.source,
  cbr.confidence,
  cbr.review_status,
  cbr.execution_status
FROM cards c
LEFT JOIN card_battle_rules cbr ON cbr.card_id = c.id
WHERE lower(c.name) IN ('the one ring', 'orim''s chant')
ORDER BY c.name, cbr.source, cbr.review_status, cbr.execution_status, cbr.logical_rule_key;

SELECT
  'pg025_one_ring_orims_precheck_counts' AS check_name,
  (SELECT count(*) FROM cards WHERE lower(name) = 'the one ring') AS one_ring_card_rows,
  (
    SELECT count(*)
    FROM cards
    WHERE lower(name) = 'the one ring'
      AND md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) =
        '31d30901b663f08a6862c5b76f174887'
  ) AS one_ring_expected_oracle_hash_rows,
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
      AND review_status IN ('verified', 'active')
      AND execution_status IN ('auto', 'executable')
  ) AS one_ring_exact_rule_rows,
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
  ) AS one_ring_legacy_draw_engine_rows,
  (SELECT count(*) FROM cards WHERE lower(name) = 'orim''s chant') AS orims_chant_card_rows,
  (
    SELECT count(*)
    FROM cards
    WHERE lower(name) = 'orim''s chant'
      AND md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) =
        '3eea7a9ed9e829743964806f5f56cf75'
  ) AS orims_chant_expected_oracle_hash_rows,
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
      AND review_status IN ('verified', 'active')
      AND execution_status IN ('auto', 'executable')
  ) AS orims_chant_exact_rule_rows,
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
  ) AS orims_chant_legacy_silence_rows;

SELECT
  'pg025_one_ring_orims_snapshot_precheck' AS check_name,
  name,
  function_tags,
  battle_rules
FROM card_intelligence_snapshot
WHERE lower(name) IN ('the one ring', 'orim''s chant')
ORDER BY name;
