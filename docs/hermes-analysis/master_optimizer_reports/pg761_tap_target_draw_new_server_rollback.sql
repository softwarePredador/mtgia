BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('pressure point', 'repel the darkness')
   OR normalized_name LIKE 'pressure point // %'
   OR normalized_name LIKE 'repel the darkness // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg761_tap_target_draw_new_server_tap_tar_20260711_124020;

COMMIT;
