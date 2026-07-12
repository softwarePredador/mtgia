BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('paradise plume')
   OR normalized_name LIKE 'paradise plume // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg821_paradise_plume_chosen_color_spell_20260712_085838;

COMMIT;
