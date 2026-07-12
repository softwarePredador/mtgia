BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('murasa behemoth')
   OR normalized_name LIKE 'murasa behemoth // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg816_controller_land_graveyard_threshol_20260712_075535;

COMMIT;
