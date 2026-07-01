BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('apprentice wizard', 'fyndhorn elder', 'golgari signet', 'greenweaver druid', 'gruul signet', 'gyre engineer', 'knotvine mystic', 'kozilek''s channeler', 'llanowar tribe', 'nantuko elder', 'orzhov signet', 'palladium myr', 'rakdos signet', 'selesnya signet', 'sunastian falconer', 'weaver of currents')
   OR normalized_name LIKE 'apprentice wizard // %'
   OR normalized_name LIKE 'fyndhorn elder // %'
   OR normalized_name LIKE 'golgari signet // %'
   OR normalized_name LIKE 'greenweaver druid // %'
   OR normalized_name LIKE 'gruul signet // %'
   OR normalized_name LIKE 'gyre engineer // %'
   OR normalized_name LIKE 'knotvine mystic // %'
   OR normalized_name LIKE 'kozilek''s channeler // %'
   OR normalized_name LIKE 'llanowar tribe // %'
   OR normalized_name LIKE 'nantuko elder // %'
   OR normalized_name LIKE 'orzhov signet // %'
   OR normalized_name LIKE 'palladium myr // %'
   OR normalized_name LIKE 'rakdos signet // %'
   OR normalized_name LIKE 'selesnya signet // %'
   OR normalized_name LIKE 'sunastian falconer // %'
   OR normalized_name LIKE 'weaver of currents // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg324_xmage_permanent_fixed_tap_mana_wave_20260701_19244;

COMMIT;
