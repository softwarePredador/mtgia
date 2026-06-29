BEGIN;

DELETE FROM public.card_battle_rules
WHERE (normalized_name = 'furygale flocking'
   AND logical_rule_key = 'battle_rule_v1:63b66f50aad09aa5669ac693b2fca7e5')
   OR (normalized_name = 'tempt with bunnies'
   AND logical_rule_key IN (
     'battle_rule_v1:64814289c1def19e7cd5bb7462c4cf86',
     'battle_rule_v1:ac96c7799172699f5d7b6b0dc5e4aa80'
   ));

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pgc060_runtime_annotation_executor_20260629;

COMMIT;
