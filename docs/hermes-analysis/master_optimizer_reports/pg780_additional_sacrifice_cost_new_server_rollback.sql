BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('abjure', 'deprive', 'final vengeance', 'withering boon', 'worthy cost')
   OR normalized_name LIKE 'abjure // %'
   OR normalized_name LIKE 'deprive // %'
   OR normalized_name LIKE 'final vengeance // %'
   OR normalized_name LIKE 'withering boon // %'
   OR normalized_name LIKE 'worthy cost // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg780_additional_sacrifice_cost_new_serv_20260711_181409;

COMMIT;
