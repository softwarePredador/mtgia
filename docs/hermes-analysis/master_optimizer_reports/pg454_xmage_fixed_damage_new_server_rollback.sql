BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('acceptable losses', 'artillerize', 'collateral damage', 'fiery conclusion', 'improvised club', 'magma rift', 'reckless abandon', 'shard volley', 'sonic burst', 'sonic seizure')
   OR normalized_name LIKE 'acceptable losses // %'
   OR normalized_name LIKE 'artillerize // %'
   OR normalized_name LIKE 'collateral damage // %'
   OR normalized_name LIKE 'fiery conclusion // %'
   OR normalized_name LIKE 'improvised club // %'
   OR normalized_name LIKE 'magma rift // %'
   OR normalized_name LIKE 'reckless abandon // %'
   OR normalized_name LIKE 'shard volley // %'
   OR normalized_name LIKE 'sonic burst // %'
   OR normalized_name LIKE 'sonic seizure // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg454_xmage_fixed_damage_new_server_20260705_000101;

COMMIT;
