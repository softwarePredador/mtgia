BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('jace''s phantasm')
   OR normalized_name LIKE 'jace''s phantasm // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg815_opponent_graveyard_threshold_boost_20260712_074659;

COMMIT;
