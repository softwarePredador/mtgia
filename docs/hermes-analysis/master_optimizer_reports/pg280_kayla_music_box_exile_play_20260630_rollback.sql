BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('kayla''s music box')
   OR normalized_name LIKE 'kayla''s music box // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg280_kayla_music_box_exile_play_20260630_123818;

COMMIT;
