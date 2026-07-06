BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('carrier thrall', 'gravpack monoist')
   OR normalized_name LIKE 'carrier thrall // %'
   OR normalized_name LIKE 'gravpack monoist // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg538_dies_token_new_server_20260706_001447;

COMMIT;
