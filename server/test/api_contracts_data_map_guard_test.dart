import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String contracts;

  setUpAll(() {
    contracts = File('doc/API_CONTRACTS_AND_DATA_MAP.md').readAsStringSync();
  });

  group('API contracts data map source guards', () {
    test('documents route-discovery edge cases and operational aliases', () {
      for (final route in const [
        'GET /cards/:id/rulings',
        'GET /binder/stats',
        'GET /binder/availability?card_ids=',
        'GET /community/decks/following',
        'GET /community/decks/:id/comments?page=&limit=',
        'POST /community/decks/:id/comments',
        'POST /community/decks/:id/reports',
        'GET /community/trade-matches?deck_id=&limit=',
        'GET /decks/:id/battle-replays?limit=',
        'GET /decks/:id/battle-replays/:replayId',
        'POST /decks/:id/reports',
        'GET /reports/:id',
        'GET /ready',
      ]) {
        expect(
          contracts,
          contains('| `$route'),
          reason:
              '$route must stay documented in API_CONTRACTS_AND_DATA_MAP.md',
        );
      }
    });

    test('does not document a generic GET binder item route', () {
      expect(
        contracts,
        isNot(contains('| `GET /binder/:id`')),
        reason:
            'server/routes/binder/[id]/index.dart only supports GET for the '
            'special /binder/stats alias; item detail GET is not a contract.',
      );
    });

    test(
      'preserves recently added AI contract rows from source-backed docs',
      () {
        for (final route in const [
          'POST /ai/simulate',
          'GET /ai/commander-learning?commander=',
        ]) {
          expect(
            contracts,
            contains('| `$route'),
            reason:
                '$route is source-backed and must not be dropped by docs sync.',
          );
        }
      },
    );

    test('documents Commander Learning list/detail metadata boundary', () {
      final row = _contractRowFor(
        contracts,
        'GET /ai/commander-learning?commander=',
      );

      expect(row, contains('safe summary fields'));
      expect(
        row,
        contains('detail-mode `role_summary` is canonicalized at read time'),
      );
      expect(
        row,
        contains(
          'PG ingress metadata may remain stale until approved backfill',
        ),
      );
      expect(row, contains('role_summary_source=card_list_canonicalized'));
      expect(row, contains('role_summary_source=persisted_metadata_fallback'));
      expect(row, contains('metadata_canonicalization_failed'));
      expect(row, contains('Raw Hermes `metadata` must remain hidden'));
    });

    test('documents advisory AI simulation response shapes', () {
      final simulate = _contractRowFor(contracts, 'POST /ai/simulate');
      final optimize = _contractRowFor(contracts, 'POST /ai/optimize');

      expect(simulate, contains('simulations` is clamped to `1..5000`'));
      expect(
        simulate,
        contains('This is a write route when storage tables exist'),
      );
      expect(simulate, contains('not legal verdict'));

      expect(optimize, contains('swap_integrity'));
      expect(contracts, contains('card_id:quantity:condition:role'));
      expect(contracts, contains('Changing which physical card is the'));
      expect(contracts, contains('cache contract is\n`v20`'));
      expect(contracts, contains('cache key is SHA-256'));
      expect(contracts, contains('scoped by `user_id`, `deck_id`'));
      expect(contracts, contains('commander_functional_role_floors_v3'));
      expect(optimize, contains('optimize_cache_support_test.dart'));
    });

    test('documents the four AI routes removed by D-31 only as removed', () {
      final removedSection = contracts.substring(
        contracts.indexOf('### Removed AI routes (D-31, BT-AI-029)'),
        contracts.indexOf('### Market'),
      );
      final liveContracts = contracts.replaceFirst(removedSection, '');
      for (final (route, substitute) in const [
        ('POST /decks/:id/recommendations', 'Optimize'),
        ('GET /decks/:id/simulate', 'Battle'),
        ('POST /ai/simulate-matchup', 'Battle'),
        ('POST /ai/weakness-analysis', 'Analyze'),
      ]) {
        expect(
          liveContracts,
          isNot(contains('| `$route')),
          reason: '$route was removed (D-31) and is no longer a contract',
        );
        final row = _contractRowFor(removedSection, route);
        expect(row, contains(substitute), reason: route);
      }
      expect(removedSection, contains('server/config/ai_route_registry.json'));
      expect(removedSection, contains('ai_route_registry_test.dart'));
    });

    test('documents deck builder read/write contract boundaries', () {
      final cards = _contractRowFor(
        contracts,
        'GET /cards?id=&name=&set=&include_tokens=&dedupe=&commander_format=&page=&limit=',
      );
      final printings = _contractRowFor(
        contracts,
        'GET /cards/printings?name=&limit=&dedupe=',
      );
      final resolve = _contractRowFor(contracts, 'POST /cards/resolve');
      final batchResolve = _contractRowFor(
        contracts,
        'POST /cards/resolve/batch',
      );
      final communityCopy = _contractRowFor(
        contracts,
        'POST /community/decks/:id',
      );
      final deckList = _contractRowFor(contracts, 'GET /decks');
      final createDeck = _contractRowFor(contracts, 'POST /decks');
      final deckDetail = _contractRowFor(contracts, 'GET /decks/:id');
      final updateDeck = _contractRowFor(contracts, 'PUT /decks/:id');
      final addCard = _contractRowFor(contracts, 'POST /decks/:id/cards');
      final bulkCards = _contractRowFor(
        contracts,
        'POST /decks/:id/cards/bulk',
      );
      final setCard = _contractRowFor(contracts, 'POST /decks/:id/cards/set');
      final replaceCard = _contractRowFor(
        contracts,
        'POST /decks/:id/cards/replace',
      );
      final validate = _contractRowFor(contracts, 'POST /decks/:id/validate');
      final pricing = _contractRowFor(contracts, 'POST /decks/:id/pricing');
      final export = _contractRowFor(contracts, 'GET /decks/:id/export');

      expect(cards, contains('include_tokens` defaults to `false`'));
      expect(cards, contains('`dedupe=identity`'));
      expect(cards, contains('`dedupe=false`'));
      expect(cards, contains('`commander_format=commander\\|brawl`'));
      expect(cards, contains('final commander eligibility'));
      expect(cards, contains('limited per IP (BT-CAT-03'));
      expect(cards, contains('429 `catalog_search_rate_limited`'));
      expect(cards, contains('503 `rate_limit_unavailable` (fail-closed)'));

      expect(printings, contains('Read-only since BT-CAT-04'));
      expect(
        printings,
        contains('never writes to the database and never calls Scryfall'),
      );
      expect(
        printings,
        contains('A legacy `sync=true` is accepted and ignored'),
      );
      expect(printings, contains('cards_printings_read_only_test.dart'));
      expect(printings, isNot(contains('write-capable')));

      expect(resolve, contains('Read-only since BT-CAT-02'));
      expect(resolve, contains('404 `{error: card_not_in_catalog'));
      expect(resolve, contains('never calls Scryfall and never writes'));
      expect(resolve, contains('cards_resolve_read_only_test.dart'));
      expect(resolve, isNot(contains('Scryfall fallback')));

      // D-63: a demanda de carta ausente sai do log, sem tabela.
      for (final row in [printings, resolve]) {
        expect(row, contains('`MANALOOM_CATALOG_CARD_DEMAND` log line'));
        expect(row, contains('no table and no database write'));
        expect(row, contains('catalog_card_demand_log_test.dart'));
      }

      expect(batchResolve, contains('card_identity_bridge` first'));
      expect(batchResolve, contains('bridge `match_priority`'));
      expect(batchResolve, contains('before preferred-printing'));
      expect(batchResolve, contains('`cards` fallback'));
      expect(batchResolve, contains('split-face names'));

      expect(communityCopy, contains('{success: true, deck}'));
      expect(
        communityCopy,
        contains('does not return `newDeckId` at the top level'),
      );
      expect(communityCopy, contains('Copied cards preserve only `card_id`'));
      expect(
        communityCopy,
        contains('deck_pricing_export_community_contract_test.dart'),
      );
      expect(communityCopy, contains('draft/review'));

      expect(deckList, contains('JSON array of decks'));
      expect(deckList, contains('card_count'));
      expect(deckList, contains('color_identity'));
      expect(deckList, contains('presentation union'));
      expect(deckList, contains('best-effort'));
      expect(deckList, contains('records non-200 detail fetches'));
      expect(deckList, contains('deck_fetch_hydration_contract_test.dart'));
      expect(deckList, contains('not `{data}`'));

      expect(createDeck, contains('DeckRulesService(... strict:false)'));
      expect(createDeck, contains('strict Commander/readiness validation'));
      expect(createDeck, contains('card_identity_bridge` first'));
      expect(createDeck, contains('fallback to `cards`'));
      expect(createDeck, contains('bridge `match_priority`'));
      expect(createDeck, contains('before preferred-printing'));
      expect(createDeck, contains('DeckProvider.createDeck(...)'));
      expect(createDeck, contains('explicit strategy metadata'));

      expect(deckDetail, contains('Root-level deck fields'));
      expect(deckDetail, contains('there is no nested root `deck` wrapper'));
      expect(deckDetail, contains('deterministic `deck_snapshot_hash`'));
      expect(deckDetail, contains('response-capture `deck_version_at`'));
      expect(
        deckDetail,
        contains('carries the returned snapshot identity through Life Counter'),
      );
      expect(deckDetail, contains('do not expose `oracle_id`, `layout`, or'));
      expect(deckDetail, contains('presentation aggregates'));
      expect(deckDetail, contains('deck_fetch_hydration_contract_test.dart'));

      final postGame = _contractRowFor(
        contracts,
        'POST /decks/:id/post-game-notes',
      );
      expect(
        postGame,
        contains('Snapshot hash/version must be omitted together'),
      );
      expect(
        postGame,
        contains('preserve the already persisted session identity'),
      );
      expect(postGame, contains('post_game_two_client_live_test.dart'));
      expect(postGame, contains('offline retry without duplicate'));

      expect(updateDeck, contains('{success: true, deck}'));
      expect(updateDeck, contains('replaces the full list'));
      expect(updateDeck, contains('preserve existing saved card `condition`'));
      expect(updateDeck, contains('newly added cards may omit `condition`'));
      expect(updateDeck, contains('card_identity_bridge` first'));
      expect(updateDeck, contains('fallback to `cards`'));
      expect(updateDeck, contains('bridge `match_priority`'));
      expect(updateDeck, contains('before preferred-printing'));
      expect(updateDeck, contains('DeckRulesService(... strict:false)'));

      expect(addCard, contains('Success response'));
      expect(addCard, contains('card_name'));
      expect(addCard, contains('total_cards'));
      expect(addCard, contains('DeckRulesService'));

      expect(bulkCards, contains('Existing legacy `deck_cards.condition`'));
      expect(bulkCards, contains('newly inserted bulk rows default to `NM`'));
      expect(
        bulkCards,
        contains('must not drop legacy decklist condition metadata'),
      );

      expect(setCard, contains('Success response'));
      expect(setCard, contains('replace_same_name=true'));
      expect(setCard, contains('same-name printing behavior'));
      expect(setCard, contains('not `oracle_id`/`physicalCopyKey`'));

      expect(replaceCard, contains('same-name-only'));
      expect(
        replaceCard,
        contains('does not use `oracle_id`/`physicalCopyKey`'),
      );
      expect(replaceCard, contains('changed=false'));

      expect(validate, contains('{ok: true, format, deck_id}'));
      expect(validate, contains('HTTP 404'));
      expect(validate, contains('error_code: deck_not_found'));
      expect(validate, contains('{ok: false, error, card_name?}'));
      expect(validate, contains('deck_validation_route_support_test.dart'));
      expect(validate, contains('DeckRulesService(... strict:true)'));
      expect(validate, contains('validation_updated_at'));
      expect(validate, contains('owner-row-locked'));
      expect(validate, contains('Migration 047'));
      expect(validate, contains('final legality/shape gate'));
      expect(validate, contains('post-save strict validation failure'));

      expect(pricing, contains('estimated_total_usd'));
      expect(pricing, contains('missing_price_cards'));
      expect(pricing, contains('does not return `total` or `missing` aliases'));
      expect(pricing, contains('always updates the deck pricing snapshot'));
      expect(pricing, contains('No Scryfall call and no write to `cards`'));
      expect(pricing, contains('have no effect since D-35'));
      expect(pricing, isNot(contains('may update card prices')));
      expect(pricing, isNot(contains('Scryfall fetches')));
      expect(pricing, contains('write-capable only because'));
      expect(pricing, contains('not deck strategy evidence'));

      expect(export, isNot(contains('deck_id`,')));
      expect(export, contains('does not return `deck_id`'));
      expect(export, contains('card_count` is exported line count'));
      expect(export, contains('not total quantity'));
    });
  });
}

String _contractRowFor(String contracts, String route) {
  final marker = '| `$route`';
  final start = contracts.indexOf(marker);
  if (start < 0) {
    throw StateError('Missing API contract row for $route');
  }
  final end = contracts.indexOf('\n', start);
  return contracts.substring(start, end < 0 ? contracts.length : end);
}
