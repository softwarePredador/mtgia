BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('accursed spirit', 'bladetusk boar', 'crowd of cinders', 'dross prowler', 'gluttonous zombie', 'highborn ghoul', 'krenko''s enforcer', 'prickly boggart', 'razortooth rats', 'severed legion', 'shadowmage infiltrator', 'spectral rider', 'squirming mass', 'undercity shade', 'woebearer')
   OR normalized_name LIKE 'accursed spirit // %'
   OR normalized_name LIKE 'bladetusk boar // %'
   OR normalized_name LIKE 'crowd of cinders // %'
   OR normalized_name LIKE 'dross prowler // %'
   OR normalized_name LIKE 'gluttonous zombie // %'
   OR normalized_name LIKE 'highborn ghoul // %'
   OR normalized_name LIKE 'krenko''s enforcer // %'
   OR normalized_name LIKE 'prickly boggart // %'
   OR normalized_name LIKE 'razortooth rats // %'
   OR normalized_name LIKE 'severed legion // %'
   OR normalized_name LIKE 'shadowmage infiltrator // %'
   OR normalized_name LIKE 'spectral rider // %'
   OR normalized_name LIKE 'squirming mass // %'
   OR normalized_name LIKE 'undercity shade // %'
   OR normalized_name LIKE 'woebearer // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg658_static_fear_intimidate_new_server_20260708_135146;

COMMIT;
