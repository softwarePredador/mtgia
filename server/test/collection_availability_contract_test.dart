import 'dart:io';

import '../bin/migrate.dart' as migrate;
import 'package:server/collection_availability_contract.dart';
import 'package:test/test.dart';

String normalizeSql(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

void main() {
  group('collection availability contract', () {
    final migration = migrate.migrations.singleWhere(
      (candidate) => candidate.version == '045',
    );
    final bootstrap = File('database_setup.sql').readAsStringSync();

    test('migration and bootstrap expose the same canonical views', () {
      expect(migration.name, 'create_collection_availability_contract');
      for (final sql in [migration.up, bootstrap]) {
        final normalized = normalizeSql(sql);
        expect(
          normalized,
          contains('create or replace view collection_availability_snapshot'),
        );
        expect(
          normalized,
          contains('create or replace view binder_item_availability'),
        );
        expect(normalized, contains('coalesce(c.oracle_id, c.id)'));
        expect(normalized, contains("d.deleted_at is null"));
        expect(normalized, contains("bi.list_type = 'have'"));
        expect(normalized, contains("bi.list_type = 'want'"));
      }
      expect(
        normalizeSql(migration.down!),
        contains('drop view if exists binder_item_availability'),
      );
    });

    test(
      'free, missing and commitments are clamped and independently named',
      () {
        final normalized = normalizeSql(collectionAvailabilityViewsSql);
        expect(normalized, contains('as owned_quantity'));
        expect(normalized, contains('as allocated_quantity'));
        expect(normalized, contains('as committed_trade_quantity'));
        expect(normalized, contains('as free_quantity'));
        expect(normalized, contains('as missing_quantity'));
        expect(normalized, contains('as wanted_missing_quantity'));
        expect(normalized, contains('greatest('));
        expect(
          normalized,
          contains("'pending', 'accepted', 'shipped', 'delivered', 'disputed'"),
        );
      },
    );

    test('item availability is deterministic across multiple printings', () {
      final normalized = normalizeSql(collectionAvailabilityViewsSql);
      expect(normalized, contains('partition by bi.user_id'));
      expect(
        normalized,
        contains('case when bi.for_trade or bi.for_sale then 0 else 1 end'),
      );
      expect(normalized, contains('rows between unbounded preceding'));
      expect(normalized, contains('as available_quantity'));
    });

    test(
      'quantity parser never leaks negative or malformed values from maps',
      () {
        expect(collectionQuantity(3), 3);
        expect(collectionQuantity(4.9), 4);
        expect(collectionQuantity('5'), 5);
        expect(collectionQuantity(null), 0);
        expect(collectionQuantity('invalid'), 0);
      },
    );
  });
}
