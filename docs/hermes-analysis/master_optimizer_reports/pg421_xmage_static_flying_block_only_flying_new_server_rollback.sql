BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('belbe''s percher', 'cloud djinn', 'cloud dragon', 'cloud elemental', 'cloud pirates', 'cloud spirit', 'cloud sprite', 'hoverguard observer', 'long-finned skywhale', 'rishadan airship', 'scrapskin drake', 'skywinder drake', 'stratozeppelid', 'stronghold zeppelin', 'tattered haunter', 'vaporkin', 'wanderlight spirit', 'welkin tern')
   OR normalized_name LIKE 'belbe''s percher // %'
   OR normalized_name LIKE 'cloud djinn // %'
   OR normalized_name LIKE 'cloud dragon // %'
   OR normalized_name LIKE 'cloud elemental // %'
   OR normalized_name LIKE 'cloud pirates // %'
   OR normalized_name LIKE 'cloud spirit // %'
   OR normalized_name LIKE 'cloud sprite // %'
   OR normalized_name LIKE 'hoverguard observer // %'
   OR normalized_name LIKE 'long-finned skywhale // %'
   OR normalized_name LIKE 'rishadan airship // %'
   OR normalized_name LIKE 'scrapskin drake // %'
   OR normalized_name LIKE 'skywinder drake // %'
   OR normalized_name LIKE 'stratozeppelid // %'
   OR normalized_name LIKE 'stronghold zeppelin // %'
   OR normalized_name LIKE 'tattered haunter // %'
   OR normalized_name LIKE 'vaporkin // %'
   OR normalized_name LIKE 'wanderlight spirit // %'
   OR normalized_name LIKE 'welkin tern // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg421_xmage_static_flying_block_only_flying_new_server_2;

COMMIT;
