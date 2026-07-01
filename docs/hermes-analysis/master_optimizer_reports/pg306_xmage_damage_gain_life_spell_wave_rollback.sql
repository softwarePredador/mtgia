BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('agonizing syphon', 'dark nourishment', 'defibrillating current', 'douse in gloom', 'essence drain', 'essence extraction', 'last kiss', 'pharika''s cure', 'sorin''s thirst', 'vampiric feast', 'vicious hunger', 'warleader''s helix', 'winter''s intervention')
   OR normalized_name LIKE 'agonizing syphon // %'
   OR normalized_name LIKE 'dark nourishment // %'
   OR normalized_name LIKE 'defibrillating current // %'
   OR normalized_name LIKE 'douse in gloom // %'
   OR normalized_name LIKE 'essence drain // %'
   OR normalized_name LIKE 'essence extraction // %'
   OR normalized_name LIKE 'last kiss // %'
   OR normalized_name LIKE 'pharika''s cure // %'
   OR normalized_name LIKE 'sorin''s thirst // %'
   OR normalized_name LIKE 'vampiric feast // %'
   OR normalized_name LIKE 'vicious hunger // %'
   OR normalized_name LIKE 'warleader''s helix // %'
   OR normalized_name LIKE 'winter''s intervention // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg306_xmage_damage_gain_life_spell_wave_20260701_125800;

COMMIT;
