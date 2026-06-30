BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('assemble the players')
   OR normalized_name LIKE 'assemble the players // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg276_assemble_the_players_top_library_small_creature_20;

COMMIT;
