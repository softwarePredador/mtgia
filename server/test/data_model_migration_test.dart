import '../bin/migrate.dart' as migrate;
import 'package:test/test.dart';

void main() {
  group('data model migrations', () {
    test('migration 022 persists aggregate identity and intelligence views',
        () {
      final migration = migrate.migrations.singleWhere(
        (migration) => migration.version == '022',
      );
      final up = migration.up.toLowerCase();

      expect(
        migration.name,
        equals('create_card_identity_and_intelligence_views'),
      );
      expect(up, contains('create table if not exists card_meta_insights'));
      expect(up, contains('create table if not exists card_localized_names'));
      expect(up, contains('create or replace view card_identity_bridge'));
      expect(
        up,
        contains('create or replace view optimize_candidate_quality_summary'),
      );
      expect(up, contains('create or replace view card_intelligence_snapshot'));

      expect(
        up.indexOf('create table if not exists card_meta_insights'),
        lessThan(
            up.indexOf('create or replace view card_intelligence_snapshot')),
      );
      expect(
        up.indexOf('create table if not exists card_localized_names'),
        lessThan(up.indexOf('create or replace view card_identity_bridge')),
      );
      expect(
        up.indexOf('create table if not exists card_function_tags'),
        lessThan(
          up.indexOf(
              'create or replace view optimize_candidate_quality_summary'),
        ),
      );
    });
  });
}
