BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('dauntless onslaught', 'hearts on fire', 'mischief and mayhem', 'nahiri''s stoneblades', 'sick and tired', 'symbiosis', 'windborne charge')
   OR normalized_name LIKE 'dauntless onslaught // %'
   OR normalized_name LIKE 'hearts on fire // %'
   OR normalized_name LIKE 'mischief and mayhem // %'
   OR normalized_name LIKE 'nahiri''s stoneblades // %'
   OR normalized_name LIKE 'sick and tired // %'
   OR normalized_name LIKE 'symbiosis // %'
   OR normalized_name LIKE 'windborne charge // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg703_multi_target_boost_scope_new_serve_20260710_140443;

COMMIT;
