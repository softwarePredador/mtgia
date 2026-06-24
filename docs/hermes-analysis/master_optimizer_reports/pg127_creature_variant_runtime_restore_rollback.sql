BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('colossal skyturtle', 'abigale, eloquent first-year', 'glen elendra archmage');

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg127_creature_variant_runtime_restore_20260624_001336;

COMMIT;
