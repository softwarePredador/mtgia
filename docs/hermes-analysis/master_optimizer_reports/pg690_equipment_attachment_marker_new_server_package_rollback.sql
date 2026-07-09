BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('boots of speed', 'ranger''s longbow')
   OR normalized_name LIKE 'boots of speed // %'
   OR normalized_name LIKE 'ranger''s longbow // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg690_pg690_equipment_attachment_marker_20260709_041819;

COMMIT;
