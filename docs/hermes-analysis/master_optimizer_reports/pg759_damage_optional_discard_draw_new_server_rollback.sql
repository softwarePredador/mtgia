BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('incinerating blast', 'tweeze')
   OR normalized_name LIKE 'incinerating blast // %'
   OR normalized_name LIKE 'tweeze // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg759_damage_optional_discard_draw_new_s_20260711_115206;

COMMIT;
