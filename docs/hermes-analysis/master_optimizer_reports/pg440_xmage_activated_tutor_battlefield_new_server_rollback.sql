BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('amrou scout', 'bogbrew witch', 'burnished hart', 'cateran brute', 'cateran kidnappers', 'cateran persuader', 'dawntreader elk', 'diligent farmhand', 'embodiment of spring', 'font of fertility', 'frontier guide', 'moggcatcher', 'neverwinter dryad', 'oashra cultivator', 'planar bridge', 'ramosian commander', 'ramosian lieutenant', 'ramosian sergeant', 'seahunter', 'skyshroud poacher', 'whisper squad')
   OR normalized_name LIKE 'amrou scout // %'
   OR normalized_name LIKE 'bogbrew witch // %'
   OR normalized_name LIKE 'burnished hart // %'
   OR normalized_name LIKE 'cateran brute // %'
   OR normalized_name LIKE 'cateran kidnappers // %'
   OR normalized_name LIKE 'cateran persuader // %'
   OR normalized_name LIKE 'dawntreader elk // %'
   OR normalized_name LIKE 'diligent farmhand // %'
   OR normalized_name LIKE 'embodiment of spring // %'
   OR normalized_name LIKE 'font of fertility // %'
   OR normalized_name LIKE 'frontier guide // %'
   OR normalized_name LIKE 'moggcatcher // %'
   OR normalized_name LIKE 'neverwinter dryad // %'
   OR normalized_name LIKE 'oashra cultivator // %'
   OR normalized_name LIKE 'planar bridge // %'
   OR normalized_name LIKE 'ramosian commander // %'
   OR normalized_name LIKE 'ramosian lieutenant // %'
   OR normalized_name LIKE 'ramosian sergeant // %'
   OR normalized_name LIKE 'seahunter // %'
   OR normalized_name LIKE 'skyshroud poacher // %'
   OR normalized_name LIKE 'whisper squad // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg440_xmage_activated_tutor_battlefield_new_server_20260;

COMMIT;
