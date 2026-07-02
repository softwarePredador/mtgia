BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('dosan''s oldest chant', 'resupply', 'revitalize', 'reviving dose', 'ritual of rejuvenation')
   OR normalized_name LIKE 'dosan''s oldest chant // %'
   OR normalized_name LIKE 'resupply // %'
   OR normalized_name LIKE 'revitalize // %'
   OR normalized_name LIKE 'reviving dose // %'
   OR normalized_name LIKE 'ritual of rejuvenation // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg371_life_gain_draw_spell_wave_20260702_104450;

COMMIT;
