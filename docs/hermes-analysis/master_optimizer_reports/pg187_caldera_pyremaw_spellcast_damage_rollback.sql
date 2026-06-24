BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('caldera pyremaw')
   OR normalized_name LIKE 'caldera pyremaw // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg187_caldera_pyremaw_spellcast_damage_20260624_205240;

COMMIT;
