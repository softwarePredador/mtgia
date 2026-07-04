BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('acceptable losses', 'artillerize', 'bone splinters', 'costly plunder', 'embrace oblivion', 'eviscerator''s insight', 'improvised club', 'morbid curiosity', 'powerstone fracture', 'raze', 'sonic burst', 'sonic seizure')
   OR normalized_name LIKE 'acceptable losses // %'
   OR normalized_name LIKE 'artillerize // %'
   OR normalized_name LIKE 'bone splinters // %'
   OR normalized_name LIKE 'costly plunder // %'
   OR normalized_name LIKE 'embrace oblivion // %'
   OR normalized_name LIKE 'eviscerator''s insight // %'
   OR normalized_name LIKE 'improvised club // %'
   OR normalized_name LIKE 'morbid curiosity // %'
   OR normalized_name LIKE 'powerstone fracture // %'
   OR normalized_name LIKE 'raze // %'
   OR normalized_name LIKE 'sonic burst // %'
   OR normalized_name LIKE 'sonic seizure // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg384_additional_cost_spell_runtime_new_server_20260704_;

COMMIT;
