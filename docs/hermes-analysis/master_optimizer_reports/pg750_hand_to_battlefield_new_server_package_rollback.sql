BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('copper gnomes', 'didgeridoo', 'dragon arch', 'elvish piper', 'firebrand ranger', 'krosan wayfarer', 'llanowar scout', 'quicksilver amulet', 'sakura-tribe scout', 'scaled herbalist', 'thran temporal gateway', 'walking atlas')
   OR normalized_name LIKE 'copper gnomes // %'
   OR normalized_name LIKE 'didgeridoo // %'
   OR normalized_name LIKE 'dragon arch // %'
   OR normalized_name LIKE 'elvish piper // %'
   OR normalized_name LIKE 'firebrand ranger // %'
   OR normalized_name LIKE 'krosan wayfarer // %'
   OR normalized_name LIKE 'llanowar scout // %'
   OR normalized_name LIKE 'quicksilver amulet // %'
   OR normalized_name LIKE 'sakura-tribe scout // %'
   OR normalized_name LIKE 'scaled herbalist // %'
   OR normalized_name LIKE 'thran temporal gateway // %'
   OR normalized_name LIKE 'walking atlas // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg750_hand_to_battlefield_new_server_han_20260711_082520;

COMMIT;
