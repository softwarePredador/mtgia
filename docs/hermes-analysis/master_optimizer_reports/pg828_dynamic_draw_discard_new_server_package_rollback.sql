BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('flow of knowledge', 'pull from tomorrow')
   OR normalized_name LIKE 'flow of knowledge // %'
   OR normalized_name LIKE 'pull from tomorrow // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg828_dynamic_draw_discard_new_server_20260712_111415;

COMMIT;
