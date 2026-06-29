BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bridgeworks battle', 'hydroelectric specimen', 'selvala, heart of the wilds', 'devoted druid', 'birgi, god of storytelling', 'fractured powerstone', 'incubation druid', 'delighted halfling')
   OR normalized_name LIKE 'bridgeworks battle // %'
   OR normalized_name LIKE 'hydroelectric specimen // %'
   OR normalized_name LIKE 'selvala, heart of the wilds // %'
   OR normalized_name LIKE 'devoted druid // %'
   OR normalized_name LIKE 'birgi, god of storytelling // %'
   OR normalized_name LIKE 'fractured powerstone // %'
   OR normalized_name LIKE 'incubation druid // %'
   OR normalized_name LIKE 'delighted halfling // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg259_exact_ramp_runtime_promotions_20260629_20260629_17;

COMMIT;
