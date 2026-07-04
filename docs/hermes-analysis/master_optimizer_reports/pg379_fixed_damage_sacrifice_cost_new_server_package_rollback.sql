BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('collateral damage', 'fiery conclusion', 'magma rift', 'reckless abandon', 'shard volley')
   OR normalized_name LIKE 'collateral damage // %'
   OR normalized_name LIKE 'fiery conclusion // %'
   OR normalized_name LIKE 'magma rift // %'
   OR normalized_name LIKE 'reckless abandon // %'
   OR normalized_name LIKE 'shard volley // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg379_fixed_damage_sacrifice_cost_new_server_20260704_02;

COMMIT;
