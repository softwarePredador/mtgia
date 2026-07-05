BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('no more lies', 'reject', 'scatter ray', 'spectral interference')
   OR normalized_name LIKE 'no more lies // %'
   OR normalized_name LIKE 'reject // %'
   OR normalized_name LIKE 'scatter ray // %'
   OR normalized_name LIKE 'spectral interference // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg528_counter_unless_pays_exile_new_serv_20260705_201753;

COMMIT;
