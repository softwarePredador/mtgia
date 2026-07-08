BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('final strike', 'fling', 'thud')
   OR normalized_name LIKE 'final strike // %'
   OR normalized_name LIKE 'fling // %'
   OR normalized_name LIKE 'thud // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg655_sacrifice_creature_power_damage_ne_20260708_122228;

COMMIT;
