BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('penance')
   OR normalized_name LIKE 'penance // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg241_penance_damage_prevention_20260626_110838;

COMMIT;
