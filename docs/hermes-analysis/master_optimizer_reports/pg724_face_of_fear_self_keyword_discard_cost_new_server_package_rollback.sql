BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('face of fear')
   OR normalized_name LIKE 'face of fear // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg724_face_of_fear_self_keyword_discard_20260710_221412;

COMMIT;
