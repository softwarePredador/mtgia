BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('angelic curator', 'azorius first-wing', 'beloved chaplain', 'commander eesha', 'horizon drake', 'nacatl savage', 'needlebug', 'tel-jilad archers', 'tel-jilad chosen', 'tel-jilad outrider', 'yavimaya scion')
   OR normalized_name LIKE 'angelic curator // %'
   OR normalized_name LIKE 'azorius first-wing // %'
   OR normalized_name LIKE 'beloved chaplain // %'
   OR normalized_name LIKE 'commander eesha // %'
   OR normalized_name LIKE 'horizon drake // %'
   OR normalized_name LIKE 'nacatl savage // %'
   OR normalized_name LIKE 'needlebug // %'
   OR normalized_name LIKE 'tel-jilad archers // %'
   OR normalized_name LIKE 'tel-jilad chosen // %'
   OR normalized_name LIKE 'tel-jilad outrider // %'
   OR normalized_name LIKE 'yavimaya scion // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg452_xmage_static_protection_card_types_new_server_2026;

COMMIT;
