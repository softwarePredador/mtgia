BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('high fae trickster', 'hypersonic dragon', 'quick sliver', 'raff capashen, ship''s mage', 'shimmer myr', 'vernal equinox', 'yeva, nature''s herald')
   OR normalized_name LIKE 'high fae trickster // %'
   OR normalized_name LIKE 'hypersonic dragon // %'
   OR normalized_name LIKE 'quick sliver // %'
   OR normalized_name LIKE 'raff capashen, ship''s mage // %'
   OR normalized_name LIKE 'shimmer myr // %'
   OR normalized_name LIKE 'vernal equinox // %'
   OR normalized_name LIKE 'yeva, nature''s herald // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg465_xmage_static_cast_flash_permission_new_server_2026;

COMMIT;
