BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('angelsong', 'darkness', 'haze of pollen', 'holy day', 'lull', 'root snare')
   OR normalized_name LIKE 'angelsong // %'
   OR normalized_name LIKE 'darkness // %'
   OR normalized_name LIKE 'haze of pollen // %'
   OR normalized_name LIKE 'holy day // %'
   OR normalized_name LIKE 'lull // %'
   OR normalized_name LIKE 'root snare // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg622_prevent_all_combat_damage_new_serv_20260707_152050;

COMMIT;
