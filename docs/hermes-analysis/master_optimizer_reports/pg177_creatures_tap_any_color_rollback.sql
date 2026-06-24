BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('enduring vitality', 'cryptolith rite')
   OR normalized_name LIKE 'enduring vitality // %'
   OR normalized_name LIKE 'cryptolith rite // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg177_creatures_tap_any_color_20260624_131953;

COMMIT;
