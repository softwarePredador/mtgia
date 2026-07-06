BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('icatian crier', 'pegasus refuge', 'sliversmith', 'thraben standard bearer')
   OR normalized_name LIKE 'icatian crier // %'
   OR normalized_name LIKE 'pegasus refuge // %'
   OR normalized_name LIKE 'sliversmith // %'
   OR normalized_name LIKE 'thraben standard bearer // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg542_activated_token_discard_new_server_20260706_015701;

COMMIT;
