BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('consume the meek', 'culling sun', 'doomskar', 'extinguish all hope', 'granulate', 'in garruk''s wake', 'jokulhaups', 'obliterate', 'sublime exhalation', 'supreme verdict')
   OR normalized_name LIKE 'consume the meek // %'
   OR normalized_name LIKE 'culling sun // %'
   OR normalized_name LIKE 'doomskar // %'
   OR normalized_name LIKE 'extinguish all hope // %'
   OR normalized_name LIKE 'granulate // %'
   OR normalized_name LIKE 'in garruk''s wake // %'
   OR normalized_name LIKE 'jokulhaups // %'
   OR normalized_name LIKE 'obliterate // %'
   OR normalized_name LIKE 'sublime exhalation // %'
   OR normalized_name LIKE 'supreme verdict // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg680_destroy_all_board_wipe_20260709_004253;

COMMIT;
