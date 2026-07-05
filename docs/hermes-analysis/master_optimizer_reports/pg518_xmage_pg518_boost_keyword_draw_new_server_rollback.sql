BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('guided strike', 'moment of defiance', 'wildsize')
   OR normalized_name LIKE 'guided strike // %'
   OR normalized_name LIKE 'moment of defiance // %'
   OR normalized_name LIKE 'wildsize // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.xmage_pg518_boost_keyword_draw_new_serve_20260705_170024;

COMMIT;
