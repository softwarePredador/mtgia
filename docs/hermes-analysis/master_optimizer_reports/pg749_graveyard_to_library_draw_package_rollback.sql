BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('footbottom feast', 'forever young', 'frantic salvage', 'gravepurge')
   OR normalized_name LIKE 'footbottom feast // %'
   OR normalized_name LIKE 'forever young // %'
   OR normalized_name LIKE 'frantic salvage // %'
   OR normalized_name LIKE 'gravepurge // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg749_graveyard_to_library_draw_new_serv_20260711_074910;

COMMIT;
