BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('moon-vigil adherents')
   OR normalized_name LIKE 'moon-vigil adherents // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg818_moon_vigil_battlefield_graveyard_c_20260712_081746;

COMMIT;
