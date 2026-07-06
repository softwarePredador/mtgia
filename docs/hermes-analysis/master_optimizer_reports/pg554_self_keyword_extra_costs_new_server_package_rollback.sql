BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('fledgling imp', 'insatiable souleater', 'olivia''s dragoon', 'patrol hound', 'shadowcloak vampire')
   OR normalized_name LIKE 'fledgling imp // %'
   OR normalized_name LIKE 'insatiable souleater // %'
   OR normalized_name LIKE 'olivia''s dragoon // %'
   OR normalized_name LIKE 'patrol hound // %'
   OR normalized_name LIKE 'shadowcloak vampire // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg554_self_keyword_extra_costs_new_serve_20260706_061152;

COMMIT;
