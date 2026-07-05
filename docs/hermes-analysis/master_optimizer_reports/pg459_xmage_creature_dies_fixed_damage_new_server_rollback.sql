BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bogardan firefiend', 'careless celebrant', 'footlight fiend', 'goblin arsonist', 'mudbutton torchrunner', 'perilous myr', 'pitchburn devils', 'pyre spawn')
   OR normalized_name LIKE 'bogardan firefiend // %'
   OR normalized_name LIKE 'careless celebrant // %'
   OR normalized_name LIKE 'footlight fiend // %'
   OR normalized_name LIKE 'goblin arsonist // %'
   OR normalized_name LIKE 'mudbutton torchrunner // %'
   OR normalized_name LIKE 'perilous myr // %'
   OR normalized_name LIKE 'pitchburn devils // %'
   OR normalized_name LIKE 'pyre spawn // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg459_xmage_creature_dies_fixed_damage_new_server_202607;

COMMIT;
