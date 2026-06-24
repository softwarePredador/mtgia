BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('misty rainforest', 'verdant catacombs', 'polluted delta')
   OR normalized_name LIKE 'misty rainforest // %'
   OR normalized_name LIKE 'verdant catacombs // %'
   OR normalized_name LIKE 'polluted delta // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg158_fetchlands_20260624_090255;

COMMIT;
