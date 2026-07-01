BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('baleful strix', 'carven caryatid', 'cloudkin seer', 'council of advisors', 'elvish visionary', 'gallant citizen', 'generous stray', 'gryff vanguard', 'helpful hunter', 'joraga visionary', 'jungle barrier', 'kavu climber', 'kindly customer', 'merchant of secrets', 'messenger falcons', 'muse drake', 'nimble innovator', 'owlbear', 'pond prophet', 'rhox oracle', 'roving harper', 'shaman of spring', 'skyscanner', 'spirited companion', 'striped bears', 'tome raider', 'wall of blossoms', 'wistful selkie')
   OR normalized_name LIKE 'baleful strix // %'
   OR normalized_name LIKE 'carven caryatid // %'
   OR normalized_name LIKE 'cloudkin seer // %'
   OR normalized_name LIKE 'council of advisors // %'
   OR normalized_name LIKE 'elvish visionary // %'
   OR normalized_name LIKE 'gallant citizen // %'
   OR normalized_name LIKE 'generous stray // %'
   OR normalized_name LIKE 'gryff vanguard // %'
   OR normalized_name LIKE 'helpful hunter // %'
   OR normalized_name LIKE 'joraga visionary // %'
   OR normalized_name LIKE 'jungle barrier // %'
   OR normalized_name LIKE 'kavu climber // %'
   OR normalized_name LIKE 'kindly customer // %'
   OR normalized_name LIKE 'merchant of secrets // %'
   OR normalized_name LIKE 'messenger falcons // %'
   OR normalized_name LIKE 'muse drake // %'
   OR normalized_name LIKE 'nimble innovator // %'
   OR normalized_name LIKE 'owlbear // %'
   OR normalized_name LIKE 'pond prophet // %'
   OR normalized_name LIKE 'rhox oracle // %'
   OR normalized_name LIKE 'roving harper // %'
   OR normalized_name LIKE 'shaman of spring // %'
   OR normalized_name LIKE 'skyscanner // %'
   OR normalized_name LIKE 'spirited companion // %'
   OR normalized_name LIKE 'striped bears // %'
   OR normalized_name LIKE 'tome raider // %'
   OR normalized_name LIKE 'wall of blossoms // %'
   OR normalized_name LIKE 'wistful selkie // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg295_xmage_creature_etb_draw_wave_20260701_101317;

COMMIT;
