BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('forbidden alchemy', 'nagging thoughts', 'resentful revelation', 'tapping at the window')
   OR normalized_name LIKE 'forbidden alchemy // %'
   OR normalized_name LIKE 'nagging thoughts // %'
   OR normalized_name LIKE 'resentful revelation // %'
   OR normalized_name LIKE 'tapping at the window // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg578_look_library_graveyard_new_server_20260706_225325;

COMMIT;
