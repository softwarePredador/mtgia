BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('avian changeling', 'changeling sentinel', 'chitinous graspling', 'game-trail changeling', 'gangly stompling', 'impostor of the sixth pride', 'mischievous sneakling', 'mistform ultimus', 'prideful feastling', 'universal automaton', 'venomous changeling', 'woodland changeling')
   OR normalized_name LIKE 'avian changeling // %'
   OR normalized_name LIKE 'changeling sentinel // %'
   OR normalized_name LIKE 'chitinous graspling // %'
   OR normalized_name LIKE 'game-trail changeling // %'
   OR normalized_name LIKE 'gangly stompling // %'
   OR normalized_name LIKE 'impostor of the sixth pride // %'
   OR normalized_name LIKE 'mischievous sneakling // %'
   OR normalized_name LIKE 'mistform ultimus // %'
   OR normalized_name LIKE 'prideful feastling // %'
   OR normalized_name LIKE 'universal automaton // %'
   OR normalized_name LIKE 'venomous changeling // %'
   OR normalized_name LIKE 'woodland changeling // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg825_pg825_static_self_changeling_creat_20260712_102059;

COMMIT;
