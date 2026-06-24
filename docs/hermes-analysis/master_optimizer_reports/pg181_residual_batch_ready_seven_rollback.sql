BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('brass''s bounty', 'bedevil', 'cathartic reunion', 'crackle with power', 'invoke justice', 'steelshaper''s gift', 'locket of yesterdays')
   OR normalized_name LIKE 'brass''s bounty // %'
   OR normalized_name LIKE 'bedevil // %'
   OR normalized_name LIKE 'cathartic reunion // %'
   OR normalized_name LIKE 'crackle with power // %'
   OR normalized_name LIKE 'invoke justice // %'
   OR normalized_name LIKE 'steelshaper''s gift // %'
   OR normalized_name LIKE 'locket of yesterdays // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg181_residual_batch_ready_seven_20260624_143655;

COMMIT;
