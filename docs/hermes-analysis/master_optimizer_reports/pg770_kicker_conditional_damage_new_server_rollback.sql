BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('burst lightning', 'firebending lesson', 'roil eruption', 'shivan fire')
   OR normalized_name LIKE 'burst lightning // %'
   OR normalized_name LIKE 'firebending lesson // %'
   OR normalized_name LIKE 'roil eruption // %'
   OR normalized_name LIKE 'shivan fire // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg770_kicker_conditional_damage_new_serv_20260711_154242;

COMMIT;
