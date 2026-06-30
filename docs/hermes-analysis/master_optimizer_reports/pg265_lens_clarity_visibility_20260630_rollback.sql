BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('lens of clarity')
   OR normalized_name LIKE 'lens of clarity // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg265_lens_clarity_visibility_20260630_055818;

COMMIT;
