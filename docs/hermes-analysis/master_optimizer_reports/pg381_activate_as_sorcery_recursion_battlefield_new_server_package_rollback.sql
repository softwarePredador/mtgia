BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bonecaller cleric', 'valgavoth''s faithful')
   OR normalized_name LIKE 'bonecaller cleric // %'
   OR normalized_name LIKE 'valgavoth''s faithful // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg381_activate_as_sorcery_recursion_battlefield_new_serv;

COMMIT;
