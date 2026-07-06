BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('ajani''s welcome', 'bogwater lumaret', 'essence warden', 'healer of the pride', 'hinterland sanctifier', 'impassioned orator', 'kor celebrant', 'soul warden', 'soul''s attendant')
   OR normalized_name LIKE 'ajani''s welcome // %'
   OR normalized_name LIKE 'bogwater lumaret // %'
   OR normalized_name LIKE 'essence warden // %'
   OR normalized_name LIKE 'healer of the pride // %'
   OR normalized_name LIKE 'hinterland sanctifier // %'
   OR normalized_name LIKE 'impassioned orator // %'
   OR normalized_name LIKE 'kor celebrant // %'
   OR normalized_name LIKE 'soul warden // %'
   OR normalized_name LIKE 'soul''s attendant // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg558_creature_enters_life_gain_new_serv_20260706_074911;

COMMIT;
