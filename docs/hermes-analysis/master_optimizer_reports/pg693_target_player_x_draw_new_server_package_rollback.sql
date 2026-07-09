BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('braingeyser', 'stroke of genius')
   OR normalized_name LIKE 'braingeyser // %'
   OR normalized_name LIKE 'stroke of genius // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg693_target_player_x_draw_20260709_052610;

COMMIT;
