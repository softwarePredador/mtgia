BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('distorted curiosity', 'draconic lore', 'into the story', 'of one mind', 'overflowing insight', 'pearl of wisdom', 'scour the laboratory', 'winged words')
   OR normalized_name LIKE 'distorted curiosity // %'
   OR normalized_name LIKE 'draconic lore // %'
   OR normalized_name LIKE 'into the story // %'
   OR normalized_name LIKE 'of one mind // %'
   OR normalized_name LIKE 'overflowing insight // %'
   OR normalized_name LIKE 'pearl of wisdom // %'
   OR normalized_name LIKE 'scour the laboratory // %'
   OR normalized_name LIKE 'winged words // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg399_draw_self_cost_reduction_target_draw_new_server_20;

COMMIT;
