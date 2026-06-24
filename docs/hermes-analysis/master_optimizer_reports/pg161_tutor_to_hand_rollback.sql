BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('demonic tutor', 'diabolic intent', 'spellseeker', 'sylvan scrying', 'trophy mage')
   OR normalized_name LIKE 'demonic tutor // %'
   OR normalized_name LIKE 'diabolic intent // %'
   OR normalized_name LIKE 'spellseeker // %'
   OR normalized_name LIKE 'sylvan scrying // %'
   OR normalized_name LIKE 'trophy mage // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg161_tutor_to_hand_20260624_094937;

COMMIT;
