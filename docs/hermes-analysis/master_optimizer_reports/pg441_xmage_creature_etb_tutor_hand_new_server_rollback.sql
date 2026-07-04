BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('borderland ranger', 'civic wayfinder', 'daru cavalier', 'deadeye quartermaster', 'environmental scientist', 'farfinder', 'gatecreeper vine', 'goblin matron', 'heliod''s pilgrim', 'howling wolf', 'nesting wurm', 'ranger of eos', 'rune-scarred demon', 'screaming seahawk', 'squadron hawk', 'sylvan ranger', 'totem-guide hartebeest', 'transit mage', 'tribute mage')
   OR normalized_name LIKE 'borderland ranger // %'
   OR normalized_name LIKE 'civic wayfinder // %'
   OR normalized_name LIKE 'daru cavalier // %'
   OR normalized_name LIKE 'deadeye quartermaster // %'
   OR normalized_name LIKE 'environmental scientist // %'
   OR normalized_name LIKE 'farfinder // %'
   OR normalized_name LIKE 'gatecreeper vine // %'
   OR normalized_name LIKE 'goblin matron // %'
   OR normalized_name LIKE 'heliod''s pilgrim // %'
   OR normalized_name LIKE 'howling wolf // %'
   OR normalized_name LIKE 'nesting wurm // %'
   OR normalized_name LIKE 'ranger of eos // %'
   OR normalized_name LIKE 'rune-scarred demon // %'
   OR normalized_name LIKE 'screaming seahawk // %'
   OR normalized_name LIKE 'squadron hawk // %'
   OR normalized_name LIKE 'sylvan ranger // %'
   OR normalized_name LIKE 'totem-guide hartebeest // %'
   OR normalized_name LIKE 'transit mage // %'
   OR normalized_name LIKE 'tribute mage // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg441_xmage_creature_etb_tutor_hand_new_server_20260704_;

COMMIT;
