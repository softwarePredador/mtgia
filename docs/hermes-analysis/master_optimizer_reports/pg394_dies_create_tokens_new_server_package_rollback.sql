BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('beskir shieldmate', 'brindle shoat', 'brood weaver', 'conscripted infantry', 'deathbloom thallid', 'discordant piper', 'doomed dissenter', 'doomed traveler', 'dwarven castle guard', 'elgaud inquisitor', 'filigree crawler', 'garrison cat', 'hunted witness', 'infestation sage', 'maalfeld twins', 'martyr of dusk', 'myr sire', 'penumbra bobcat', 'penumbra kavu', 'penumbra spider', 'penumbra wurm', 'pretending poxbearers', 'tukatongue thallid', 'wriggling grub')
   OR normalized_name LIKE 'beskir shieldmate // %'
   OR normalized_name LIKE 'brindle shoat // %'
   OR normalized_name LIKE 'brood weaver // %'
   OR normalized_name LIKE 'conscripted infantry // %'
   OR normalized_name LIKE 'deathbloom thallid // %'
   OR normalized_name LIKE 'discordant piper // %'
   OR normalized_name LIKE 'doomed dissenter // %'
   OR normalized_name LIKE 'doomed traveler // %'
   OR normalized_name LIKE 'dwarven castle guard // %'
   OR normalized_name LIKE 'elgaud inquisitor // %'
   OR normalized_name LIKE 'filigree crawler // %'
   OR normalized_name LIKE 'garrison cat // %'
   OR normalized_name LIKE 'hunted witness // %'
   OR normalized_name LIKE 'infestation sage // %'
   OR normalized_name LIKE 'maalfeld twins // %'
   OR normalized_name LIKE 'martyr of dusk // %'
   OR normalized_name LIKE 'myr sire // %'
   OR normalized_name LIKE 'penumbra bobcat // %'
   OR normalized_name LIKE 'penumbra kavu // %'
   OR normalized_name LIKE 'penumbra spider // %'
   OR normalized_name LIKE 'penumbra wurm // %'
   OR normalized_name LIKE 'pretending poxbearers // %'
   OR normalized_name LIKE 'tukatongue thallid // %'
   OR normalized_name LIKE 'wriggling grub // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg394_dies_create_tokens_new_server_20260704_083651;

COMMIT;
