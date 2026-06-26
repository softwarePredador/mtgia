BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('galvanoth', 'velomachus lorehold', 'palantír of orthanc', 'scholar of new horizons')
   OR normalized_name LIKE 'galvanoth // %'
   OR normalized_name LIKE 'velomachus lorehold // %'
   OR normalized_name LIKE 'palantír of orthanc // %'
   OR normalized_name LIKE 'scholar of new horizons // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg234_lorehold_ready_batch_four_20260626_082257;

COMMIT;
