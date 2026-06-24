BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('treasure vault')
   OR normalized_name LIKE 'treasure vault // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg145_treasure_vault_x_treasure_land_20260624_055034;

COMMIT;
