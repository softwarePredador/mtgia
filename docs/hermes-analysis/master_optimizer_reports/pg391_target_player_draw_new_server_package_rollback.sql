BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('inspiration', 'opportunity')
   OR normalized_name LIKE 'inspiration // %'
   OR normalized_name LIKE 'opportunity // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg391_target_player_draw_new_server_20260704_072935;

COMMIT;
