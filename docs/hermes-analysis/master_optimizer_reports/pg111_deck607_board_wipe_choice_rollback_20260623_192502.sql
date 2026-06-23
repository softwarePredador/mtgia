BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN (
    'promise of loyalty',
    'starfall invocation',
    'tragic arrogance'
  )
  AND logical_rule_key IN (
    'battle_rule_v1:78fff8e218103b0710bc5ee9cf174ee9',
    'battle_rule_v1:58cfb4628b4a4a879f6f9c5e0ab3ee5f',
    'battle_rule_v1:d4d676e6ecea500f7aca4cbc7f7ae04a'
  );

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
FROM manaloom_deploy_audit.pg111_deck607_board_wipe_choice_20260623_192502
ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE
SET
  card_id = EXCLUDED.card_id,
  card_name = EXCLUDED.card_name,
  effect_json = EXCLUDED.effect_json,
  deck_role_json = EXCLUDED.deck_role_json,
  source = EXCLUDED.source,
  confidence = EXCLUDED.confidence,
  review_status = EXCLUDED.review_status,
  rule_version = EXCLUDED.rule_version,
  oracle_hash = EXCLUDED.oracle_hash,
  notes = EXCLUDED.notes,
  reviewed_by = EXCLUDED.reviewed_by,
  reviewed_at = EXCLUDED.reviewed_at,
  created_at = EXCLUDED.created_at,
  updated_at = now(),
  last_seen_at = EXCLUDED.last_seen_at,
  execution_status = EXCLUDED.execution_status;

COMMIT;
