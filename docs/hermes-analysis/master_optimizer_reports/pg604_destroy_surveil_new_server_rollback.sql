BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('deadly visit', 'pile on', 'shattered wings')
   OR normalized_name LIKE 'deadly visit // %'
   OR normalized_name LIKE 'pile on // %'
   OR normalized_name LIKE 'shattered wings // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg604_destroy_surveil_new_server_pg604_d_20260707_082832;

COMMIT;
