BEGIN;

DELETE FROM public.card_battle_rules
WHERE (normalized_name = 'erode'
   AND logical_rule_key = 'battle_rule_v1:dd175af9c77feea940de97138a916fe3')
   OR (normalized_name = 'sundering eruption // volcanic fissure'
   AND logical_rule_key = 'battle_rule_v1:98d0006543fc622cfc1d82991bd5a66a');

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pgc061_basic_land_compensation_runtime_20260629;

COMMIT;
