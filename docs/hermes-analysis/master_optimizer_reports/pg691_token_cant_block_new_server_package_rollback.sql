BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('edgewall pack', 'harried spearguard', 'synapse necromage')
   OR normalized_name LIKE 'edgewall pack // %'
   OR normalized_name LIKE 'harried spearguard // %'
   OR normalized_name LIKE 'synapse necromage // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg691_token_cant_block_20260709_045133;

COMMIT;
