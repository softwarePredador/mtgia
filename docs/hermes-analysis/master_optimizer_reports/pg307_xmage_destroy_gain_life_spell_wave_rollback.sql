BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('appetite for the unnatural', 'cursebreak', 'drain the well', 'grapple with death', 'invoke the divine', 'lich''s caress', 'maw of the mire', 'natural end', 'ray of dissolution', 'sanctify', 'sephiroth''s intervention', 'solemn offering', 'springsage ritual')
   OR normalized_name LIKE 'appetite for the unnatural // %'
   OR normalized_name LIKE 'cursebreak // %'
   OR normalized_name LIKE 'drain the well // %'
   OR normalized_name LIKE 'grapple with death // %'
   OR normalized_name LIKE 'invoke the divine // %'
   OR normalized_name LIKE 'lich''s caress // %'
   OR normalized_name LIKE 'maw of the mire // %'
   OR normalized_name LIKE 'natural end // %'
   OR normalized_name LIKE 'ray of dissolution // %'
   OR normalized_name LIKE 'sanctify // %'
   OR normalized_name LIKE 'sephiroth''s intervention // %'
   OR normalized_name LIKE 'solemn offering // %'
   OR normalized_name LIKE 'springsage ritual // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg307_xmage_destroy_gain_life_spell_wave_20260701_131317;

COMMIT;
