BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bot bashing time', 'elspeth''s smite', 'fanged flames', 'feed the flames', 'flame-blessed bolt', 'lava coil', 'magma spray', 'obliterating bolt', 'puncturing blow', 'reduce to ashes', 'scorching dragonfire', 'scorchmark')
   OR normalized_name LIKE 'bot bashing time // %'
   OR normalized_name LIKE 'elspeth''s smite // %'
   OR normalized_name LIKE 'fanged flames // %'
   OR normalized_name LIKE 'feed the flames // %'
   OR normalized_name LIKE 'flame-blessed bolt // %'
   OR normalized_name LIKE 'lava coil // %'
   OR normalized_name LIKE 'magma spray // %'
   OR normalized_name LIKE 'obliterating bolt // %'
   OR normalized_name LIKE 'puncturing blow // %'
   OR normalized_name LIKE 'reduce to ashes // %'
   OR normalized_name LIKE 'scorching dragonfire // %'
   OR normalized_name LIKE 'scorchmark // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg449_xmage_damage_exile_if_dies_new_server_20260704_232;

COMMIT;
