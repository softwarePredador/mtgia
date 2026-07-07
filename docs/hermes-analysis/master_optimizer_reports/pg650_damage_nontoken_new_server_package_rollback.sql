BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('incandescent aria')
   OR normalized_name LIKE 'incandescent aria // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg650_damage_nontoken_new_server_20260707_233132;

COMMIT;
