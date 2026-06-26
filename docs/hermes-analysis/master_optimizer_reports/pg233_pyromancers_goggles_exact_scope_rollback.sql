BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('pyromancer''s goggles')
   OR normalized_name LIKE 'pyromancer''s goggles // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg233_pyromancers_goggles_exact_scope_20260626_080634;

COMMIT;
