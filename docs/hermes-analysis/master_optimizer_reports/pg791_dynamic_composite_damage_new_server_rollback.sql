BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('focus fire', 'hobbit''s sting', 'road rage', 'slash of light')
   OR normalized_name LIKE 'focus fire // %'
   OR normalized_name LIKE 'hobbit''s sting // %'
   OR normalized_name LIKE 'road rage // %'
   OR normalized_name LIKE 'slash of light // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg791_dynamic_composite_damage_20260711_222405;

COMMIT;
