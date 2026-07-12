BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('blightning')
   OR normalized_name LIKE 'blightning // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg812_damage_discard_blightning_new_serv_20260712_070524;

COMMIT;
