BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('liliana''s standard bearer')
   OR normalized_name LIKE 'liliana''s standard bearer // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg746_etb_dynamic_draw_death_count_new_s_20260711_070750;

COMMIT;
