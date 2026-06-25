BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('the locust god', 'fable of the mirror-breaker // reflection of kiki-jiki', 'biotransference')
   OR normalized_name LIKE 'the locust god // %'
   OR normalized_name LIKE 'fable of the mirror-breaker // reflection of kiki-jiki // %'
   OR normalized_name LIKE 'biotransference // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg217_saga_draw_artifact_20260625_111141;

COMMIT;
