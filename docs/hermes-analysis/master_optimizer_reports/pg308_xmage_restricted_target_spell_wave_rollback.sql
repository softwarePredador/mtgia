BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('arrows of justice', 'asphyxiate', 'assassinate', 'blade banish', 'bring to trial', 'burning oil', 'celestial purge', 'cosmium blast', 'death stroke', 'divine arrow', 'divine verdict', 'doom blade', 'dragon''s presence', 'epic downfall', 'excoriate', 'expel', 'ghostly visit', 'gideon''s reproach', 'hamato ninpō', 'hand of death', 'immolating glare', 'impeccable timing', 'iron verdict', 'kill shot', 'lens flare', 'neck snap', 'not on my watch', 'rebuke', 'righteous blow', 'sandblast', 'slash of talons', 'sudden strike', 'swift response', 'take vengeance', 'vanquish', 'vengeance', 'wallop', 'wanderer''s intervention')
   OR normalized_name LIKE 'arrows of justice // %'
   OR normalized_name LIKE 'asphyxiate // %'
   OR normalized_name LIKE 'assassinate // %'
   OR normalized_name LIKE 'blade banish // %'
   OR normalized_name LIKE 'bring to trial // %'
   OR normalized_name LIKE 'burning oil // %'
   OR normalized_name LIKE 'celestial purge // %'
   OR normalized_name LIKE 'cosmium blast // %'
   OR normalized_name LIKE 'death stroke // %'
   OR normalized_name LIKE 'divine arrow // %'
   OR normalized_name LIKE 'divine verdict // %'
   OR normalized_name LIKE 'doom blade // %'
   OR normalized_name LIKE 'dragon''s presence // %'
   OR normalized_name LIKE 'epic downfall // %'
   OR normalized_name LIKE 'excoriate // %'
   OR normalized_name LIKE 'expel // %'
   OR normalized_name LIKE 'ghostly visit // %'
   OR normalized_name LIKE 'gideon''s reproach // %'
   OR normalized_name LIKE 'hamato ninpō // %'
   OR normalized_name LIKE 'hand of death // %'
   OR normalized_name LIKE 'immolating glare // %'
   OR normalized_name LIKE 'impeccable timing // %'
   OR normalized_name LIKE 'iron verdict // %'
   OR normalized_name LIKE 'kill shot // %'
   OR normalized_name LIKE 'lens flare // %'
   OR normalized_name LIKE 'neck snap // %'
   OR normalized_name LIKE 'not on my watch // %'
   OR normalized_name LIKE 'rebuke // %'
   OR normalized_name LIKE 'righteous blow // %'
   OR normalized_name LIKE 'sandblast // %'
   OR normalized_name LIKE 'slash of talons // %'
   OR normalized_name LIKE 'sudden strike // %'
   OR normalized_name LIKE 'swift response // %'
   OR normalized_name LIKE 'take vengeance // %'
   OR normalized_name LIKE 'vanquish // %'
   OR normalized_name LIKE 'vengeance // %'
   OR normalized_name LIKE 'wallop // %'
   OR normalized_name LIKE 'wanderer''s intervention // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg308_xmage_restricted_target_spell_wave_20260701_133416;

COMMIT;
