BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('elemental bond', 'garruk''s packleader', 'mary jane watson', 'wirewood savage', 'woodland liege')
   OR normalized_name LIKE 'elemental bond // %'
   OR normalized_name LIKE 'garruk''s packleader // %'
   OR normalized_name LIKE 'mary jane watson // %'
   OR normalized_name LIKE 'wirewood savage // %'
   OR normalized_name LIKE 'woodland liege // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg579_creature_enters_draw_new_server_20260706_231755;

COMMIT;
