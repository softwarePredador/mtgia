import 'dart:io';

import '../bin/migrate.dart' as migrate;
import 'package:test/test.dart';

String normalizeSql(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

void main() {
  group('social runtime schema contract', () {
    final setup = File('database_setup.sql').readAsStringSync().toLowerCase();
    final migration = migrate.migrations.singleWhere(
      (candidate) => candidate.version == '041',
    );
    final migrationUp = migration.up.toLowerCase();
    final normalizedSetup = normalizeSql(setup);
    final normalizedMigrationUp = normalizeSql(migrationUp);

    test('bootstrap and migration expose every route-owned relation', () {
      for (final table in const [
        'user_binder_items',
        'trade_offers',
        'trade_items',
        'trade_messages',
        'trade_status_history',
        'conversations',
        'direct_messages',
        'notifications',
      ]) {
        final declaration = 'create table if not exists $table';
        expect(setup, contains(declaration), reason: 'bootstrap: $table');
        expect(migrationUp, contains(declaration), reason: 'migration: $table');
      }
    });

    test('privacy and concurrency constraints match in both schema paths', () {
      for (final sql in [normalizedSetup, normalizedMigrationUp]) {
        expect(sql, contains('uq_user_binder_items_identity'));
        expect(sql, contains("list_type in ('have', 'want')"));
        expect(sql, contains('alter column binder_item_id drop not null'));
        expect(
          sql,
          contains(
            'foreign key (binder_item_id) references user_binder_items(id) '
            'on delete set null',
          ),
        );
        expect(sql, contains('uq_conversation_participants'));
        expect(sql, contains('least(user_a_id, user_b_id)'));
        expect(sql, contains('greatest(user_a_id, user_b_id)'));
        expect(sql, contains('idx_notifications_unread'));
        expect(sql, contains('chk_trade_offers_delivery_method'));
        for (final deliveryMethod in const [
          'correios',
          'motoboy',
          'pessoalmente',
          'outro',
        ]) {
          expect(sql, contains("'$deliveryMethod'"));
        }
      }
    });

    test('active-user guards are installed only after social tables exist', () {
      final setupSocial = setup.indexOf(
        'create table if not exists user_binder_items',
      );
      final setupGuards = setup.indexOf('do \$active_user_triggers\$');
      final migrationSocial = migrationUp.indexOf(
        'create table if not exists user_binder_items',
      );
      final migrationGuards = migrationUp.indexOf(r'do $active_user_triggers$');

      expect(setupSocial, greaterThanOrEqualTo(0));
      expect(setupGuards, greaterThan(setupSocial));
      expect(migrationSocial, greaterThanOrEqualTo(0));
      expect(migrationGuards, greaterThan(migrationSocial));
    });
  });
}
