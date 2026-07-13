BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bristling boar', 'charging rhino', 'huang zhong, shu general', 'ironhoof ox', 'norwood riders', 'stalking tiger')
   OR normalized_name LIKE 'bristling boar // %'
   OR normalized_name LIKE 'charging rhino // %'
   OR normalized_name LIKE 'huang zhong, shu general // %'
   OR normalized_name LIKE 'ironhoof ox // %'
   OR normalized_name LIKE 'norwood riders // %'
   OR normalized_name LIKE 'stalking tiger // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg858_static_cant_be_blocked_by_more_tha_20260713_024015;

COMMIT;
