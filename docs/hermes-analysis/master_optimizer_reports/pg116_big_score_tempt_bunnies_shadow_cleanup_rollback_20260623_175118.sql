BEGIN;

DELETE FROM public.card_battle_rules r
WHERE
  (r.normalized_name = 'big score' AND r.logical_rule_key IN (
    'battle_rule_v1:1c91b96cef3218cfe2eaed9484a5661b',
    'battle_rule_v1:ff9144b5fff75408e1a76a99888fdeca'
  ))
  OR
  (r.normalized_name = 'tempt with bunnies' AND r.logical_rule_key IN (
    'battle_rule_v1:030b2f3e0f549a462c3c8ea429877980'
  ));

INSERT INTO public.card_battle_rules (
  normalized_name,
  card_id,
  card_name,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  rule_version,
  oracle_hash,
  notes,
  reviewed_by,
  reviewed_at,
  created_at,
  updated_at,
  last_seen_at,
  logical_rule_key,
  execution_status
)
SELECT
  normalized_name,
  card_id,
  card_name,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  rule_version,
  oracle_hash,
  notes,
  reviewed_by,
  reviewed_at,
  created_at,
  updated_at,
  last_seen_at,
  logical_rule_key,
  execution_status
FROM manaloom_deploy_audit.pg116_big_score_tempt_bunnies_shadow_cleanup_20260623_175118;

COMMIT;
