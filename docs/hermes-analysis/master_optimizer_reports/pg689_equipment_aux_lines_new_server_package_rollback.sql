BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bramble armor', 'darksteel axe', 'maul of the skyclaves', 'meltstrider''s gear', 'piston sledge', 'scavenged blade', 'shredder''s armor', 'utility knife')
   OR normalized_name LIKE 'bramble armor // %'
   OR normalized_name LIKE 'darksteel axe // %'
   OR normalized_name LIKE 'maul of the skyclaves // %'
   OR normalized_name LIKE 'meltstrider''s gear // %'
   OR normalized_name LIKE 'piston sledge // %'
   OR normalized_name LIKE 'scavenged blade // %'
   OR normalized_name LIKE 'shredder''s armor // %'
   OR normalized_name LIKE 'utility knife // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg689_pg689_equipment_aux_lines_new_serv_20260709_035705;

COMMIT;
