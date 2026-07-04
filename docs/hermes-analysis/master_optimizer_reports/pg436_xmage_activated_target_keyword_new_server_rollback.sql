BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('accursed horde', 'air marshal', 'alabaster mage', 'axgard cavalry', 'beacon behemoth', 'bloodlust inciter', 'bloodthorn taunter', 'crimson mage', 'goblin motivator', 'hotfoot gnome', 'jawbone skulkin', 'kelsinko ranger', 'krosan groundshaker', 'might weaver', 'mosstodon', 'onyx mage', 'rage weaver', 'rakeclaw gargantuan', 'sky weaver', 'sootstoke kindler', 'spearbreaker behemoth', 'trailblazing historian', 'whalebone glider', 'whip sergeant')
   OR normalized_name LIKE 'accursed horde // %'
   OR normalized_name LIKE 'air marshal // %'
   OR normalized_name LIKE 'alabaster mage // %'
   OR normalized_name LIKE 'axgard cavalry // %'
   OR normalized_name LIKE 'beacon behemoth // %'
   OR normalized_name LIKE 'bloodlust inciter // %'
   OR normalized_name LIKE 'bloodthorn taunter // %'
   OR normalized_name LIKE 'crimson mage // %'
   OR normalized_name LIKE 'goblin motivator // %'
   OR normalized_name LIKE 'hotfoot gnome // %'
   OR normalized_name LIKE 'jawbone skulkin // %'
   OR normalized_name LIKE 'kelsinko ranger // %'
   OR normalized_name LIKE 'krosan groundshaker // %'
   OR normalized_name LIKE 'might weaver // %'
   OR normalized_name LIKE 'mosstodon // %'
   OR normalized_name LIKE 'onyx mage // %'
   OR normalized_name LIKE 'rage weaver // %'
   OR normalized_name LIKE 'rakeclaw gargantuan // %'
   OR normalized_name LIKE 'sky weaver // %'
   OR normalized_name LIKE 'sootstoke kindler // %'
   OR normalized_name LIKE 'spearbreaker behemoth // %'
   OR normalized_name LIKE 'trailblazing historian // %'
   OR normalized_name LIKE 'whalebone glider // %'
   OR normalized_name LIKE 'whip sergeant // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg436_xmage_activated_target_keyword_new_server_20260704;

COMMIT;
