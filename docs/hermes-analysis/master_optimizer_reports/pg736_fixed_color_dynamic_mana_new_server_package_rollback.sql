BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('karametra''s acolyte', 'magus of the coffers', 'priest of titania', 'viridian joiner')
   OR normalized_name LIKE 'karametra''s acolyte // %'
   OR normalized_name LIKE 'magus of the coffers // %'
   OR normalized_name LIKE 'priest of titania // %'
   OR normalized_name LIKE 'viridian joiner // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg736_fixed_color_dynamic_mana_new_serve_20260711_025659;

COMMIT;
