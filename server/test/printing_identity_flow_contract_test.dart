import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('printing identity flow source contracts', () {
    test('binder, marketplace and public binder expose physical identity', () {
      final routes = [
        File('routes/binder/index.dart').readAsStringSync(),
        File('routes/community/marketplace/index.dart').readAsStringSync(),
        File('routes/community/binders/[userId].dart').readAsStringSync(),
      ];

      for (final route in routes) {
        expect(route, contains('c.scryfall_id::text'));
        expect(route, contains('c.oracle_id::text'));
        expect(route, contains('c.collector_number'));
        expect(route, contains('c.card_faces_json'));
        expect(route, contains('SELECT DISTINCT ON (LOWER(code))'));
        expect(route, contains('normalizeScryfallImageUrl('));
        expect(route, contains("'collector_number':"));
        expect(route, contains("'set_name':"));
        expect(route, contains("'set_release_date':"));
        expect(route, contains("'language':"));
      }

      final publicBinder = routes[2];
      expect(publicBinder, contains("params['item_id']"));
      expect(publicBinder, contains('bi.id = CAST(@itemId AS uuid)'));
      expect(publicBinder, contains('bi.created_at'));
      expect(publicBinder, contains('bi.updated_at'));
      expect(publicBinder, contains("'created_at':"));
      expect(publicBinder, contains("'updated_at':"));
    });

    test('trade creation captures and detail prefers immutable identity', () {
      final create = File('routes/trades/index.dart').readAsStringSync();
      final detail = File('routes/trades/[id]/index.dart').readAsStringSync();

      expect(create, contains("'trade_item_snapshot_v1'"));
      expect(create, contains("'captured'"));
      expect(create, contains("'physical', jsonb_build_object"));
      expect(create, contains("'card', jsonb_strip_nulls"));
      expect(create, contains('snapshot_captured_at'));
      expect(create, contains('JOIN user_binder_items binder'));
      expect(create, contains('JOIN cards card'));

      expect(detail, contains("ti.item_snapshot #>> '{physical,condition}'"));
      expect(detail, contains("ti.item_snapshot #>> '{card,scryfall_id}'"));
      expect(detail, contains("ti.item_snapshot #>> '{card,oracle_id}'"));
      expect(
        detail,
        contains("ti.item_snapshot #>> '{card,collector_number}'"),
      );
      expect(detail, contains("ti.item_snapshot #> '{card,card_faces}'"));
      expect(detail, contains('LEFT JOIN user_binder_items'));
      expect(detail, contains('LEFT JOIN cards'));
      expect(detail, contains('normalizeScryfallImageUrl('));
      expect(detail, contains("'snapshot_status': snapshotStatus"));
      expect(detail, contains("'identity_status': identityStatus"));
      expect(detail, contains("'language': m['language']"));
    });

    test('optimize removals keep the card id actually present in the deck', () {
      final route = File('routes/ai/optimize/index.dart').readAsStringSync();

      expect(route, contains("originalCard?['card_id']?.toString()"));
      expect(route, contains('cardId: originalCardId'));
      expect(
        route,
        isNot(
          contains(
            "type: 'remove',\n                  name: '\${v['name']}',\n                  cardId: '\${v['id']}'",
          ),
        ),
      );
    });
  });
}
