BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('barrels of blasting jelly', 'foraging wickermaw', 'gravestone strider', 'salvaged manaworker', 'scarecrow guide', 'shire scarecrow', 'three tree mascot')
   OR normalized_name LIKE 'barrels of blasting jelly // %'
   OR normalized_name LIKE 'foraging wickermaw // %'
   OR normalized_name LIKE 'gravestone strider // %'
   OR normalized_name LIKE 'salvaged manaworker // %'
   OR normalized_name LIKE 'scarecrow guide // %'
   OR normalized_name LIKE 'shire scarecrow // %'
   OR normalized_name LIKE 'three tree mascot // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg595_limited_times_any_color_mana_new_s_20260707_051029;

COMMIT;
