BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('embrace the paradox', 'eureka moment', 'growth spiral', 'lessons from life')
   OR normalized_name LIKE 'embrace the paradox // %'
   OR normalized_name LIKE 'eureka moment // %'
   OR normalized_name LIKE 'growth spiral // %'
   OR normalized_name LIKE 'lessons from life // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.xmage_pg516_draw_put_land_from_hand_new_20260705_161259;

COMMIT;
