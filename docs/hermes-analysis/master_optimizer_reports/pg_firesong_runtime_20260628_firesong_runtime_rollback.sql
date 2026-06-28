BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('firesong and sunspeaker')
   OR normalized_name LIKE 'firesong and sunspeaker // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg_firesong_runtime_20260628_firesong_runtime_20260628_1;

COMMIT;
