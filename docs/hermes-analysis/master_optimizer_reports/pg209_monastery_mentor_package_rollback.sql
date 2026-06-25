BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('monastery mentor')
   OR normalized_name LIKE 'monastery mentor // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg209_monastery_mentor_20260625_075104;

COMMIT;
