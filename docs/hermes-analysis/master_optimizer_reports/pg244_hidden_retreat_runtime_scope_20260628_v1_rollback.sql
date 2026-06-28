BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('hidden retreat')
   OR normalized_name LIKE 'hidden retreat // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg244_hidden_retreat_runtime_scope_20260628_065441;

COMMIT;
