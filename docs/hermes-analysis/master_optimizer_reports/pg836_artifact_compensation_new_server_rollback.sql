BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('buy your silence', 'zuko''s exile')
   OR normalized_name LIKE 'buy your silence // %'
   OR normalized_name LIKE 'zuko''s exile // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg836_artifact_compensation_new_server_20260712_181626;

COMMIT;
