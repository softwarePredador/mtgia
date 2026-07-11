BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('amateur auteur', 'ancestral recall', 'black lotus', 'cleanse', 'crusade', 'nimble pilferer', 'novellamental', 'pradesh gypsies', 'river''s favor', 'timmy, power gamer')
   OR normalized_name LIKE 'amateur auteur // %'
   OR normalized_name LIKE 'ancestral recall // %'
   OR normalized_name LIKE 'black lotus // %'
   OR normalized_name LIKE 'cleanse // %'
   OR normalized_name LIKE 'crusade // %'
   OR normalized_name LIKE 'nimble pilferer // %'
   OR normalized_name LIKE 'novellamental // %'
   OR normalized_name LIKE 'pradesh gypsies // %'
   OR normalized_name LIKE 'river''s favor // %'
   OR normalized_name LIKE 'timmy, power gamer // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg788_next_safe_existing_scopes_new_serv_20260711_211319;

COMMIT;
