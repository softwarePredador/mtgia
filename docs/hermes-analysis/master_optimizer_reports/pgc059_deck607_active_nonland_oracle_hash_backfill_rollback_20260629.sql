BEGIN;

DELETE FROM public.card_battle_rules r
USING manaloom_deploy_audit.pgc059_deck607_active_nonland_oracle_hash_backfill_20260629 b
WHERE r.normalized_name = b.normalized_name
  AND r.logical_rule_key = b.logical_rule_key;

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pgc059_deck607_active_nonland_oracle_hash_backfill_20260629;

COMMIT;
