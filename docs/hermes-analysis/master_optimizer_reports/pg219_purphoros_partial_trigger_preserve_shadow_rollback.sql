BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('purphoros, god of the forge')
   OR normalized_name LIKE 'purphoros, god of the forge // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg219_purphoros_partial_trigger_preserve_shadow_20260626;

COMMIT;
