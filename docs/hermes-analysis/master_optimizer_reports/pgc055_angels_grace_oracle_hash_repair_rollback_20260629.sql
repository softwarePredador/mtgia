BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name = 'angel''s grace'
  AND logical_rule_key = 'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pgc055_angels_grace_oracle_hash_repair_20260629;

COMMIT;
