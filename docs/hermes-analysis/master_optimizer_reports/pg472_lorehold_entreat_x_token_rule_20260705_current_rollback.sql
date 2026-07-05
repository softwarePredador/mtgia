BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name = 'entreat the angels'
  AND logical_rule_key = 'battle_rule_v1:0ce4d97cb4f226cd2df5f9bdbdebc04e';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg472_lorehold_entreat_x_token_rule_20260705_current
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
  updated_at = EXCLUDED.updated_at,
  last_seen_at = EXCLUDED.last_seen_at,
  execution_status = EXCLUDED.execution_status;

COMMIT;
