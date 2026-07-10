BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('ant queen', 'broodmate dragon', 'roc egg', 'sprouting thrinax')
   OR normalized_name LIKE 'ant queen // %'
   OR normalized_name LIKE 'broodmate dragon // %'
   OR normalized_name LIKE 'roc egg // %'
   OR normalized_name LIKE 'sprouting thrinax // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg720_token_variable_arg_new_server_toke_20260710_203259;

COMMIT;
