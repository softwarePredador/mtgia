BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('sage of lat-nam', 'thraxodemon')
   OR normalized_name LIKE 'sage of lat-nam // %'
   OR normalized_name LIKE 'thraxodemon // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg615_activated_draw_sacrifice_target_pg_20260707_124911;

COMMIT;
