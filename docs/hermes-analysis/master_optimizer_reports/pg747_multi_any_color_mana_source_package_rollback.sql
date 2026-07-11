BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('gilded lotus', 'somberwald sage', 'transdimensional bovine')
   OR normalized_name LIKE 'gilded lotus // %'
   OR normalized_name LIKE 'somberwald sage // %'
   OR normalized_name LIKE 'transdimensional bovine // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg747_multi_any_color_mana_source_new_se_20260711_071909;

COMMIT;
