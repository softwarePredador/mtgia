BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg624_priority_lorehold_trusted_status_20260707_backup;

CREATE TABLE manaloom_deploy_audit.pg624_priority_lorehold_trusted_status_20260707_backup AS
SELECT *
FROM public.card_battle_rules
WHERE (normalized_name, logical_rule_key) IN (
  ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
  ('library of leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3'),
  ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2'),
  ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470')
);

DO $$
DECLARE
  v_bad jsonb;
  v_count integer;
BEGIN
  WITH target(normalized_name, logical_rule_key, battle_model_scope) AS (
    VALUES
      ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'conditional_opponent_color_mana_rock_v1'),
      ('library of leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3', 'discard_replacement_to_top_v1'),
      ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2', 'scroll_rack_upkeep_single_exchange_v1'),
      ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'pain_talisman_color_pair_partial_v1')
  ),
  joined AS (
    SELECT
      target.normalized_name,
      target.logical_rule_key,
      target.battle_model_scope AS expected_scope,
      rule.card_name,
      rule.review_status,
      rule.execution_status,
      rule.oracle_hash,
      rule.effect_json->>'battle_model_scope' AS actual_scope,
      md5(COALESCE(card.oracle_text, '')) AS card_oracle_hash
    FROM target
    LEFT JOIN public.card_battle_rules rule
      ON rule.normalized_name = target.normalized_name
     AND rule.logical_rule_key = target.logical_rule_key
    LEFT JOIN public.cards card
      ON card.id = rule.card_id
  )
  SELECT jsonb_agg(to_jsonb(joined) ORDER BY normalized_name)
    INTO v_bad
  FROM joined
  WHERE card_name IS NULL
     OR review_status <> 'active'
     OR execution_status <> 'auto'
     OR actual_scope <> expected_scope
     OR oracle_hash IS DISTINCT FROM card_oracle_hash;

  SELECT count(*)
    INTO v_count
  FROM manaloom_deploy_audit.pg624_priority_lorehold_trusted_status_20260707_backup;

  IF v_count <> 4 THEN
    RAISE EXCEPTION 'PG624 abort: expected 4 backup rows, found %', v_count;
  END IF;

  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'PG624 abort: pre-update rule drift: %', v_bad;
  END IF;
END $$;

WITH target(normalized_name, logical_rule_key) AS (
  VALUES
    ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
    ('library of leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3'),
    ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2'),
    ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470')
),
updated AS (
  UPDATE public.card_battle_rules rule
  SET
    review_status = 'verified',
    reviewed_by = 'codex_pg624_priority_lorehold_trusted_status_2026_07_07',
    reviewed_at = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP,
    last_seen_at = CURRENT_TIMESTAMP,
    notes = CASE
      WHEN COALESCE(rule.notes, '') LIKE '%PG624 2026-07-07%'
        THEN rule.notes
      ELSE concat_ws(
        E'\n',
        NULLIF(rule.notes, ''),
        'PG624 2026-07-07: promoted active/auto trusted Lorehold priority rule to verified after focused runtime evidence in test_priority_lorehold_card_runtime.py (12/12).'
      )
    END
  FROM target
  WHERE rule.normalized_name = target.normalized_name
    AND rule.logical_rule_key = target.logical_rule_key
  RETURNING rule.normalized_name, rule.logical_rule_key, rule.review_status, rule.execution_status
)
SELECT
  count(*) AS updated_rows,
  count(*) FILTER (WHERE review_status = 'verified' AND execution_status = 'auto') AS verified_auto_rows
FROM updated;

DO $$
DECLARE
  v_bad jsonb;
BEGIN
  WITH target(normalized_name, logical_rule_key, battle_model_scope) AS (
    VALUES
      ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'conditional_opponent_color_mana_rock_v1'),
      ('library of leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3', 'discard_replacement_to_top_v1'),
      ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2', 'scroll_rack_upkeep_single_exchange_v1'),
      ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'pain_talisman_color_pair_partial_v1')
  ),
  joined AS (
    SELECT
      target.normalized_name,
      target.logical_rule_key,
      target.battle_model_scope AS expected_scope,
      rule.card_name,
      rule.review_status,
      rule.execution_status,
      rule.oracle_hash,
      rule.effect_json->>'battle_model_scope' AS actual_scope,
      md5(COALESCE(card.oracle_text, '')) AS card_oracle_hash
    FROM target
    LEFT JOIN public.card_battle_rules rule
      ON rule.normalized_name = target.normalized_name
     AND rule.logical_rule_key = target.logical_rule_key
    LEFT JOIN public.cards card
      ON card.id = rule.card_id
  )
  SELECT jsonb_agg(to_jsonb(joined) ORDER BY normalized_name)
    INTO v_bad
  FROM joined
  WHERE review_status <> 'verified'
     OR execution_status <> 'auto'
     OR actual_scope <> expected_scope
     OR oracle_hash IS DISTINCT FROM card_oracle_hash;

  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'PG624 abort: post-update verification failed: %', v_bad;
  END IF;
END $$;

COMMIT;
