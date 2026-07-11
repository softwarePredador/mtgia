BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('mystic meditation', 'thirst for discovery', 'thirst for identity', 'thirst for knowledge', 'thirst for meaning')
   OR normalized_name LIKE 'mystic meditation // %'
   OR normalized_name LIKE 'thirst for discovery // %'
   OR normalized_name LIKE 'thirst for identity // %'
   OR normalized_name LIKE 'thirst for knowledge // %'
   OR normalized_name LIKE 'thirst for meaning // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg739_draw_discard_unless_new_server_20260711_034911;

COMMIT;
