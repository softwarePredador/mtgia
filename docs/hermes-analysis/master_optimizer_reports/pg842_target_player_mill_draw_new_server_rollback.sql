BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('pilfered plans', 'thassa''s bounty', 'thought scour', 'weight of memory')
   OR normalized_name LIKE 'pilfered plans // %'
   OR normalized_name LIKE 'thassa''s bounty // %'
   OR normalized_name LIKE 'thought scour // %'
   OR normalized_name LIKE 'weight of memory // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg842_target_player_mill_draw_new_server_20260712_200018;

COMMIT;
