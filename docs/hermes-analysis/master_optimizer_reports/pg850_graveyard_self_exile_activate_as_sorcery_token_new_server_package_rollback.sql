BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('dauntless cathar', 'fairgrounds patrol', 'ghoulcaller''s accomplice', 'goldmeadow nomad', 'mother bear', 'stoic grove-guide', 'suspicious shambler')
   OR normalized_name LIKE 'dauntless cathar // %'
   OR normalized_name LIKE 'fairgrounds patrol // %'
   OR normalized_name LIKE 'ghoulcaller''s accomplice // %'
   OR normalized_name LIKE 'goldmeadow nomad // %'
   OR normalized_name LIKE 'mother bear // %'
   OR normalized_name LIKE 'stoic grove-guide // %'
   OR normalized_name LIKE 'suspicious shambler // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg850_graveyard_self_exile_activate_as_s_20260712_230546;

COMMIT;
