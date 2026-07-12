BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg798_lorehold_active_rule_verification_new_server_20260712 AS
SELECT r.*
FROM public.card_battle_rules r
WHERE (r.normalized_name, r.logical_rule_key) IN (
  ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
  ('library of leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3'),
  ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2'),
  ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470')
);

DO $$
DECLARE
  v_bad jsonb;
BEGIN
  WITH target(card_name, normalized_name, logical_rule_key, expected_effect, expected_scope, expected_oracle_hash) AS (
    VALUES
      ('Fellwar Stone', 'fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'ramp_permanent', 'conditional_opponent_color_mana_rock_v1', 'd63befc8ac40d9a38732f9b5c1a7414a'),
      ('Library of Leng', 'library of leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3', 'passive', 'discard_replacement_to_top_v1', '575aef3cc2523831e440ea7dcd55fa6e'),
      ('Scroll Rack', 'scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2', 'topdeck_manipulation', 'scroll_rack_upkeep_single_exchange_v1', '8133928f03d5a5a77f2beecfcbd09e30'),
      ('Talisman of Conviction', 'talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'ramp_permanent', 'pain_talisman_color_pair_partial_v1', 'd49ceec937367a344a9f0948eea4f8f2')
  ),
  checked AS (
    SELECT
      t.card_name,
      c.id AS card_id,
      md5(coalesce(c.oracle_text, '')) AS current_oracle_hash,
      r.review_status,
      r.execution_status,
      r.effect_json->>'effect' AS current_effect,
      r.effect_json->>'battle_model_scope' AS current_scope
    FROM target t
    LEFT JOIN public.cards c
      ON lower(c.name) = t.normalized_name
    LEFT JOIN public.card_battle_rules r
      ON r.normalized_name = t.normalized_name
     AND r.logical_rule_key = t.logical_rule_key
  )
  SELECT jsonb_agg(checked ORDER BY card_name)
    INTO v_bad
  FROM checked
  JOIN target USING (card_name)
  WHERE card_id IS NULL
     OR current_oracle_hash <> expected_oracle_hash
     OR review_status <> 'active'
     OR execution_status <> 'auto'
     OR current_effect <> expected_effect
     OR current_scope <> expected_scope;

  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'PG798 abort: target rows are not exact active/auto matches: %', v_bad;
  END IF;
END $$;

WITH target(card_name, normalized_name, logical_rule_key, expected_oracle_hash) AS (
  VALUES
    ('Fellwar Stone', 'fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'd63befc8ac40d9a38732f9b5c1a7414a'),
    ('Library of Leng', 'library of leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3', '575aef3cc2523831e440ea7dcd55fa6e'),
    ('Scroll Rack', 'scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2', '8133928f03d5a5a77f2beecfcbd09e30'),
    ('Talisman of Conviction', 'talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'd49ceec937367a344a9f0948eea4f8f2')
),
updated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'verified',
    oracle_hash = t.expected_oracle_hash,
    reviewed_by = 'codex-pg798-active-rule-verification',
    reviewed_at = now(),
    updated_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'PG798: promoted from active/auto to verified/auto after focused Lorehold priority runtime proof and current Oracle hash check.')
  FROM target t
  WHERE r.normalized_name = t.normalized_name
    AND r.logical_rule_key = t.logical_rule_key
    AND r.review_status = 'active'
    AND r.execution_status = 'auto'
  RETURNING r.normalized_name, r.logical_rule_key
)
SELECT count(*) AS promoted_rows FROM updated;

COMMIT;
