BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('basal thrull', 'blood pet', 'blood vassal', 'catalyst elemental', 'coal golem', 'composite golem', 'crosis''s attendant', 'darigaaz''s attendant', 'dromar''s attendant', 'morgue toad', 'rith''s attendant', 'satyr hedonist', 'treva''s attendant')
   OR normalized_name LIKE 'basal thrull // %'
   OR normalized_name LIKE 'blood pet // %'
   OR normalized_name LIKE 'blood vassal // %'
   OR normalized_name LIKE 'catalyst elemental // %'
   OR normalized_name LIKE 'coal golem // %'
   OR normalized_name LIKE 'composite golem // %'
   OR normalized_name LIKE 'crosis''s attendant // %'
   OR normalized_name LIKE 'darigaaz''s attendant // %'
   OR normalized_name LIKE 'dromar''s attendant // %'
   OR normalized_name LIKE 'morgue toad // %'
   OR normalized_name LIKE 'rith''s attendant // %'
   OR normalized_name LIKE 'satyr hedonist // %'
   OR normalized_name LIKE 'treva''s attendant // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg447_xmage_self_sacrifice_mana_source_new_server_202607;

COMMIT;
