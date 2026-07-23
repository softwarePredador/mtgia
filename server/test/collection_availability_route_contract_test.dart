import 'dart:io';

import 'package:test/test.dart';

String source(String path) => File(path).readAsStringSync();

void main() {
  group('collection availability route contract', () {
    test('private binder exposes one canonical quantity vocabulary', () {
      final binder = source('routes/binder/index.dart');
      final stats = source('routes/binder/[id]/index.dart');
      for (final field in const [
        'playable_card_id',
        'owned_quantity',
        'allocated_quantity',
        'committed_trade_quantity',
        'free_quantity',
        'missing_quantity',
        'available_quantity',
      ]) {
        expect(binder, contains("'$field':"), reason: field);
      }
      expect(stats, contains("'deck_missing_quantity':"));
      expect(stats, contains('collection_availability_snapshot'));
    });

    test('deck search availability resolves every printing by playable id', () {
      final route = source('routes/binder/[id]/index.dart');

      expect(route, contains("id == 'availability'"));
      expect(route, contains('GET /binder/availability?card_ids='));
      expect(route, contains('COALESCE(c.oracle_id, c.id)'));
      expect(route, contains('collection_availability_snapshot'));
      expect(route, contains("'playable_card_id':"));
      expect(route, contains("'owned_quantity':"));
      expect(route, contains("'allocated_quantity':"));
      expect(route, contains("'free_quantity':"));
      expect(route, contains("'missing_quantity':"));
    });

    test('binder deck usage joins alternate printings by playable identity', () {
      final list = source('routes/binder/index.dart');
      final stats = source('routes/binder/[id]/index.dart');

      expect(
        list,
        contains('du.playable_card_id = COALESCE(c.oracle_id, c.id)'),
      );
      expect(stats, contains('WITH binder_identities AS'));
      expect(stats, contains('JOIN deck_usage deck USING (playable_card_id)'));
    });

    test('public binder and marketplace advertise only item availability', () {
      final publicBinder = source('routes/community/binders/[userId].dart');
      final marketplace = source('routes/community/marketplace/index.dart');
      for (final route in [publicBinder, marketplace]) {
        expect(route, contains('binder_item_availability'));
        expect(route, contains('available_quantity > 0'));
        expect(route, contains("'available_quantity':"));
      }
    });

    test('deck optimizer prefers free copies by playable identity', () {
      final optimizer = source('lib/ai/optimize_swap_candidate_support.dart');
      expect(optimizer, contains('collection_availability_snapshot'));
      expect(optimizer, contains('COALESCE(c.oracle_id, c.id)'));
      expect(optimizer, contains('availability.free_quantity'));
      expect(optimizer, contains("'available_quantity': availableQuantity"));
      expect(optimizer, isNot(contains('WHERE bi.card_id = c.id')));
    });

    test(
      'trade creation serializes inventory and rechecks inside transaction',
      () {
        final trade = source('routes/trades/index.dart');
        final transaction = trade.indexOf('pool.runTx');
        final binderLock = trade.indexOf('FOR UPDATE', transaction);
        final availabilityCheck = trade.indexOf(
          '_requireTradeItemsAvailable(',
          binderLock,
        );
        final insert = trade.indexOf(
          'INSERT INTO trade_offers',
          availabilityCheck,
        );

        expect(transaction, greaterThanOrEqualTo(0));
        expect(binderLock, greaterThan(transaction));
        expect(availabilityCheck, greaterThan(binderLock));
        expect(insert, greaterThan(availabilityCheck));
        expect(trade, contains('trade_quantity_unavailable'));
        expect(trade, contains('binder_item_id duplicado'));
        expect(trade, contains('binder_item_availability'));
      },
    );
  });
}
