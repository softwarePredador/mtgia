BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('drag under', 'galestrike', 'leave in the dust', 'repulse', 'symbol of unsummoning')
   OR normalized_name LIKE 'drag under // %'
   OR normalized_name LIKE 'galestrike // %'
   OR normalized_name LIKE 'leave in the dust // %'
   OR normalized_name LIKE 'repulse // %'
   OR normalized_name LIKE 'symbol of unsummoning // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg374_bounce_draw_spell_wave_pg374_bounce_draw_spell_wav;

COMMIT;
