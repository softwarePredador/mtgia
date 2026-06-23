BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bender''s waterskin', 'victory chimes');

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg109_benders_waterskin_victory_chimes_20260623_171938;

COMMIT;
