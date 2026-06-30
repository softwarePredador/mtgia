BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('goliath daydreamer', 'twinflame tyrant', 'verge rangers', 'boros reckoner', 'terror of the peaks', 'balefire liege', 'firesong and sunspeaker', 'repercussion')
   OR normalized_name LIKE 'goliath daydreamer // %'
   OR normalized_name LIKE 'twinflame tyrant // %'
   OR normalized_name LIKE 'verge rangers // %'
   OR normalized_name LIKE 'boros reckoner // %'
   OR normalized_name LIKE 'terror of the peaks // %'
   OR normalized_name LIKE 'balefire liege // %'
   OR normalized_name LIKE 'firesong and sunspeaker // %'
   OR normalized_name LIKE 'repercussion // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg263_lorehold_runtime_gap_ready_batch_20260630_20260630;

COMMIT;
