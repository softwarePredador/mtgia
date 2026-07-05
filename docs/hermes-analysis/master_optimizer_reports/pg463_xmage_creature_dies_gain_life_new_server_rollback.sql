BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('anodet lurker', 'enatu golem', 'grasping longneck', 'guardian automaton', 'highland game', 'onulet', 'tarpan')
   OR normalized_name LIKE 'anodet lurker // %'
   OR normalized_name LIKE 'enatu golem // %'
   OR normalized_name LIKE 'grasping longneck // %'
   OR normalized_name LIKE 'guardian automaton // %'
   OR normalized_name LIKE 'highland game // %'
   OR normalized_name LIKE 'onulet // %'
   OR normalized_name LIKE 'tarpan // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg463_xmage_creature_dies_gain_life_new_server_20260705_;

COMMIT;
