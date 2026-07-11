BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('divine offering', 'molder', 'serene offering', 'tidy conclusion')
   OR normalized_name LIKE 'divine offering // %'
   OR normalized_name LIKE 'molder // %'
   OR normalized_name LIKE 'serene offering // %'
   OR normalized_name LIKE 'tidy conclusion // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg776_destroy_dynamic_gain_life_new_serv_20260711_172405;

COMMIT;
