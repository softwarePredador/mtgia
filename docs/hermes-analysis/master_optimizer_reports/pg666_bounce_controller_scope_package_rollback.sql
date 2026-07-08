BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('rescue', 'stern dismissal')
   OR normalized_name LIKE 'rescue // %'
   OR normalized_name LIKE 'stern dismissal // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg666_bounce_controller_scope_20260708_182140;

COMMIT;
