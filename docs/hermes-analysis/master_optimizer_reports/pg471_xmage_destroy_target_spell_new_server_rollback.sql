BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bone splinters', 'embrace oblivion', 'powerstone fracture', 'raze')
   OR normalized_name LIKE 'bone splinters // %'
   OR normalized_name LIKE 'embrace oblivion // %'
   OR normalized_name LIKE 'powerstone fracture // %'
   OR normalized_name LIKE 'raze // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg471_xmage_destroy_target_spell_new_server_20260705_021;

COMMIT;
