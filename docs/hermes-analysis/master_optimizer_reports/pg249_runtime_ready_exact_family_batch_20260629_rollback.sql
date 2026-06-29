BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('verge rangers', 'firesong and sunspeaker', 'goliath daydreamer', 'boros reckoner', 'terror of the peaks', 'balefire liege', 'repercussion')
   OR normalized_name LIKE 'verge rangers // %'
   OR normalized_name LIKE 'firesong and sunspeaker // %'
   OR normalized_name LIKE 'goliath daydreamer // %'
   OR normalized_name LIKE 'boros reckoner // %'
   OR normalized_name LIKE 'terror of the peaks // %'
   OR normalized_name LIKE 'balefire liege // %'
   OR normalized_name LIKE 'repercussion // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg249_runtime_ready_exact_family_batch_20260629_143348;

COMMIT;
