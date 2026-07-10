BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('aang''s defense', 'gallantry')
   OR normalized_name LIKE 'aang''s defense // %'
   OR normalized_name LIKE 'gallantry // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg718_blocking_boost_draw_new_server_blo_20260710_200045;

COMMIT;
