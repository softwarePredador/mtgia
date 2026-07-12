BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('animal attendant', 'biophagus', 'carnelian orb of dragonkind')
   OR normalized_name LIKE 'animal attendant // %'
   OR normalized_name LIKE 'biophagus // %'
   OR normalized_name LIKE 'carnelian orb of dragonkind // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg832_mana_spent_cast_trigger_new_server_20260712_130709;

COMMIT;
