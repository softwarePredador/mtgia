BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('academy raider', 'impaler shrike')
   OR normalized_name LIKE 'academy raider // %'
   OR normalized_name LIKE 'impaler shrike // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg660_combat_damage_optional_draw_new_se_20260708_142516;

COMMIT;
