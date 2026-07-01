BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('banners raised', 'bar the door', 'burn bright', 'charge', 'chorus of woe', 'desperate charge', 'ethereal guidance', 'glorious charge', 'inspired charge', 'path of anger''s flame', 'righteous charge', 'scare tactics', 'shield wall', 'solidarity', 'steadfastness', 'virtuous charge', 'vitalizing wind', 'warrior''s charge', 'warrior''s honor')
   OR normalized_name LIKE 'banners raised // %'
   OR normalized_name LIKE 'bar the door // %'
   OR normalized_name LIKE 'burn bright // %'
   OR normalized_name LIKE 'charge // %'
   OR normalized_name LIKE 'chorus of woe // %'
   OR normalized_name LIKE 'desperate charge // %'
   OR normalized_name LIKE 'ethereal guidance // %'
   OR normalized_name LIKE 'glorious charge // %'
   OR normalized_name LIKE 'inspired charge // %'
   OR normalized_name LIKE 'path of anger''s flame // %'
   OR normalized_name LIKE 'righteous charge // %'
   OR normalized_name LIKE 'scare tactics // %'
   OR normalized_name LIKE 'shield wall // %'
   OR normalized_name LIKE 'solidarity // %'
   OR normalized_name LIKE 'steadfastness // %'
   OR normalized_name LIKE 'virtuous charge // %'
   OR normalized_name LIKE 'vitalizing wind // %'
   OR normalized_name LIKE 'warrior''s charge // %'
   OR normalized_name LIKE 'warrior''s honor // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg322_xmage_boost_controlled_until_eot_wave_20260701_183;

COMMIT;
