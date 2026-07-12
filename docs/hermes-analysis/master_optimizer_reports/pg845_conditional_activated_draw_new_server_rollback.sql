BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('endless atlas', 'falkenrath pit fighter', 'fool''s tome', 'ragamuffyn', 'tapestry of the ages')
   OR normalized_name LIKE 'endless atlas // %'
   OR normalized_name LIKE 'falkenrath pit fighter // %'
   OR normalized_name LIKE 'fool''s tome // %'
   OR normalized_name LIKE 'ragamuffyn // %'
   OR normalized_name LIKE 'tapestry of the ages // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg845_conditional_activated_draw_new_ser_20260712_211331;

COMMIT;
