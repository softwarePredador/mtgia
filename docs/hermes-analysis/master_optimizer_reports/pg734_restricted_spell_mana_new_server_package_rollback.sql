BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('beastcaller savant', 'curious homunculus // voracious reader', 'herd heirloom', 'humble naturalist', 'ore-rich stalactite // cosmium catalyst', 'pelargir survivor', 'vodalian arcanist')
   OR normalized_name LIKE 'beastcaller savant // %'
   OR normalized_name LIKE 'curious homunculus // voracious reader // %'
   OR normalized_name LIKE 'herd heirloom // %'
   OR normalized_name LIKE 'humble naturalist // %'
   OR normalized_name LIKE 'ore-rich stalactite // cosmium catalyst // %'
   OR normalized_name LIKE 'pelargir survivor // %'
   OR normalized_name LIKE 'vodalian arcanist // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg734_restricted_spell_mana_new_server_20260711_021310;

COMMIT;
