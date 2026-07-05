BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('death in the family', 'despark', 'isolate', 'kin-tree severance')
   OR normalized_name LIKE 'death in the family // %'
   OR normalized_name LIKE 'despark // %'
   OR normalized_name LIKE 'isolate // %'
   OR normalized_name LIKE 'kin-tree severance // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg495_exile_mana_value_target_new_server_20260705_084946;

COMMIT;
