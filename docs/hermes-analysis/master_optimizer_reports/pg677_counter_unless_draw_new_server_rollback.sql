BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('disrupt', 'runeboggle')
   OR normalized_name LIKE 'disrupt // %'
   OR normalized_name LIKE 'runeboggle // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg677_counter_unless_draw_new_server_20260708_232921;

COMMIT;
