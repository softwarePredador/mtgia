BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg116_big_score_tempt_bunnies_shadow_cleanup_20260623_175118 AS
SELECT *
FROM public.card_battle_rules
WHERE
  (normalized_name = 'big score' AND logical_rule_key IN (
    'battle_rule_v1:1c91b96cef3218cfe2eaed9484a5661b',
    'battle_rule_v1:ff9144b5fff75408e1a76a99888fdeca'
  ))
  OR
  (normalized_name = 'tempt with bunnies' AND logical_rule_key IN (
    'battle_rule_v1:030b2f3e0f549a462c3c8ea429877980'
  ));

DO $$
DECLARE
  v_big_score_cards integer;
  v_tempt_cards integer;
BEGIN
  SELECT count(*)
    INTO v_big_score_cards
  FROM public.cards
  WHERE lower(name) = 'big score'
    AND md5(coalesce(oracle_text, '')) = '9c4fbe06104051a2e8b1d295d307b26a';

  SELECT count(*)
    INTO v_tempt_cards
  FROM public.cards
  WHERE lower(name) = 'tempt with bunnies'
    AND md5(coalesce(oracle_text, '')) = '201f6c7234bfef550f3d497e736f0d7a';

  IF v_big_score_cards <> 1 THEN
    RAISE EXCEPTION 'PG116 abort: expected exactly one Big Score card row, got %', v_big_score_cards;
  END IF;

  IF v_tempt_cards <> 1 THEN
    RAISE EXCEPTION 'PG116 abort: expected exactly one Tempt with Bunnies card row, got %', v_tempt_cards;
  END IF;
END $$;

WITH deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PG116: deprecated stale shadow row after promoted Big Score / Tempt with Bunnies rules were already validated.'
    )
  WHERE
    (r.normalized_name = 'big score' AND r.logical_rule_key IN (
      'battle_rule_v1:1c91b96cef3218cfe2eaed9484a5661b',
      'battle_rule_v1:ff9144b5fff75408e1a76a99888fdeca'
    ))
    OR
    (r.normalized_name = 'tempt with bunnies' AND r.logical_rule_key IN (
      'battle_rule_v1:030b2f3e0f549a462c3c8ea429877980'
    ))
  RETURNING r.card_name, r.logical_rule_key
)
SELECT count(*) AS deprecated_shadow_rows
FROM deprecated;

COMMIT;
