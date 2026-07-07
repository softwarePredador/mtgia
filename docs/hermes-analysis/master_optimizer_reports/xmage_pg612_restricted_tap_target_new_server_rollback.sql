BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('ali baba', 'coeurl', 'kitsune diviner', 'law-rune enforcer', 'sigardian priest', 'sterling keykeeper', 'storm front')
   OR normalized_name LIKE 'ali baba // %'
   OR normalized_name LIKE 'coeurl // %'
   OR normalized_name LIKE 'kitsune diviner // %'
   OR normalized_name LIKE 'law-rune enforcer // %'
   OR normalized_name LIKE 'sigardian priest // %'
   OR normalized_name LIKE 'sterling keykeeper // %'
   OR normalized_name LIKE 'storm front // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg612_restricted_tap_target_new_server_20260707_114017;

COMMIT;
