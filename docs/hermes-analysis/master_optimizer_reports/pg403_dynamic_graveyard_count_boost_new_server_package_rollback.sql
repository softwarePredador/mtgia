BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('festive funeral', 'ghoul''s feast')
   OR normalized_name LIKE 'festive funeral // %'
   OR normalized_name LIKE 'ghoul''s feast // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg403_dynamic_graveyard_count_boost_new_server_20260704_;

COMMIT;
